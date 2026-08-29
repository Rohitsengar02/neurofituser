import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_heading.dart';
import '../widgets/primary_button.dart';
import '../widgets/video_player_card.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  final List<String> _videoAssets = [
    'assets/videos/onboarding.mp4',
    'assets/videos/onboarding_2.mp4',
  ];

  final List<String> _subtitles = [
    'Workouts, nutrition, progress tracking and mindset \u2013 everything you need to become your best self.',
    'Get guided workouts, track progress and stay consistent with recommendations made just for you.',
  ];

  late AnimationController _textRevealController;
  late Animation<double> _textRevealProgress;

  @override
  void initState() {
    super.initState();

    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _textRevealProgress = CurvedAnimation(
      parent: _textRevealController,
      curve: Curves.easeOutCubic,
    );

    // Initial state: fully revealed for screen 1
    _textRevealController.value = 1.0;
  }

  @override
  void dispose() {
    _textRevealController.dispose();
    super.dispose();
  }

  void _onActionButtonPressed() async {
    HapticFeedback.mediumImpact();

    if (_currentPage == 0) {
      // 1. Show the 2nd video FIRST
      setState(() {
        _currentPage = 1;
      });

      // Reset text reveal
      _textRevealController.reset();

      // 2. Short delay so the video appears first, then run staggered blur text reveal
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) {
        _textRevealController.forward();
      }
    } else {
      // Screen 2: Navigate to Register Screen
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        top: false, // Edge-to-edge flush top
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Video Card: Shows video first on transition
                Expanded(
                  child: VideoPlayerCard(
                    videoAssetPath: _videoAssets[_currentPage],
                  ),
                ),

                // 2. Bottom Content Section with Staggered Blur Reveal
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Staggered Heading with Blur Text Reveal & Character Stagger
                      AnimatedHeading(
                        pageIndex: _currentPage,
                        animation: _textRevealProgress,
                      ),

                      const SizedBox(height: 12),

                      // Animated Subtitle description with staggered blur reveal
                      AnimatedBuilder(
                        animation: _textRevealProgress,
                        builder: (context, child) {
                          if (_currentPage == 0) {
                            return Text(
                              _subtitles[0],
                              style: AppTheme.bodyStyle,
                            );
                          }

                          // Staggered interval for subtitle on Screen 2 (0.55 -> 1.0)
                          final double animVal = _textRevealProgress.value;
                          final double subProgress = ((animVal - 0.55) / 0.45).clamp(0.0, 1.0);
                          final double subBlur = (1.0 - subProgress) * 10.0;
                          final double subSlide = (1.0 - subProgress) * 12.0;

                          return Transform.translate(
                            offset: Offset(0, subSlide),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: subBlur,
                                sigmaY: subBlur,
                                tileMode: TileMode.decal,
                              ),
                              child: Opacity(
                                opacity: subProgress,
                                child: Text(
                                  _subtitles[1],
                                  style: AppTheme.bodyStyle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Action Button: "Get Started" on Screen 1 -> "Register" on Screen 2
                      PrimaryButton(
                        text: _currentPage == 0 ? 'Get Started' : 'Register',
                        onTap: _onActionButtonPressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
