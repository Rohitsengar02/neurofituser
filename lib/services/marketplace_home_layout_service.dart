import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class LayoutSectionModel {
  String id;
  String sectionId;
  String title;
  String subtitle;
  bool showTitle;
  String type; // 'products', 'banners', 'categories', 'subcategories', 'custom_promo'
  String layoutMode; // 'carousel', 'grid', 'banner_strip', 'hero_carousel', 'two_column'
  String filterSource; // 'all', 'featured', 'trending', 'category', 'subcategory', 'selected_ids', 'custom'
  String filterId; // categoryId or subcategoryId if filtered
  String filterName; // category or subcategory name
  List<String> selectedItemIds; // specific banner or product IDs
  int itemLimit;
  int sortOrder;
  bool isActive;
  String customBannerImageUrl;
  String customBannerTargetType;
  String customBannerTargetId;
  String customBannerButtonText;
  String customBannerBadge;
  DateTime? createdAt;
  DateTime? updatedAt;

  LayoutSectionModel({
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
    this.customBannerTargetType = 'category',
    this.customBannerTargetId = '',
    this.customBannerButtonText = 'Shop Now',
    this.customBannerBadge = '',
    this.createdAt,
    this.updatedAt,
  })  : sectionId = sectionId ?? id,
        selectedItemIds = selectedItemIds ?? [];

  factory LayoutSectionModel.fromJson(Map<String, dynamic> json) {
    final secId = json['id']?.toString() ?? json['sectionId']?.toString() ?? json['_id']?.toString() ?? 'sec_${DateTime.now().millisecondsSinceEpoch}';

    List<String> ids = [];
    if (json['selectedItemIds'] != null && json['selectedItemIds'] is List) {
      ids = (json['selectedItemIds'] as List).map((e) => e.toString()).toList();
    } else if (json['productIds'] != null && json['productIds'] is List) {
      ids = (json['productIds'] as List).map((e) => e.toString()).toList();
    }

    final String rawType = json['type']?.toString() ?? (json['productIds'] != null ? 'products' : 'products');
    final String rawLayout = json['layoutMode']?.toString() ?? json['layoutType']?.toString() ?? 'carousel';
    final bool active = json['isActive'] != null ? (json['isActive'] == true) : (json['isEnabled'] != false);

    return LayoutSectionModel(
      id: secId,
      sectionId: json['sectionId']?.toString() ?? secId,
      title: json['title']?.toString() ?? 'Section',
      subtitle: json['subtitle']?.toString() ?? '',
      showTitle: json['showTitle'] == true || json['showHeading'] == true || (json['showTitle'] == null && json['title'] != null && json['title'].toString().isNotEmpty),
      type: rawType,
      layoutMode: rawLayout,
      filterSource: json['filterSource']?.toString() ?? (ids.isNotEmpty ? 'selected_ids' : 'all'),
      filterId: json['filterId']?.toString() ?? '',
      filterName: json['filterName']?.toString() ?? '',
      selectedItemIds: ids,
      itemLimit: (json['itemLimit'] as num?)?.toInt() ?? 10,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['displayOrder'] as num?)?.toInt() ?? 1,
      isActive: active,
      customBannerImageUrl: json['customBannerImageUrl']?.toString() ?? '',
      customBannerTargetType: json['customBannerTargetType']?.toString() ?? 'category',
      customBannerTargetId: json['customBannerTargetId']?.toString() ?? '',
      customBannerButtonText: json['customBannerButtonText']?.toString() ?? 'Shop Now',
      customBannerBadge: json['customBannerBadge']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toFirestoreFields() {
    return {
      'id': {'stringValue': id},
      'title': {'stringValue': title},
      'subtitle': {'stringValue': subtitle},
      'showTitle': {'booleanValue': showTitle},
      'type': {'stringValue': type},
      'layoutMode': {'stringValue': layoutMode},
      'filterSource': {'stringValue': filterSource},
      'filterId': {'stringValue': filterId},
      'filterName': {'stringValue': filterName},
      'selectedItemIds': {
        'arrayValue': {
          'values': selectedItemIds.map((item) => {'stringValue': item}).toList()
        }
      },
      'itemLimit': {'integerValue': itemLimit.toString()},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'isActive': {'booleanValue': isActive},
      'customBannerImageUrl': {'stringValue': customBannerImageUrl},
      'createdAt': {'timestampValue': (createdAt ?? DateTime.now()).toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': (updatedAt ?? DateTime.now()).toUtc().toIso8601String()},
    };
  }

  factory LayoutSectionModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String secId = fields['id']?['stringValue'] ?? docId;
    final String title = fields['title']?['stringValue'] ?? 'Section';
    final String subtitle = fields['subtitle']?['stringValue'] ?? '';
    final bool showTitle = fields['showTitle']?['booleanValue'] ?? (fields['showHeading']?['booleanValue'] ?? true);
    final String type = fields['type']?['stringValue'] ?? 'products';
    final String layoutMode = fields['layoutMode']?['stringValue'] ?? 'carousel';
    final String filterSource = fields['filterSource']?['stringValue'] ?? 'all';
    final String filterId = fields['filterId']?['stringValue'] ?? '';
    final String filterName = fields['filterName']?['stringValue'] ?? '';

    final selectedIds = (fields['selectedItemIds']?['arrayValue']?['values'] as List<dynamic>?)
            ?.map((v) => v['stringValue']?.toString() ?? '')
            .where((v) => v.isNotEmpty)
            .toList() ??
        [];

    final int itemLimit = int.tryParse(fields['itemLimit']?['integerValue']?.toString() ?? '10') ?? 10;
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;
    final bool isActive = fields['isActive']?['booleanValue'] ?? true;
    final String customBannerImageUrl = fields['customBannerImageUrl']?['stringValue'] ?? '';

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();

    return LayoutSectionModel(
      id: secId,
      title: title,
      subtitle: subtitle,
      showTitle: showTitle,
      type: type,
      layoutMode: layoutMode,
      filterSource: filterSource,
      filterId: filterId,
      filterName: filterName,
      selectedItemIds: selectedIds,
      itemLimit: itemLimit,
      sortOrder: sortOrder,
      isActive: isActive,
      customBannerImageUrl: customBannerImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class MarketplaceHomeLayoutService extends ChangeNotifier {
  Future<void> fetchLayout({bool silent = false}) => fetchLayoutSectionsFromFirestore(silent: silent);
  static final MarketplaceHomeLayoutService _instance = MarketplaceHomeLayoutService._internal();
  factory MarketplaceHomeLayoutService() => _instance;
  static MarketplaceHomeLayoutService get instance => _instance;

  IO.Socket? _socket;

  MarketplaceHomeLayoutService._internal() {
    fetchLayoutSectionsFromFirestore();
    startRealtimeSync();
    _initSocket();
  }

  void _initSocket() {
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.on('layout_section_created', (data) {
        if (data is Map<String, dynamic>) {
          final newSec = LayoutSectionModel.fromJson(data);
          _sections.removeWhere((s) => s.id == newSec.id || s.sectionId == newSec.sectionId);
          _sections.add(newSec);
          _sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('layout_section_updated', (data) {
        if (data is Map<String, dynamic>) {
          final updated = LayoutSectionModel.fromJson(data);
          final index = _sections.indexWhere((s) => s.id == updated.id || s.sectionId == updated.sectionId);
          if (index != -1) {
            _sections[index] = updated;
          } else {
            _sections.add(updated);
          }
          _sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('layout_section_deleted', (data) {
        final delId = (data is Map) ? (data['id'] ?? data['sectionId']) : data.toString();
        _sections.removeWhere((s) => s.id == delId || s.sectionId == delId);
        notifyListeners();
      });

      _socket?.on('layout_sections_updated', (data) {
        if (data is List) {
          final List<LayoutSectionModel> list = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) list.add(LayoutSectionModel.fromJson(item));
          }
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _sections.clear();
          _sections.addAll(list);
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  Timer? _syncTimer;
  void startRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchLayoutSectionsFromFirestore(silent: true);
    });
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';
  static const String firestoreBase = "https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<LayoutSectionModel> _sections = [];
  List<LayoutSectionModel> get sections => List.unmodifiable(_sections);
  List<LayoutSectionModel> get activeSections => _sections.where((s) => s.isActive).toList();

  Future<void> fetchLayoutSectionsFromFirestore({bool silent = false}) async {
    if (!silent) _isLoading = true;
    if (!silent) notifyListeners();

    final candidateUrls = ApiConstants.candidateBaseUrls.map((b) => Uri.parse('$b/api/layout')).toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final rawData = (body['data'] ?? body) as List<dynamic>? ?? [];
          if (rawData.isNotEmpty) {
            final List<LayoutSectionModel> fetched = rawData.map((item) {
              return LayoutSectionModel.fromJson(Map<String, dynamic>.from(item as Map));
            }).toList();

            fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            _sections.clear();
            _sections.addAll(fetched);
            debugPrint('✅ [LAYOUT SECTIONS LOADED FROM MONGODB ATLAS] ${_sections.length} live sections');
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
}
