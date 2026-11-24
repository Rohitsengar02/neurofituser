import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class WorkoutCategoryModel {
  final String id;
  final String name;
  final String description;
  final String mediaType; // 'image' | 'gif' | 'video'
  final String mediaUrl;
  final int sortOrder;
  final bool isActive;

  WorkoutCategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.mediaType = 'image',
    this.mediaUrl = '',
    this.sortOrder = 1,
    this.isActive = true,
  });

  factory WorkoutCategoryModel.fromJson(Map<String, dynamic> json) {
    return WorkoutCategoryModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      mediaType: json['mediaType'] ?? 'image',
      mediaUrl: json['mediaUrl'] ?? '',
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] : int.tryParse(json['sortOrder']?.toString() ?? '1') ?? 1,
      isActive: json['isActive'] ?? true,
    );
  }
}

class WorkoutCategoryBackendService extends ChangeNotifier {
  static final WorkoutCategoryBackendService _instance = WorkoutCategoryBackendService._internal();
  factory WorkoutCategoryBackendService() => _instance;

  WorkoutCategoryBackendService._internal() {
    _initSocket();
  }

  final List<WorkoutCategoryModel> _categories = [];
  bool _isLoading = false;
  IO.Socket? _socket;

  List<WorkoutCategoryModel> get categories => List.unmodifiable(_categories);
  List<WorkoutCategoryModel> get activeCategories =>
      _categories.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;

  void _initSocket() {
    if (ApiConstants.demoMode) return;
    try {
      final socketUrl = ApiConstants.apiBaseUrl.replaceAll('/api', '');
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.on('workout_category_updated', (data) {
        debugPrint('⚡ [Workout App Category Socket Event]: $data');
        fetchCategories(silent: true);
      });
    } catch (e) {
      debugPrint('⚠️ [Workout App Category Socket Init Error]: $e');
    }
  }

  Future<void> fetchCategories({bool silent = false}) async {
    if (!silent && _categories.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    final candidateUrls = ApiConstants.candidateBaseUrls
        .map((b) => Uri.parse('$b/api/workout-categories'))
        .toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final rawList = (decoded['data'] ?? decoded) as List<dynamic>? ?? [];
          if (rawList.isNotEmpty) {
            _categories.clear();
            for (final item in rawList) {
              _categories.add(WorkoutCategoryModel.fromJson(Map<String, dynamic>.from(item as Map)));
            }
            _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            debugPrint('✅ [WORKOUT CATEGORIES LOADED] ${_categories.length} categories');
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (_) {}
    }

    if (_categories.isEmpty) {
      _categories.addAll(getDefaultFallbackCategories());
    }

    _isLoading = false;
    notifyListeners();
  }

  List<WorkoutCategoryModel> getDefaultFallbackCategories() {
    return [
      WorkoutCategoryModel(id: 'wcat_strength', name: 'Strength', mediaType: 'image', mediaUrl: 'workout_category_1.png', sortOrder: 1),
      WorkoutCategoryModel(id: 'wcat_hiit', name: 'HIIT & Circuit', mediaType: 'image', mediaUrl: 'workout_category_2.jpg', sortOrder: 2),
      WorkoutCategoryModel(id: 'wcat_yoga', name: 'Yoga & Flow', mediaType: 'image', mediaUrl: 'workout_category_3.png', sortOrder: 3),
      WorkoutCategoryModel(id: 'wcat_core', name: 'Core & Abs', mediaType: 'image', mediaUrl: 'workout_category_4.png', sortOrder: 4),
      WorkoutCategoryModel(id: 'wcat_cardio', name: 'Cardio Blast', mediaType: 'image', mediaUrl: 'workout_category_5.png', sortOrder: 5),
    ];
  }
}
