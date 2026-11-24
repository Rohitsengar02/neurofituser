import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'user_backend_service.dart';

class LoggedMealModel {
  final String mealId;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String foodName;
  final String source;
  final String category;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String servingSize;
  final double quantity;
  final String time;
  final String iconType;

  String get id => mealId;
  String get name => foodName;

  LoggedMealModel({
    required this.mealId,
    required this.mealType,
    required this.foodName,
    this.source = 'USDA',
    this.category = 'General',
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.servingSize = '1 serving',
    this.quantity = 1.0,
    this.time = '',
    this.iconType = 'restaurant',
  });

  factory LoggedMealModel.fromJson(Map<String, dynamic> json) {
    return LoggedMealModel(
      mealId: (json['mealId'] ?? '').toString(),
      mealType: (json['mealType'] ?? 'breakfast').toString(),
      foodName: (json['foodName'] ?? json['name'] ?? 'Meal').toString(),
      source: (json['source'] ?? 'USDA').toString(),
      category: (json['category'] ?? 'General').toString(),
      calories: json['calories'] is int
          ? json['calories']
          : int.tryParse(json['calories']?.toString() ?? '0') ?? 0,
      protein: (json['protein'] is num)
          ? (json['protein'] as num).toDouble()
          : double.tryParse(json['protein']?.toString() ?? '0') ?? 0.0,
      carbs: (json['carbs'] is num)
          ? (json['carbs'] as num).toDouble()
          : double.tryParse(json['carbs']?.toString() ?? '0') ?? 0.0,
      fat: (json['fat'] is num)
          ? (json['fat'] as num).toDouble()
          : double.tryParse(json['fat']?.toString() ?? '0') ?? 0.0,
      fiber: (json['fiber'] is num)
          ? (json['fiber'] as num).toDouble()
          : double.tryParse(json['fiber']?.toString() ?? '0') ?? 0.0,
      servingSize: (json['servingSize'] ?? '1 serving').toString(),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      time: (json['time'] ?? '').toString(),
      iconType: (json['iconType'] ?? 'restaurant').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealId': mealId,
      'mealType': mealType,
      'foodName': foodName,
      'source': source,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'servingSize': servingSize,
      'quantity': quantity,
      'time': time,
      'iconType': iconType,
    };
  }
}

class UserDailyNutritionModel {
  final String uid;
  final String date;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final int consumedCalories;
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;
  final double consumedFiber;
  final int waterGlasses;
  final int waterTargetGlasses;
  final int waterMilliliters;
  final List<LoggedMealModel> meals;

  List<LoggedMealModel> get loggedMeals => meals;

  static UserDailyNutritionModel empty() {
    return UserDailyNutritionModel(
      uid: '',
      date: DateTime.now().toString().substring(0, 10),
      targetCalories: 2400,
      targetProtein: 140,
      targetCarbs: 220,
      targetFat: 60,
      consumedCalories: 0,
      consumedProtein: 0.0,
      consumedCarbs: 0.0,
      consumedFat: 0.0,
      consumedFiber: 0.0,
      waterGlasses: 0,
      waterTargetGlasses: 8,
      waterMilliliters: 0,
      meals: [],
    );
  }

  UserDailyNutritionModel({
    required this.uid,
    required this.date,
    this.targetCalories = 2400,
    this.targetProtein = 140,
    this.targetCarbs = 220,
    this.targetFat = 60,
    this.consumedCalories = 0,
    this.consumedProtein = 0.0,
    this.consumedCarbs = 0.0,
    this.consumedFat = 0.0,
    this.consumedFiber = 0.0,
    this.waterGlasses = 0,
    this.waterTargetGlasses = 8,
    this.waterMilliliters = 0,
    List<LoggedMealModel>? meals,
  }) : meals = meals ?? [];

