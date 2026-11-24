import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ExerciseCategoryModel {
  String id;
  String categoryId;
  String name;
  String slug;
  String description;
  String imageUrl;
  String mediaType; // 'image' | 'gif' | 'video'
  int sortOrder;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  ExerciseCategoryModel({
    this.id = '',
    required this.categoryId,
    required this.name,
    this.slug = '',
    this.description = '',
    this.imageUrl = '',
    this.mediaType = 'image',
    this.sortOrder = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ExerciseCategoryModel.fromJson(Map<String, dynamic> json) {
    final String rawUrl = json['imageUrl'] ?? json['icon'] ?? '';
    String mType = json['mediaType'] ?? 'image';
    if (mType == 'image' && rawUrl.isNotEmpty) {
      final lower = rawUrl.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
        mType = 'video';
      } else if (lower.endsWith('.gif')) {
        mType = 'gif';
      }
    }

    return ExerciseCategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      categoryId: json['categoryId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      imageUrl: rawUrl,
      mediaType: mType,
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder']
          : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ExerciseCategoryBackendService extends ChangeNotifier {
  static final ExerciseCategoryBackendService _instance = ExerciseCategoryBackendService._internal();
  factory ExerciseCategoryBackendService() => _instance;
  ExerciseCategoryBackendService._internal() {
    fetchCategories();
  }

  final List<ExerciseCategoryModel> _categories = [];
  bool _isLoading = false;

  List<ExerciseCategoryModel> get categories => List.unmodifiable(_categories);
  List<ExerciseCategoryModel> get activeCategories => List.unmodifiable(_categories.where((c) => c.isActive));
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = ApiConstants.baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/api/exercise-categories'));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          _categories.clear();
          for (var item in body['data']) {
            _categories.add(ExerciseCategoryModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching exercise categories in user app: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
