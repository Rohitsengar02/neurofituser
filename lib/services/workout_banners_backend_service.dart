import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class WorkoutBannerModel {
  String id;
  String bannerId;
  String title;
  String subtitle;
  String imageUrl;
  String mediaType; // 'image' | 'gif' | 'video'
  String targetType;
  String targetId;
  String targetName;
  String badge;
  String buttonText;
  bool showTitle;
  int sortOrder;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  WorkoutBannerModel({
    this.id = '',
    required this.bannerId,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.mediaType = 'image',
    this.targetType = 'category',
    this.targetId = '',
    this.targetName = '',
    this.badge = '',
    this.buttonText = 'Explore',
    this.showTitle = true,
    this.sortOrder = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WorkoutBannerModel.fromJson(Map<String, dynamic> json) {
    final String rawUrl = json['imageUrl']?.toString() ?? json['mediaUrl']?.toString() ?? '';
    String mType = json['mediaType']?.toString() ?? 'image';
    if (mType == 'image') {
      final lower = rawUrl.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.avi')) {
        mType = 'video';
      } else if (lower.endsWith('.gif')) {
        mType = 'gif';
      }
    }

    return WorkoutBannerModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bannerId: json['bannerId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      imageUrl: rawUrl,
      mediaType: mType,
      targetType: json['targetType']?.toString() ?? 'category',
      targetId: json['targetId']?.toString() ?? '',
      targetName: json['targetName']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? 'Explore',
      showTitle: json['showTitle'] ?? true,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bannerId': bannerId,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'mediaType': mediaType,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'badge': badge,
      'buttonText': buttonText,
      'showTitle': showTitle,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

class WorkoutBannersBackendService extends ChangeNotifier {
  static final WorkoutBannersBackendService _instance = WorkoutBannersBackendService._internal();
  factory WorkoutBannersBackendService() => _instance;
  WorkoutBannersBackendService._internal() {
    fetchWorkoutBanners();
    _initSocket();
  }

  final List<WorkoutBannerModel> _banners = [];
  bool _isLoading = false;
  IO.Socket? _socket;

  List<WorkoutBannerModel> get banners =>
      _banners.isNotEmpty ? List.unmodifiable(_banners) : getDefaultFallbackBanners();
  bool get isLoading => _isLoading;

  void _initSocket() {
    if (ApiConstants.demoMode) return;
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        debugPrint('⚡ [UserApp WorkoutBanners Socket] Connected to $socketUri');
        _socket?.emit('join_user_room', 'app_user');
      });

      _socket?.on('workout_banner_created', (data) {
        debugPrint('🔔 [UserApp WorkoutBanners Socket] Banner created: $data');
        if (data is Map) {
          final banner = WorkoutBannerModel.fromJson(Map<String, dynamic>.from(data));
          final idx = _banners.indexWhere((b) =>
              (b.id.isNotEmpty && b.id == banner.id) ||
              (b.bannerId.isNotEmpty && b.bannerId == banner.bannerId));
          if (idx == -1) {
            _banners.add(banner);
          } else {
            _banners[idx] = banner;
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('workout_banner_updated', (data) {
        debugPrint('🔔 [UserApp WorkoutBanners Socket] Banner updated: $data');
        if (data is Map) {
          final banner = WorkoutBannerModel.fromJson(Map<String, dynamic>.from(data));
          final idx = _banners.indexWhere((b) =>
              (b.id.isNotEmpty && b.id == banner.id) ||
              (b.bannerId.isNotEmpty && b.bannerId == banner.bannerId));
          if (idx != -1) {
            _banners[idx] = banner;
          } else {
            _banners.add(banner);
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('workout_banner_deleted', (data) {
        debugPrint('🔔 [UserApp WorkoutBanners Socket] Banner deleted: $data');
        if (data is Map) {
          final id = data['id']?.toString() ?? '';
          final bannerId = data['bannerId']?.toString() ?? '';
          _banners.removeWhere((b) =>
              (id.isNotEmpty && b.id == id) ||
              (bannerId.isNotEmpty && b.bannerId == bannerId));
          notifyListeners();
        }
      });

      _socket?.on('workout_banners_updated', (data) {
        debugPrint('🔔 [UserApp WorkoutBanners Socket] Banners updated list received');
        if (data is List) {
          _banners.clear();
          for (var item in data) {
            if (item is Map) {
              _banners.add(WorkoutBannerModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.onDisconnect((_) {
        debugPrint('🔌 [UserApp WorkoutBanners Socket] Disconnected');
      });
    } catch (e) {
      debugPrint('⚠️ [UserApp WorkoutBanners Socket] Init error: $e');
    }
  }

  Future<void> fetchWorkoutBanners({bool silent = false}) async {
    if (!silent && _banners.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    final candidateUrls = ApiConstants.candidateBaseUrls
        .map((b) => Uri.parse('$b/api/workout-banners'))
        .toList();

    for (final url in candidateUrls) {
      try {
        final response = await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final rawList = (body['data'] ?? body) as List<dynamic>? ?? [];
          if (rawList.isNotEmpty) {
            _banners.clear();
            for (var item in rawList) {
              _banners.add(WorkoutBannerModel.fromJson(Map<String, dynamic>.from(item as Map)));
            }
            _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            debugPrint('✅ [WORKOUT BANNERS LOADED FROM MONGODB ATLAS] ${_banners.length} banners');
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (_) {}
    }

    if (_banners.isEmpty) {
      _banners.addAll(getDefaultFallbackBanners());
    }

    _isLoading = false;
    notifyListeners();
  }

  List<WorkoutBannerModel> getDefaultFallbackBanners() {
    return [
      WorkoutBannerModel(
        bannerId: 'wbanner_1',
        title: '30-Day Summer Shred',
        subtitle: 'High intensity fat burn & full body sculpting',
        imageUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=1200&auto=format&fit=crop',
        badge: 'TRENDING',
        buttonText: 'Join Challenge',
        sortOrder: 1,
      ),
      WorkoutBannerModel(
        bannerId: 'wbanner_2',
        title: 'Lean Muscle Hypertrophy',
        subtitle: 'Dumbbell & compound progressive overload with Coach David',
        imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=1200&auto=format&fit=crop',
        badge: 'POPULAR',
        buttonText: 'Start Program',
        sortOrder: 2,
      ),
      WorkoutBannerModel(
        bannerId: 'wbanner_3',
        title: 'Morning Sun Vinyasa & Core',
        subtitle: 'Spine alignment, mobility and breathwork for peak daily energy',
        imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=1200&auto=format&fit=crop',
        badge: 'NEW FLOW',
        buttonText: 'Explore',
        sortOrder: 3,
      ),
    ];
  }
}
