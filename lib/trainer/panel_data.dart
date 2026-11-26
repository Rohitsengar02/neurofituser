import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trainer_data.dart';

// Trainer panel state: the coach's profile from onboarding, panel mode, and
// the data behind the 10 dashboard features (plans, clients, content,
// schedule, messages, earnings, reviews, diet templates). Everything is
// local and persisted so the panel works without the backend.

String face(int i, {bool woman = false}) => 'https://randomuser.me/api/portraits/${woman ? 'women' : 'men'}/$i.jpg';

class PPlan {
  String name;
  int months, price, subs;
  bool active;
  List<String> perks;
  PPlan(this.name, this.months, this.price, this.subs, this.active, this.perks);
  Map<String, dynamic> toJson() => {'n': name, 'm': months, 'p': price, 's': subs, 'a': active, 'k': perks};
  static PPlan fromJson(Map<String, dynamic> j) =>
      PPlan(j['n'], j['m'], j['p'], j['s'], j['a'], List<String>.from(j['k'] ?? const []));
}

class PClient {
  final String id, name, photo, goal, plan;
  final DateTime since, until;
  final double startKg, nowKg;
  final int workouts, streak;
  String status; // active, expiring, paused
  String note;
  int unread;
  final List<ChatMsg> chat;
  PClient(this.id, this.name, this.photo, this.goal, this.plan, this.since, this.until, this.startKg, this.nowKg, this.workouts,
      this.streak, this.status, this.note, this.unread, this.chat);
  int get daysLeft => until.difference(DateTime.now()).inDays;
  double get progress => (workouts / 48).clamp(0, 1);
}

class PWorkout {
  final String id, title, level, kind; // kind: Video, Plan, Live replay
  final int minutes;
  final List<String> exercises;
  final String? cover; // asset path or base64 bytes
  final DateTime at;
  bool published;
  int views, saves;
  PWorkout(this.id, this.title, this.level, this.kind, this.minutes, this.exercises, this.cover, this.at, this.published, this.views,
      this.saves);
  Map<String, dynamic> toJson() => {
        'i': id,
        't': title,
        'l': level,
        'k': kind,
        'm': minutes,
        'e': exercises,
        'c': cover,
        'a': at.millisecondsSinceEpoch,
        'p': published,
        'v': views,
        's': saves,
      };
  static PWorkout fromJson(Map<String, dynamic> j) => PWorkout(j['i'], j['t'], j['l'], j['k'], j['m'], List<String>.from(j['e']),
      j['c'], DateTime.fromMillisecondsSinceEpoch(j['a']), j['p'], j['v'], j['s']);
}

class PSession {
  final String id, title, kind; // Live class, 1:1 call, Check-in
  final DateTime at;
  final int minutes;
  final String? client;
  PSession(this.id, this.title, this.kind, this.at, this.minutes, this.client);
  Map<String, dynamic> toJson() => {'i': id, 't': title, 'k': kind, 'a': at.millisecondsSinceEpoch, 'm': minutes, 'c': client};
  static PSession fromJson(Map<String, dynamic> j) =>
      PSession(j['i'], j['t'], j['k'], DateTime.fromMillisecondsSinceEpoch(j['a']), j['m'], j['c']);
}

class PTxn {
  final String title, sub;
  final int amount; // negative for payouts
  final DateTime at;
  PTxn(this.title, this.sub, this.amount, this.at);
  Map<String, dynamic> toJson() => {'t': title, 's': sub, 'v': amount, 'a': at.millisecondsSinceEpoch};
  static PTxn fromJson(Map<String, dynamic> j) => PTxn(j['t'], j['s'], j['v'], DateTime.fromMillisecondsSinceEpoch(j['a']));
}

class PReview {
  final String id, name, photo, text;
  final int stars;
  final DateTime at;
  String? reply;
  PReview(this.id, this.name, this.photo, this.text, this.stars, this.at, [this.reply]);
}

