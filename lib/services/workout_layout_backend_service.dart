import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class WorkoutLayoutSectionModel {
  String id;
  String sectionId;
  String title;
  String subtitle;
  bool showTitle;
  String type;
  String layoutMode;
  String filterSource;
  String filterId;
  String filterName;
  List<String> selectedItemIds;
  int itemLimit;
  int sortOrder;
  bool isActive;
  String customBannerImageUrl;
  String customBannerVideoUrl;
  String customBannerTargetType;
  String customBannerTargetId;
  String customBannerButtonText;
  String customBannerBadge;

  WorkoutLayoutSectionModel({
    required this.id,
    String? sectionId,
    required this.title,
    this.subtitle = '',
    this.showTitle = true,
    required this.type,
    this.layoutMode = 'carousel',
    this.filterSource = 'all',
    this.filterId = '',
    this.filterName = '',
    List<String>? selectedItemIds,
    this.itemLimit = 10,
    this.sortOrder = 1,
    this.isActive = true,
    this.customBannerImageUrl = '',
    this.customBannerVideoUrl = '',
    this.customBannerTargetType = 'program',
    this.customBannerTargetId = '',
    this.customBannerButtonText = 'Start Workout',
    this.customBannerBadge = '',
  })  : sectionId = sectionId ?? id,
        selectedItemIds = selectedItemIds ?? [];

  factory WorkoutLayoutSectionModel.fromJson(Map<String, dynamic> json) {
    final secId = json['id'] ?? json['sectionId'] ?? json['_id'] ?? 'sec_${DateTime.now().millisecondsSinceEpoch}';

    List<String> ids = [];
    if (json['selectedItemIds'] != null && json['selectedItemIds'] is List) {
      ids = (json['selectedItemIds'] as List).map((e) => e.toString()).toList();
    }

    return WorkoutLayoutSectionModel(
      id: secId,
      sectionId: json['sectionId'] ?? secId,
      title: json['title'] ?? 'Section',
      subtitle: json['subtitle'] ?? '',
      showTitle: json['showTitle'] ?? json['showHeading'] ?? true,
      type: json['type'] ?? 'popular_programs',
      layoutMode: json['layoutMode'] ?? 'carousel',
      filterSource: json['filterSource'] ?? 'all',
      filterId: json['filterId'] ?? '',
      filterName: json['filterName'] ?? '',
      selectedItemIds: ids,
      itemLimit: (json['itemLimit'] as num?)?.toInt() ?? 10,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['displayOrder'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] ?? true,
      customBannerImageUrl: json['customBannerImageUrl'] ?? '',
      customBannerVideoUrl: json['customBannerVideoUrl'] ?? '',
      customBannerTargetType: json['customBannerTargetType'] ?? 'program',
      customBannerTargetId: json['customBannerTargetId'] ?? '',
      customBannerButtonText: json['customBannerButtonText'] ?? 'Start Workout',
      customBannerBadge: json['customBannerBadge'] ?? '',
    );
  }
}

class WorkoutLayoutBackendService extends ChangeNotifier {
  static final WorkoutLayoutBackendService _instance = WorkoutLayoutBackendService._internal();
  factory WorkoutLayoutBackendService() => _instance;

  WorkoutLayoutBackendService._internal() {
    fetchLayoutSections();
    _initSocket();
  }

  IO.Socket? _socket;

  void _initSocket() {
    if (ApiConstants.demoMode) return;
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        debugPrint('⚡ [UserApp WorkoutLayout Socket] Connected to $socketUri');
        _socket?.emit('join_user_room', 'app_user');
      });

      _socket?.on('workout_layout_updated', (data) {
        debugPrint('🔔 [UserApp WorkoutLayout Socket] Layout updated live: $data');
        fetchLayoutSections(silent: true);
      });

      _socket?.onDisconnect((_) {
        debugPrint('🔌 [UserApp WorkoutLayout Socket] Disconnected');
      });
    } catch (e) {
      debugPrint('⚠️ [UserApp WorkoutLayout Socket] Init error: $e');
    }
  }

  final List<WorkoutLayoutSectionModel> _sections = [];
  List<WorkoutLayoutSectionModel> get sections => List.unmodifiable(_sections);
  List<WorkoutLayoutSectionModel> get activeSections =>
      _sections.where((s) => s.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchLayoutSections({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    final candidateUrls = ApiConstants.candidateBaseUrls
        .map((b) => Uri.parse('$b/api/workout-layout'))
        .toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final rawList = (body['data'] ?? body) as List<dynamic>? ?? [];

          final fetched = rawList.map((item) {
            return WorkoutLayoutSectionModel.fromJson(Map<String, dynamic>.from(item as Map));
          }).toList();

          fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          _sections.clear();
          _sections.addAll(fetched);
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (_) {}
    }

    // Default fallback if offline
    if (_sections.isEmpty) {
      _loadDefaultOfflineSections();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadDefaultOfflineSections() {
    _sections.clear();
    _sections.addAll([
      WorkoutLayoutSectionModel(id: '1', title: 'Featured Programs', type: 'hero_banners', layoutMode: 'hero_carousel', sortOrder: 1),
      WorkoutLayoutSectionModel(id: '2', title: 'Categories', type: 'categories', layoutMode: 'square_cards', sortOrder: 2),
      WorkoutLayoutSectionModel(id: '3', title: 'Popular Programs', type: 'popular_programs', layoutMode: 'carousel', sortOrder: 3),
      WorkoutLayoutSectionModel(id: '4', title: 'Workout Spotlight', type: 'bento_spotlight', layoutMode: 'bento', sortOrder: 4),
      WorkoutLayoutSectionModel(id: '5', title: 'Target Muscle Groups', type: 'muscle_groups', layoutMode: 'carousel', sortOrder: 5),
      WorkoutLayoutSectionModel(id: '6', title: 'Elite Coaches', type: 'celebrity_coaches', layoutMode: 'carousel', sortOrder: 6),
      WorkoutLayoutSectionModel(id: '7', title: 'Workout by Equipment', type: 'equipment_training', layoutMode: 'carousel', sortOrder: 7),
      WorkoutLayoutSectionModel(id: '8', title: 'Trending Challenges', type: 'trending_challenges', layoutMode: 'carousel', sortOrder: 8),
      WorkoutLayoutSectionModel(id: '9', title: 'Music-Synced Workouts', type: 'audio_beats', layoutMode: 'carousel', sortOrder: 9),
    ]);
  }
}
