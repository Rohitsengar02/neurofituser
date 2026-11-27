import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/live_backend.dart';
import '../backend/sync_store.dart';

// Trainers, plans and everything a subscriber gets from their trainer:
// live sessions, workout plan, diet, chat, check-ins, bookings and
// notifications. Loaded from the NeuroFit API and kept on the phone, so it
// opens instantly and works offline.

String unsplash(String id, [int w = 600]) =>
    id.startsWith('http') || id.startsWith('data:') || id.isEmpty ? id : 'https://images.unsplash.com/photo-$id?w=$w&auto=format&fit=crop&q=80';
String exImg(String f) => 'assets/exercises/images/$f';

class TrainerCat {
  final String name;
  final IconData icon;
  final Color color;
  const TrainerCat(this.name, this.icon, this.color);
}

const trainerCats = [
  TrainerCat('Strength', Icons.fitness_center_rounded, Color(0xFF16A34A)),
  TrainerCat('Weight loss', Icons.local_fire_department_rounded, Color(0xFFF97316)),
  TrainerCat('Muscle gain', Icons.sports_gymnastics_rounded, Color(0xFF0EA5E9)),
  TrainerCat('Yoga', Icons.self_improvement_rounded, Color(0xFFA855F7)),
  TrainerCat('Nutrition', Icons.eco_rounded, Color(0xFF10B981)),
  TrainerCat('HIIT', Icons.bolt_rounded, Color(0xFFEAB308)),
  TrainerCat('Mobility', Icons.accessibility_new_rounded, Color(0xFF3B82F6)),
  TrainerCat('Boxing', Icons.sports_mma_rounded, Color(0xFFEF4444)),
];

class Plan {
  final String name;
  final int months, price;
  final List<String> perks;
  const Plan(this.name, this.months, this.price, this.perks);
  int get perMonth => price ~/ months;
}

class Trainer {
  final String id, name, role, cat, photo, city, bio;
  final double rating;
  final int reviews, years, clients, price;
  final bool live, online, top;
  final List<String> tags;
  Trainer(this.id, this.name, this.role, this.cat, this.photo, this.city, this.bio, this.rating, this.reviews, this.years,
      this.clients, this.price,
      {this.live = false, this.online = true, this.top = false, this.tags = const []});

  String get first => name.split(' ').first;
  String get img => unsplash(photo);

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'role': role, 'cat': cat, 'photo': photo, 'city': city, 'bio': bio, 'rating': rating,
        'reviews': reviews, 'years': years, 'clients': clients, 'price': price, 'live': live, 'online': online, 'top': top, 'tags': tags,
        'plans': [for (final p in _plans ?? const <Plan>[]) {'name': p.name, 'months': p.months, 'price': p.price, 'perks': p.perks}],
      };

  /// From the API (coach profile approved by the admin).
  factory Trainer.fromJson(Map<String, dynamic> j) {
    num n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;
    final t = Trainer(
      (j['id'] ?? j['userId'] ?? '').toString(),
      (j['name'] ?? 'Coach').toString(),
      (j['role'] ?? j['headline'] ?? 'Fitness coach').toString(),
      (j['cat'] ?? 'Strength').toString(),
      (j['photo'] ?? j['photoUrl'] ?? '').toString(),
      (j['city'] ?? '').toString(),
      (j['bio'] ?? '').toString(),
      n(j['rating']).toDouble(),
      n(j['reviews']).toInt(),
      n(j['years']).toInt(),
      n(j['clients']).toInt(),
      n(j['price'] ?? 999).toInt(),
      live: j['live'] == true,
      online: j['online'] != false,
      top: j['top'] == true,
      tags: [for (final x in (j['tags'] is List ? j['tags'] as List : const [])) x.toString()],
    );
    t._plans = [
      for (final p in (j['plans'] is List ? j['plans'] as List : const []))
        if (p is Map && p['active'] != false)
          Plan((p['name'] ?? 'Plan').toString(), n(p['months'] ?? 1).toInt().clamp(1, 36), n(p['price']).toInt(),
              [for (final x in (p['perks'] is List ? p['perks'] as List : const [])) x.toString()]),
    ];
    return t;
  }

  // ignore: prefer_final_fields
  List<Plan>? _plans;
  List<Plan> get plans => _plans != null && _plans!.isNotEmpty ? _plans! : _defaultPlans;
  List<Plan> get _defaultPlans => [
        Plan('Monthly', 1, price, const ['Personal workout plan', 'Weekly check-ins', 'Chat with your coach', '2 live sessions']),
        Plan('Quarterly', 3, (price * 2.6).round(), const [
          'Everything in Monthly',
          'Custom diet plan',
          '6 live sessions',
          'Form checks on video',
        ]),
        Plan('Yearly', 12, (price * 9).round(), const [
          'Everything in Quarterly',
          'Unlimited live sessions',
          'Priority replies',
          'Free NeuroFit kit',
        ]),
      ];
}

