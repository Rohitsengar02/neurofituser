import 'dart:async';

import 'package:flutter/widgets.dart';

import 'live_backend.dart';
import 'sync_store.dart';

/// Counts app sessions for the admin's user analytics (one small record per day):
/// `session_day/<yyyy-mm-dd>` = { count, seconds, screens, bounces }.
/// A session ends when the app goes to the background; under 10 s with one
/// screen counts as a bounce. Stored offline first, synced with the rest.
class UsageTracker with WidgetsBindingObserver {
  UsageTracker._();
  static final UsageTracker I = UsageTracker._();

  DateTime? _start;
  int _screens = 0;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _begin();
  }

  /// Call when a new screen opens (the route observer does this).
  void screen() => _screens++;

  void _begin() {
    _start = DateTime.now();
    _screens = 1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      unawaited(_end());
    } else if (state == AppLifecycleState.resumed && _start == null) {
      _begin();
    }
  }

  Future<void> _end() async {
    final s = _start;
    if (s == null || !AppSession.isSignedIn) return;
    _start = null;
    final secs = DateTime.now().difference(s).inSeconds.clamp(0, 6 * 3600);
    final day = s.toIso8601String().substring(0, 10);
    final cur = await SyncStore.I.get('session_day', day) ?? {};
    int n(String k) => (cur[k] as num?)?.toInt() ?? 0;
    await SyncStore.I.put('session_day', day, {
      'count': n('count') + 1,
      'seconds': n('seconds') + secs,
      'screens': n('screens') + _screens,
      'bounces': n('bounces') + (secs < 10 && _screens <= 1 ? 1 : 0),
    });
    await SyncStore.I.push();
  }
}

/// Counts screen opens for [UsageTracker].
class UsageRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) UsageTracker.I.screen();
  }
}
