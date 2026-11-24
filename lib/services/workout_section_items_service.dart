import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// One row of a workout section (program, coach, muscle group, etc.).
/// Kept schema-light so the admin panel can add fields without app updates.
class WorkoutSectionItem {
  final String id;
  final Map<String, dynamic> data;

  const WorkoutSectionItem({required this.id, required this.data});

  String str(String key, [String fallback = '']) {
    final v = data[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  double dbl(String key, [double fallback = 0]) {
    final v = data[key];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }

  bool flag(String key, [bool fallback = false]) {
    final v = data[key];
    if (v is bool) return v;
    return fallback;
  }
}

/// Loads the items for every dynamic workout section from Backend.
///
/// Lookup order for a section:
///   1. `/api/workout-sections/{sectionId}/items`          (per-section override)
///   2. `/api/{collectionForType}` e.g. `workout-programs` (shared pool by type)
///
/// Each item doc is expected to have `isActive` (bool) and `sortOrder` (num).
/// Results are cached in memory for [_ttl] so tab switches are instant.
class WorkoutSectionItemsService extends ChangeNotifier {
  WorkoutSectionItemsService._();
  static final WorkoutSectionItemsService instance =
      WorkoutSectionItemsService._();

  static const Duration _ttl = Duration(minutes: 5);

  final Map<String, List<WorkoutSectionItem>> _cache = {};
  final Map<String, DateTime> _fetchedAt = {};
  final Set<String> _inFlight = {};

  static const Map<String, String> collectionForType = {
    'popular_programs': 'programs',
    'bento_spotlight': 'programs',
    'muscle_groups': 'exercise-categories',
    'celebrity_coaches': 'trainers',
    'equipment_training': 'exercises',
    'trending_challenges': 'challenges',
    'audio_beats': 'workouts',
  };

  bool isLoaded(String sectionId) => _cache.containsKey(sectionId);
  bool isLoading(String sectionId) => _inFlight.contains(sectionId);

  List<WorkoutSectionItem> items(String sectionId) =>
      _cache[sectionId] ?? const [];

  Future<void> fetch(
    String sectionId,
    String type, {
    bool force = false,
  }) async {
    if (_inFlight.contains(sectionId)) return;
    final at = _fetchedAt[sectionId];
    if (!force && at != null && DateTime.now().difference(at) < _ttl) return;

    _inFlight.add(sectionId);
    try {
      final col = collectionForType[type];
      final candidateUrls = <Uri>[];

      for (final base in ApiConstants.candidateBaseUrls) {
        candidateUrls.add(Uri.parse('$base/api/workout-sections/$sectionId/items'));
        if (col != null) {
          candidateUrls.add(Uri.parse('$base/api/$col'));
        }
      }

      for (final url in candidateUrls) {
        try {
          final res = await http.get(url).timeout(const Duration(seconds: 3));
          if (res.statusCode == 200) {
            final body = jsonDecode(res.body);
            final rawList = (body['data'] ?? body['items'] ?? body) as List<dynamic>? ?? [];
            if (rawList.isNotEmpty) {
              final parsed = rawList.map((item) {
                final map = Map<String, dynamic>.from(item as Map);
                final id = (map['id'] ?? map['_id'] ?? '').toString();
                return WorkoutSectionItem(id: id, data: map);
              }).where((i) => i.flag('isActive', true)).toList();

              _cache[sectionId] = parsed;
              _fetchedAt[sectionId] = DateTime.now();
              return;
            }
          }
        } catch (_) {}
      }

      // If backend has no custom items yet, mark empty so fallback seed data is used cleanly
      _cache[sectionId] = const [];
      _fetchedAt[sectionId] = DateTime.now();
    } catch (e) {
      debugPrint('[WorkoutSectionItems] $sectionId ($type) failed: $e');
      _cache.putIfAbsent(sectionId, () => const []);
    } finally {
      _inFlight.remove(sectionId);
      notifyListeners();
    }
  }

  /// Fire all section fetches in parallel (does not await completion).
  void prefetchAll(Iterable<({String id, String type})> sections) {
    for (final s in sections) {
      if (collectionForType.containsKey(s.type)) {
        fetch(s.id, s.type);
      }
    }
  }
}
