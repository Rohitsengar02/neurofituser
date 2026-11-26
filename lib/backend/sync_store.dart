import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import 'live_backend.dart';
import 'local_db.dart';

/// The user's own small records (water per day, steps per day, app sessions,
/// favourites...). Saved to SQLite at once, so the app never waits on the
/// network, then pushed to the server in batches. Changes made on another
/// device come back with [pull]. Conflicts: the newest change wins.
///
///   await SyncStore.I.put('water_day', '2026-11-26', {'glasses': 6});
///   final day = await SyncStore.I.get('water_day', '2026-11-26');
class SyncStore extends ChangeNotifier {
  SyncStore._();
  static final SyncStore I = SyncStore._();

  Timer? _pushTimer;
  Timer? _pullTimer;
  io.Socket? _socket;
  bool _pulling = false;

  /// Collections that changed in the last pull (stores re-read only those).
  final Set<String> changed = {};

  Future<void> start() async {
    if (ApiConstants.demoMode) return;
    await LocalDb.I.open();
    Connectivity.I.addListener(_onConnectivity);
    _pullTimer?.cancel();
    _pullTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncNow());
    _connectSocket();
    unawaited(syncNow());
  }

  void stop() {
    _pullTimer?.cancel();
    _pushTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    Connectivity.I.removeListener(_onConnectivity);
  }

  void _onConnectivity() {
    if (Connectivity.I.online) unawaited(syncNow());
  }

  void _connectSocket() {
    if (_socket != null || !AppSession.isSignedIn) return;
    try {
      _socket = io.io(
        ApiConstants.socketUrl,
        io.OptionBuilder().setTransports(['websocket']).setAuth({'token': AppSession.accessToken ?? ''}).enableReconnection().build(),
      );
      // Another device of this user saved something: fetch it.
      _socket!.on('sync_available', (_) => unawaited(pull()));
      _socket!.onConnect((_) {
        if (AppSession.userId.isNotEmpty) _socket!.emit('join_user_room', AppSession.userId);
      });
      _listeners.forEach((ev, fns) => _socket!.on(ev, (_) => _fire(ev)));
    } catch (_) {}
  }

  // Live events from the server ("products_updated", "order:user_updated"...).
  final Map<String, List<void Function()>> _listeners = {};
  final Map<String, Timer> _debounce = {};

  /// Runs [fn] when the server sends [event]. Bursts are merged (one call per second).
  void on(String event, void Function() fn) {
    final first = !_listeners.containsKey(event);
    (_listeners[event] ??= []).add(fn);
    if (first && _socket != null) _socket!.on(event, (_) => _fire(event));
  }

  void _fire(String event) {
    _debounce[event]?.cancel();
    _debounce[event] = Timer(const Duration(seconds: 1), () {
      for (final fn in List.of(_listeners[event] ?? const <void Function()>[])) {
        fn();
      }
    });
  }

  /// After sign-in: connect live events and pull this user's data.
  void signedIn() {
    _socket?.dispose();
    _socket = null;
    _connectSocket();
    unawaited(syncNow());
  }

  Future<Map<String, dynamic>?> get(String col, String id) => LocalDb.I.recordGet(col, id);
  Future<Map<String, Map<String, dynamic>>> all(String col) => LocalDb.I.recordList(col);

  Future<void> put(String col, String id, Map<String, dynamic> data) async {
    await LocalDb.I.recordPut(col, id, data);
    _schedulePush();
  }

  Future<void> remove(String col, String id) async {
    await LocalDb.I.recordPut(col, id, const {}, deleted: true);
    _schedulePush();
  }

  void _schedulePush() {
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(seconds: 4), () => unawaited(push()));
  }

  Future<void> syncNow() async {
    if (!AppSession.isSignedIn) return;
    await push();
    await pull();
    await Outbox.flush();
  }

  Future<void> push() async {
    if (!AppSession.isSignedIn) return;
    final dirty = await LocalDb.I.recordsDirty();
    if (dirty.isEmpty) return;
    try {
      await Api.send('POST', '/sync/push', {'changes': dirty});
      await LocalDb.I.recordsClean(dirty);
    } catch (_) {
      // offline: they stay dirty and go next time
    }
  }

  Future<void> pull() async {
    if (_pulling || !AppSession.isSignedIn) return;
    _pulling = true;
    try {
      var since = int.tryParse(await LocalDb.I.metaGet('sync_cursor') ?? '') ?? 0;
      changed.clear();
      final dirty = {for (final r in await LocalDb.I.recordsDirty()) '${r['collection']}|${r['id']}': r['updatedAt'] as String};
      for (var page = 0; page < 20; page++) {
        final j = await Api.get('/sync/pull?since=$since');
        for (final c in Api.list(j, 'changes')) {
          final col = c['collection'].toString();
          final id = c['id'].toString();
          // Keep a newer local edit that hasn't been pushed yet.
          final mine = dirty['$col|$id'];
          if (mine != null && mine.compareTo(c['updatedAt'].toString()) > 0) continue;
          await LocalDb.I.recordPut(col, id, Map<String, dynamic>.from((c['data'] ?? const {}) as Map),
              deleted: c['deleted'] == true, dirty: false, updatedAt: c['updatedAt'].toString());
          changed.add(col);
        }
        since = (j['cursor'] as num?)?.toInt() ?? since;
        await LocalDb.I.metaPut('sync_cursor', '$since');
        if (j['hasMore'] != true) break;
      }
      if (changed.isNotEmpty) notifyListeners();
    } catch (_) {
      // offline
    } finally {
      _pulling = false;
    }
  }
}
