import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class FitnessStaggeredHeadline extends StatefulWidget {
  final bool isLogin;

  const FitnessStaggeredHeadline({
    super.key,
    this.isLogin = false,
  });

  @override
  State<FitnessStaggeredHeadline> createState() => _FitnessStaggeredHeadlineState();
}

class _FitnessStaggeredHeadlineState extends State<FitnessStaggeredHeadline>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _iconPulseController;
  late AnimationController _iconRotateController;

  @override
  void initState() {
    super.initState();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _iconRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    _iconPulseController.dispose();
    _iconRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.105).clamp(36.0, 46.0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _revealController,
        _iconPulseController,
        _iconRotateController,
      ]),
      builder: (context, child) {
        final double anim = _revealController.value;

        // Line 1: 0.0 -> 0.45
        final double l1 = ((anim - 0.0) / 0.45).clamp(0.0, 1.0);
        final double l1Blur = math.max(0.001, (1.0 - l1) * 14.0);
        final double l1Slide = (1.0 - l1) * 20.0;

        // Line 2: 0.25 -> 0.70
        final double l2 = ((anim - 0.25) / 0.45).clamp(0.0, 1.0);
        final double l2Blur = math.max(0.001, (1.0 - l2) * 14.0);
        final double l2Slide = (1.0 - l2) * 20.0;

        // Line 3: 0.50 -> 0.95
        final double l3 = ((anim - 0.50) / 0.45).clamp(0.0, 1.0);
        final double l3Blur = math.max(0.001, (1.0 - l3) * 14.0);
        final double l3Slide = (1.0 - l3) * 20.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // LINE 1: "fitness [🏋️ Badge] goals" or "welcome [💪 Badge] back"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur, tileMode: TileMode.decal),
                child: Opacity(
                  opacity: l1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.isLogin ? 'welcome ' : 'fitness ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
                            letterSpacing: -1.4,
                            height: 1.15,
                          ),
                        ),

                        // Inline Animated Badge 1: Dumbbell / Muscle with energetic coral/orange gradient
                        _buildAnimatedBadge(
                          icon: widget.isLogin ? Icons.fitness_center_rounded : Icons.fitness_center_rounded,
                          gradientColors: [
                            Color.lerp(const Color(0xFFFF5722), const Color(0xFFFF3D00), _iconPulseController.value)!,
                            Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFF7043), _iconPulseController.value)!,
                          ],
                          scale: 1.0 + (_iconPulseController.value * 0.08),
                          rotation: math.sin(_iconPulseController.value * math.pi) * 0.1,
                          glowColor: const Color(0xFFFF5722),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          widget.isLogin ? 'back' : 'plans',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
                            letterSpacing: -1.4,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // LINE 2: "with the most" or "to your daily"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur, tileMode: TileMode.decal),
                child: Opacity(
                  opacity: l2,
                  child: Text(
                    widget.isLogin ? 'to your daily' : 'with the most',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                      letterSpacing: -1.4,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // LINE 3: "valuable [🔥/⚡ Badge]" or "workout [🎯 Badge]"
            Transform.translate(
              offset: Offset(0, l3Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l3Blur, sigmaY: l3Blur, tileMode: TileMode.decal),
                child: Opacity(
                  opacity: l3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.isLogin ? 'workouts ' : 'valuable ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
                            letterSpacing: -1.4,
                            height: 1.15,
                          ),
                        ),

                        // Inline Animated Badge 2: Rotating/Pulsing Energy/Streak badge
                        _buildAnimatedBadge(
                          icon: widget.isLogin ? Icons.bolt_rounded : Icons.local_fire_department_rounded,
                          gradientColors: [
                            Color.lerp(const Color(0xFF10B981), const Color(0xFF059669), _iconPulseController.value)!,
                            Color.lerp(const Color(0xFF34D399), const Color(0xFF10B981), _iconPulseController.value)!,
                          ],
                          scale: 1.0 + (math.sin(_iconRotateController.value * 4 * math.pi) * 0.06),
                          rotation: math.sin(_iconRotateController.value * 2 * math.pi) * 0.15,
                          glowColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedBadge({
    required IconData icon,
    required List<Color> gradientColors,
    required double scale,
    required double rotation,
    required Color glowColor,
  }) {
    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
