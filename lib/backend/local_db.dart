import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// On-device storage for offline mode.
///
/// Phones use SQLite (three small tables). The web build has no SQLite, so it
/// keeps the same data in browser storage through SharedPreferences.
///
/// - `cache`   last good answer for each API read, shown when offline
/// - `outbox`  writes made while offline, sent in order when back online
/// - `records` the user's own synced records (water, steps, sessions...)
class LocalDb {
  LocalDb._();
  static final LocalDb I = LocalDb._();

  Database? _db;
  Future<void>? _opening;
  SharedPreferences? _prefs;

  Future<void> open() => _opening ??= _open();

  Future<void> _open() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
      return;
    }
    try {
      final dir = await getDatabasesPath();
      _db = await openDatabase(
        '$dir/neurofit_offline.db',
        version: 1,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE cache (k TEXT PRIMARY KEY, body TEXT NOT NULL, at INTEGER NOT NULL)');
          await db.execute('CREATE TABLE outbox (id INTEGER PRIMARY KEY AUTOINCREMENT, method TEXT, url TEXT, body TEXT, headers TEXT, at INTEGER)');
          await db.execute('CREATE TABLE records (col TEXT NOT NULL, id TEXT NOT NULL, data TEXT NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL, dirty INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (col, id))');
          await db.execute('CREATE TABLE meta (k TEXT PRIMARY KEY, v TEXT)');
        },
      );
    } catch (e) {
      debugPrint('[offline] SQLite unavailable ($e), using preferences');
      _prefs = await SharedPreferences.getInstance();
    }
  }

  bool get _sql => _db != null;

  // ---------------- cache ----------------
  static const _cacheMax = 400;

  Future<String?> cacheGet(String k) async {
    await open();
    if (_sql) {
      final r = await _db!.query('cache', columns: ['body'], where: 'k = ?', whereArgs: [k], limit: 1);
      return r.isEmpty ? null : r.first['body'] as String;
    }
    return _prefs!.getString('c:$k');
  }

  Future<void> cachePut(String k, String body) async {
    await open();
    if (body.length > 1500000) return; // very large lists are not worth keeping
    if (_sql) {
      await _db!.insert('cache', {'k': k, 'body': body, 'at': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
      if (DateTime.now().second % 20 == 0) {
        await _db!.execute('DELETE FROM cache WHERE k NOT IN (SELECT k FROM cache ORDER BY at DESC LIMIT $_cacheMax)');
      }
      return;
    }
    if (body.length > 200000) return; // browser storage is small
    final keys = _prefs!.getStringList('c:keys') ?? <String>[];
    keys.remove(k);
    keys.add(k);
    while (keys.length > 120) {
      await _prefs!.remove('c:${keys.removeAt(0)}');
    }
    await _prefs!.setStringList('c:keys', keys);
    await _prefs!.setString('c:$k', body);
  }

  // ---------------- outbox ----------------
  Future<void> outboxAdd(String method, String url, String body, Map<String, String> headers) async {
    await open();
    final row = {'method': method, 'url': url, 'body': body, 'headers': jsonEncode(headers), 'at': DateTime.now().millisecondsSinceEpoch};
    if (_sql) {
      await _db!.insert('outbox', row);
      return;
    }
    final list = _prefs!.getStringList('outbox') ?? <String>[];
    list.add(jsonEncode({...row, 'id': DateTime.now().microsecondsSinceEpoch}));
    await _prefs!.setStringList('outbox', list);
  }

  Future<List<Map<String, dynamic>>> outboxAll() async {
    await open();
    if (_sql) {
      final rows = await _db!.query('outbox', orderBy: 'id ASC', limit: 200);
      return [for (final r in rows) Map<String, dynamic>.from(r)];
    }
    return [for (final s in _prefs!.getStringList('outbox') ?? const <String>[]) Map<String, dynamic>.from(jsonDecode(s) as Map)];
  }

  Future<int> outboxCount() async {
    await open();
    if (_sql) return Sqflite.firstIntValue(await _db!.rawQuery('SELECT count(*) FROM outbox')) ?? 0;
    return (_prefs!.getStringList('outbox') ?? const []).length;
  }

  Future<void> outboxRemove(Object id) async {
    await open();
    if (_sql) {
      await _db!.delete('outbox', where: 'id = ?', whereArgs: [id]);
      return;
    }
    final list = _prefs!.getStringList('outbox') ?? <String>[];
    list.removeWhere((s) => (jsonDecode(s) as Map)['id'] == id);
    await _prefs!.setStringList('outbox', list);
  }

  // ---------------- records ----------------
  Future<void> recordPut(String col, String id, Map<String, dynamic> data, {bool deleted = false, bool dirty = true, String? updatedAt}) async {
    await open();
    final at = updatedAt ?? DateTime.now().toUtc().toIso8601String();
    if (_sql) {
      await _db!.insert('records', {'col': col, 'id': id, 'data': jsonEncode(data), 'deleted': deleted ? 1 : 0, 'updated_at': at, 'dirty': dirty ? 1 : 0},
          conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    final map = _webRecords();
    map['$col|$id'] = {'col': col, 'id': id, 'data': data, 'deleted': deleted, 'updated_at': at, 'dirty': dirty};
    await _prefs!.setString('records', jsonEncode(map));
  }

  Future<Map<String, dynamic>?> recordGet(String col, String id) async {
    await open();
    if (_sql) {
      final r = await _db!.query('records', where: 'col = ? AND id = ? AND deleted = 0', whereArgs: [col, id], limit: 1);
      return r.isEmpty ? null : Map<String, dynamic>.from(jsonDecode(r.first['data'] as String) as Map);
    }
    final e = _webRecords()['$col|$id'];
    if (e == null || e['deleted'] == true) return null;
    return Map<String, dynamic>.from(e['data'] as Map);
  }

  Future<Map<String, Map<String, dynamic>>> recordList(String col) async {
    await open();
    if (_sql) {
      final rows = await _db!.query('records', where: 'col = ? AND deleted = 0', whereArgs: [col]);
      return {for (final r in rows) r['id'] as String: Map<String, dynamic>.from(jsonDecode(r['data'] as String) as Map)};
    }
    return {
      for (final e in _webRecords().values)
        if (e['col'] == col && e['deleted'] != true) e['id'] as String: Map<String, dynamic>.from(e['data'] as Map),
    };
  }

  Future<List<Map<String, dynamic>>> recordsDirty() async {
    await open();
    if (_sql) {
      final rows = await _db!.query('records', where: 'dirty = 1', limit: 500);
      return [
        for (final r in rows)
          {'collection': r['col'], 'id': r['id'], 'data': jsonDecode(r['data'] as String), 'deleted': r['deleted'] == 1, 'updatedAt': r['updated_at']},
      ];
    }
    return [
      for (final e in _webRecords().values)
        if (e['dirty'] == true) {'collection': e['col'], 'id': e['id'], 'data': e['data'], 'deleted': e['deleted'] == true, 'updatedAt': e['updated_at']},
    ];
  }

  Future<void> recordsClean(List<Map<String, dynamic>> pushed) async {
    await open();
    if (_sql) {
      final b = _db!.batch();
      for (final p in pushed) {
        b.update('records', {'dirty': 0}, where: 'col = ? AND id = ? AND updated_at = ?', whereArgs: [p['collection'], p['id'], p['updatedAt']]);
      }
      await b.commit(noResult: true);
      return;
    }
    final map = _webRecords();
    for (final p in pushed) {
      final e = map['${p['collection']}|${p['id']}'];
      if (e != null && e['updated_at'] == p['updatedAt']) e['dirty'] = false;
    }
    await _prefs!.setString('records', jsonEncode(map));
  }

  Map<String, dynamic> _webRecords() {
    final raw = _prefs!.getString('records');
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  // ---------------- meta ----------------
  Future<String?> metaGet(String k) async {
    await open();
    if (_sql) {
      final r = await _db!.query('meta', where: 'k = ?', whereArgs: [k], limit: 1);
      return r.isEmpty ? null : r.first['v'] as String?;
    }
    return _prefs!.getString('m:$k');
  }

  Future<void> metaPut(String k, String v) async {
    await open();
    if (_sql) {
      await _db!.insert('meta', {'k': k, 'v': v}, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    await _prefs!.setString('m:$k', v);
  }

  /// Sign-out: forget everything that belonged to the previous user.
  Future<void> wipe() async {
    await open();
    if (_sql) {
      await _db!.delete('cache');
      await _db!.delete('outbox');
      await _db!.delete('records');
      await _db!.delete('meta');
      return;
    }
    for (final k in _prefs!.getKeys().where((k) => k.startsWith('c:') || k.startsWith('m:') || k == 'outbox' || k == 'records').toList()) {
      await _prefs!.remove(k);
    }
  }
}