/// Approved coaches from the API (admin approves them). Empty until loaded.
final List<Trainer> trainers = [];

/// The coach a subscription points to, even before the list has loaded.
final Map<String, Trainer> _trainerCache = {};

Trainer trainerById(String id) =>
    trainers.where((t) => t.id == id).firstOrNull ?? _trainerCache[id] ?? Trainer(id, 'Coach', 'Fitness coach', 'Strength', '', '', '', 0, 0, 0, 0, 999);

class Ex {
  final String name, img, sets, muscle;
  const Ex(this.name, this.img, this.sets, this.muscle);
}

/// Workout plan the trainer assigns, one day per entry.
/// The subscriber's workout plan, one day per entry. Starts as NeuroFit's
/// default program; the coach's published workouts are put first.
final List<(String, String, List<Ex>)> planDays = [...defaultPlanDays];

const defaultPlanDays = [
  ('Push day', 'Chest · shoulders · triceps', [
    Ex('Barbell bench press', '0025-EIeI8Vf.jpg', '4 × 8', 'Chest'),
    Ex('Incline dumbbell press', '0314-ns0SIbU.jpg', '3 × 10', 'Upper chest'),
    Ex('Seated shoulder press', '0405-znQUdHY.jpg', '3 × 10', 'Shoulders'),
    Ex('Lateral raise', '0334-DsgkuIt.jpg', '3 × 15', 'Side delts'),
    Ex('Triceps dip', '0814-X6C6i5Y.jpg', '3 × 12', 'Triceps'),
  ]),
  ('Leg day', 'Quads · glutes · hamstrings', [
    Ex('Back squat', '0043-qXTaZnJ.jpg', '4 × 6', 'Quads'),
    Ex('Walking lunge', '1460-IZVHb27.jpg', '3 × 12', 'Glutes'),
    Ex('Leg press', '1760-yn8yg1r.jpg', '3 × 12', 'Quads'),
    Ex('Kettlebell swing', '0549-UHJlbu3.jpg', '3 × 15', 'Posterior chain'),
  ]),
  ('Pull day', 'Back · biceps', [
    Ex('Bent-over row', '0027-eZyBC3j.jpg', '4 × 8', 'Back'),
    Ex('Biceps curl', '0294-NbVPDMW.jpg', '3 × 12', 'Biceps'),
    Ex('Core crunch', '0274-TFqbd8t.jpg', '3 × 20', 'Core'),
    Ex('Mountain climber', '0630-RJgzwny.jpg', '3 × 30 s', 'Core'),
  ]),
  ('Conditioning', 'HIIT · core', [
    Ex('Burpee', '1160-dK9394r.jpg', '5 × 45 s', 'Full body'),
    Ex('Jump rope', '0685-oLrKqDH.jpg', '5 × 1 min', 'Cardio'),
    Ex('Plank hold', '0687-XVDdcoj.jpg', '3 × 45 s', 'Core'),
    Ex('Push-up', '0662-I4hDWkc.jpg', '3 × max', 'Chest'),
  ]),
];

/// The subscriber's meal plan: the coach's diet when one is assigned.
final List<(String, String, String, int, IconData, Color)> dietPlan = [...defaultDietPlan];

