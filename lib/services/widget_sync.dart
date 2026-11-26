import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../trainer/trainer_data.dart';
import '../widgets/side_island.dart';
import 'hydration_store.dart';

// Feeds the five Android home screen widgets (steps, today stats, quick
// actions, water and workout) and handles taps on them. Android only; a no-op
// on web and iOS.
//
// The water widget's +250 button is handled natively and stores the amount
// under 'water_pending'; the app adds it to today's log when it opens.

class WidgetSync {
  WidgetSync._();

  static const _pkg = 'com.neurofit.athlete.pro.widgets';
  static const providers = ['StepsWidget', 'StatsWidget', 'QuickActionsWidget', 'WaterWidget', 'WorkoutWidget'];

  /// Where a widget tap wants to go: steps, water, workout, meal, kemo,
  /// trainer, stats. Cleared by whoever handles it.
  static final route = ValueNotifier<String?>(null);

  static bool get _on => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Timer? _debounce;
  static bool _started = false;

  static Future<void> init() async {
    if (!_on || _started) return;
    _started = true;
    try {
      final first = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _open(first);
      HomeWidget.widgetClicked.listen(_open);
    } catch (_) {}
    AppLifecycleListener(onResume: () {
      _pullWater();
      push();
    });
    HydrationStore.I.addListener(_schedule);
    TrainerStore.I.addListener(_schedule);
    await _pullWater();
    await push();
  }

  static void _open(Uri? uri) {
    if (uri == null) return;
    final r = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
    if (r.isNotEmpty) route.value = r;
  }

  static void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), push);
  }

  static Future<void> _pullWater() async {
    try {
      final v = await HomeWidget.getWidgetData<int>('water_pending', defaultValue: 0);
      final n = v ?? 0;
      if (n <= 0) return;
      await HomeWidget.saveWidgetData<int>('water_pending', 0);
      for (var i = 0; i < n ~/ 250; i++) {
        HydrationStore.I.add('water', 250);
      }
      final rest = n % 250;
      if (rest > 0) HydrationStore.I.add('water', rest);
    } catch (_) {}
  }

  static Future<void> push() async {
    if (!_on) return;
    try {
      final h = HydrationStore.I;
      final t = TrainerStore.I;
      final day = planDays[t.planIndex];
      final done = day.$3.where((e) => t.isDone(e.name)).length;
      final data = <String, Object>{
        'steps': IslandStats.steps,
        'step_goal': IslandStats.stepGoal,
        'kcal_eaten': IslandStats.eaten,
        'kcal_burned': IslandStats.burned,
        'kcal_budget': IslandStats.budget,
        'water': h.total,
        'water_goal': h.goal,
        'sleep': '7h 20m',
        'streak': h.streak,
        'workout': day.$1,
        'workout_sub': day.$2,
        'workout_total': day.$3.length,
        'workout_done': done,
        'workout_moves': [
          ...day.$3.where((e) => !t.isDone(e.name)),
          ...day.$3.where((e) => t.isDone(e.name)),
        ].map((e) => '${e.name} ${e.sets}').join('|'),
        'coach': t.active && t.trainer != null ? t.trainer!.name : '',
      };
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData(e.key, e.value);
      }
      for (final p in providers) {
        await HomeWidget.updateWidget(qualifiedAndroidName: '$_pkg.$p');
      }
    } catch (e) {
      debugPrint('Widget sync: $e');
    }
  }
}
