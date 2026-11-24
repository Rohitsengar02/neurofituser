import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'user_backend_service.dart';

class UserWorkoutProgress {
  final String uid;
  final String workoutId;
  final String workoutTitle;
  final int dayNumber;
  final int weekNumber;
  final String status; // 'not_started', 'in_progress', 'completed'
  final int currentExerciseIndex;
  final int currentSetIndex;
  final int totalDurationSeconds;
  final Set<String> completedExercises;
  final bool dayCompleted;

  UserWorkoutProgress({
    required this.uid,
    required this.workoutId,
    this.workoutTitle = 'Workout',
    this.dayNumber = 1,
    this.weekNumber = 1,
    this.status = 'not_started',
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.totalDurationSeconds = 0,
    Set<String>? completedExercises,
    this.dayCompleted = false,
  }) : completedExercises = completedExercises ?? {};

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed' || dayCompleted;
  bool get isNotStarted => status == 'not_started';

  factory UserWorkoutProgress.fromJson(Map<String, dynamic> json) {
    final rawCompleted = json['completedExercises'];
    final Set<String> completedSet = {};
    if (rawCompleted is List) {
      for (var item in rawCompleted) {
        if (item != null) completedSet.add(item.toString());
      }
    }

    return UserWorkoutProgress(
      uid: (json['uid'] ?? '').toString(),
      workoutId: (json['workoutId'] ?? '').toString(),
      workoutTitle: (json['workoutTitle'] ?? 'Workout').toString(),
      dayNumber: json['dayNumber'] is int
          ? json['dayNumber']
          : int.tryParse(json['dayNumber']?.toString() ?? '1') ?? 1,
      weekNumber: json['weekNumber'] is int
          ? json['weekNumber']
          : int.tryParse(json['weekNumber']?.toString() ?? '1') ?? 1,
      status: (json['status'] ?? 'not_started').toString(),
      currentExerciseIndex: json['currentExerciseIndex'] is int
          ? json['currentExerciseIndex']
          : int.tryParse(json['currentExerciseIndex']?.toString() ?? '0') ?? 0,
      currentSetIndex: json['currentSetIndex'] is int
          ? json['currentSetIndex']
          : int.tryParse(json['currentSetIndex']?.toString() ?? '0') ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] is int
          ? json['totalDurationSeconds']
          : int.tryParse(json['totalDurationSeconds']?.toString() ?? '0') ?? 0,
      completedExercises: completedSet,
      dayCompleted: json['dayCompleted'] == true || json['status'] == 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'workoutId': workoutId,
      'workoutTitle': workoutTitle,
      'dayNumber': dayNumber,
      'weekNumber': weekNumber,
      'status': status,
      'currentExerciseIndex': currentExerciseIndex,
      'currentSetIndex': currentSetIndex,
      'totalDurationSeconds': totalDurationSeconds,
      'completedExercises': completedExercises.toList(),
      'dayCompleted': dayCompleted,
    };
  }
}

class UserWorkoutService extends ChangeNotifier {
  static final UserWorkoutService _instance = UserWorkoutService._internal();
  factory UserWorkoutService() => _instance;
  static UserWorkoutService get instance => _instance;
  UserWorkoutService._internal() {
    _initSocket();
  }

  IO.Socket? _socket;
  final Map<String, UserWorkoutProgress> _cache = {};

  String get _currentUid {
    final uid = UserBackendService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    return 'guest_athlete';
  }

  String _cacheKey(String uid, String workoutId, int dayNumber) =>
      '${uid}_${workoutId}_$dayNumber';