const defaultDietPlan = [
  ('Breakfast', '8:00 AM', 'Oats with whey, banana and peanut butter', 520, Icons.free_breakfast_rounded, Color(0xFFF59E0B)),
  ('Mid-morning', '11:00 AM', 'Greek yogurt with berries and almonds', 260, Icons.icecream_rounded, Color(0xFFEC4899)),
  ('Lunch', '1:30 PM', 'Brown rice, dal, paneer tikka and salad', 680, Icons.lunch_dining_rounded, Color(0xFF16A34A)),
  ('Pre-workout', '5:00 PM', 'Black coffee and two rice cakes with honey', 180, Icons.coffee_rounded, Color(0xFF9A6B4F)),
  ('Dinner', '8:30 PM', 'Grilled chicken or tofu, quinoa and veggies', 610, Icons.dinner_dining_rounded, Color(0xFF3B82F6)),
];

class ChatMsg {
  final bool me;
  final String text;
  final DateTime at;
  const ChatMsg(this.me, this.text, this.at);
  Map<String, dynamic> toJson() => {'m': me, 't': text, 'a': at.millisecondsSinceEpoch};
  static ChatMsg fromJson(Map<String, dynamic> j) => ChatMsg(j['m'], j['t'], DateTime.fromMillisecondsSinceEpoch(j['a']));
}

class Note {
  final String title, body, kind; // kind: live, plan, chat, checkin, diet, booking
  final DateTime at;
  bool read;
  String? _id; // server notification id
  Note(this.title, this.body, this.kind, this.at, {this.read = false});
  Map<String, dynamic> toJson() => {'t': title, 'b': body, 'k': kind, 'a': at.millisecondsSinceEpoch, 'r': read};
  static Note fromJson(Map<String, dynamic> j) =>
      Note(j['t'], j['b'], j['k'], DateTime.fromMillisecondsSinceEpoch(j['a']), read: j['r'] ?? false);
}

class CheckIn {
  final DateTime at;
  final double weight;
  final int energy, sleep; // 1..5
  final String note;
  const CheckIn(this.at, this.weight, this.energy, this.sleep, this.note);
  Map<String, dynamic> toJson() => {'a': at.millisecondsSinceEpoch, 'w': weight, 'e': energy, 's': sleep, 'n': note};
  static CheckIn fromJson(Map<String, dynamic> j) =>
      CheckIn(DateTime.fromMillisecondsSinceEpoch(j['a']), (j['w'] as num).toDouble(), j['e'], j['s'], j['n']);
}

class Booking {
  final DateTime at;
  final String type;
  final String id;
  Booking(this.at, this.type, [String? id]) : id = id ?? 'bkg_${DateTime.now().microsecondsSinceEpoch}';
  Map<String, dynamic> toJson() => {'a': at.millisecondsSinceEpoch, 't': type, 'i': id};
  static Booking fromJson(Map<String, dynamic> j) => Booking(DateTime.fromMillisecondsSinceEpoch(j['a']), j['t'], j['i']);
}

String hhmm(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

String dayName(DateTime d) {
  const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]}';
}

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
}