class PDiet {
  String name, goal;
  int kcal, protein;
  List<String> meals;
  int assigned;
  PDiet(this.name, this.goal, this.kcal, this.protein, this.meals, this.assigned);
  Map<String, dynamic> toJson() => {'n': name, 'g': goal, 'k': kcal, 'p': protein, 'm': meals, 'a': assigned};
  static PDiet fromJson(Map<String, dynamic> j) => PDiet(j['n'], j['g'], j['k'], j['p'], List<String>.from(j['m']), j['a']);
}

const specialtyOptions = [
  'Strength',
  'Fat loss',
  'Muscle gain',
  'Yoga',
  'HIIT',
  'Mobility',
  'Running',
  'Boxing',
  'Pilates',
  'Nutrition',
  'Rehab',
  'Calisthenics',
];

class PanelStore extends ChangeNotifier {
  PanelStore._() {
    _seed();
    _load();
  }
  static final PanelStore I = PanelStore._();
  static const _key = 'trainer_panel_v1';

  bool registered = false;
  bool panelMode = false;
  bool ready = false;

  // Profile from onboarding.
  String name = 'Rohit Sengar';
  String headline = 'Strength and fat-loss coach';
  String bio = 'I help busy people get strong, lean and consistent with simple plans that fit real life.';
  String city = 'Delhi';
  String mode = 'Online';
  int years = 3;
  List<String> specialties = ['Strength', 'Fat loss'];
  List<String> certs = ['ACE Certified Personal Trainer'];
  String? photo; // base64

  bool acceptingClients = true;

  // Live.
  bool live = false;
  DateTime? liveSince;
  String liveTitle = '';
  int liveSessions = 0;

  final List<PPlan> plans = [];
  final List<PClient> clients = [];
  final List<PWorkout> workouts = [];
  final List<PSession> sessions = [];
  final List<PTxn> txns = [];
  final List<PReview> reviews = [];
  final List<PDiet> diets = [];

  // ----- derived -----
  int get activeClients => clients.where((c) => c.status != 'paused').length;
  int get expiring => clients.where((c) => c.status == 'expiring').length;
  int get unread => clients.fold(0, (a, c) => a + c.unread);
  int get balance => txns.fold(0, (a, t) => a + t.amount);
  int get monthEarnings {
    final now = DateTime.now();
    return txns.where((t) => t.amount > 0 && t.at.month == now.month && t.at.year == now.year).fold(0, (a, t) => a + t.amount);
  }

  double get rating => reviews.isEmpty ? 0 : reviews.fold(0, (a, r) => a + r.stars) / reviews.length;
  List<PSession> get upcoming {
    final now = DateTime.now().subtract(const Duration(minutes: 30));
    final l = sessions.where((s) => s.at.isAfter(now)).toList()..sort((a, b) => a.at.compareTo(b.at));
    return l;
  }

  /// Earnings per week for the last 8 weeks (oldest first).
  List<int> get weekly {
    final now = DateTime.now();
    final out = List<int>.filled(8, 0);
    for (final t in txns.where((t) => t.amount > 0)) {
      final w = now.difference(t.at).inDays ~/ 7;
      if (w < 8) out[7 - w] += t.amount;
    }
    return out;
  }

  // ----- actions -----
  void register({
    required String name,
    required String headline,
    required String bio,
    required String city,
    required String mode,
    required int years,
    required List<String> specialties,
    required List<String> certs,
    required List<PPlan> plans,
    String? photo,
  }) {
    this.name = name;
    this.headline = headline;
    this.bio = bio;
    this.city = city;
    this.mode = mode;
    this.years = years;
    this.specialties = specialties;
    this.certs = certs;
    this.photo = photo;
    this.plans
      ..clear()
      ..addAll(plans);
    registered = true;
    panelMode = true;
    _save();
  }

  void enterPanel() {
    panelMode = true;
    _save();
  }

  void exitPanel() {
    panelMode = false;
    _save();
  }

  void leaveCoaching() {
    registered = false;
    panelMode = false;
    _save();
  }

  void setAccepting(bool v) {
    acceptingClients = v;
    _save();
  }

  void updateProfile({String? name, String? headline, String? bio, String? city, String? photo}) {
    if (name != null) this.name = name;
    if (headline != null) this.headline = headline;
    if (bio != null) this.bio = bio;
    if (city != null) this.city = city;
    if (photo != null) this.photo = photo;
    _save();
  }

