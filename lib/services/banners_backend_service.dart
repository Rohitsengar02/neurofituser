import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'category_backend_service.dart';

class BannerModel {
  final String bannerId;
  final String id;
  String title;
  String subtitle;
  String imageUrl;
  String imageKey;
  String targetType; // 'category', 'product', 'offer', 'brand'
  String targetId;
  String targetName;
  String buttonText;
  String badge;
  int sortOrder;
  String status;
  bool isActive;
  String discountCode;
  final DateTime createdAt;
  DateTime updatedAt;

  BannerModel({
    required this.bannerId,
    String? id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    String? imageKey,
    this.targetType = 'category',
    this.targetId = '',
    this.targetName = '',
    this.buttonText = 'Shop Now',
    this.badge = 'FEATURED',
    this.sortOrder = 1,
    this.status = 'Active',
    this.isActive = true,
    this.discountCode = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? bannerId,
        imageKey = imageKey ?? (imageUrl.contains('r2.dev/') ? imageUrl.split('r2.dev/').last : imageUrl),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestoreFields() {
    return {
      'bannerId': {'stringValue': bannerId},
      'title': {'stringValue': title},
      'subtitle': {'stringValue': subtitle},
      'imageUrl': {'stringValue': imageUrl},
      'imageKey': {'stringValue': imageKey},
      'targetType': {'stringValue': targetType},
      'targetId': {'stringValue': targetId},
      'targetName': {'stringValue': targetName},
      'buttonText': {'stringValue': buttonText},
      'badge': {'stringValue': badge},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'status': {'stringValue': status},
      'isActive': {'booleanValue': isActive},
      'discountCode': {'stringValue': discountCode},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory BannerModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String bId = fields['bannerId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String title = fields['title']?['stringValue'] ?? 'Special Offer';
    final String subtitle = fields['subtitle']?['stringValue'] ?? '';
    final String imageUrl = fields['imageUrl']?['stringValue'] ?? '';
    final String imageKey = fields['imageKey']?['stringValue'] ?? '';
    final String targetType = fields['targetType']?['stringValue'] ?? 'category';
    final String targetId = fields['targetId']?['stringValue'] ?? '';
    final String targetName = fields['targetName']?['stringValue'] ?? '';
    final String buttonText = fields['buttonText']?['stringValue'] ?? 'Shop Now';
    final String badge = fields['badge']?['stringValue'] ?? 'FEATURED';
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;
    final String status = fields['status']?['stringValue'] ?? 'Active';
    final bool isActive = fields['isActive']?['booleanValue'] ?? (status == 'Active');
    final String discountCode = fields['discountCode']?['stringValue'] ?? '';

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();

    return BannerModel(
      bannerId: bId,
      id: docId,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      imageKey: imageKey,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      buttonText: buttonText,
      badge: badge,
      sortOrder: sortOrder,
      status: status,
      isActive: isActive,
      discountCode: discountCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class BannersBackendService extends ChangeNotifier {
  Future<void> fetchBanners({bool silent = false}) => fetchBannersFromFirestore(silent: silent);
  static final BannersBackendService _instance = BannersBackendService._internal();
  factory BannersBackendService() => _instance;
  static BannersBackendService get instance => _instance;
  BannersBackendService._internal() {
    fetchBannersFromFirestore();
    startRealtimeSync();
  }

  Timer? _syncTimer;
  void startRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchBannersFromFirestore(silent: true);
    });
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<BannerModel> _banners = [];
  List<BannerModel> get banners => List.unmodifiable(_banners);

  Future<void> fetchBannersFromFirestore({bool silent = false}) async {
    if (!silent) _isLoading = true;
    if (!silent) notifyListeners();
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/banners?key=$firebaseApiKey&pageSize=100',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null) {
          final List<BannerModel> fetched = [];
          for (var doc in documents) {
            fetched.add(BannerModel.fromFirestoreDoc(doc));
          }
          fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _banners.clear();
          _banners.addAll(fetched);
          debugPrint('✅ [BANNERS LOADED FROM FIRESTORE] ${_banners.length} live banners');
        }
      }
    } catch (e) {
      debugPrint('Error fetching banners from Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBanner({
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String buttonText,
    String badge = 'FEATURED',
    String discountCode = '',
    required String imageFileName,
    required Uint8List imageBytes,
    int sortOrder = 1,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: imageFileName,
        imageBytes: imageBytes,
      );

      if (uploadedUrl == null) return false;

      final String bannerId = 'banner_${DateTime.now().millisecondsSinceEpoch}';
      final newBanner = BannerModel(
        bannerId: bannerId,
        title: title,
        subtitle: subtitle,
        imageUrl: uploadedUrl,
        imageKey: 'uploads/$imageFileName',
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        buttonText: buttonText,
        badge: badge,
        discountCode: discountCode,
        sortOrder: sortOrder,
      );

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/banners/$bannerId?key=$firebaseApiKey',
      );

      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newBanner.toFirestoreFields()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchBannersFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating banner: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBanner({
    required String bannerId,
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String buttonText,
    String badge = 'FEATURED',
    String discountCode = '',
    String status = 'Active',
    Uint8List? newImageBytes,
    String? newImageFileName,
    int? sortOrder,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existing = _banners.firstWhere(
        (b) => b.bannerId == bannerId,
        orElse: () => BannerModel(bannerId: bannerId, title: title, imageUrl: ''),
      );

      String finalImageUrl = existing.imageUrl;
      if (newImageBytes != null && newImageFileName != null) {
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          fileName: newImageFileName,
          imageBytes: newImageBytes,
        );
        if (uploadedUrl != null) finalImageUrl = uploadedUrl;
      }

      existing.title = title;
      existing.subtitle = subtitle;
      existing.imageUrl = finalImageUrl;
      existing.targetType = targetType;
      existing.targetId = targetId;
      existing.targetName = targetName;
      existing.buttonText = buttonText;
      existing.badge = badge;
      existing.discountCode = discountCode;
      existing.status = status;
      existing.isActive = status == 'Active';
      if (sortOrder != null) existing.sortOrder = sortOrder;
      existing.updatedAt = DateTime.now();

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/banners/$bannerId?key=$firebaseApiKey',
      );

      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': existing.toFirestoreFields()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchBannersFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating banner: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBanner(String bannerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/banners/$bannerId?key=$firebaseApiKey',
      );
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        _banners.removeWhere((b) => b.bannerId == bannerId);
        notifyListeners();
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
