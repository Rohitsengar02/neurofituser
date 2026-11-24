import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized API & Server Configuration with instant Local vs Live Render toggle
class ApiConstants {
  /// UI-only demo: every backend call is answered on the device with demo data
  /// (see lib/demo/demo_backend.dart). Build with --dart-define=DEMO_MODE=false
  /// to talk to the real backend again.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  /// 🔘 SWITCH HERE: Set to `true` for Local Backend, or `false` for Live Render Backend
  static const bool useLocalBackend = false;

  /// Live Render Production Base URL
  static const String liveRenderUrl = 'https://neurofit-full.onrender.com';

  /// Local Backend Configuration
  static const int serverPort = 5000;
  static const String lanIp = '192.168.1.36'; // Current local Wi-Fi IP address
  static const String emulatorHost = '10.0.2.2'; // Android Emulator host loopback

  /// Returns active base URL based on toggle
  static String get baseUrl {
    if (useLocalBackend) {
      if (kIsWeb) {
        return 'http://localhost:$serverPort';
      }
      try {
        if (Platform.isAndroid) {
          // Physical device via adb reverse or local Wi-Fi IP
          return 'http://127.0.0.1:$serverPort';
        }
        if (Platform.isIOS) {
          return 'http://$lanIp:$serverPort';
        }
      } catch (_) {}
      return 'http://$lanIp:$serverPort';
    }
    return liveRenderUrl;
  }

  /// REST API base URL (e.g. http://192.168.1.36:5000/api or https://neurofit-full.onrender.com/api)
  static String get apiBaseUrl {
    return '$baseUrl/api';
  }

  /// Real-time Socket.io server URL
  static String get socketUrl {
    return baseUrl;
  }

  /// Candidate Base URLs list for smart fallback & multi-device local network discovery
  static List<String> get candidateBaseUrls {
    if (useLocalBackend) {
      if (kIsWeb) {
        return [
          'http://localhost:$serverPort',
          'http://127.0.0.1:$serverPort',
          'http://$lanIp:$serverPort',
          liveRenderUrl,
        ];
      }
      return [
        'http://127.0.0.1:$serverPort', // Works on physical device with adb reverse
        'http://$lanIp:$serverPort',    // Works on physical device over Wi-Fi
        'http://10.0.2.2:$serverPort',  // Works on Android emulator
        'http://localhost:$serverPort',
        liveRenderUrl,
      ];
    } else {
      return [
        liveRenderUrl,
        'http://127.0.0.1:$serverPort',
        'http://$lanIp:$serverPort',
        'http://localhost:$serverPort',
        'http://10.0.2.2:$serverPort',
      ];
    }
  }
}