  void savePlan(PPlan p, {bool isNew = false}) {
    if (isNew) plans.add(p);
    _save();
  }

  void removePlan(PPlan p) {
    plans.remove(p);
    _save();
  }

  void togglePlan(PPlan p) {
    p.active = !p.active;
    _save();
  }

  void startLive(String title) {
    live = true;
    liveTitle = title;
    liveSince = DateTime.now();
    notifyListeners();
  }

  /// Ends the stream; returns minutes streamed.
  int endLive({int viewers = 0, int tips = 0}) {
    final m = liveSince == null ? 0 : DateTime.now().difference(liveSince!).inMinutes;
    live = false;
    liveSessions++;
    if (tips > 0) txns.insert(0, PTxn('Live tips', liveTitle, tips, DateTime.now()));
    workouts.insert(
      0,
      PWorkout('w${DateTime.now().millisecondsSinceEpoch}', liveTitle.isEmpty ? 'Live class' : liveTitle, 'All levels', 'Live replay',
          m.clamp(1, 120), const [], null, DateTime.now(), true, viewers, 0),
    );
    liveSince = null;
    _save();
    return m;
  }

  void publish(PWorkout w) {
    workouts.insert(0, w);
    _save();
  }

  void toggleWorkout(PWorkout w) {
    w.published = !w.published;
    _save();
  }

  void deleteWorkout(PWorkout w) {
    workouts.remove(w);
    _save();
  }

  void addSession(PSession s) {
    sessions.add(s);
    _save();
  }

  void cancelSession(PSession s) {
    sessions.remove(s);
    _save();
  }

  void sendTo(PClient c, String text) {
    c.chat.add(ChatMsg(true, text, DateTime.now()));
    notifyListeners();
  }

  void readChat(PClient c) {
    if (c.unread == 0) return;
    c.unread = 0;
    notifyListeners();
  }

  void setClientStatus(PClient c, String s) {
    c.status = s;
    notifyListeners();
  }

  void setClientNote(PClient c, String n) {
    c.note = n;
    notifyListeners();
  }

  void renew(PClient c) {
    c.status = 'active';
    txns.insert(0, PTxn('Renewal · ${c.name}', c.plan, plans.isEmpty ? 1499 : plans.first.price, DateTime.now()));
    _save();
  }

  bool withdraw(int amount) {
    if (amount <= 0 || amount > balance) return false;
    txns.insert(0, PTxn('Payout to bank', 'HDFC ••4821 · arrives in 1 day', -amount, DateTime.now()));
    _save();
    return true;
  }

  void reply(PReview r, String text) {
    r.reply = text;
    notifyListeners();
  }

  void saveDiet(PDiet d, {bool isNew = false}) {
    if (isNew) diets.insert(0, d);
    _save();
  }

  void assignDiet(PDiet d, int n) {
    d.assigned += n;
    _save();
  }

