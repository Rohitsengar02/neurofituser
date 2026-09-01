import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LayoutSectionModel {
  String id;
  String title;
  String subtitle;
  String type; // 'products', 'banners', 'categories'
  String layoutMode; // 'carousel', 'grid'
  String filterSource; // 'all', 'featured', 'category', 'subcategory', 'selected_ids'
  String filterId; // categoryId or subcategoryId if filtered
  String filterName; // category or subcategory name
  List<String> selectedItemIds; // specific banner or product IDs
  int itemLimit;
  int sortOrder;
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  LayoutSectionModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.type,
    this.layoutMode = 'carousel',
    this.filterSource = 'all',
    this.filterId = '',
    this.filterName = '',
    List<String>? selectedItemIds,
    this.itemLimit = 10,
    this.sortOrder = 1,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  }) : selectedItemIds = selectedItemIds ?? [];

  Map<String, dynamic> toFirestoreFields() {
    return {
      'id': {'stringValue': id},
      'title': {'stringValue': title},
      'subtitle': {'stringValue': subtitle},
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
      type: type,
      layoutMode: layoutMode,
      filterSource: filterSource,
      filterId: filterId,
      filterName: filterName,
      selectedItemIds: selectedIds,
      itemLimit: itemLimit,
      sortOrder: sortOrder,
      isActive: isActive,
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
  MarketplaceHomeLayoutService._internal() {
    fetchLayoutSectionsFromFirestore();
    startRealtimeSync();
  }

  Timer? _syncTimer;
  void startRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
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
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse('$firestoreBase/marketplace_home_layout?key=$firebaseApiKey&pageSize=100');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        final List<LayoutSectionModel> fetched = [];
        for (var doc in documents) {
          fetched.add(LayoutSectionModel.fromFirestoreDoc(doc));
        }

        fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _sections.clear();
        _sections.addAll(fetched);
        debugPrint('✅ [HOME LAYOUT LOADED] ${_sections.length} layout sections');
      }
    } catch (e) {
      debugPrint('Error loading home layout sections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSection(LayoutSectionModel section) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse('$firestoreBase/marketplace_home_layout/${section.id}?key=$firebaseApiKey');
      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': section.toFirestoreFields()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchLayoutSectionsFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving layout section: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSection(String sectionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse('$firestoreBase/marketplace_home_layout/$sectionId?key=$firebaseApiKey');
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        _sections.removeWhere((s) => s.id == sectionId);
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

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, item);

    for (int i = 0; i < _sections.length; i++) {
      _sections[i].sortOrder = i + 1;
      // Fire-and-forget background update to Firestore
      saveSection(_sections[i]);
    }
    notifyListeners();
  }
}