  factory UserDailyNutritionModel.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'];
    final List<LoggedMealModel> mealList = [];
    if (rawMeals is List) {
      for (var item in rawMeals) {
        if (item is Map) {
          mealList.add(LoggedMealModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return UserDailyNutritionModel(
      uid: (json['uid'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      targetCalories: json['targetCalories'] is int
          ? json['targetCalories']
          : int.tryParse(json['targetCalories']?.toString() ?? '2400') ?? 2400,
      targetProtein: json['targetProtein'] is int
          ? json['targetProtein']
          : int.tryParse(json['targetProtein']?.toString() ?? '140') ?? 140,
      targetCarbs: json['targetCarbs'] is int
          ? json['targetCarbs']
          : int.tryParse(json['targetCarbs']?.toString() ?? '220') ?? 220,
      targetFat: json['targetFat'] is int
          ? json['targetFat']
          : int.tryParse(json['targetFat']?.toString() ?? '60') ?? 60,
      consumedCalories: json['consumedCalories'] is int
          ? json['consumedCalories']
          : int.tryParse(json['consumedCalories']?.toString() ?? '0') ?? 0,
      consumedProtein: (json['consumedProtein'] is num)
          ? (json['consumedProtein'] as num).toDouble()
          : double.tryParse(json['consumedProtein']?.toString() ?? '0') ?? 0.0,
      consumedCarbs: (json['consumedCarbs'] is num)
          ? (json['consumedCarbs'] as num).toDouble()
          : double.tryParse(json['consumedCarbs']?.toString() ?? '0') ?? 0.0,
      consumedFat: (json['consumedFat'] is num)
          ? (json['consumedFat'] as num).toDouble()
          : double.tryParse(json['consumedFat']?.toString() ?? '0') ?? 0.0,
      consumedFiber: (json['consumedFiber'] is num)
          ? (json['consumedFiber'] as num).toDouble()
          : double.tryParse(json['consumedFiber']?.toString() ?? '0') ?? 0.0,
      waterGlasses: json['waterGlasses'] is int
          ? json['waterGlasses']
          : int.tryParse(json['waterGlasses']?.toString() ?? '0') ?? 0,
      waterTargetGlasses: json['waterTargetGlasses'] is int
          ? json['waterTargetGlasses']
          : int.tryParse(json['waterTargetGlasses']?.toString() ?? '8') ?? 8,
      waterMilliliters: json['waterMilliliters'] is int
          ? json['waterMilliliters']
          : int.tryParse(json['waterMilliliters']?.toString() ?? '0') ?? 0,
      meals: mealList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'date': date,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'consumedCalories': consumedCalories,
      'consumedProtein': consumedProtein,
      'consumedCarbs': consumedCarbs,
      'consumedFat': consumedFat,
      'consumedFiber': consumedFiber,
      'waterGlasses': waterGlasses,
      'waterTargetGlasses': waterTargetGlasses,
      'waterMilliliters': waterMilliliters,
      'meals': meals.map((m) => m.toJson()).toList(),
    };
  }
}

class UserNutritionService extends ChangeNotifier {
  static final UserNutritionService _instance = UserNutritionService._internal();
  factory UserNutritionService() => _instance;
  static UserNutritionService get instance => _instance;

  UserNutritionService._internal() {
    _initSocket();
  }

  IO.Socket? _socket;
  UserDailyNutritionModel? _currentNutrition;
  final Map<String, UserDailyNutritionModel> _dateNutritionCache = {};
  Map<String, dynamic> _historyMap = {};
  List<Map<String, dynamic>> _dailyFeaturedRecipes = [];
  Map<String, dynamic> _mealSuggestions = {};

  UserDailyNutritionModel get currentNutrition =>
      _currentNutrition ?? UserDailyNutritionModel.empty();
  Map<String, dynamic> get historyMap => _historyMap;
  List<Map<String, dynamic>> get dailyFeaturedRecipes => _dailyFeaturedRecipes;
  Map<String, dynamic> get mealSuggestions => _mealSuggestions;

  String get _currentUid {
    final uid = UserBackendService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    return 'guest_athlete';
  }

  void _initSocket() {
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
        debugPrint('🔌 UserNutritionService connected to Socket.io');
        _joinUserRoom();
      });

      _socket?.on('user_nutrition_updated', (data) {
        if (data is Map && data['nutrition'] != null) {
          try {
            _currentNutrition = UserDailyNutritionModel.fromJson(
              Map<String, dynamic>.from(data['nutrition']),
            );
            _saveToLocalPrefs(_currentNutrition!);
            notifyListeners();
          } catch (e) {
            debugPrint('Error parsing real-time nutrition: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('UserNutritionService socket error: $e');
    }
  }

  void _joinUserRoom() {
    final uid = _currentUid;
    if (uid.isNotEmpty && _socket != null && _socket!.connected) {
      _socket?.emit('join_user_nutrition', {'uid': uid});
    }
  }

  // 1. Fetch Today's Nutrition (starts from 0 kcal and 0 glasses)
  Future<UserDailyNutritionModel> fetchTodayNutrition({String? date}) async {
    final uid = _currentUid;
    final targetDate = date ?? DateTime.now().toString().substring(0, 10);

    // Try local cache first for instant UI response
    await _loadFromLocalPrefs(targetDate);

    try {
      final uri = Uri.parse(
        '${ApiConstants.apiBaseUrl}/user-nutrition/today?uid=$uid&date=$targetDate',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['nutrition'] != null) {
          _currentNutrition = UserDailyNutritionModel.fromJson(
            Map<String, dynamic>.from(data['nutrition']),
          );
          _saveToLocalPrefs(_currentNutrition!);
          notifyListeners();
          return _currentNutrition!;
        }
      }
    } catch (e) {
      debugPrint('Error fetching today nutrition from API: $e');
    }

    return _currentNutrition ??
        UserDailyNutritionModel(
          uid: uid,
          date: targetDate,
          consumedCalories: 0,
          consumedProtein: 0.0,
          consumedCarbs: 0.0,
          consumedFat: 0.0,
          waterGlasses: 0,
        );
  }

  // 1b. Fetch Nutrition for Any Specific Date (without necessarily replacing currentNutrition if not today)
  Future<UserDailyNutritionModel> fetchNutritionForDate(String dateKey, {bool forceRefresh = false}) async {
    final todayKey = DateTime.now().toString().substring(0, 10);
    if (dateKey == todayKey && !forceRefresh && _currentNutrition != null) {
      return _currentNutrition!;
    }

    if (!forceRefresh && _dateNutritionCache.containsKey(dateKey)) {
      return _dateNutritionCache[dateKey]!;
    }

    final uid = _currentUid;
    try {
      final uri = Uri.parse(
        '${ApiConstants.apiBaseUrl}/user-nutrition/today?uid=$uid&date=$dateKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['nutrition'] != null) {
          final model = UserDailyNutritionModel.fromJson(
            Map<String, dynamic>.from(data['nutrition']),
          );
          _dateNutritionCache[dateKey] = model;
          if (dateKey == todayKey) {
            _currentNutrition = model;
            notifyListeners();
          }
          return model;
        }
      }
    } catch (e) {
      debugPrint('Error fetching nutrition for date $dateKey: $e');
    }

    final fallback = UserDailyNutritionModel(
      uid: uid,
      date: dateKey,
      consumedCalories: 0,
      consumedProtein: 0.0,
      consumedCarbs: 0.0,
      consumedFat: 0.0,
      waterGlasses: 0,
    );
    _dateNutritionCache[dateKey] = fallback;
    return fallback;
  }

  // 1c. Fetch Nutrition History map for calendar indicators
  Future<Map<String, dynamic>> fetchNutritionHistory({String? startDate, String? endDate}) async {
    final uid = _currentUid;
    try {
      var url = '${ApiConstants.apiBaseUrl}/user-nutrition/history?uid=$uid';
      if (startDate != null && endDate != null) {
        url += '&startDate=$startDate&endDate=$endDate';
      }
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['history'] != null) {
          _historyMap = Map<String, dynamic>.from(data['history']);
          notifyListeners();
          return _historyMap;
        }
      }
    } catch (e) {
      debugPrint('Error fetching nutrition history: $e');
    }
    return _historyMap;
  }

  // 2. Log a meal into today's or specific date's nutrition
  Future<bool> logMeal({
    required String mealType,
    String? foodName,
    String? name,
    String? date,
    String source = 'USDA',
    String category = 'General',
    int calories = 0,
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
    double fiber = 0.0,
    String servingSize = '1 serving',
    double quantity = 1.0,
    String iconType = 'restaurant',
  }) async {
    final actualFoodName = foodName ?? name ?? 'Food Item';
    final uid = _currentUid;
    final dateKey = date ?? _currentNutrition?.date ?? DateTime.now().toString().substring(0, 10);

    // Optimistic local update
    final now = DateTime.now();
    final timeStr = '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final newMeal = LoggedMealModel(
      mealId: 'meal_${DateTime.now().millisecondsSinceEpoch}',
      mealType: mealType,
      foodName: actualFoodName,
      source: source,
      category: category,
      calories: (calories * quantity).round(),
      protein: protein * quantity,
      carbs: carbs * quantity,
      fat: fat * quantity,
      fiber: fiber * quantity,
      servingSize: servingSize,
      quantity: quantity,
      time: timeStr,
      iconType: iconType,
    );

    final current = (dateKey == _currentNutrition?.date)
        ? (_currentNutrition ?? UserDailyNutritionModel.empty())
        : (_dateNutritionCache[dateKey] ?? UserDailyNutritionModel.empty());

    final updatedMeals = List<LoggedMealModel>.from(current.meals)..add(newMeal);
    final updatedModel = UserDailyNutritionModel(
      uid: uid,
      date: dateKey,
      targetCalories: current.targetCalories,
      targetProtein: current.targetProtein,
      targetCarbs: current.targetCarbs,
      targetFat: current.targetFat,
      consumedCalories: current.consumedCalories + newMeal.calories,
      consumedProtein: current.consumedProtein + newMeal.protein,
      consumedCarbs: current.consumedCarbs + newMeal.carbs,
      consumedFat: current.consumedFat + newMeal.fat,
      consumedFiber: current.consumedFiber + newMeal.fiber,
      waterGlasses: current.waterGlasses,
      waterTargetGlasses: current.waterTargetGlasses,
      waterMilliliters: current.waterMilliliters,
      meals: updatedMeals,
    );

    if (dateKey == _currentNutrition?.date) {
      _currentNutrition = updatedModel;
      _saveToLocalPrefs(_currentNutrition!);
    }
    _dateNutritionCache[dateKey] = updatedModel;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/user-nutrition/log-meal');
      final body = {
        'uid': uid,
        'date': dateKey,
        'mealType': mealType,
        'foodName': actualFoodName,
        'source': source,
        'category': category,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'servingSize': servingSize,
        'quantity': quantity,
        'iconType': iconType,
      };

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['nutrition'] != null) {
          final serverModel = UserDailyNutritionModel.fromJson(
            Map<String, dynamic>.from(data['nutrition']),
          );
          if (dateKey == _currentNutrition?.date) {
            _currentNutrition = serverModel;
            _saveToLocalPrefs(_currentNutrition!);
          }
          _dateNutritionCache[dateKey] = serverModel;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error logging meal: $e');
    }

    return true;
  }

  // 3. Delete a meal
  Future<void> deleteMeal(String mealId, {String? date}) async {
    final targetMealId = mealId;
    final uid = _currentUid;
    final dateKey = date ?? _currentNutrition?.date ?? DateTime.now().toString().substring(0, 10);

    if (_currentNutrition != null && targetMealId.isNotEmpty && (_currentNutrition!.date == dateKey)) {
      final item = _currentNutrition!.meals.firstWhere(
        (m) => m.mealId == targetMealId,
        orElse: () => LoggedMealModel(mealId: '', mealType: '', foodName: ''),
      );

      final updatedMeals =
          _currentNutrition!.meals.where((m) => m.mealId != targetMealId).toList();

      _currentNutrition = UserDailyNutritionModel(
        uid: uid,
        date: _currentNutrition!.date,
        targetCalories: _currentNutrition!.targetCalories,
        targetProtein: _currentNutrition!.targetProtein,
        targetCarbs: _currentNutrition!.targetCarbs,
        targetFat: _currentNutrition!.targetFat,
        consumedCalories:
            (_currentNutrition!.consumedCalories - item.calories).clamp(0, 99999),
        consumedProtein:
            (_currentNutrition!.consumedProtein - item.protein).clamp(0.0, 99999.0),
        consumedCarbs:
            (_currentNutrition!.consumedCarbs - item.carbs).clamp(0.0, 99999.0),
        consumedFat:
            (_currentNutrition!.consumedFat - item.fat).clamp(0.0, 99999.0),
        consumedFiber:
            (_currentNutrition!.consumedFiber - item.fiber).clamp(0.0, 99999.0),
        waterGlasses: _currentNutrition!.waterGlasses,
        waterTargetGlasses: _currentNutrition!.waterTargetGlasses,
        waterMilliliters: _currentNutrition!.waterMilliliters,
        meals: updatedMeals,
      );
      _dateNutritionCache[_currentNutrition!.date] = _currentNutrition!;
      _saveToLocalPrefs(_currentNutrition!);
      notifyListeners();
    } else if (_dateNutritionCache.containsKey(dateKey)) {
      final cached = _dateNutritionCache[dateKey]!;
      final item = cached.meals.firstWhere(
        (m) => m.mealId == targetMealId,
        orElse: () => LoggedMealModel(mealId: '', mealType: '', foodName: ''),
      );
      final updatedMeals = cached.meals.where((m) => m.mealId != targetMealId).toList();
      _dateNutritionCache[dateKey] = UserDailyNutritionModel(
        uid: uid,
        date: dateKey,
        targetCalories: cached.targetCalories,
        targetProtein: cached.targetProtein,
        targetCarbs: cached.targetCarbs,
        targetFat: cached.targetFat,
        consumedCalories: (cached.consumedCalories - item.calories).clamp(0, 99999),
        consumedProtein: (cached.consumedProtein - item.protein).clamp(0.0, 99999.0),
        consumedCarbs: (cached.consumedCarbs - item.carbs).clamp(0.0, 99999.0),
        consumedFat: (cached.consumedFat - item.fat).clamp(0.0, 99999.0),
        consumedFiber: (cached.consumedFiber - item.fiber).clamp(0.0, 99999.0),
        waterGlasses: cached.waterGlasses,
        waterTargetGlasses: cached.waterTargetGlasses,
        waterMilliliters: cached.waterMilliliters,
        meals: updatedMeals,
      );
      notifyListeners();
    }

    try {
      final uri =
          Uri.parse('${ApiConstants.apiBaseUrl}/user-nutrition/meal/$uid/$mealId');
      await http.delete(uri).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error deleting meal: $e');
    }
  }

  // 4. Update hydration / water intake glasses
  Future<void> updateWater({int? glasses, int delta = 1, String? date}) async {
    final uid = _currentUid;
    final dateKey = date ?? _currentNutrition?.date ?? DateTime.now().toString().substring(0, 10);
    final current = (dateKey == _currentNutrition?.date)
        ? (_currentNutrition ?? UserDailyNutritionModel.empty())
        : (_dateNutritionCache[dateKey] ?? UserDailyNutritionModel.empty());
    final newGlasses = (glasses ?? (current.waterGlasses + delta)).clamp(0, 16);

    final updatedModel = UserDailyNutritionModel(
      uid: uid,
      date: dateKey,
      targetCalories: current.targetCalories,
      targetProtein: current.targetProtein,
      targetCarbs: current.targetCarbs,
      targetFat: current.targetFat,
      consumedCalories: current.consumedCalories,
      consumedProtein: current.consumedProtein,
      consumedCarbs: current.consumedCarbs,
      consumedFat: current.consumedFat,
      consumedFiber: current.consumedFiber,
      waterGlasses: newGlasses,
      waterTargetGlasses: current.waterTargetGlasses,
      waterMilliliters: newGlasses * 250,
      meals: current.meals,
    );

    if (dateKey == _currentNutrition?.date) {
      _currentNutrition = updatedModel;
      _saveToLocalPrefs(_currentNutrition!);
    }
    _dateNutritionCache[dateKey] = updatedModel;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/user-nutrition/water');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid': uid,
              'glasses': newGlasses,
              'date': dateKey,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error updating water: $e');
    }
  }