  // ----- persistence -----
  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        registered = j['reg'] ?? false;
        panelMode = j['mode'] ?? false;
        name = j['name'] ?? name;
        headline = j['head'] ?? headline;
        bio = j['bio'] ?? bio;
        city = j['city'] ?? city;
        mode = j['how'] ?? mode;
        years = j['yrs'] ?? years;
        specialties = List<String>.from(j['spec'] ?? specialties);
        certs = List<String>.from(j['certs'] ?? certs);
        photo = j['photo'];
        acceptingClients = j['acc'] ?? true;
        liveSessions = j['ls'] ?? 0;
        if (j['plans'] != null) {
          plans
            ..clear()
            ..addAll((j['plans'] as List).map((e) => PPlan.fromJson(Map<String, dynamic>.from(e))));
        }
        if (j['wo'] != null) {
          workouts
            ..clear()
            ..addAll((j['wo'] as List).map((e) => PWorkout.fromJson(Map<String, dynamic>.from(e))));
        }
        if (j['ses'] != null) {
          sessions
            ..clear()
            ..addAll((j['ses'] as List).map((e) => PSession.fromJson(Map<String, dynamic>.from(e))));
        }
        if (j['tx'] != null) {
          txns
            ..clear()
            ..addAll((j['tx'] as List).map((e) => PTxn.fromJson(Map<String, dynamic>.from(e))));
        }
        if (j['diet'] != null) {
          diets
            ..clear()
            ..addAll((j['diet'] as List).map((e) => PDiet.fromJson(Map<String, dynamic>.from(e))));
        }
      }
    } catch (_) {}
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      // Keep at most a few uploaded covers so storage stays small.
      var covers = 0;
      final wo = workouts.map((w) {
        final j = w.toJson();
        final c = w.cover;
        if (c != null && !c.startsWith('assets/')) {
          covers++;
          if (covers > 4) j['c'] = null;
        }
        return j;
      }).toList();
      await p.setString(
        _key,
        jsonEncode({
          'reg': registered,
          'mode': panelMode,
          'name': name,
          'head': headline,
          'bio': bio,
          'city': city,
          'how': mode,
          'yrs': years,
          'spec': specialties,
          'certs': certs,
          'photo': photo,
          'acc': acceptingClients,
          'ls': liveSessions,
          'plans': plans.map((e) => e.toJson()).toList(),
          'wo': wo,
          'ses': sessions.map((e) => e.toJson()).toList(),
          'tx': txns.take(60).map((e) => e.toJson()).toList(),
          'diet': diets.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  // ----- seed -----
  void _seed() {
    final now = DateTime.now();
    DateTime d(int days, [int h = 9, int m = 0]) => DateTime(now.year, now.month, now.day + days, h, m);

    plans.addAll([
      PPlan('Monthly', 1, 1499, 18, true, ['Custom workout plan', 'Weekly check-in', 'Chat support']),
      PPlan('Quarterly', 3, 3899, 11, true, ['Everything in Monthly', 'Diet plan', '2 video calls a month']),
      PPlan('Yearly', 12, 12999, 5, true, ['Everything in Quarterly', 'Priority replies', 'Live classes free']),
    ]);

    final names = [
      ('Aarav Mehta', 12, false, 'Lose 8 kg', 'Quarterly', 84.0, 79.4, 31, 9, 'active', 2),
      ('Isha Kapoor', 44, true, 'Tone up', 'Monthly', 62.0, 59.8, 22, 14, 'active', 1),
      ('Kabir Singh', 32, false, 'Build muscle', 'Yearly', 68.0, 72.5, 46, 21, 'active', 0),
      ('Neha Verma', 65, true, 'Run 10K', 'Monthly', 58.0, 56.9, 12, 4, 'expiring', 0),
      ('Rahul Nair', 75, false, 'Lose 12 kg', 'Quarterly', 96.0, 90.1, 27, 6, 'active', 3),
      ('Sara Khan', 21, true, 'Postpartum fitness', 'Monthly', 70.0, 67.2, 18, 3, 'expiring', 0),
      ('Vikram Rao', 52, false, 'Mobility', 'Monthly', 78.0, 77.6, 8, 0, 'paused', 0),
      ('Ananya Das', 90, true, 'Strength', 'Quarterly', 55.0, 56.3, 35, 11, 'active', 1),
    ];
    final msgs = [
      'Done with today’s workout! Legs are on fire 🔥',
      'Can I swap squats for leg press today?',
      'Hit a new PR on deadlift, 120 kg!',
      'Missed yesterday, will double up today.',
      'What should I eat before a morning session?',
      'Feeling much more energetic this week.',
      'Back pain is better, can we restart?',
      'Thanks for the new plan 🙏',
    ];
    for (var i = 0; i < names.length; i++) {
      final n = names[i];
      final since = d(-(20 + i * 9));
      final months = n.$5 == 'Yearly' ? 12 : n.$5 == 'Quarterly' ? 3 : 1;
      var until = DateTime(since.year, since.month + months, since.day);
      if (n.$10 == 'expiring') until = d(2 + i % 3);
      if (until.isBefore(now) && n.$10 == 'active') until = DateTime(now.year, now.month + 1, since.day);
      clients.add(PClient(
        'c$i',
        n.$1,
        face(n.$2, woman: n.$3),
        n.$4,
        n.$5,
        since,
        until,
        n.$6,
        n.$7,
        n.$8,
        n.$9,
        n.$10,
        '',
        n.$11,
        [
          ChatMsg(true, 'How did the session go today?', now.subtract(Duration(hours: 3 + i))),
          ChatMsg(false, msgs[i], now.subtract(Duration(hours: 2 + i, minutes: 10 * i))),
        ],
      ));
    }

    workouts.addAll([
      PWorkout('w1', 'Full body burn', 'Beginner', 'Video', 25, ['Jumping jacks', 'Squat', 'Push-up', 'Plank'],
          exImg('1160-dK9394r.jpg'), d(-2), true, 1840, 212),
      PWorkout('w2', 'Push day hypertrophy', 'Intermediate', 'Plan', 55, ['Bench press', 'Incline DB press', 'Dips', 'Lateral raise'],
          exImg('0025-EIeI8Vf.jpg'), d(-6), true, 960, 140),
      PWorkout('w3', 'Mobility flow', 'All levels', 'Video', 15, ['Cat-cow', 'World’s greatest stretch', 'Hip 90/90'], null, d(-9),
          false, 0, 0),
    ]);

    sessions.addAll([
      PSession('s1', 'HIIT live class', 'Live class', d(0, 18, 30), 45, null),
      PSession('s2', 'Form check', '1:1 call', d(0, 20, 0), 20, 'Aarav Mehta'),
      PSession('s3', 'Monthly review', 'Check-in', d(1, 9, 30), 30, 'Isha Kapoor'),
      PSession('s4', 'Mobility live', 'Live class', d(2, 7, 0), 30, null),
      PSession('s5', 'Diet consult', '1:1 call', d(3, 19, 0), 30, 'Rahul Nair'),
    ]);

    var k = 0;
    for (var w = 0; w < 8; w++) {
      final n = 2 + (w * 7 + 3) % 4;
      for (var j = 0; j < n; j++) {
        final c = clients[k++ % clients.length];
        final price = c.plan == 'Yearly' ? 12999 : c.plan == 'Quarterly' ? 3899 : 1499;
        txns.add(PTxn('${c.plan} plan · ${c.name}', 'Subscription', price, now.subtract(Duration(days: w * 7 + j * 2, hours: j))));
      }
    }
    txns.add(PTxn('Payout to bank', 'HDFC ••4821', -18000, now.subtract(const Duration(days: 30))));
    txns.add(PTxn('Payout to bank', 'HDFC ••4821', -15000, now.subtract(const Duration(days: 45))));
    txns.sort((a, b) => b.at.compareTo(a.at));

    reviews.addAll([
      PReview('r1', 'Isha Kapoor', face(44, woman: true), 'Down 2 kg in a month and I actually enjoy training now. Super clear plans.', 5,
          now.subtract(const Duration(days: 2))),
      PReview('r2', 'Kabir Singh', face(32), 'Gained 4.5 kg of mostly muscle. The weekly check-ins keep me honest.', 5,
          now.subtract(const Duration(days: 6)), 'Proud of you Kabir, next stop 75! 💪'),
      PReview('r3', 'Rahul Nair', face(75), 'Great coach. Sometimes replies take a few hours, but always helpful.', 4,
          now.subtract(const Duration(days: 11))),
      PReview('r4', 'Ananya Das', face(90, woman: true), 'Best decision this year. My deadlift went from 40 to 70 kg.', 5,
          now.subtract(const Duration(days: 19))),
    ]);

    diets.addAll([
      PDiet('Lean cut 1800', 'Fat loss', 1800, 140, ['Oats with whey and berries', 'Paneer bhurji wrap', 'Greek yogurt', 'Grilled chicken, rice, salad'], 9),
      PDiet('Muscle gain 2800', 'Muscle gain', 2800, 170, ['Eggs, toast, banana', 'Chicken biryani bowl', 'Peanut butter shake', 'Fish curry with rice'], 4),
      PDiet('Veg balance 2000', 'Maintenance', 2000, 110, ['Poha with peanuts', 'Rajma chawal', 'Sprouts chaat', 'Tofu stir fry with roti'], 6),
    ]);
  }
}