String inr(int v) {
  final s = v.toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

// =====================================================================
//  SUBSCRIBER STORE
// =====================================================================

class TrainerStore extends ChangeNotifier {
  TrainerStore._() {
    _load();
    SyncStore.I.on('trainers_updated', refresh);
    SyncStore.I.on('notification:new', _onNotification);
  }
  static final TrainerStore I = TrainerStore._();
  static const _key = 'trainer_sub_v2';

  String? trainerId;
  String? planName;
  DateTime? since, until;
  final Set<String> following = {};
  final Set<String> doneToday = {}; // exercise names ticked today
  final Map<String, int> daysDone = {}; // yyyy-m-d -> 1
  final List<ChatMsg> chat = [];
  final List<Note> notes = [];
  final List<CheckIn> checkins = [];
  final List<Booking> bookings = [];
  final List<DateTime> _sessions = []; // coach's upcoming live sessions
  String _doneDay = '';
  bool loaded = false;
  Future<void>? _refreshing;

  Trainer? get trainer => trainerId == null ? null : trainerById(trainerId!);
  bool get active => trainer != null && (until?.isAfter(DateTime.now()) ?? false);
  int get unread => notes.where((n) => !n.read).length;
  int get planIndex => planDays.isEmpty ? 0 : (DateTime.now().weekday - 1) % planDays.length;
  int get streak {
    var n = 0;
    var d = DateTime.now();
    while (daysDone.containsKey(_k(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  static String _k(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Next live class of the coach (from their schedule), else this evening.
  DateTime get nextLive {
    final now = DateTime.now();
    final next = _sessions.where((t) => t.isAfter(now.subtract(const Duration(minutes: 45)))).toList()..sort();
    if (next.isNotEmpty) return next.first;
    var t = DateTime(now.year, now.month, now.day, 18, 30);
    if (t.isBefore(now.subtract(const Duration(minutes: 45)))) t = t.add(const Duration(days: 1));
    return t;
  }

  bool get liveNow {
    if (trainer?.live == true) return true;
    if (_sessions.isEmpty) return false;
    final d = DateTime.now().difference(nextLive).inMinutes;
    return d >= -10 && d <= 45;
  }

  // ------------------------------------------------------------------
  // Server
  // ------------------------------------------------------------------

  /// Loads coaches and this user's coaching data. Safe to call often.
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    try {
      final j = await Api.get('/trainers?limit=200');
      final list = [for (final t in Api.list(j)) Trainer.fromJson(t)];
      trainers
        ..clear()
        ..addAll(list);
      for (final t in list) {
        _trainerCache[t.id] = t;
      }
      loaded = true;
      notifyListeners();
    } catch (_) {}
    if (!AppSession.isSignedIn) return;
    try {
      final sub = (await Api.get('/trainers/me/subscription'))['data'];
      if (sub is Map) {
        final m = Map<String, dynamic>.from(sub);
        if (m['trainer'] is Map) {
          final t = Trainer.fromJson(Map<String, dynamic>.from(m['trainer'] as Map));
          _trainerCache[t.id] = t;
        }
        trainerId = (m['trainerId'] ?? '').toString();
        planName = m['planName']?.toString();
        since = DateTime.tryParse('${m['since']}')?.toLocal();
        until = DateTime.tryParse('${m['until']}')?.toLocal();
        _applyPlan(m['workout'] is Map ? Map<String, dynamic>.from(m['workout'] as Map) : null,
            m['diet'] is Map ? Map<String, dynamic>.from(m['diet'] as Map) : null);
      } else {
        trainerId = null;
        planName = null;
        until = null;
        _applyPlan(null, null);
      }
      final res = await Future.wait([
        Api.get('/trainers/me/following'),
        Api.get('/trainers/me/checkins'),
        Api.get('/trainers/me/bookings'),
        Api.get('/notifications'),
      ]);
      following
        ..clear()
        ..addAll([for (final x in (res[0]['data'] as List? ?? const [])) x.toString()]);
      checkins
        ..clear()
        ..addAll([
          for (final c in Api.list(res[1]))
            CheckIn(DateTime.tryParse('${c['at'] ?? c['createdAt']}')?.toLocal() ?? DateTime.now(), ((c['weight'] as num?) ?? 0).toDouble(),
                ((c['energy'] as num?) ?? 3).toInt(), ((c['sleep'] as num?) ?? 3).toInt(), (c['note'] ?? '').toString()),
        ]);
      bookings
        ..clear()
        ..addAll([
          for (final b in Api.list(res[2]))
            if (b['status'] != 'cancelled')
              Booking(DateTime.tryParse('${b['at']}')?.toLocal() ?? DateTime.now(), (b['type'] ?? 'Session').toString(), b['id']?.toString()),
        ]..sort((a, c) => a.at.compareTo(c.at)));
      notes
        ..clear()
        ..addAll([
          for (final n in Api.list(res[3]))
            if (const {'live', 'plan', 'chat', 'checkin', 'diet', 'booking', 'trainer'}.contains(n['type']))
              Note((n['title'] ?? '').toString(), (n['body'] ?? n['message'] ?? '').toString(), n['type'] == 'trainer' ? 'plan' : n['type'].toString(),
                  DateTime.tryParse('${n['createdAt']}')?.toLocal() ?? DateTime.now(),
                  read: n['isRead'] == true)
              .._id = n['id']?.toString(),
        ]);
      if (trainerId != null && trainerId!.isNotEmpty) await Future.wait([_loadChat(), _loadSessions()]);
      notifyListeners();
      _save();
    } catch (_) {}
  }

  Future<void> _loadChat() async {
    try {
      final j = await Api.get('/trainers/$trainerId/chat');
      chat
        ..clear()
        ..addAll([
          for (final m in Api.list(j))
            ChatMsg(m['me'] == true, (m['text'] ?? '').toString(), DateTime.tryParse('${m['createdAt']}')?.toLocal() ?? DateTime.now()),
        ]);
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    try {
      final j = await Api.get('/live/sessions?status=all&trainerId=$trainerId');
      _sessions
        ..clear()
        ..addAll([
          for (final x in Api.list(j))
            if (x['status'] != 'ended') ?DateTime.tryParse('${x['startsAt']}')?.toLocal(),
        ]);
    } catch (_) {}
  }

  void _onNotification() {
    if (trainerId != null) {
      _loadChat().then((_) => notifyListeners());
    }
    refresh();
  }

  /// Coach's workout and diet replace the default plan.
  void _applyPlan(Map<String, dynamic>? w, Map<String, dynamic>? d) {
    planDays
      ..clear()
      ..addAll(defaultPlanDays);
    if (w != null) {
      final ex = [
        for (final e in (w['exercises'] is List ? w['exercises'] as List : const []))
          if (e is Map)
            Ex((e['name'] ?? '').toString(), (e['img'] ?? e['image'] ?? '').toString(), (e['sets'] ?? '3 × 12').toString(), (e['muscle'] ?? '').toString())
          else
            Ex(e.toString(), _exImgFor(e.toString()), '3 × 12', ''),
      ];
      if (ex.isNotEmpty) {
        planDays.insert(0, ((w['title'] ?? 'Coach plan').toString(), '${w['level'] ?? 'All levels'} · ${w['minutes'] ?? 30} min', ex));
      }
    }
    dietPlan
      ..clear()
      ..addAll(defaultDietPlan);
    if (d != null) {
      final meals = [for (final m in (d['meals'] is List ? d['meals'] as List : const [])) m.toString()];
      final kcal = ((d['kcal'] as num?) ?? 0).toInt();
      if (meals.isNotEmpty) {
        final out = <(String, String, String, int, IconData, Color)>[];
        for (var i = 0; i < meals.length; i++) {
          final t = defaultDietPlan[i % defaultDietPlan.length];
          out.add((t.$1, t.$2, meals[i], kcal > 0 ? kcal ~/ meals.length : t.$4, t.$5, t.$6));
        }
        dietPlan
          ..clear()
          ..addAll(out);
      }
    }
  }

  /// A matching picture from the default program, if the coach used the same exercise.
  static String _exImgFor(String name) {
    final n = name.toLowerCase();
    for (final d in defaultPlanDays) {
      for (final e in d.$3) {
        if (e.name.toLowerCase() == n) return e.img;
      }
    }
    return defaultPlanDays.first.$3.first.img;
  }

  // ------------------------------------------------------------------
  // Actions (saved on the phone at once, sent to the server)
  // ------------------------------------------------------------------

  void subscribe(Trainer t, Plan p) {
    trainerId = t.id;
    _trainerCache[t.id] = t;
    planName = p.name;
    since = DateTime.now();
    until = DateTime.now().add(Duration(days: 30 * p.months));
    chat.clear();
    _changed();
    Api.send('POST', '/trainers/${t.id}/subscribe', {'planName': p.name}).then((_) => refresh()).catchError((_) => <String, dynamic>{});
  }

  void cancel() {
    trainerId = null;
    planName = null;
    until = null;
    _applyPlan(null, null);
    _changed();
    Api.send('DELETE', '/trainers/me/subscription').catchError((_) => <String, dynamic>{});
  }

  void toggleFollow(Trainer t) {
    following.contains(t.id) ? following.remove(t.id) : following.add(t.id);
    _changed();
    Api.send('POST', '/trainers/${t.id}/follow').catchError((_) => <String, dynamic>{});
  }

  bool isDone(String ex) {
    _rollDay();
    return doneToday.contains(ex);
  }

  void toggleDone(String ex, int total) {
    _rollDay();
    doneToday.contains(ex) ? doneToday.remove(ex) : doneToday.add(ex);
    if (doneToday.length >= total) {
      daysDone[_k(DateTime.now())] = 1;
    } else {
      daysDone.remove(_k(DateTime.now()));
    }
    _changed();
    SyncStore.I.put('coach_progress', 'me', {'day': _doneDay, 'done': doneToday.toList(), 'days': daysDone});
  }

  void _rollDay() {
    final k = _k(DateTime.now());
    if (_doneDay != k) {
      _doneDay = k;
      doneToday.clear();
    }
  }

  /// Sends a message to the coach. Their reply arrives live.
  void send(String text) {
    chat.add(ChatMsg(true, text, DateTime.now()));
    _changed();
    final id = trainerId;
    if (id == null) return;
    Api.send('POST', '/trainers/$id/chat', {'text': text}).catchError((_) => <String, dynamic>{});
  }

  void addCheckIn(CheckIn c) {
    checkins.insert(0, c);
    _changed();
    final id = trainerId;
    if (id == null) return;
    Api.send('POST', '/trainers/$id/checkins',
        {'at': c.at.toUtc().toIso8601String(), 'weight': c.weight, 'energy': c.energy, 'sleep': c.sleep, 'note': c.note}).catchError((_) => <String, dynamic>{});
  }

  void book(Booking b) {
    bookings.add(b);
    bookings.sort((a, c) => a.at.compareTo(c.at));
    _changed();
    final id = trainerId;
    if (id == null) return;
    Api.send('POST', '/trainers/$id/bookings', {'id': b.id, 'at': b.at.toUtc().toIso8601String(), 'type': b.type}).catchError((_) => <String, dynamic>{});
  }

  void cancelBooking(Booking b) {
    bookings.remove(b);
    _changed();
    Api.send('DELETE', '/trainers/me/bookings/${b.id}').catchError((_) => <String, dynamic>{});
  }

  void markRead(Note n) {
    n.read = true;
    _changed();
    if (n._id != null) Api.send('POST', '/notifications/${n._id}/read').catchError((_) => <String, dynamic>{});
  }

  void readAll() {
    for (final n in notes) {
      n.read = true;
    }
    _changed();
    Api.send('POST', '/notifications/read-all').catchError((_) => <String, dynamic>{});
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        trainerId = j['tid'];
        planName = j['plan'];
        since = j['since'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['since']);
        until = j['until'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['until']);
        following.addAll(List<String>.from(j['fol'] ?? []));
        _doneDay = j['dd'] ?? '';
        doneToday.addAll(List<String>.from(j['done'] ?? []));
        (j['days'] as Map<String, dynamic>? ?? {}).forEach((k, v) => daysDone[k] = v as int);
        chat.addAll([for (final m in j['chat'] ?? []) ChatMsg.fromJson(Map<String, dynamic>.from(m))]);
        notes.addAll([for (final m in j['notes'] ?? []) Note.fromJson(Map<String, dynamic>.from(m))]);
        checkins.addAll([for (final m in j['ci'] ?? []) CheckIn.fromJson(Map<String, dynamic>.from(m))]);
        bookings.addAll([for (final m in j['bk'] ?? []) Booking.fromJson(Map<String, dynamic>.from(m))]);
        for (final t in (j['trainers'] as List? ?? const [])) {
          final tr = Trainer.fromJson(Map<String, dynamic>.from(t as Map));
          _trainerCache[tr.id] = tr;
          trainers.add(tr);
        }
        notifyListeners();
      }
      final prog = await SyncStore.I.get('coach_progress', 'me');
      if (prog != null && prog['day'] == _k(DateTime.now())) {
        _doneDay = prog['day'];
        doneToday
          ..clear()
          ..addAll(List<String>.from(prog['done'] ?? const []));
      }
      (prog?['days'] as Map? ?? const {}).forEach((k, v) => daysDone[k.toString()] = (v as num).toInt());
    } catch (_) {}
    refresh();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          'tid': trainerId,
          'plan': planName,
          'since': since?.millisecondsSinceEpoch,
          'until': until?.millisecondsSinceEpoch,
          'fol': following.toList(),
          'dd': _doneDay,
          'done': doneToday.toList(),
          'days': daysDone,
          'chat': chat.map((m) => m.toJson()).toList(),
          'notes': notes.take(40).map((m) => m.toJson()).toList(),
          'ci': checkins.map((m) => m.toJson()).toList(),
          'bk': bookings.map((m) => m.toJson()).toList(),
          // Coaches shown offline on the next start.
          'trainers': [for (final t in trainers.take(60)) t.toJson()],
        }),
      );
    } catch (_) {}
  }
}
