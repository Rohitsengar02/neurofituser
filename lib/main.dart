import 'dart:async';
import 'services/widget_sync.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'constants/api_constants.dart';
import 'backend/live_backend.dart';
import 'backend/local_db.dart';
import 'backend/sync_store.dart';
import 'backend/usage_tracker.dart';
import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

import 'services/fcm_notification_service.dart';

void main() {
  // Live API: tokens, offline cache and the offline outbox (lib/backend/live_backend.dart).
  final realClient = http.Client();
  http.runWithClient(_startApp, () => LiveBackendClient(realClient));
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!ApiConstants.demoMode) {
    await AppSession.load();
    await LocalDb.I.open();
    AppSession.onSignedOut = () => _navKey.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
    // Send anything saved offline last time, then keep this device in sync.
    unawaited(SyncStore.I.start());
    UsageTracker.I.start();
  }
  try {
    // No Firebase in demo mode. Firebase also has no web config yet.
    if (ApiConstants.demoMode || kIsWeb) throw Exception('Firebase skipped');
    await Firebase.initializeApp();
    await FcmNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const NeurofitApp());
  // Android home screen widgets.
  WidgetSync.init();
}

final _navKey = GlobalKey<NavigatorState>();

class NeurofitApp extends StatelessWidget {
  const NeurofitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neurofit',
      navigatorKey: _navKey,
      navigatorObservers: [UsageRouteObserver()],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/terms': (context) => const TermsOfServiceScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/privacy') {
          return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
        }
        if (settings.name == '/terms') {
          return MaterialPageRoute(builder: (_) => const TermsOfServiceScreen());
        }
        return null;
      },
    );
  }
}