  // 5. Fetch Daily Rotating Recipes Carousel (Saved for 1 day in MongoDB, 100% free APIs)
  Future<List<Map<String, dynamic>>> fetchDailyFeaturedRecipes() async {
    try {
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/recipes/daily-featured');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['recipes'] is List) {
          _dailyFeaturedRecipes = List<Map<String, dynamic>>.from(
            data['recipes'].map((x) => Map<String, dynamic>.from(x)),
          );
          notifyListeners();
          return _dailyFeaturedRecipes;
        }
      }
    } catch (e) {
      debugPrint('Error fetching daily featured recipes: $e');
    }
    return _dailyFeaturedRecipes;
  }

  // 6. Search foods for logging (Prioritizes USDA FIRST)
  Future<List<Map<String, dynamic>>> searchFoods(String query, {String category = 'All'}) async {
    try {
      final encodedQ = Uri.encodeComponent(query.trim().isEmpty ? 'healthy' : query.trim());
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/foods/search-live?query=$encodedQ&source=all');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
            data['data'].map((x) => Map<String, dynamic>.from(x)),
          );

          // Ensure USDA meals are strictly at the top of the list
          results.sort((a, b) {
            final isUsdaA = (a['source'] ?? '').toString().toUpperCase().contains('USDA');
            final isUsdaB = (b['source'] ?? '').toString().toUpperCase().contains('USDA');
            if (isUsdaA && !isUsdaB) return -1;
            if (!isUsdaA && isUsdaB) return 1;
            return 0;
          });

          if (category != 'All') {
            return results
                .where((f) => (f['category'] ?? '').toString().toLowerCase() == category.toLowerCase())
                .toList();
          }

          return results;
        }
      }
    } catch (e) {
      debugPrint('Error searching foods: $e');
    }
    return [];
  }

  // 7. Meal suggestions for empty slots
  Future<Map<String, dynamic>> fetchMealSuggestions() async {
    try {
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}/user-nutrition/suggestions');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['suggestions'] is Map) {
          _mealSuggestions = Map<String, dynamic>.from(data['suggestions']);
          notifyListeners();
          return _mealSuggestions;
        }
      }
    } catch (_) {}
    return _mealSuggestions;
  }

  Future<void> _saveToLocalPrefs(UserDailyNutritionModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('un_${model.uid}_${model.date}', jsonEncode(model.toJson()));
    } catch (_) {}
  }

  Future<UserDailyNutritionModel?> _loadFromLocalPrefs([String? targetDate]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = targetDate ?? DateTime.now().toString().substring(0, 10);
      final raw = prefs.getString('un_${_currentUid}_$dateKey');
      if (raw != null) {
        return UserDailyNutritionModel.fromJson(jsonDecode(raw));
      }
    } catch (_) {}
    return null;
  }
}
