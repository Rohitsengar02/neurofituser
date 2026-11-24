import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../constants/api_constants.dart';
import 'user_backend_service.dart';

/// Top-level background handler for FCM Push Notifications
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📲 [FCM Background Notification] Received: ${message.messageId}');
}

class FcmNotificationService {
  FcmNotificationService._internal();
  static final FcmNotificationService instance = FcmNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _token;

  String? get fcmToken => _token;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request Android 13+ Notification Permission via permission_handler
      if (!kIsWeb) {
        try {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        } catch (_) {}
      }

      // 2. Request FCM permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📲 FCM Permission status: ${settings.authorizationStatus}');

      // 3. Enable Foreground Heads-Up Notification Display on Device
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Get device registration token
      _token = await _fcm.getToken();
      debugPrint('📲 FCM Device Token: $_token');

      if (_token != null) {
        await _registerTokenWithBackend(_token!);
      }

      // Listen to token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _token = newToken;
        _registerTokenWithBackend(newToken);
      });

      // 6. Subscribe to default topics
      await _fcm.subscribeToTopic('orders_updates');
      await _fcm.subscribeToTopic('broadcast');

      final user = UserBackendService.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        await _fcm.subscribeToTopic('user_${user.uid}');
      }

      // 7. Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Foreground Notification] ${message.notification?.title}: ${message.notification?.body}');
      });

      // 8. Listen to notification click / open
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [FCM Opened App from Notification] Data: ${message.data}');
      });
    } catch (e) {
      debugPrint('⚠️ FCM Notification Init notice: $e');
    }
  }

  Future<void> subscribeUserTopic(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _fcm.subscribeToTopic('user_$uid');
      if (_token != null) {
        await _registerTokenWithBackend(_token!, uid: uid);
      }
    } catch (_) {}
  }

  Future<void> _registerTokenWithBackend(String token, {String? uid}) async {
    final activeUid = uid ?? UserBackendService.instance.currentUser?.uid ?? '';
    final endpoints = [
      Uri.parse('${ApiConstants.apiBaseUrl}/notifications/register-token'),
      ...ApiConstants.candidateBaseUrls.map((b) => Uri.parse('$b/api/notifications/register-token')),
    ];

    for (final url in endpoints) {
      try {
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': token,
            'uid': activeUid,
            'role': 'user',
          }),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200 || res.statusCode == 201) {
          debugPrint('✅ FCM Token registered with backend at $url & topics subscribed');
          break;
        }
      } catch (_) {}
    }
  }
}
