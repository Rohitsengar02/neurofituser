import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/live_backend.dart';
import '../backend/me.dart';
import '../backend/media.dart';
import '../backend/sync_store.dart';
import 'trainer_data.dart';

// Trainer panel state: the coach's profile from onboarding, panel mode, and
// the data behind the 10 dashboard features (plans, clients, content,
// schedule, messages, earnings, reviews, diet templates). Everything comes
// from the NeuroFit API (/api/panel) and is kept on the phone for offline use.


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
  final String userId;
  PClient(this.id, this.name, this.photo, this.goal, this.plan, this.since, this.until, this.startKg, this.nowKg, this.workouts,
      this.streak, this.status, this.note, this.unread, this.chat, {this.userId = ''});
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
  String id;
  List<String> assignedTo = [];
  PDiet(this.name, this.goal, this.kcal, this.protein, this.meals, this.assigned, [String? id])
      : id = id ?? 'td_${DateTime.now().microsecondsSinceEpoch}';
  Map<String, dynamic> toJson() => {'n': name, 'g': goal, 'k': kcal, 'p': protein, 'm': meals, 'a': assigned, 'i': id};
  static PDiet fromJson(Map<String, dynamic> j) => PDiet(j['n'], j['g'], j['k'], j['p'], List<String>.from(j['m']), j['a'], j['i']);
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
    _load();
    SyncStore.I.on('notification:new', () {
      if (registered) refresh();
    });
  }
  static final PanelStore I = PanelStore._();
  static const _key = 'trainer_panel_v2';

  bool registered = false;
  bool panelMode = false;
  bool ready = false;

  /// pending until the admin approves the coach, then approved.
  String status = 'pending';

  // Profile from onboarding.
  String name = '';
  String headline = '';
  String bio = '';
  String city = '';
  String mode = 'Online';
  int years = 0;
  List<String> specialties = [];
  List<String> certs = [];
  String? photo; // URL (R2) or base64 until uploaded

  bool acceptingClients = true;

  // Live.
  bool live = false;
  DateTime? liveSince;
  String liveTitle = '';
  int liveSessions = 0;
  String? liveId;

  /// LiveKit room details for the current broadcast (null if LiveKit is not set up).
  String? liveUrl, liveToken;

  final List<PPlan> plans = [];
  final List<PClient> clients = [];
  final List<PWorkout> workouts = [];
  final List<PSession> sessions = [];
  final List<PTxn> txns = [];
  final List<PReview> reviews = [];
  final List<PDiet> diets = [];
  int _paidBalance = 0;

  // ----- derived -----
  int get activeClients => clients.where((c) => c.status != 'paused').length;
  int get expiring => clients.where((c) => c.status == 'expiring').length;
  int get unread => clients.fold(0, (a, c) => a + c.unread);
  int get balance => _paidBalance > 0 ? _paidBalance : txns.fold(0, (a, t) => a + t.amount);
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

  // ----- server -----
  static void _bg(Future<Object?> f) => f.catchError((_) => null);
  static DateTime _at(Object? v) => DateTime.tryParse('${v ?? ''}')?.toLocal() ?? DateTime.now();
  static int _n(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  Map<String, dynamic> get _profileJson => {
        'name': name,
        'headline': headline,
        'role': headline,
        'bio': bio,
        'city': city,
        'mode': mode,
        'years': years,
        'specialties': specialties,
        'cat': specialties.isEmpty ? 'Strength' : specialties.first,
        'tags': specialties,
        'certifications': certs,
        'accepting': acceptingClients,
        if (photo != null && photo!.startsWith('http')) 'photo': photo,
        'price': plans.isEmpty ? 999 : plans.first.price,
        'plans': [for (final p in plans) {'name': p.name, 'months': p.months, 'price': p.price, 'perks': p.perks, 'active': p.active}],
      };

  void _pushProfile() => _bg(Api.send('PUT', '/panel/me', _profileJson));

  /// Pulls the coach's profile, clients, content, schedule, money and reviews.
  Future<void> refresh() async {
    if (!AppSession.isSignedIn) return;
    try {
      final me = (await Api.get('/panel/me'))['data'];
      if (me is! Map) return;
      final t = Map<String, dynamic>.from(me);
      registered = true;
      status = (t['status'] ?? 'pending').toString();
      name = (t['name'] ?? name).toString();
      headline = (t['headline'] ?? t['role'] ?? headline).toString();
      bio = (t['bio'] ?? bio).toString();
      city = (t['city'] ?? city).toString();
      mode = (t['mode'] ?? mode).toString();
      years = _n(t['years']);
      specialties = [for (final x in (t['specialties'] as List? ?? const [])) x.toString()];
      certs = [for (final x in (t['certifications'] as List? ?? const [])) x.toString()];
      if ((t['photo'] ?? '').toString().isNotEmpty) photo = t['photo'].toString();
      acceptingClients = t['accepting'] != false;
      plans
        ..clear()
        ..addAll([
          for (final p in (t['plans'] as List? ?? const []))
            if (p is Map)
              PPlan((p['name'] ?? 'Plan').toString(), _n(p['months'] ?? 1), _n(p['price']), 0, p['active'] != false,
                  [for (final x in (p['perks'] as List? ?? const [])) x.toString()]),
        ]);
    } on ApiError catch (e) {
      if (e.status == 404) {
        registered = false;
        panelMode = false;
      }
      ready = true;
      notifyListeners();
      return;
    } catch (_) {
      return; // offline: keep what is saved
    }
    await Future.wait([_clients(), _content(), _money(), _reviews(), _schedule(), _diets()]);
    ready = true;
    notifyListeners();
    _save();
  }

  Future<void> _clients() async {
    try {
      final res = await Future.wait([Api.get('/panel/clients'), Api.get('/panel/checkins')]);
      final weights = <String, List<double>>{};
      for (final c in Api.list(res[1]).reversed) {
        final w = (c['weight'] as num?)?.toDouble();
        if (w != null && w > 0) (weights[(c['userId'] ?? '').toString()] ??= []).add(w);
      }
      final old = {for (final c in clients) c.userId: c.chat};
      clients
        ..clear()
        ..addAll([
          for (final c in Api.list(res[0]))
            PClient(
              (c['id'] ?? '').toString(),
              (c['name'] ?? 'Client').toString(),
              (c['photo'] ?? '').toString(),
              (c['goal'] ?? c['trainerNote'] ?? '').toString(),
              (c['planName'] ?? '').toString(),
              _at(c['since']),
              _at(c['until']),
              weights[c['userId']]?.first ?? 0,
              weights[c['userId']]?.last ?? 0,
              _n(c['workouts']),
              0,
              (c['status'] ?? 'active').toString(),
              (c['trainerNote'] ?? '').toString(),
              _n(c['unread']),
              old[(c['userId'] ?? '').toString()] ?? <ChatMsg>[],
              userId: (c['userId'] ?? '').toString(),
            ),
        ]);
      for (final p in plans) {
        p.subs = clients.where((c) => c.plan == p.name && c.status != 'paused').length;
      }
    } catch (_) {}
  }

  Future<void> _content() async {
    try {
      final j = await Api.get('/panel/workouts');
      workouts
        ..clear()
        ..addAll([
          for (final w in Api.list(j))
            PWorkout(
              (w['id'] ?? '').toString(),
              (w['title'] ?? 'Workout').toString(),
              (w['level'] ?? 'All levels').toString(),
              (w['kind'] ?? 'Video').toString(),
              _n(w['minutes']),
              [for (final e in (w['exercises'] as List? ?? const [])) e is Map ? (e['name'] ?? '').toString() : e.toString()],
              (w['cover'] ?? '').toString().isEmpty ? null : w['cover'].toString(),
              _at(w['createdAt']),
              w['isActive'] != false,
              _n(w['views']),
              _n(w['saves']),
            ),
        ]);
    } catch (_) {}
  }

  Future<void> _money() async {
    try {
      final res = await Future.wait([Api.get('/panel/transactions'), Api.get('/panel/dashboard')]);
      txns
        ..clear()
        ..addAll([
          for (final t in Api.list(res[0]))
            PTxn((t['title'] ?? '').toString(), (t['status'] ?? '').toString(), _n(t['amount']), _at(t['at'])),
        ]);
      final d = res[1]['data'];
      if (d is Map) {
        final paidOut = txns.where((t) => t.amount < 0).fold(0, (a, t) => a + t.amount);
        _paidBalance = _n(d['balance']) + paidOut;
      }
    } catch (_) {}
  }

  Future<void> _reviews() async {
    try {
      final j = await Api.get('/panel/reviews');
      reviews
        ..clear()
        ..addAll([
          for (final r in Api.list(j))
            PReview((r['id'] ?? '').toString(), (r['name'] ?? 'Member').toString(), (r['photo'] ?? '').toString(), (r['text'] ?? '').toString(),
                _n(r['stars'] ?? 5), _at(r['createdAt']), r['reply']?.toString()),
        ]);
    } catch (_) {}
  }

  Future<void> _schedule() async {
    try {
      final me = AppSession.userId;
      final res = await Future.wait([Api.get('/live/sessions?status=all&trainerId=$me'), Api.get('/panel/bookings')]);
      sessions
        ..clear()
        ..addAll([
          for (final x in Api.list(res[0]))
            if (x['status'] != 'ended')
              PSession((x['id'] ?? '').toString(), (x['title'] ?? 'Live class').toString(), (x['type'] ?? 'Live class').toString(), _at(x['startsAt']),
                  _n(x['durationMin'] ?? 45), x['client']?.toString()),
          for (final b in Api.list(res[1]))
            if (b['status'] != 'cancelled')
              PSession((b['id'] ?? '').toString(), (b['type'] ?? 'Session').toString(), '1:1 call', _at(b['at']), 30,
                  clients.where((c) => c.userId == b['userId']).firstOrNull?.name),
        ]);
      liveSessions = Api.list(res[0]).where((x) => x['status'] == 'ended').length;
      final on = Api.list(res[0]).where((x) => x['status'] == 'live').firstOrNull;
      if (on != null && !live) {
        live = true;
        liveId = on['id']?.toString();
        liveTitle = (on['title'] ?? '').toString();
        liveSince = _at(on['startedAt'] ?? on['startsAt']);
      }
    } catch (_) {}
  }

  Future<void> _diets() async {
    try {
      final j = await Api.get('/panel/diets');
      diets
        ..clear()
        ..addAll([
          for (final d in Api.list(j))
            PDiet((d['name'] ?? 'Diet').toString(), (d['goal'] ?? '').toString(), _n(d['kcal']), _n(d['protein']),
                [for (final m in (d['meals'] as List? ?? const [])) m.toString()], _n(d['assigned']), (d['id'] ?? '').toString())
              ..assignedTo = [for (final x in (d['assignedTo'] as List? ?? const [])) x.toString()],
        ]);
    } catch (_) {}
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
    status = 'pending';
    _save();
    () async {
      final url = await Media.uploadBase64(photo, folder: 'coaches');
      if (url != null) this.photo = url;
      try {
        await Api.send('POST', '/panel/apply', {..._profileJson, if (url != null) 'photo': url});
        _pushProfile(); // plans and the rest of the profile
      } catch (_) {}
      _save();
    }();
  }

  void enterPanel() {
    panelMode = true;
    _save();
    refresh();
  }

  void exitPanel() {
    panelMode = false;
    _save();
  }

  void leaveCoaching() {
    registered = false;
    panelMode = false;
    acceptingClients = false;
    _save();
    _bg(Api.send('PUT', '/panel/me', {'accepting': false}));
  }

  void setAccepting(bool v) {
    acceptingClients = v;
    _save();
    _bg(Api.send('PUT', '/panel/me', {'accepting': v}));
  }

  void updateProfile({String? name, String? headline, String? bio, String? city, String? photo}) {
    if (name != null) this.name = name;
    if (headline != null) this.headline = headline;
    if (bio != null) this.bio = bio;
    if (city != null) this.city = city;
    if (photo != null) this.photo = photo;
    _save();
    () async {
      if (photo != null && !photo.startsWith('http')) {
        final url = await Media.uploadBase64(photo, folder: 'coaches');
        if (url != null) this.photo = url;
      }
      _pushProfile();
      _save();
    }();
  }

  void savePlan(PPlan p, {bool isNew = false}) {
    if (isNew) plans.add(p);
    _save();
    _pushProfile();
  }

  void removePlan(PPlan p) {
    plans.remove(p);
    _save();
    _pushProfile();
  }

  void togglePlan(PPlan p) {
    p.active = !p.active;
    _save();
    _pushProfile();
  }

  /// Goes live: creates the session (subscribers are notified) and gets a
  /// LiveKit token for the camera stream.
  void startLive(String title) {
    live = true;
    liveTitle = title;
    liveSince = DateTime.now();
    liveId = 'live_${DateTime.now().millisecondsSinceEpoch}';
    liveUrl = null;
    liveToken = null;
    notifyListeners();
    Api.send('POST', '/live/sessions', {'id': liveId, 'title': title, 'type': 'Live class', 'goLive': true}).then((j) {
      liveUrl = j['url']?.toString();
      liveToken = j['token']?.toString();
      notifyListeners();
    }).catchError((_) {});
  }

  /// Ends the stream; returns minutes streamed.
  int endLive({int viewers = 0, int tips = 0}) {
    final m = liveSince == null ? 0 : DateTime.now().difference(liveSince!).inMinutes;
    live = false;
    liveSessions++;
    final id = liveId;
    if (id != null) _bg(Api.send('POST', '/live/sessions/$id/end'));
    final w = PWorkout('tw_${DateTime.now().millisecondsSinceEpoch}', liveTitle.isEmpty ? 'Live class' : liveTitle, 'All levels', 'Live replay',
        m.clamp(1, 120), const [], null, DateTime.now(), true, viewers, 0);
    workouts.insert(0, w);
    _bg(Api.send('POST', '/panel/workouts', _workoutJson(w)));
    liveSince = null;
    liveId = null;
    liveUrl = null;
    liveToken = null;
    _save();
    return m;
  }

  Map<String, dynamic> _workoutJson(PWorkout w) => {
        'id': w.id,
        'title': w.title,
        'level': w.level,
        'kind': w.kind,
        'minutes': w.minutes,
        'exercises': w.exercises,
        if (w.cover != null && (w.cover!.startsWith('http') || w.cover!.startsWith('assets/'))) 'cover': w.cover,
        'isActive': w.published,
        'views': w.views,
        'saves': w.saves,
      };

  void publish(PWorkout w) {
    workouts.insert(0, w);
    _save();
    () async {
      var body = _workoutJson(w);
      final c = w.cover;
      if (c != null && !c.startsWith('http') && !c.startsWith('assets/')) {
        final url = await Media.uploadBase64(c, folder: 'workouts');
        if (url != null) body = {...body, 'cover': url};
      }
      _bg(Api.send('POST', '/panel/workouts', body));
    }();
  }

  void toggleWorkout(PWorkout w) {
    w.published = !w.published;
    _save();
    _bg(Api.send('POST', '/panel/workouts', {'id': w.id, 'isActive': w.published}));
  }

  void deleteWorkout(PWorkout w) {
    workouts.remove(w);
    _save();
    _bg(Api.send('DELETE', '/panel/workouts/${w.id}'));
  }

  void addSession(PSession s) {
    sessions.add(s);
    _save();
    _bg(Api.send('POST', '/live/sessions', {
      'id': s.id,
      'title': s.title,
      'type': s.kind,
      'startsAt': s.at.toUtc().toIso8601String(),
      'durationMin': s.minutes,
      'goLive': false,
      if (s.client != null) 'client': s.client,
    }));
  }

  void cancelSession(PSession s) {
    sessions.remove(s);
    _save();
    _bg(Api.send('DELETE', '/live/sessions/${s.id}'));
  }

  void sendTo(PClient c, String text) {
    c.chat.add(ChatMsg(true, text, DateTime.now()));
    notifyListeners();
    if (c.userId.isNotEmpty) _bg(Api.send('POST', '/panel/clients/${c.userId}/chat', {'text': text}));
  }

  /// Opens a client's chat: loads the thread and marks it read.
  void readChat(PClient c) {
    c.unread = 0;
    notifyListeners();
    if (c.userId.isEmpty) return;
    Api.get('/panel/clients/${c.userId}/chat').then((j) {
      c.chat
        ..clear()
        ..addAll([for (final m in Api.list(j)) ChatMsg(m['me'] == true, (m['text'] ?? '').toString(), _at(m['createdAt']))]);
      notifyListeners();
    }).catchError((_) {});
  }

  void setClientStatus(PClient c, String s) {
    c.status = s;
    notifyListeners();
    _bg(Api.send('PUT', '/panel/clients/${c.id}', {'status': s}));
  }

  void setClientNote(PClient c, String n) {
    c.note = n;
    notifyListeners();
    _bg(Api.send('PUT', '/panel/clients/${c.id}', {'note': n}));
  }

  void renew(PClient c) {
    c.status = 'active';
    final plan = plans.where((p) => p.name == c.plan).firstOrNull;
    _save();
    Api.send('PUT', '/panel/clients/${c.id}', {'status': 'active', 'renewMonths': plan?.months ?? 1}).then((_) => refresh()).catchError((_) {});
  }

  bool withdraw(int amount) {
    if (amount <= 0 || amount > balance) return false;
    txns.insert(0, PTxn('Payout to bank', 'Requested · arrives after approval', -amount, DateTime.now()));
    _paidBalance -= amount;
    _save();
    Api.send('POST', '/panel/payouts', {'amount': amount}).then((_) => _money().then((_) => notifyListeners())).catchError((_) {});
    return true;
  }

  void reply(PReview r, String text) {
    r.reply = text;
    notifyListeners();
    _bg(Api.send('POST', '/panel/reviews/${r.id}/reply', {'text': text}));
  }

  Map<String, dynamic> _dietJson(PDiet d) =>
      {'id': d.id, 'name': d.name, 'goal': d.goal, 'kcal': d.kcal, 'protein': d.protein, 'meals': d.meals, 'assigned': d.assigned, 'assignedTo': d.assignedTo};

  void saveDiet(PDiet d, {bool isNew = false}) {
    if (isNew) diets.insert(0, d);
    _save();
    _bg(Api.send('POST', '/panel/diets', _dietJson(d)));
  }

  /// Sends the diet to the next [n] active clients who don't have it yet.
  void assignDiet(PDiet d, int n) {
    final next = clients.where((c) => c.status != 'paused' && c.userId.isNotEmpty && !d.assignedTo.contains(c.userId)).take(n).toList();
    d.assignedTo.addAll(next.map((c) => c.userId));
    d.assigned = d.assignedTo.isEmpty ? d.assigned + n : d.assignedTo.length;
    _save();
    _bg(Api.send('POST', '/panel/diets', _dietJson(d)));
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
        status = j['status'] ?? status;
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
    if (name.isEmpty) name = Me.name;
    ready = true;
    notifyListeners();
    refresh();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      // Keep at most a few local (not yet uploaded) covers so storage stays small.
      var covers = 0;
      final wo = workouts.map((w) {
        final j = w.toJson();
        final c = w.cover;
        if (c != null && !c.startsWith('assets/') && !c.startsWith('http')) {
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
          'status': status,
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
}
