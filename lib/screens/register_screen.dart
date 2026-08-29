import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_icon_marquee.dart';
import '../widgets/fitness_staggered_headline.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'questionnaire_screen.dart';
import 'terms_of_service_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _buttonsController;

  @override
  void initState() {
    super.initState();
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start button reveal shortly after text starts revealing
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _buttonsController.forward();
    });
  }

  @override
  void dispose() {
    _buttonsController.dispose();
    super.dispose();
  }

  void _onOAuthSuccess(String provider) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const QuestionnaireScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildStaggeredButton({
    required Widget child,
    required double startInterval,
    required double endInterval,
  }) {
    final slideAnim = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
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
      child: FadeTransition(
        opacity: fadeAnim,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1:1 Aspect Ratio Animated Marquee at the top (edge-to-edge)
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const AnimatedIconMarquee(),
                // Back Arrow overlay
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
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
          
          // Bottom area: Text and Staggered Buttons
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Staggered Fitness Headline (just above buttons)
                    const FitnessStaggeredHeadline(isLogin: false),
                    const SizedBox(height: 28),

                    // Staggered Buttons
                    _buildStaggeredButton(
                      startInterval: 0.0,
                      endInterval: 0.5,
                      child: _buildAuthButton(
                        text: 'Sign up with Apple',
                        icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                        backgroundColor: const Color(0xFF1C1D22),
                        textColor: Colors.white,
                        onTap: () => _onOAuthSuccess('Apple'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildStaggeredButton(
                      startInterval: 0.15,
                      endInterval: 0.65,
                      child: _buildAuthButton(
                        text: 'Continue with Google',
                        icon: _buildGoogleIcon(),
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF141518),
                        borderColor: const Color(0xFFE5E7EB),
                        onTap: () => _onOAuthSuccess('Google'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildStaggeredButton(
                      startInterval: 0.30,
                      endInterval: 0.80,
                      child: _buildAuthButton(
                        text: 'I have an account',
                        backgroundColor: const Color(0xFFF1F3F6),
                        textColor: const Color(0xFF141518),
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 400),
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const LoginScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Terms and conditions
                    _buildStaggeredButton(
                      startInterval: 0.45,
                      endInterval: 1.0,
                      child: Text.rich(
                        TextSpan(
                          text: 'By continuing you confirm that you agree to our ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const TermsOfServiceScreen(),
                                    ),
                                  );
                                },
                            ),
                            const TextSpan(text: ', '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyPolicyScreen(),
                                    ),
                                  );
                                },
                            ),
                            const TextSpan(text: ' and fitness safety guidelines.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
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
    Widget? icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFEA4335),
          ),
        ),
      ),
    );
  }
}
