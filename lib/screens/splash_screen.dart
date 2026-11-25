import 'package:permission_handler/permission_handler.dart';
import '../services/user_backend_service.dart';
import 'dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';
import '../widgets/kemo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // One timeline drives the whole intro: Kemo pops in, slides left,
  // and the NEUROFIT wordmark is wiped in from behind Kemo.
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  static const _green = Color(0xFF16A34A);
  static const _ink = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _t.forward();
    });

    // Check User Authentication: If user is registered / logged in -> go DIRECTLY to Dashboard
    Future.wait([
      UserBackendService.instance.checkAuthStatus(),
      Future.delayed(const Duration(milliseconds: 2900)),
    ]).then((_) {
      Future.delayed(Duration.zero, () {
        if (!mounted) return;

        Widget targetScreen = const OnboardingScreen();
        final userService = UserBackendService.instance;

        if (userService.isLoggedIn) {
          debugPrint('Logged in athlete session detected (${userService.currentUser?.email}). Bypassing onboarding & auth -> Opening Dashboard directly!');
          targetScreen = const DashboardScreen();
        } else {
          debugPrint('No active user session. Showing Onboarding.');
          targetScreen = const OnboardingScreen();
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      });
    });
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Notification permission request notice: $e');
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  double _seg(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      c.transform(((_t.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final kemo = (w * 0.22).clamp(64.0, 96.0);
    final font = (w * 0.105).clamp(30.0, 48.0);
    final word = GoogleFonts.plusJakartaSans(
      fontSize: font,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
      height: 1,
    );
    final wordPainter = TextPainter(
      text: TextSpan(text: 'NEUROFIT', style: word),
      textDirection: TextDirection.ltr,
    )..layout();
    final wordW = wordPainter.width;
    const gap = 12.0;
    final total = kemo + gap + wordW;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final pop = _seg(0.0, 0.28, Curves.easeOutBack);
            final slide = _seg(0.30, 0.58, Curves.easeInOutCubic);
            final wipe = _seg(0.40, 0.78);
            final tag = _seg(0.72, 0.95);
            // Kemo starts centred, then moves to the left of the wordmark.
            final kemoX = (total / 2 - kemo / 2) * slide;
            return Stack(
              children: [
                // soft green glow behind the logo
                Center(
                  child: Opacity(
                    opacity: pop * 0.9,
                    child: Container(
                      width: total * 1.3,
                      height: kemo * 2.4,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFD9F99D).withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: total,
                    height: kemo * 1.25,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Wordmark, revealed left-to-right as Kemo moves away.
                        Positioned(
                          left: kemo + gap,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: wipe,
                              child: Transform.translate(
                                offset: Offset(-18 * (1 - wipe), 0),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'NEURO',
                                        style: word.copyWith(color: _ink),
                                      ),
                                      TextSpan(
                                        text: 'FIT',
                                        style: word.copyWith(color: _green),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(-kemoX, 0),
                          child: Transform.scale(
                            scale: pop,
                            child: SizedBox(
                              width: kemo,
                              height: kemo,
                              child: KemoFace(
                                size: kemo,
                                emotion: wipe > 0.95
                                    ? KemoEmotion.excited
                                    : KemoEmotion.happy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.22),
                  child: Opacity(
                    opacity: tag,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - tag)),
                      child: Text(
                        'Your AI fitness buddy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.86),
                  child: Opacity(
                    opacity: tag,
                    child: SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation(_green),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
