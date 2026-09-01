import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CategoryModel {
  final String categoryId;
  final String id;
  String name;
  String title;
  String slug;
  String imageUrl;
  String imageKey;
  String bucketName;
  int itemCount;
  int productCount;
  int subCount;
  int subCategoryCount;
  String description;
  String status;
  bool isActive;
  int sortOrder;
  String createdBy;
  final DateTime createdAt;
  DateTime updatedAt;

  CategoryModel({
    required this.categoryId,
    String? id,
    required this.name,
    String? title,
    required this.slug,
    required this.imageUrl,
    this.imageKey = '',
    this.bucketName = 'neurofit',
    this.itemCount = 0,
    int? productCount,
    this.subCount = 0,
    int? subCategoryCount,
    this.description = '',
    this.status = 'Active',
    this.isActive = true,
    this.sortOrder = 1,
    this.createdBy = 'admin@neurofit.app',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? categoryId,
        title = title ?? name,
        productCount = productCount ?? itemCount,
        subCategoryCount = subCategoryCount ?? subCount,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestoreFields() {
    return {
      'categoryId': {'stringValue': categoryId},
      'name': {'stringValue': name},
      'slug': {'stringValue': slug},
      'imageUrl': {'stringValue': imageUrl},
      'imageKey': {'stringValue': imageKey},
      'bucketName': {'stringValue': bucketName},
      'itemCount': {'integerValue': itemCount.toString()},
      'productCount': {'integerValue': productCount.toString()},
      'subCount': {'integerValue': subCount.toString()},
      'subCategoryCount': {'integerValue': subCategoryCount.toString()},
      'description': {'stringValue': description},
      'status': {'stringValue': status},
      'isActive': {'booleanValue': isActive},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'createdBy': {'stringValue': createdBy},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory CategoryModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String catId = fields['categoryId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String name = fields['name']?['stringValue'] ?? fields['title']?['stringValue'] ?? 'Unnamed Category';
    final String slug = fields['slug']?['stringValue'] ?? name.toLowerCase().replaceAll(' ', '-');
    final String imageUrl = fields['imageUrl']?['stringValue'] ?? '';
    final String imageKey = fields['imageKey']?['stringValue'] ?? '';
    final String bucketName = fields['bucketName']?['stringValue'] ?? 'neurofit';
    final int count = int.tryParse(fields['itemCount']?['integerValue']?.toString() ?? '0') ?? 0;
    final int pCount = int.tryParse(fields['productCount']?['integerValue']?.toString() ?? '$count') ?? count;
    final int subCount = int.tryParse(fields['subCount']?['integerValue']?.toString() ?? '0') ?? 0;
    final int subCatCount = int.tryParse(fields['subCategoryCount']?['integerValue']?.toString() ?? '$subCount') ?? subCount;
    final String desc = fields['description']?['stringValue'] ?? '';
    final String status = fields['status']?['stringValue'] ?? 'Active';
    final bool isActive = fields['isActive']?['booleanValue'] ?? (status == 'Active');
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;
    final String createdBy = fields['createdBy']?['stringValue'] ?? 'admin@neurofit.app';

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();

    return CategoryModel(
      categoryId: catId,
      id: docId,
      name: name,
      title: name,
      slug: slug,
      imageUrl: imageUrl,
      imageKey: imageKey,
      bucketName: bucketName,
      itemCount: count,
      productCount: pCount,
      subCount: subCount,
      subCategoryCount: subCatCount,
      description: desc,
      status: status,
      isActive: isActive,
      sortOrder: sortOrder,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class SubCategoryModel {
  final String subCategoryId;
  final String id;
  final String parentCategoryId;
  final String parentCategoryName;
  String name;
  String title;
  String slug;
  String imageUrl;
  String imageKey;
  int productCount;
  int itemCount;
  String status;
  bool isActive;
  int sortOrder;
  final DateTime createdAt;
  DateTime updatedAt;

  SubCategoryModel({
    required this.subCategoryId,
    String? id,
    required this.parentCategoryId,
    required this.parentCategoryName,
    required this.name,
    String? title,
    required this.slug,
    required this.imageUrl,
    this.imageKey = '',
    this.productCount = 0,
    int? itemCount,
    this.status = 'Active',
    this.isActive = true,
    this.sortOrder = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? subCategoryId,
        title = title ?? name,
        itemCount = itemCount ?? productCount,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestoreFields() {
    return {
      'subCategoryId': {'stringValue': subCategoryId},
      'parentCategoryId': {'stringValue': parentCategoryId},
      'parentCategoryName': {'stringValue': parentCategoryName},
      'name': {'stringValue': name},
      'slug': {'stringValue': slug},
      'imageUrl': {'stringValue': imageUrl},
      'imageKey': {'stringValue': imageKey},
      'productCount': {'integerValue': productCount.toString()},
      'status': {'stringValue': status},
      'isActive': {'booleanValue': isActive},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory SubCategoryModel.fromFirestoreDoc(Map<String, dynamic> doc, String parentId, String parentName) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String sId = fields['subCategoryId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String pId = fields['parentCategoryId']?['stringValue'] ?? parentId;
    final String pName = fields['parentCategoryName']?['stringValue'] ?? parentName;
    final String name = fields['name']?['stringValue'] ?? fields['title']?['stringValue'] ?? 'Unnamed Subcategory';
    final String slug = fields['slug']?['stringValue'] ?? name.toLowerCase().replaceAll(' ', '-');
    final String imageUrl = fields['imageUrl']?['stringValue'] ?? '';
    final String imageKey = fields['imageKey']?['stringValue'] ?? '';
    final int pCount = int.tryParse(fields['productCount']?['integerValue']?.toString() ?? '0') ?? 0;
    final String status = fields['status']?['stringValue'] ?? 'Active';
    final bool isActive = fields['isActive']?['booleanValue'] ?? (status == 'Active');
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();

    return SubCategoryModel(
      subCategoryId: sId,
      id: docId,
      parentCategoryId: pId,
      parentCategoryName: pName,
      name: name,
      title: name,
      slug: slug,
      imageUrl: imageUrl,
      imageKey: imageKey,
      productCount: pCount,
      status: status,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CategoryBackendService extends ChangeNotifier {
  Future<void> fetchCategories({bool silent = false}) => fetchCategoriesFromFirestore(silent: silent);
  static final CategoryBackendService _instance = CategoryBackendService._internal();
  factory CategoryBackendService() => _instance;
  static CategoryBackendService get instance => _instance;
  CategoryBackendService._internal() {
    fetchCategoriesFromFirestore();
    fetchAllSubCategoriesFromFirestore();
    startRealtimeSync();
  }

  Timer? _syncTimer;
  void startRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchCategoriesFromFirestore(silent: true);
      fetchAllSubCategoriesFromFirestore(silent: true);
    });
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';
  static const String r2AccountId = '61519b8c6a1a20d3535eb39e85687539';
  static const String r2ApiToken = 'cfat_CUzcTemF5447Ag5mi2gIrcDGYyrMrHSrO9PY6q5Sc69f5185';
  static const String r2BucketName = 'neurofit';
  static const String r2PublicDevUrl = 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<CategoryModel> _categories = [];
  final List<SubCategoryModel> _subCategories = [];

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<SubCategoryModel> get subCategories => List.unmodifiable(_subCategories);

  Future<void> fetchCategoriesFromFirestore({bool silent = false}) async {
    if (!silent) _isLoading = true;
    if (!silent) notifyListeners();
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/categories?key=$firebaseApiKey&pageSize=100',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null && documents.isNotEmpty) {
          final List<CategoryModel> fetched = [];
          for (var doc in documents) {
            fetched.add(CategoryModel.fromFirestoreDoc(doc));
          }
          fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _categories.clear();
          _categories.addAll(fetched);
          debugPrint('✅ [CATEGORIES LOADED FROM FIRESTORE] ${_categories.length} live categories');
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch categories error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllSubCategoriesFromFirestore({bool silent = false}) async {
    if (!silent) _isLoading = true;
    if (!silent) notifyListeners();
    _isLoading = true;
    notifyListeners();

    try {
      final List<SubCategoryModel> allSubs = [];
      final List<Future<void>> futures = [];

      for (var cat in _categories) {
        futures.add(() async {
          final Uri subUri = Uri.parse(
            'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/categories/${cat.categoryId}/subcategories?key=$firebaseApiKey',
          );
          try {
            final res = await http.get(subUri).timeout(const Duration(seconds: 6));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              final docs = data['documents'] as List<dynamic>?;
              if (docs != null) {
                for (var d in docs) {
                  allSubs.add(SubCategoryModel.fromFirestoreDoc(d, cat.categoryId, cat.name));
                }
              }
            }
          } catch (_) {}
        }());
      }

      await Future.wait(futures);
      _subCategories.clear();
      _subCategories.addAll(allSubs);
      debugPrint('✅ [SUBCATEGORIES LOADED FROM FIRESTORE] ${_subCategories.length} live subcategories');
    } catch (e) {
      debugPrint('Firestore fetch subcategories error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadRawImageToR2({
    required String fileName,
    required Uint8List imageBytes,
  }) async {
    try {
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final Uri r2Uri = Uri.parse(
        'https://api.cloudflare.com/client/v4/accounts/$r2AccountId/r2/buckets/$r2BucketName/objects/uploads/$cleanFileName',
      );

      String mimeType = 'image/jpeg';
      if (cleanFileName.endsWith('.png')) mimeType = 'image/png';
      if (cleanFileName.endsWith('.webp')) mimeType = 'image/webp';

      final res = await http.put(
        r2Uri,
        headers: {
          'Authorization': 'Bearer $r2ApiToken',
          'Content-Type': mimeType,
        },
        body: imageBytes,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return '$r2PublicDevUrl/$cleanFileName';
      }
      return '$r2PublicDevUrl/$cleanFileName';
    } catch (e) {
      debugPrint('R2 Upload error: $e');
      return '$r2PublicDevUrl/$fileName';
    }
  }

  Future<bool> createCategory({
    required String name,
    required String slug,
    required String description,
    required String fileName,
    required Uint8List imageBytes,
    int sortOrder = 1,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uploadedUrl = await uploadRawImageToR2(fileName: fileName, imageBytes: imageBytes);
      if (uploadedUrl == null) return false;

      final catId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
      final newCat = CategoryModel(
        categoryId: catId,
        name: name,
        slug: slug,
        description: description,
        imageUrl: uploadedUrl,
        imageKey: 'uploads/$fileName',
        sortOrder: sortOrder,
      );

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/categories/$catId?key=$firebaseApiKey',
      );

      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newCat.toFirestoreFields()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchCategoriesFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSubCategory({
    required String parentCategoryId,
    required String parentCategoryName,
    required String name,
    required String slug,
    required String fileName,
    required Uint8List imageBytes,
    int sortOrder = 1,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uploadedUrl = await uploadRawImageToR2(fileName: fileName, imageBytes: imageBytes);
      if (uploadedUrl == null) return false;

      final subId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
      final newSub = SubCategoryModel(
        subCategoryId: subId,
        parentCategoryId: parentCategoryId,
        parentCategoryName: parentCategoryName,
        name: name,
        slug: slug,
        imageUrl: uploadedUrl,
        imageKey: 'uploads/$fileName',
        sortOrder: sortOrder,
      );

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/categories/$parentCategoryId/subcategories/$subId?key=$firebaseApiKey',
      );

      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newSub.toFirestoreFields()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchAllSubCategoriesFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