  void _initSocket() {
    if (ApiConstants.demoMode) return;
    try {
      _socket = IO.io(
        ApiConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        debugPrint('🔌 UserWorkoutService connected to Socket.io');
        _joinUserRoom();
      });

      _socket?.on('user_workout_started', (data) {
        if (data is Map) {
          _handleLiveProgressUpdate(Map<String, dynamic>.from(data));
        }
      });

      _socket?.on('user_workout_progress_updated', (data) {
        if (data is Map) {
          _handleLiveProgressUpdate(Map<String, dynamic>.from(data));
        }
      });

      _socket?.on('user_workout_reset', (data) {
        if (data is Map) {
          _handleLiveProgressUpdate(Map<String, dynamic>.from(data));
        }
      });
    } catch (e) {
      debugPrint('UserWorkoutService Socket init error: $e');
    }
  }

  void _joinUserRoom() {
    final uid = _currentUid;
    if (uid.isNotEmpty && _socket != null && _socket!.connected) {
      _socket?.emit('join_user_room', uid);
    }
  }

  void _handleLiveProgressUpdate(Map<String, dynamic> data) {
    try {
      final rawWorkout = data['userWorkout'];
      if (rawWorkout is Map) {
        final progress =
            UserWorkoutProgress.fromJson(Map<String, dynamic>.from(rawWorkout));
        final key = _cacheKey(progress.uid, progress.workoutId, progress.dayNumber);
        _cache[key] = progress;
        _saveToLocalPrefs(key, progress);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error parsing live progress socket: $e');
    }
  }

  UserWorkoutProgress? getCachedProgress(String workoutId, int dayNumber) {
    final key = _cacheKey(_currentUid, workoutId, dayNumber);
    return _cache[key];
  }

  // 1. Fetch live user progress for a workout day
  Future<UserWorkoutProgress> fetchProgress(String workoutId, int dayNumber) async {
    final uid = _currentUid;
    final key = _cacheKey(uid, workoutId, dayNumber);

    // Try local memory first
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Try local storage
    final local = await _loadFromLocalPrefs(key);
    if (local != null) {
      _cache[key] = local;
      notifyListeners();
    }

    try {
      final uri = Uri.parse(
          '${ApiConstants.apiBaseUrl}/user-workouts/progress/$uid/$workoutId/$dayNumber');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['userWorkout'] != null) {
          final progress = UserWorkoutProgress.fromJson(
              Map<String, dynamic>.from(data['userWorkout']));
          _cache[key] = progress;
          _saveToLocalPrefs(key, progress);
          notifyListeners();
          return progress;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user workout progress: $e');
    }

    return _cache[key] ??
        UserWorkoutProgress(uid: uid, workoutId: workoutId, dayNumber: dayNumber);
  }

  // 2. Start a workout session
  Future<UserWorkoutProgress?> startWorkout({
    required String workoutId,
    required String workoutTitle,
    required int dayNumber,
    int weekNumber = 1,
    List<Map<String, dynamic>> exercises = const [],
  }) async {
    final uid = _currentUid;
    final key = _cacheKey(uid, workoutId, dayNumber);
    _joinUserRoom();

    try {
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/user-workouts/start');
      final body = {
        'uid': uid,
        'workoutId': workoutId,
        'workoutTitle': workoutTitle,
        'dayNumber': dayNumber,
        'weekNumber': weekNumber,
        'exercises': exercises,
        'totalExercisesCount': exercises.length,
      };

      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['userWorkout'] != null) {
          final progress = UserWorkoutProgress.fromJson(
              Map<String, dynamic>.from(data['userWorkout']));
          _cache[key] = progress;
          _saveToLocalPrefs(key, progress);
          notifyListeners();
          return progress;
        }
      }
    } catch (e) {
      debugPrint('Error starting workout session: $e');
    }

    // Fallback in-memory
    final fallback = UserWorkoutProgress(
      uid: uid,
      workoutId: workoutId,
      workoutTitle: workoutTitle,
      dayNumber: dayNumber,
      weekNumber: weekNumber,
      status: 'in_progress',
    );
    _cache[key] = fallback;
    _saveToLocalPrefs(key, fallback);
    notifyListeners();
    return fallback;
  }

  // 3. Update active workout progress in real time
  Future<void> updateProgress({
    required String workoutId,
    required int dayNumber,
    int? currentExerciseIndex,
    int? currentSetIndex,
    String? completedExerciseId,
    bool? isExerciseCompleted,
    int? totalDurationSeconds,
    bool? dayCompleted,
  }) async {
    final uid = _currentUid;
    final key = _cacheKey(uid, workoutId, dayNumber);

    // Optimistic local update
    final current = _cache[key] ??
        UserWorkoutProgress(uid: uid, workoutId: workoutId, dayNumber: dayNumber);
    final Set<String> updatedCompleted = Set.from(current.completedExercises);
    if (completedExerciseId != null && completedExerciseId.isNotEmpty) {
      if (isExerciseCompleted != false) {
        updatedCompleted.add(completedExerciseId);
      } else {
        updatedCompleted.remove(completedExerciseId);
      }
    }

    final updated = UserWorkoutProgress(
      uid: uid,
      workoutId: workoutId,
      workoutTitle: current.workoutTitle,
      dayNumber: dayNumber,
      weekNumber: current.weekNumber,
      status: dayCompleted == true ? 'completed' : 'in_progress',
      currentExerciseIndex: currentExerciseIndex ?? current.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? current.currentSetIndex,
      totalDurationSeconds: totalDurationSeconds ?? current.totalDurationSeconds,
      completedExercises: updatedCompleted,
      dayCompleted: dayCompleted ?? current.dayCompleted,
    );

    _cache[key] = updated;
    _saveToLocalPrefs(key, updated);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/user-workouts/progress');
      final body = {
        'uid': uid,
        'workoutId': workoutId,
        'dayNumber': dayNumber,
        if (currentExerciseIndex != null)
          'currentExerciseIndex': currentExerciseIndex,
        if (currentSetIndex != null) 'currentSetIndex': currentSetIndex,
        if (completedExerciseId != null)
          'completedExerciseId': completedExerciseId,
        if (isExerciseCompleted != null)
          'isExerciseCompleted': isExerciseCompleted,
        if (totalDurationSeconds != null)
          'totalDurationSeconds': totalDurationSeconds,
        if (dayCompleted != null) 'dayCompleted': dayCompleted,
      };

      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      debugPrint('Error updating workout progress: $e');
    }
  }

  // 4. Toggle single exercise completion (from checkbox on Day Detail screen)
  Future<void> toggleExerciseCompletion({
    required String workoutId,
    required int dayNumber,
    required String exerciseId,
    required bool isDone,
  }) async {
    await updateProgress(
      workoutId: workoutId,
      dayNumber: dayNumber,
      completedExerciseId: exerciseId,
      isExerciseCompleted: isDone,
    );
  }

  // 5. Reset progress for a day
  Future<void> resetWorkout(String workoutId, int dayNumber) async {
    final uid = _currentUid;
    final key = _cacheKey(uid, workoutId, dayNumber);

    // Optimistic reset
    final reset = UserWorkoutProgress(
      uid: uid,
      workoutId: workoutId,
      dayNumber: dayNumber,
      status: 'not_started',
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      totalDurationSeconds: 0,
      completedExercises: {},
      dayCompleted: false,
    );
    _cache[key] = reset;
    _saveToLocalPrefs(key, reset);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/user-workouts/reset');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'workoutId': workoutId,
          'dayNumber': dayNumber,
        }),
      );
    } catch (e) {
      debugPrint('Error resetting workout: $e');
    }
  }

  Future<void> _saveToLocalPrefs(String key, UserWorkoutProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uw_$key', jsonEncode(progress.toJson()));
    } catch (_) {}
  }

  Future<UserWorkoutProgress?> _loadFromLocalPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('uw_$key');
      if (str != null) {
        return UserWorkoutProgress.fromJson(jsonDecode(str));
      }
    } catch (_) {}
    return null;
  }
}
