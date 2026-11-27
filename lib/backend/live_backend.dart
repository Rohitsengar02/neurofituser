import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'local_db.dart';

/// The signed-in user's tokens, kept across app restarts.
class AppSession {
  AppSession._();

  static String? accessToken;
  static String? refreshToken;
  static String userId = '';

  static bool get isSignedIn => (refreshToken ?? '').isNotEmpty;
  static const _k = 'app_session_v1';

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      accessToken = j['a'];
      refreshToken = j['r'];
      userId = (j['u'] ?? '').toString();
    } catch (_) {}
  }

  /// Saves the tokens from /auth/register, /auth/login, /auth/google or /auth/refresh.
  static Future<void> save(Map<String, dynamic> j) async {
    final data = j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : <String, dynamic>{};
    accessToken = (j['accessToken'] ?? data['accessToken'])?.toString();
    refreshToken = (j['refreshToken'] ?? data['refreshToken'] ?? refreshToken)?.toString();
    userId = (data['uid'] ?? data['id'] ?? userId).toString();
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode({'a': accessToken, 'r': refreshToken, 'u': userId}));
    } catch (_) {}
  }

  static Future<void> clear() async {
    final r = refreshToken;
    accessToken = null;
    refreshToken = null;
    userId = '';
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_k);
    } catch (_) {}
    await LocalDb.I.wipe();
    if (r != null) {
      try {
        await http.post(Uri.parse('${ApiConstants.apiBaseUrl}/auth/logout'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': r})).timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
  }

  static Completer<bool>? _refreshing;

  /// New access token from the refresh token. One refresh at a time.
  static Future<bool> refresh(http.Client inner) async {
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<bool>();
    try {
      if (!isSignedIn) {
        c.complete(false);
      } else {
        final res = await inner.post(Uri.parse('${ApiConstants.apiBaseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': refreshToken})).timeout(const Duration(seconds: 60));
        if (res.statusCode == 200) {
          await save(jsonDecode(res.body) as Map<String, dynamic>);
          c.complete(true);
        } else if (res.statusCode == 401) {
          // Refresh token revoked or expired: the user must sign in again.
          accessToken = null;
          refreshToken = null;
          await _persist();
          onSignedOut?.call();
          c.complete(false);
        } else {
          c.complete(false);
        }
      }
    } catch (_) {
      c.complete(false); // offline: keep the session, try later
    } finally {
      _refreshing = null;
    }
    return c.future;
  }

  /// Called when the session can no longer be refreshed.
  static void Function()? onSignedOut;
}

/// Online/offline state the UI (and stores) can listen to.
class Connectivity extends ChangeNotifier {
  Connectivity._();
  static final Connectivity I = Connectivity._();
  bool online = true;
  int pending = 0;

  void setPending(int n) {
    pending = n;
    notifyListeners();
  }

  void _set(bool v) {
    if (online == v) return;
    online = v;
    notifyListeners();
    if (v) Outbox.flush();
  }
}

/// Every HTTP call in the app goes through this client (see main.dart).
///
/// - Calls to the NeuroFit API get the user's token, the platform header, and
///   one retry after a token refresh.
/// - Old hosts (the previous backend, localhost) and Firestore REST calls are
///   pointed at the live API.
/// - Reads are cached on the device. With no network the last answer is used,
///   so the app opens and works offline.
/// - Writes made offline go to an outbox and are sent, in order, once the
///   phone is back online. The server takes the client's ids, so a replay
///   never creates duplicates.
class LiveBackendClient extends http.BaseClient {
  LiveBackendClient(this._inner);
  final http.Client _inner;

  static final Uri _base = Uri.parse(ApiConstants.baseUrl);
  static const _legacyHosts = {'neurofit-full.onrender.com', 'neurofit-api.onrender.com', 'localhost', '127.0.0.1', '10.0.2.2', '192.168.1.34', '192.168.1.36'};
  // Never queued: they need an answer now (sign-in, uploads, live calls, payments).
  static const _noQueue = ['/api/auth/', '/api/media/', '/api/live/', '/api/track', '/api/sync/'];

  static String get platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.name;
    }
  }

  @override
  void close() {}

  static Uri map(Uri u) {
    if (u.host == 'firestore.googleapis.com') {
      final q = Map<String, dynamic>.from(u.queryParametersAll)..remove('key');
      return _base.replace(path: '/fs${u.path}', queryParameters: q.isEmpty ? null : q);
    }
    if (_legacyHosts.contains(u.host) && u.host != _base.host && (u.path.startsWith('/api') || u.path.startsWith('/uploads'))) {
      return _base.replace(path: u.path, query: u.hasQuery ? u.query : null);
    }
    return u;
  }

  static bool ours(Uri u) => u.host == _base.host && u.port == _base.port;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host == 'api.cloudflare.com') {
      return _json(request, 400, {'success': false, 'message': 'Uploads go through the NeuroFit API'});
    }
    final url = map(request.url);
    final bytes = await request.finalize().toBytes();
    if (!ours(url)) return _inner.send(_copy(request, url, bytes));

    final isRead = request.method == 'GET';
    final cacheKey = '${AppSession.userId}|${url.toString()}';
    final queueable = !isRead && url.path.startsWith('/api/') && !_noQueue.any(url.path.startsWith) && !request.headers.containsKey('x-no-queue');

    // Writes made while we already know we're offline go straight to the outbox.
    if (queueable && !Connectivity.I.online) return _queue(request, url, bytes);

    Future<http.StreamedResponse> go() {
      final timeout = isRead ? const Duration(seconds: 25) : const Duration(seconds: 45);
      return _inner.send(_copy(request, url, bytes)).timeout(timeout);
    }

    http.StreamedResponse res;
    try {
      res = await go();
      if (res.statusCode == 401 && !url.path.contains('/auth/')) {
        await res.stream.drain<void>();
        if (await AppSession.refresh(_inner)) {
          res = await go();
        } else {
          return _json(request, 401, {'success': false, 'message': 'Please sign in again.'});
        }
      }
    } catch (e) {
      // No network (or the server is waking up and timed out).
      Connectivity.I._set(false);
      _scheduleRetry();
      if (isRead) {
        final hit = await LocalDb.I.cacheGet(cacheKey);
        if (hit != null) return _raw(request, 200, hit, offline: true);
        rethrow;
      }
      if (queueable) return _queue(request, url, bytes);
      rethrow;
    }

    Connectivity.I._set(true);
    if (isRead && res.statusCode == 200 && url.path.startsWith('/api/')) {
      // Keep a copy for offline use, then hand the same bytes to the caller.
      final body = await res.stream.toBytes();
      final text = utf8.decode(body, allowMalformed: true);
      unawaited(LocalDb.I.cachePut(cacheKey, text));
      return http.StreamedResponse(Stream.value(body), res.statusCode,
          contentLength: body.length, request: request, headers: res.headers, reasonPhrase: res.reasonPhrase);
    }
    return res;
  }

  http.Request _copy(http.BaseRequest request, Uri url, List<int> bytes) {
    final r = http.Request(request.method, url)
      ..followRedirects = request.followRedirects
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    r.headers.remove('x-no-queue');
    if (ours(url)) {
      r.headers['x-client-platform'] = platform;
      if ((AppSession.accessToken ?? '').isNotEmpty && !r.headers.containsKey('Authorization')) {
        r.headers['Authorization'] = 'Bearer ${AppSession.accessToken}';
      }
    }
    return r;
  }

  Future<http.StreamedResponse> _queue(http.BaseRequest request, Uri url, List<int> bytes) async {
    final body = utf8.decode(bytes, allowMalformed: true);
    final headers = Map<String, String>.from(request.headers)..remove('Authorization');
    await LocalDb.I.outboxAdd(request.method, url.toString(), body, headers);
    Connectivity.I.setPending(await LocalDb.I.outboxCount());
    Object? echo;
    try {
      echo = body.isEmpty ? null : jsonDecode(body);
    } catch (_) {}
    // Answer like the server would, so screens carry on; the real call follows later.
    return _json(request, 202, {'success': true, 'queued': true, 'message': 'Saved offline. Will sync when online.', if (echo != null) 'data': echo});
  }

  static Timer? _retry;
  static void _scheduleRetry() {
    _retry ??= Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        final r = await http.get(Uri.parse('${ApiConstants.baseUrl}/health')).timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) {
          Connectivity.I._set(true);
          _retry?.cancel();
          _retry = null;
        }
      } catch (_) {}
    });
  }

  http.StreamedResponse _raw(http.BaseRequest req, int status, String body, {bool offline = false}) {
    final b = utf8.encode(body);
    return http.StreamedResponse(Stream.value(b), status, contentLength: b.length, request: req, headers: {
      'content-type': 'application/json; charset=utf-8',
      if (offline) 'x-offline': '1',
    });
  }

  http.StreamedResponse _json(http.BaseRequest req, int status, Object body) => _raw(req, status, jsonEncode(body));
}

