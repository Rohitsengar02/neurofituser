import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class WorkoutExerciseModel {
  String exerciseId;
  String title;
  String categoryId;
  String muscleGroup;
  String mediaUrl;
  String mediaType;
  int sets;
  int reps;
  int durationSeconds;
  int restSeconds;
  String instructions;

  WorkoutExerciseModel({
    required this.exerciseId,
    required this.title,
    this.categoryId = '',
    this.muscleGroup = '',
    this.mediaUrl = '',
    this.mediaType = 'image',
    this.sets = 3,
    this.reps = 12,
    this.durationSeconds = 0,
    this.restSeconds = 45,
    this.instructions = '',
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      exerciseId: (json['exerciseId'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      muscleGroup: (json['muscleGroup'] ?? '').toString(),
      mediaUrl: (json['mediaUrl'] ?? json['imageUrl'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? 'image').toString(),
      sets: json['sets'] is int ? json['sets'] : int.tryParse(json['sets']?.toString() ?? '3') ?? 3,
      reps: json['reps'] is int ? json['reps'] : int.tryParse(json['reps']?.toString() ?? '12') ?? 12,
      durationSeconds: json['durationSeconds'] is int ? json['durationSeconds'] : int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0,
      restSeconds: json['restSeconds'] is int ? json['restSeconds'] : int.tryParse(json['restSeconds']?.toString() ?? '45') ?? 45,
      instructions: (json['instructions'] ?? json['tip'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'title': title,
      'categoryId': categoryId,
      'muscleGroup': muscleGroup,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'restSeconds': restSeconds,
      'instructions': instructions,
    };
  }
}

class WorkoutDayModel {
  int dayNumber;
  int weekNumber;
  String title;
  String focus;
  int durationMinutes;
  int caloriesBurn;
  bool isRestDay;
  List<WorkoutExerciseModel> exercises;

  WorkoutDayModel({
    this.dayNumber = 1,
    this.weekNumber = 1,
    String? title,
    String? focus,
    this.durationMinutes = 45,
    this.caloriesBurn = 350,
    this.isRestDay = false,
    List<WorkoutExerciseModel>? exercises,
  })  : title = title ?? '',
        focus = focus ?? 'Full Body Focus',
        exercises = exercises ?? [];

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) {
    final List<WorkoutExerciseModel> exList = [];
    if (json['exercises'] is List) {
      for (var e in json['exercises']) {
        if (e != null && e is Map) {
          exList.add(WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return WorkoutDayModel(
      dayNumber: json['dayNumber'] is int ? json['dayNumber'] : int.tryParse(json['dayNumber']?.toString() ?? '1') ?? 1,
      weekNumber: json['weekNumber'] is int ? json['weekNumber'] : int.tryParse(json['weekNumber']?.toString() ?? '1') ?? 1,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      focus: (json['focus'] ?? 'Full Body Focus').toString(),
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] : int.tryParse(json['durationMinutes']?.toString() ?? '45') ?? 45,
      caloriesBurn: json['caloriesBurn'] is int ? json['caloriesBurn'] : int.tryParse(json['caloriesBurn']?.toString() ?? '350') ?? 350,
      isRestDay: json['isRestDay'] == true,
      exercises: exList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'weekNumber': weekNumber,
      'title': title,
      'focus': focus,
      'durationMinutes': durationMinutes,
      'caloriesBurn': caloriesBurn,
      'isRestDay': isRestDay,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkoutModel {
  String id;
  String title;
  String subtitle;
  String description;
  String category;
  String workoutCategoryId;
  int durationMinutes;
  int caloriesBurn;
  String level;
  String coach;
  String imageUrl;
  String mediaType;
  int exercisesCount;
  double completionRate;
  double rating;
  List<String> tags;
  List<WorkoutExerciseModel> exercises;
  List<WorkoutDayModel> days;
  bool isFeatured;
  bool isActive;

  WorkoutModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    required this.category,
    this.workoutCategoryId = '',
    this.durationMinutes = 45,
    this.caloriesBurn = 350,
    this.level = 'Intermediate',
    this.coach = 'Coach Vikram',
    required this.imageUrl,
    this.mediaType = 'image',
    this.exercisesCount = 6,
    this.completionRate = 92.0,
    this.rating = 4.9,
    List<String>? tags,
    List<WorkoutExerciseModel>? exercises,
    List<WorkoutDayModel>? days,
    this.isFeatured = true,
    this.isActive = true,
  })  : tags = tags ?? [],
        exercises = exercises ?? [],
        days = days ?? [];

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['imageUrl'] ?? json['mediaUrl'] ?? '').toString();
    String mType = (json['mediaType'] ?? 'image').toString();
    if (mType == 'image' && rawUrl.isNotEmpty) {
      final lower = rawUrl.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
        mType = 'video';
      } else if (lower.endsWith('.gif')) {
        mType = 'gif';
      }
    }

    final List<WorkoutExerciseModel> exList = [];
    if (json['exercises'] is List) {
      for (var e in json['exercises']) {
        if (e != null && e is Map) {
          exList.add(WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final List<WorkoutDayModel> dList = [];
    if (json['days'] is List) {
      for (var d in json['days']) {
        if (d != null && d is Map) {
          dList.add(WorkoutDayModel.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }

    final List<String> tList = [];
    if (json['tags'] is List) {
      for (var t in json['tags']) {
        if (t != null && t.toString().isNotEmpty) {
          tList.add(t.toString());
        }
      }
    }

    return WorkoutModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      workoutCategoryId: (json['workoutCategoryId'] ?? '').toString(),
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] : int.tryParse(json['durationMinutes']?.toString() ?? '45') ?? 45,
      caloriesBurn: json['caloriesBurn'] is int ? json['caloriesBurn'] : int.tryParse(json['caloriesBurn']?.toString() ?? '350') ?? 350,
      level: (json['level'] ?? 'Intermediate').toString(),
      coach: (json['coach'] ?? 'Coach Vikram').toString(),
      imageUrl: rawUrl,
      mediaType: mType,
      exercisesCount: exList.isNotEmpty ? exList.length : (json['exercisesCount'] is int ? json['exercisesCount'] : int.tryParse(json['exercisesCount']?.toString() ?? '6') ?? 6),
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 92.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      tags: tList,
      exercises: exList,
      days: dList,
      isFeatured: json['isFeatured'] == true,
      isActive: json['isActive'] != false,
    );
  }
}

class WorkoutsBackendService extends ChangeNotifier {
  static final WorkoutsBackendService _instance = WorkoutsBackendService._internal();
  factory WorkoutsBackendService() => _instance;
  WorkoutsBackendService._internal() {
    _initSocket();
    fetchWorkouts();
  }

  IO.Socket? _socket;
  List<WorkoutModel> _workouts = [];
  List<WorkoutModel> get workouts => List.unmodifiable(_workouts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _initSocket() {
    try {
      final socketUrl = ApiConstants.baseUrl;
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.onConnect((_) {
        debugPrint('⚡ [WORKOUTS SOCKET CONNECTED] Realtime active');
      });

      _socket?.on('workout_created', (data) {
        if (data != null) {
          final newW = WorkoutModel.fromJson(Map<String, dynamic>.from(data));
          _workouts.removeWhere((w) => w.id == newW.id);
          _workouts.insert(0, newW);
          notifyListeners();
        }
      });

      _socket?.on('workout_updated', (data) {
        if (data != null) {
          final updatedW = WorkoutModel.fromJson(Map<String, dynamic>.from(data));
          final idx = _workouts.indexWhere((w) => w.id == updatedW.id);
          if (idx != -1) {
            _workouts[idx] = updatedW;
          } else {
            _workouts.insert(0, updatedW);
          }
          notifyListeners();
        }
      });

      _socket?.on('workout_deleted', (data) {
        if (data != null && data['id'] != null) {
          final id = data['id'].toString();
          _workouts.removeWhere((w) => w.id == id);
          notifyListeners();
        }
      });

      _socket?.on('workouts_updated', (data) {
        if (data is List) {
          _workouts.clear();
          for (var item in data) {
            _workouts.add(WorkoutModel.fromJson(Map<String, dynamic>.from(item)));
          }
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error initializing workouts socket in user app: $e');
    }
  }

  Future<void> fetchWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/api/workouts')).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          _workouts.clear();
          for (var item in body['data']) {
            _workouts.add(WorkoutModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching workouts in user app: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
