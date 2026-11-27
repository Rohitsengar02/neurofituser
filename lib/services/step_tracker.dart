import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/sync_store.dart';

/// Real step counting, the way Google Fit does it on the phone:
///
/// * The hardware step counter (Android TYPE_STEP_COUNTER, iOS CMPedometer)
///   reports a running total since the last reboot. We keep the last raw
///   value and add each increase to today's count, so steps survive app
///   restarts and the count resets at midnight. A drop in the raw value
///   means the phone rebooted, and the new raw value is all new steps.
/// * When there is no hardware counter (web, some phones) we fall back to
///   peak detection on the accelerometer.
/// * Steps are bucketed per hour for the day chart and kept per day for the
///   calendar. Nothing is invented: days without data are zero.
class StepTracker extends ChangeNotifier {
  StepTracker._();
  static final StepTracker instance = StepTracker._();

  static const _key = 'step_tracker_v1';
  static const double strideM = 0.74;
  static const double kcalPerStep = 0.04;

  int goal = 10000;
  int today = 0;
  List<int> hours = List.filled(24, 0);
  final Map<String, int> history = {}; // yyyy-mm-dd -> steps
  String status = 'unknown'; // walking / stopped / unknown
  String source = 'starting'; // sensor / motion / unavailable / denied / starting

  String _day = _dayKey(DateTime.now());
  int? _lastRaw;
  bool _started = false;
  StreamSubscription<StepCount>? _steps;
  StreamSubscription<PedestrianStatus>? _ped;
  StreamSubscription<UserAccelerometerEvent>? _accel;
  Timer? _fallbackTimer, _saveTimer;

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int stepsOn(DateTime d) => _dayKey(d) == _day ? today : (history[_dayKey(d)] ?? 0);
  double get km => today * strideM / 1000;
  int get kcal => (today * kcalPerStep).round();
  int get activeMin => hours.where((h) => h > 60).length * 60 ~/ 2 + today ~/ 110;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _load();
    if (!kIsWeb) {
      try {
        final s = await Permission.activityRecognition.request();
        if (s.isPermanentlyDenied || s.isDenied) {
          final s2 = await Permission.sensors.request();
          if (!s2.isGranted && !s.isGranted && s.isPermanentlyDenied) source = 'denied';
        }
      } catch (_) {}
    }
    _listenHardware();
    // If the hardware counter says nothing within a few seconds, fall back
    // to the accelerometer.
    _fallbackTimer = Timer(const Duration(seconds: 4), () {
      if (source != 'sensor') _listenMotion();
      // Desktop browsers have no motion sensor and never send an event.
      Timer(const Duration(seconds: 5), () {
        if (source == 'starting') {
          source = 'unavailable';
          notifyListeners();
        }
      });
    });
    notifyListeners();
  }

  void _listenHardware() {
    if (kIsWeb) return;
    try {
      _steps = Pedometer.stepCountStream.listen(_onRaw, onError: (_) {
        if (source != 'sensor') _listenMotion();
      });
      _ped = Pedometer.pedestrianStatusStream.listen((e) {
        status = e.status;
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}
  }

  void _onRaw(StepCount e) {
    source = 'sensor';
    _accel?.cancel();
    _accel = null;
    final raw = e.steps;
    final last = _lastRaw;
    _lastRaw = raw;
    if (last == null) {
      _save();
      notifyListeners();
      return;
    }
    final delta = raw >= last ? raw - last : raw; // reboot resets the counter
    if (delta > 0 && delta < 20000) _add(delta);
  }

  // Accelerometer fallback: low-pass the magnitude and count peaks that are
  // at least 280 ms apart, like a basic pedometer.
  double _avg = 0, _prev = 0;
  bool _rising = false;
  DateTime _lastPeak = DateTime.fromMillisecondsSinceEpoch(0);

  void _listenMotion() {
    if (_accel != null || source == 'sensor') return;
    try {
      _accel = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((e) {
        if (source != 'motion') {
          source = 'motion';
          notifyListeners();
        }
        final m = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        _avg = _avg * 0.8 + m * 0.2;
        if (_avg > _prev) {
          _rising = true;
        } else if (_rising && _prev > 1.1) {
          _rising = false;
          final now = DateTime.now();
          final gap = now.difference(_lastPeak).inMilliseconds;
          if (gap > 280 && gap < 2000) _add(1);
          _lastPeak = now;
          status = 'walking';
        }
        _prev = _avg;
      }, onError: (_) {
        source = 'unavailable';
        notifyListeners();
      });
    } catch (_) {
      source = 'unavailable';
      notifyListeners();
    }
  }

  void _add(int n) {
    final now = DateTime.now();
    final k = _dayKey(now);
    if (k != _day) {
      history[_day] = today;
      _day = k;
      today = 0;
      hours = List.filled(24, 0);
    }
    today += n;
    hours[now.hour] += n;
    history[_day] = today;
    _saveTimer ??= Timer(const Duration(seconds: 3), () {
      _saveTimer = null;
      _save();
    });
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      goal = j['goal'] ?? goal;
      _lastRaw = j['lastRaw'];
      (j['history'] as Map<String, dynamic>? ?? {}).forEach((k, v) => history[k] = v as int);
      if (j['day'] == _day) {
        today = j['today'] ?? 0;
        hours = List<int>.from(j['hours'] ?? List.filled(24, 0));
      } else if (j['day'] != null) {
        history[j['day']] = j['today'] ?? 0;
      }
    } catch (_) {}
    try {
      // Days counted on the user's other phone.
      (await SyncStore.I.all('steps_day')).forEach((k, v) {
        final n = (v['steps'] as num?)?.toInt() ?? 0;
        if (k != _day && n > (history[k] ?? 0)) history[k] = n;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          'goal': goal,
          'lastRaw': _lastRaw,
          'day': _day,
          'today': today,
          'hours': hours,
          'history': history,
        }),
      );
      // Synced to the account (other devices + admin analytics).
      await SyncStore.I.put('steps_day', _day, {'steps': today, 'goal': goal, 'km': double.parse(km.toStringAsFixed(2)), 'kcal': kcal});
    } catch (_) {}
  }

  void setGoal(int g) {
    goal = g;
    _save();
    notifyListeners();
  }

  @override
  void dispose() {
    _steps?.cancel();
    _ped?.cancel();
    _accel?.cancel();
    _fallbackTimer?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
