import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/user_backend_service.dart';
import '../widgets/email_auth_sheet.dart';
import '../widgets/animated_icon_marquee.dart';
import '../widgets/fitness_staggered_headline.dart';
import 'privacy_policy_screen.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import 'questionnaire_screen.dart';
import 'terms_of_service_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _buttonsController;

  @override
  void initState() {
    super.initState();
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _buttonsController.forward();
    });
  }

  @override
  void dispose() {
    _buttonsController.dispose();
    super.dispose();
  }

  void _onAppleSignIn() {
    HapticFeedback.mediumImpact();
    _signInWithRealGoogle();
  }

  // -------------------------------------------------------------
  // REAL GOOGLE AUTHENTICATION & DIRECT FIRESTORE NAVIGATION
  // -------------------------------------------------------------
  void _signInWithRealGoogle() async {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Connecting to Google...',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    UserModel? user;
    try {
      user = await UserBackendService.instance.signInWithRealGoogle();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pop(); // Dismiss connecting loader

    if (user == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22C55E),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Welcome, ${user.name} (${user.email})',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(milliseconds: 1500),
      ),
    );

    final Widget nextScreen = user.hasCompletedOnboarding
        ? const DashboardScreen()
        : const QuestionnaireScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _emailAuth() async {
    final user = await showEmailAuthSheet(context, register: false);
    if (user != null && mounted) goAfterSignIn(context, user);
  }

  Widget _buildStaggeredButton({
    required Widget child,
    required double startInterval,
    required double endInterval,
  }) {
    final slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _buttonsController,
            curve: Interval(
              startInterval,
              endInterval,
              curve: Curves.easeOutCubic,
            ),
          ),
        );
    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(opacity: fadeAnim, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const AnimatedIconMarquee(),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FitnessStaggeredHeadline(isLogin: true),
                    const SizedBox(height: 28),

                    // 1. Sign in with Apple
                    _buildStaggeredButton(
                      startInterval: 0.0,
                      endInterval: 0.5,
                      child: _buildAuthButton(
                        text: 'Sign in with Apple',
                        icon: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 22,
                        ),
                        backgroundColor: const Color(0xFF1C1D22),
                        textColor: Colors.white,
                        onTap: _onAppleSignIn,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Continue with Google
                    _buildStaggeredButton(
                      startInterval: 0.18,
                      endInterval: 0.68,
                      child: _buildAuthButton(
                        text: 'Continue with Google',
                        icon: _buildGoogleIcon(),
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF141518),
                        borderColor: const Color(0xFFE5E7EB),
                        onTap: _signInWithRealGoogle,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email sign-in form
                    _buildStaggeredButton(
                      startInterval: 0.27,
                      endInterval: 0.77,
                      child: _buildAuthButton(
                        text: 'Continue with Email',
                        icon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF141518), size: 20),
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF141518),
                        borderColor: const Color(0xFFE5E7EB),
                        onTap: _emailAuth,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Don't have an account? Sign up
                    _buildStaggeredButton(
                      startInterval: 0.36,
                      endInterval: 0.86,
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Don\'t have an account? ',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF6B7280),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF22C55E),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        pageBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const RegisterScreen(),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Terms & Privacy Policy
                    _buildStaggeredButton(
                      startInterval: 0.50,
                      endInterval: 1.0,
                      child: Center(
                        child: Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            text: 'By signing in you agree to our ',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsOfServiceScreen(),
                                      ),
                                    );
                                  },
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required Widget icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.2)
            : null,
        boxShadow: backgroundColor == Colors.white
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);

    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4);
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853);
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335);

    canvas.drawCircle(center, w / 2, bluePaint);
    canvas.drawCircle(center, w / 2.8, Paint()..color = Colors.white);

    final rect = Rect.fromCircle(center: center, radius: w / 2);
    canvas.drawArc(rect, 0.7, 1.6, true, greenPaint);
    canvas.drawArc(rect, 2.3, 1.6, true, yellowPaint);
    canvas.drawArc(rect, 3.9, 1.5, true, redPaint);

    canvas.drawCircle(center, w / 3.4, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 1, center.dy - 2.5, w / 2.1, 5),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
