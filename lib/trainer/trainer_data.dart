import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Trainers, plans and everything a subscriber gets from their trainer:
// live sessions, workout plan, diet, chat, check-ins, bookings and
// notifications. Kept on the phone so it works without the backend.

String unsplash(String id, [int w = 600]) => 'https://images.unsplash.com/photo-$id?w=$w&auto=format&fit=crop&q=80';
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
  const Trainer(this.id, this.name, this.role, this.cat, this.photo, this.city, this.bio, this.rating, this.reviews, this.years,
      this.clients, this.price,
      {this.live = false, this.online = true, this.top = false, this.tags = const []});

  String get first => name.split(' ').first;
  String get img => unsplash(photo);

  List<Plan> get plans => [
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

const trainers = [
  Trainer('t1', 'Rahul Sharma', 'Strength & muscle coach', 'Strength', '1567013127542-490d757e51fc', 'Delhi',
      'Former national-level powerlifter. I build simple, progressive plans that get you strong without burning out.',
      4.9, 1240, 8, 1200, 999,
      live: true, top: true, tags: ['Powerlifting', 'Hypertrophy', 'Beginners']),
  Trainer('t2', 'Anjali Mehta', 'Weight loss specialist', 'Weight loss', '1548690312-e3b507d8c110', 'Mumbai',
      'Certified nutrition coach. Sustainable fat loss with food you actually enjoy and workouts that fit a busy day.',
      4.8, 980, 6, 980, 899,
      top: true, tags: ['Fat loss', 'Home workouts', 'Nutrition']),
  Trainer('t3', 'Vikram Singh', 'Muscle gain coach', 'Muscle gain', '1583454110551-21f2fa2afe61', 'Bengaluru',
      'Physique competitor and coach. Lean bulking, smart volume and recovery for steady size gains.',
      4.9, 1530, 7, 1500, 1099,
      live: true, top: true, tags: ['Bulking', 'Physique', 'Recovery']),
  Trainer('t4', 'Neha Patel', 'Yoga & wellness coach', 'Yoga', '1518611012118-696072aa579a', 'Pune',
      'RYT-500 yoga teacher. Flexibility, breath work and calm strength for body and mind.',
      4.7, 760, 5, 760, 799,
      tags: ['Hatha', 'Vinyasa', 'Breathwork']),
  Trainer('t5', 'Arjun Kapoor', 'HIIT & conditioning', 'HIIT', '1571019613454-1cb2f99b2d8b', 'Hyderabad',
      'Short, intense sessions that build engine and burn fat. Perfect when you only have 20 minutes.',
      4.8, 640, 6, 820, 849,
      live: true, tags: ['HIIT', 'Conditioning', 'Athletes']),
  Trainer('t6', 'Sara Khan', 'Mobility & rehab', 'Mobility', '1534528741775-53994a69daeb', 'Chennai',
      'Physiotherapist. Fix stiff hips, cranky shoulders and back pain with guided mobility and strength.',
      4.9, 520, 9, 600, 1199,
      top: true, tags: ['Rehab', 'Posture', 'Pain-free']),
  Trainer('t7', 'Kabir Rao', 'Boxing coach', 'Boxing', '1517838277536-f5f99be501cd', 'Delhi',
      'Amateur boxing champion. Footwork, combos and serious cardio in every session.',
      4.6, 410, 4, 380, 749,
      tags: ['Boxing', 'Cardio', 'Footwork']),
  Trainer('t8', 'Isha Verma', 'Nutrition coach', 'Nutrition', '1524504388940-b1c1722653e1', 'Jaipur',
      'Sports dietitian. Indian meal plans for performance, fat loss and better energy.',
      4.8, 690, 7, 900, 699,
      tags: ['Indian diet', 'Macros', 'Vegetarian']),
];

Trainer trainerById(String id) => trainers.firstWhere((t) => t.id == id, orElse: () => trainers.first);

class Ex {
  final String name, img, sets, muscle;
  const Ex(this.name, this.img, this.sets, this.muscle);
}

/// Workout plan the trainer assigns, one day per entry.
const planDays = [
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

const dietPlan = [
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
  const Booking(this.at, this.type);
  Map<String, dynamic> toJson() => {'a': at.millisecondsSinceEpoch, 't': type};
  static Booking fromJson(Map<String, dynamic> j) => Booking(DateTime.fromMillisecondsSinceEpoch(j['a']), j['t']);
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
  }
  static final TrainerStore I = TrainerStore._();
  static const _key = 'trainer_sub_v1';

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
  String _doneDay = '';

  Trainer? get trainer => trainerId == null ? null : trainerById(trainerId!);
  bool get active => trainer != null && (until?.isAfter(DateTime.now()) ?? false);
  int get unread => notes.where((n) => !n.read).length;
  int get planIndex => (DateTime.now().weekday - 1) % planDays.length;
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

  DateTime get nextLive {
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, 18, 30);
    if (t.isBefore(now.subtract(const Duration(minutes: 45)))) t = t.add(const Duration(days: 1));
    return t;
  }

  bool get liveNow {
    final d = DateTime.now().difference(nextLive).inMinutes;
    return d >= -10 && d <= 45;
  }

  void subscribe(Trainer t, Plan p) {
    trainerId = t.id;
    planName = p.name;
    since = DateTime.now();
    until = DateTime.now().add(Duration(days: 30 * p.months));
    chat
      ..clear()
      ..add(ChatMsg(false, 'Hey Rohit! Welcome aboard 🎉 I am ${t.first}, your coach. Tell me your main goal for the next 12 weeks?', DateTime.now()));
    notes.insertAll(0, [
      Note('Welcome to ${t.first}\'s team', 'Your ${p.name.toLowerCase()} plan is active. Your first workout is ready.', 'plan', DateTime.now()),
      Note('Live session today', '${t.first} goes live at ${hhmm(nextLive)}. Tap to join.', 'live', DateTime.now()),
      Note('Diet plan ready', 'Your 1,950 kcal meal plan has been shared.', 'diet', DateTime.now()),
    ]);
    _changed();
  }

  void cancel() {
    trainerId = null;
    planName = null;
    until = null;
    _changed();
  }

  void toggleFollow(Trainer t) {
    following.contains(t.id) ? following.remove(t.id) : following.add(t.id);
    _changed();
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
  }

  void _rollDay() {
    final k = _k(DateTime.now());
    if (_doneDay != k) {
      _doneDay = k;
      doneToday.clear();
    }
  }

  void send(String text) {
    chat.add(ChatMsg(true, text, DateTime.now()));
    _changed();
    final t = trainer;
    if (t == null) return;
    final l = text.toLowerCase();
    final reply = l.contains('diet') || l.contains('eat') || l.contains('food')
        ? 'Stick to the meal plan, and keep protein around 120 g a day. Swap any meal with something similar in calories.'
        : l.contains('pain') || l.contains('hurt') || l.contains('injur')
            ? 'Stop that exercise for today. Send me a short video of the movement and I will adjust your plan.'
            : l.contains('skip') || l.contains('miss') || l.contains('busy')
                ? 'No stress. Do the 20-minute conditioning day instead, and we will catch up tomorrow.'
                : 'Great question! I have noted it and will cover it in tonight\'s live session too. Keep going 💪';
    Future.delayed(const Duration(milliseconds: 1400), () {
      chat.add(ChatMsg(false, reply, DateTime.now()));
      notes.insert(0, Note('${t.first} replied', reply, 'chat', DateTime.now()));
      _changed();
    });
  }

  void addCheckIn(CheckIn c) {
    checkins.insert(0, c);
    final t = trainer;
    if (t != null) notes.insert(0, Note('Check-in received', '${t.first} will review your check-in within 24 hours.', 'checkin', DateTime.now()));
    _changed();
  }

  void book(Booking b) {
    bookings.add(b);
    bookings.sort((a, c) => a.at.compareTo(c.at));
    notes.insert(0, Note('Session booked', '${b.type} on ${dayName(b.at)} at ${hhmm(b.at)}', 'booking', DateTime.now()));
    _changed();
  }

  void cancelBooking(Booking b) {
    bookings.remove(b);
    _changed();
  }

  void markRead(Note n) {
    n.read = true;
    _changed();
  }

  void readAll() {
    for (final n in notes) {
      n.read = true;
    }
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) {
        _seed();
        return;
      }
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
      notifyListeners();
    } catch (_) {
      _seed();
    }
  }

  void _seed() {
    following.addAll(['t1', 't3']);
    final now = DateTime.now();
    checkins.add(CheckIn(now.subtract(const Duration(days: 7)), 74.2, 4, 3, 'Felt strong this week'));
    checkins.add(CheckIn(now.subtract(const Duration(days: 14)), 75.1, 3, 3, 'Busy week at work'));
    _changed();
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
        }),
      );
    } catch (_) {}
  }
}
