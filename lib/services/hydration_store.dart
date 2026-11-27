import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/live_backend.dart';
import '../backend/sync_store.dart';
import '../widgets/side_island.dart' show IslandStats;

/// One drink type the user can log. [hydration] is how much of the volume
/// counts towards the water goal (coffee hydrates a little less than water).
class Drink {
  final String id, name;
  final IconData icon;
  final Color color;
  final double hydration;
  const Drink(this.id, this.name, this.icon, this.color, [this.hydration = 1]);
}

const drinks = [
  Drink('water', 'Water', Icons.water_drop_rounded, Color(0xFF3B82F6)),
  Drink('tea', 'Green tea', Icons.emoji_food_beverage_rounded, Color(0xFF22A06B), 0.95),
  Drink('coffee', 'Coffee', Icons.coffee_rounded, Color(0xFF9A6B4F), 0.8),
  Drink('juice', 'Juice', Icons.local_drink_rounded, Color(0xFFF59E0B), 0.9),
  Drink('milk', 'Milk', Icons.local_cafe_rounded, Color(0xFF94A3B8), 0.9),
  Drink('coconut', 'Coconut water', Icons.eco_rounded, Color(0xFF14B8A6)),
  Drink('shake', 'Protein shake', Icons.blender_rounded, Color(0xFF8B5CF6), 0.85),
  Drink('soda', 'Sparkling', Icons.bubble_chart_rounded, Color(0xFF06B6D4)),
];

Drink drinkById(String id) => drinks.firstWhere((d) => d.id == id, orElse: () => drinks.first);

class DrinkEntry {
  final String drink;
  final int ml;
  final DateTime at;
  const DrinkEntry(this.drink, this.ml, this.at);
  int get counted => (ml * drinkById(drink).hydration).round();
  Map<String, dynamic> toJson() => {'d': drink, 'ml': ml, 'at': at.millisecondsSinceEpoch};
  static DrinkEntry fromJson(Map<String, dynamic> j) =>
      DrinkEntry(j['d'] as String, j['ml'] as int, DateTime.fromMillisecondsSinceEpoch(j['at'] as int));
}

/// Today's drink log, a 7-day history and reminder settings. It keeps
/// IslandStats.waterMl in sync, and logs a plain water entry when another
/// screen (island, overview card) bumps waterMl directly.
class HydrationStore extends ChangeNotifier {
  HydrationStore._() {
    IslandStats.waterMl.addListener(_external);
    _load();
  }
  static final HydrationStore I = HydrationStore._();
  static const _key = 'hydration_v2';

  int goal = IslandStats.waterGoal;
  bool reminders = true;
  int reminderEveryMin = 90;
  int streak = 0;
  final List<DrinkEntry> today = [];
  final Map<String, int> history = {};
  DrinkEntry? _lastRemoved;
  bool _syncing = false;

