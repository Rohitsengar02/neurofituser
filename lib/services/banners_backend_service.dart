import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'category_backend_service.dart';
import '../constants/api_constants.dart';

class BannerModel {
  final String bannerId;
  final String id;
  String title;
  String subtitle;
  String imageUrl;
  String imageKey;
  String mediaType; // 'image', 'gif', 'video'
  bool showTitle;
  bool showHeading;
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
    this.mediaType = 'image',
    this.showTitle = true,
    this.showHeading = true,
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
      'mediaType': {'stringValue': mediaType},
      'showTitle': {'booleanValue': showTitle},
      'showHeading': {'booleanValue': showHeading},
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

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final String bId = json['bannerId']?.toString() ?? json['id']?.toString() ?? json['_id']?.toString() ?? 'banner_${DateTime.now().millisecondsSinceEpoch}';
    final String title = json['title']?.toString() ?? 'Special Offer';
    final String subtitle = json['subtitle']?.toString() ?? '';
    final String imageUrl = json['imageUrl']?.toString() ?? json['image']?.toString() ?? '';
    final lower = imageUrl.toLowerCase();

    String mType = json['mediaType']?.toString() ?? '';
    if (mType.isEmpty) {
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
        mType = 'video';
      } else if (lower.endsWith('.gif')) {
        mType = 'gif';
      } else {
        mType = 'image';
      }
    }

    final String targetType = json['targetType']?.toString() ?? 'category';
    final String targetId = json['targetId']?.toString() ?? '';
    final String targetName = json['targetName']?.toString() ?? '';
    final String buttonText = json['buttonText']?.toString() ?? 'Shop Now';
    final String badge = json['badge']?.toString() ?? 'FEATURED';
    final int sortOrder = (json['sortOrder'] as num?)?.toInt() ?? 1;
    final String status = json['status']?.toString() ?? 'Active';
    final bool active = json['isActive'] == true || status == 'Active';
    final String discountCode = json['discountCode']?.toString() ?? '';

    return BannerModel(
      bannerId: bId,
      id: bId,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      mediaType: mType,
      showTitle: json['showTitle'] ?? true,
      showHeading: json['showHeading'] ?? json['showTitle'] ?? true,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      buttonText: buttonText,
      badge: badge,
      sortOrder: sortOrder,
      status: status,
      isActive: active,
      discountCode: discountCode,
    );
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

  IO.Socket? _socket;

  BannersBackendService._internal() {
    fetchBannersFromFirestore();
    startRealtimeSync();
    _initSocket();
  }

  void _initSocket() {
    if (ApiConstants.demoMode) return;
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.on('banner_created', (data) {
        if (data is Map<String, dynamic>) {
          final newBanner = BannerModel.fromJson(data);
          _banners.removeWhere((b) => b.bannerId == newBanner.bannerId || b.id == newBanner.id);
          _banners.add(newBanner);
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('banner_updated', (data) {
        if (data is Map<String, dynamic>) {
          final updated = BannerModel.fromJson(data);
          final index = _banners.indexWhere((b) => b.bannerId == updated.bannerId || b.id == updated.id);
          if (index != -1) {
            _banners[index] = updated;
          } else {
            _banners.add(updated);
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('banner_deleted', (data) {
        final delId = (data is Map) ? (data['id'] ?? data['bannerId']) : data.toString();
        _banners.removeWhere((b) => b.bannerId == delId || b.id == delId);
        notifyListeners();
      });

      _socket?.on('banners_updated', (data) {
        if (data is List) {
          final List<BannerModel> list = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) list.add(BannerModel.fromJson(item));
          }
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _banners.clear();
          _banners.addAll(list);
          notifyListeners();
        }
      });
    } catch (_) {}
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

    final candidateUrls = ApiConstants.candidateBaseUrls.map((b) => Uri.parse('$b/api/banners')).toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final rawData = (body['data'] ?? body) as List<dynamic>? ?? [];
          if (rawData.isNotEmpty) {
            final List<BannerModel> fetched = rawData.map((item) {
              return BannerModel.fromJson(Map<String, dynamic>.from(item as Map));
            }).toList();

            fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            _banners.clear();
            _banners.addAll(fetched);
            debugPrint('✅ [BANNERS LOADED FROM MONGODB ATLAS] ${_banners.length} live banners');
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
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
