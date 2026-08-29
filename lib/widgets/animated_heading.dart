import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AnimatedHeading extends StatefulWidget {
  final int pageIndex;
  final Animation<double> animation; // Progress of text reveal (0.0 -> 1.0)

  const AnimatedHeading({
    super.key,
    required this.pageIndex,
    required this.animation,
  });

  @override
  State<AnimatedHeading> createState() => _AnimatedHeadingState();
}

class _AnimatedHeadingState extends State<AnimatedHeading>
    with TickerProviderStateMixin {
  late AnimationController _autoPulseController;
  late AnimationController _autoSpinController;

  @override
  void initState() {
    super.initState();

    // Auto breathing for Screen 1 badge
    _autoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Continuous auto-spin for Screen 2 badge
    _autoSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _autoPulseController.dispose();
    _autoSpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headingFontSize = (screenWidth * 0.095).clamp(32.0, 40.0);

    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _autoPulseController, _autoSpinController]),
      builder: (context, child) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: widget.pageIndex == 0
              ? _buildSlideOneContent(headingFontSize)
              : _buildSlideTwoStaggeredContent(headingFontSize),
        );
      },
    );
  }

  Widget _buildSlideOneContent(double fontSize) {
    final double pulseScale = 1.0 + (_autoPulseController.value * 0.08);
    final double wobbleAngle = math.sin(_autoPulseController.value * math.pi) * 0.08;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line 1: "Turn your"
        Text(
          'Turn your',
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.mutedText,
            letterSpacing: -1.2,
            height: 1.15,
          ),
        ),

        // Line 2: "fitness [Dumbbell Badge] goals"
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'fitness',
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
                letterSpacing: -1.2,
                height: 1.15,
              ),
            ),
            const SizedBox(width: 8),

            // Dumbbell badge
            Transform.scale(
              scale: pulseScale,
              child: Transform.rotate(
                angle: wobbleAngle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF3D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x66FF5722),
                        blurRadius: 10 + (_autoPulseController.value * 4),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),
            Text(
              'goals',
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
                letterSpacing: -1.2,
                height: 1.15,
              ),
            ),
          ],
        ),

        // Line 3: "into results"
        Text(
          'into results',
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.mutedText,
            letterSpacing: -1.2,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  // Staggered Blur Text Reveal with character/line animations for Screen 2
  Widget _buildSlideTwoStaggeredContent(double fontSize) {
    final double animVal = widget.animation.value;

    // Stagger intervals:
    // Line 1: 0.0 -> 0.45
    final double line1Progress = ((animVal - 0.0) / 0.45).clamp(0.0, 1.0);
    final double line1Blur = (1.0 - line1Progress) * 14.0;
    final double line1Slide = (1.0 - line1Progress) * 16.0;

    // Line 2: 0.25 -> 0.75
    final double line2Progress = ((animVal - 0.25) / 0.50).clamp(0.0, 1.0);
    final double line2Blur = (1.0 - line2Progress) * 14.0;
    final double line2Slide = (1.0 - line2Progress) * 16.0;

    // Line 3: 0.50 -> 1.0
    final double line3Progress = ((animVal - 0.50) / 0.50).clamp(0.0, 1.0);
    final double line3Blur = (1.0 - line3Progress) * 14.0;
    final double line3Slide = (1.0 - line3Progress) * 16.0;

    // Badge pop & spin
    final double badgePopScale = line2Progress * (1.0 + (math.sin(_autoSpinController.value * 4 * math.pi) * 0.05));
    final double badgeSpinAngle = (_autoSpinController.value * 2 * math.pi) + ((1.0 - line2Progress) * math.pi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line 1: "Personalized plans," with Blur & Slide Reveal
        Transform.translate(
          offset: Offset(0, line1Slide),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: line1Blur,
              sigmaY: line1Blur,
              tileMode: TileMode.decal,
            ),
            child: Opacity(
              opacity: line1Progress,
              child: Text(
                'Personalized plans,',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedText,
                  letterSpacing: -1.2,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ),

        // Line 2: "[Loop Badge] smarter workouts," with Staggered Blur Reveal
        Transform.translate(
          offset: Offset(0, line2Slide),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: line2Blur,
              sigmaY: line2Blur,
              tileMode: TileMode.decal,
            ),
            child: Opacity(
              opacity: line2Progress,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pop-in and spinning smart sync arrows badge
                  Transform.scale(
                    scale: badgePopScale,
                    child: Transform.rotate(
                      angle: badgeSpinAngle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3366), Color(0xFFFF5238)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66FF3366),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sync_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  Text(
                    'smarter workouts,',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Line 3: "better you." with Staggered Blur Reveal
        Transform.translate(
          offset: Offset(0, line3Slide),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: line3Blur,
              sigmaY: line3Blur,
              tileMode: TileMode.decal,
            ),
            child: Opacity(
              opacity: line3Progress,
              child: Text(
                'better you.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedText,
                  letterSpacing: -1.2,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