  static String _k(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get total => today.fold(0, (a, e) => a + e.counted);
  double get progress => goal == 0 ? 0 : (total / goal).clamp(0.0, 1.0);
  int mlOn(DateTime d) => _k(d) == _k(DateTime.now()) ? total : (history[_k(d)] ?? 0);

  Duration get nextReminder {
    final last = today.isEmpty ? DateTime.now().subtract(const Duration(minutes: 30)) : today.last.at;
    final due = last.add(Duration(minutes: reminderEveryMin));
    final left = due.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void add(String drink, int ml) {
    today.add(DrinkEntry(drink, ml, DateTime.now()));
    today.sort((a, b) => a.at.compareTo(b.at));
    _changed();
  }

  void remove(DrinkEntry e) {
    _lastRemoved = e;
    today.remove(e);
    _changed();
  }

  bool get canUndo => _lastRemoved != null || today.isNotEmpty;

  /// Puts back the last removed entry, or removes the last added one.
  void undo() {
    if (_lastRemoved != null) {
      today.add(_lastRemoved!);
      today.sort((a, b) => a.at.compareTo(b.at));
      _lastRemoved = null;
    } else if (today.isNotEmpty) {
      today.removeLast();
    }
    _changed();
  }

  void setGoal(int g) {
    goal = g;
    _changed();
  }

  void setReminders(bool on, [int? every]) {
    reminders = on;
    if (every != null) reminderEveryMin = every;
    _changed();
  }

  void _external() {
    if (_syncing) return;
    final diff = IslandStats.waterMl.value - total;
    if (diff > 0) {
      today.add(DrinkEntry('water', diff, DateTime.now()));
      _changed(sync: false);
    }
  }

  void _changed({bool sync = true, bool push = true}) {
    history[_k(DateTime.now())] = total;
    _streak();
    if (sync) {
      _syncing = true;
      IslandStats.waterMl.value = total;
      _syncing = false;
    }
    notifyListeners();
    _save(push: push);
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        goal = j['goal'] ?? goal;
        reminders = j['rem'] ?? true;
        reminderEveryMin = j['every'] ?? 90;
        (j['history'] as Map<String, dynamic>? ?? {}).forEach((k, v) => history[k] = v as int);
        today.clear();
        if (j['day'] == _k(DateTime.now())) {
          for (final e in (j['today'] as List? ?? [])) {
            today.add(DrinkEntry.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
    } catch (_) {}
    await _fromAccount();
    SyncStore.I.addListener(() {
      if (SyncStore.I.changed.contains('water_day') || SyncStore.I.changed.contains('water_settings')) _fromAccount();
    });
    _changed(push: false);
  }

  /// Merges what the account holds (logged on another phone, or before a
  /// reinstall): settings, past days and today's drinks.
  Future<void> _fromAccount() async {
    try {
      final set = await SyncStore.I.get('water_settings', 'me');
      if (set != null) {
        goal = (set['goal'] as num?)?.toInt() ?? goal;
        reminders = set['rem'] as bool? ?? reminders;
        reminderEveryMin = (set['every'] as num?)?.toInt() ?? reminderEveryMin;
      }
      final days = await SyncStore.I.all('water_day');
      final todayKey = _k(DateTime.now());
      days.forEach((k, v) {
        final ml = (v['ml'] as num?)?.toInt() ?? 0;
        if (k != todayKey) history[k] = ml;
      });
      final t = days[todayKey];
      if (t != null) {
        final remote = [
          for (final e in (t['entries'] as List? ?? const []))
            if (e is Map) DrinkEntry.fromJson(Map<String, dynamic>.from(e)),
        ];
        final mine = {for (final e in today) e.at.millisecondsSinceEpoch};
        final added = remote.where((e) => !mine.contains(e.at.millisecondsSinceEpoch)).toList();
        if (added.isNotEmpty) {
          today
            ..addAll(added)
            ..sort((a, b) => a.at.compareTo(b.at));
          _changed(push: false);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Days in a row (up to yesterday, plus today once reached) at the goal.
  void _streak() {
    var n = 0;
    var d = DateTime.now().subtract(const Duration(days: 1));
    while ((history[_k(d)] ?? 0) >= goal && goal > 0) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    streak = n + (total >= goal && goal > 0 ? 1 : 0);
  }

  Timer? _pushTimer;

  Future<void> _save({bool push = true}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          'goal': goal,
          'rem': reminders,
          'every': reminderEveryMin,
          'day': _k(DateTime.now()),
          'today': today.map((e) => e.toJson()).toList(),
          'history': history,
        }),
      );
    } catch (_) {}
    if (!push) return;
    // Account copy (works offline, synced later) and the day's nutrition
    // record the admin analytics read.
    final day = _k(DateTime.now());
    final ml = total;
    await SyncStore.I.put('water_day', day, {'ml': ml, 'goal': goal, 'entries': today.map((e) => e.toJson()).toList()});
    await SyncStore.I.put('water_settings', 'me', {'goal': goal, 'rem': reminders, 'every': reminderEveryMin});
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(seconds: 3), () {
      Api.send('POST', '/user-nutrition/water', {'date': day, 'milliliters': ml, 'targetGlasses': (goal / 250).round()})
          .catchError((_) => <String, dynamic>{});
    });
  }
}
