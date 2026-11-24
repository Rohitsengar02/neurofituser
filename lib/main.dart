import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'constants/api_constants.dart';
import 'demo/demo_backend.dart';
import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

import 'services/fcm_notification_service.dart';

void main() {
  if (ApiConstants.demoMode) {
    // Answer every backend call on the device with demo data.
    final realClient = http.Client();
    http.runWithClient(_startApp, () => DemoBackendClient(realClient));
  } else {
    _startApp();
  }
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
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
}

class NeurofitApp extends StatelessWidget {
  const NeurofitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neurofit',
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