/// Sends writes that were made offline, oldest first.
class Outbox {
  static bool _running = false;

  static Future<void> flush() async {
    if (_running) return;
    _running = true;
    try {
      final items = await LocalDb.I.outboxAll();
      for (final it in items) {
        final req = http.Request(it['method'] as String, Uri.parse(it['url'] as String));
        try {
          final h = jsonDecode((it['headers'] ?? '{}') as String) as Map;
          req.headers.addAll(h.map((k, v) => MapEntry(k.toString(), v.toString())));
        } catch (_) {}
        req.headers['x-no-queue'] = '1';
        req.body = (it['body'] ?? '') as String;
        http.Response res;
        try {
          res = await http.Response.fromStream(await http.Client().send(req)).timeout(const Duration(seconds: 45));
        } catch (_) {
          break; // still offline; keep the rest for later
        }
        if (res.statusCode >= 500) break; // server trouble; try again later
        await LocalDb.I.outboxRemove(it['id'] as Object); // done (or rejected for good)
      }
      Connectivity.I.setPending(await LocalDb.I.outboxCount());
    } finally {
      _running = false;
    }
  }
}

/// Small helper for code that reads the API directly.
class Api {
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('${ApiConstants.apiBaseUrl}$path'));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> send(String method, String path, [Object? body]) async {
    final req = http.Request(method, Uri.parse('${ApiConstants.apiBaseUrl}$path'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body ?? {});
    final res = await http.Response.fromStream(await http.Client().send(req));
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    Object? j;
    try {
      j = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    } catch (_) {
      j = {'message': res.body};
    }
    if (res.statusCode >= 400) {
      throw ApiError(j is Map ? (j['message'] ?? 'Request failed').toString() : 'Request failed', res.statusCode, j is Map ? j['code']?.toString() : null);
    }
    return j is Map<String, dynamic> ? j : {'data': j};
  }

  static List<Map<String, dynamic>> list(Map<String, dynamic> j, [String key = 'data']) =>
      [for (final x in (j[key] is List ? j[key] as List : const [])) if (x is Map) Map<String, dynamic>.from(x)];
}

class ApiError implements Exception {
  ApiError(this.message, [this.status = 0, this.code]);
  final String message;
  final int status;
  final String? code;
  @override
  String toString() => message;
}
