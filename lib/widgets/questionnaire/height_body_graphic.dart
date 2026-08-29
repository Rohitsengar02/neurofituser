import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeightBodyGraphic extends StatelessWidget {
  final double heightCm;
  final double minHeightCm;
  final double maxHeightCm;
  final String activeUnit; // 'cm', 'ft', 'm'
  final Color themeColor;

  const HeightBodyGraphic({
    super.key,
    required this.heightCm,
    this.minHeightCm = 120.0,
    this.maxHeightCm = 230.0,
    this.activeUnit = 'cm',
    this.themeColor = const Color(0xFF22C55E),
  });

  String get formattedDisplay {
    if (activeUnit == 'ft') {
      final totalInches = heightCm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return "$feet'$inches\"";
    } else if (activeUnit == 'm') {
      return (heightCm / 100.0).toStringAsFixed(2);
    } else {
      return heightCm.round().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Height fraction between 0.0 (min) and 1.0 (max)
    final fraction = ((heightCm - minHeightCm) / (maxHeightCm - minHeightCm)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        // Dynamic body height from 50% of available height to 92% of available height
        final minBodyH = availableHeight * 0.48;
        final maxBodyH = availableHeight * 0.90;
        final currentBodyH = minBodyH + (fraction * (maxBodyH - minBodyH));

        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Subtle Background Reference Grid / Measurement Pillar
              Positioned(
                left: 20,
                bottom: 10,
                top: 20,
                child: CustomPaint(
                  size: Size(24, availableHeight - 30),
                  painter: _LaserRulerTrackPainter(
                    themeColor: themeColor,
                    fraction: fraction,
                  ),
                ),
              ),

              // 2. Animated Body Silhouette Structure (Scaled with height)
              Positioned(
                bottom: 12,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: currentBodyH, end: currentBodyH),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedBodyHeight, child) {
                    final bodyWidth = (animatedBodyHeight * 0.40).clamp(100.0, availableWidth * 0.70);

                    return SizedBox(
                      width: bodyWidth,
                      height: animatedBodyHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Vector Body Line Silhouette
                          CustomPaint(
                            size: Size(bodyWidth, animatedBodyHeight),
                            painter: _BodyStructurePainter(
                              themeColor: themeColor,
                              growthFraction: fraction,
                            ),
                          ),

                          // Top Head Measurement Laser Line & Floating Tag
                          Positioned(
                            top: 0,
                            left: -10,
                            right: -10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Glowing Dot
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Dashed/solid indicator line connecting across
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          themeColor,
                                          themeColor.withValues(alpha: 0.1),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 3. Ground Base Line / Pedestal
              Positioned(
                bottom: 6,
                left: 10,
                right: 10,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        themeColor.withValues(alpha: 0.6),
                        themeColor,
                        themeColor.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 4. Floating Height Value Badge (Top Left Corner)
              Positioned(
                top: 10,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Text(
                          formattedDisplay,
                          key: ValueKey<String>(formattedDisplay),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activeUnit,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Vector Athletic Body Structure Silhouette Painter
// -------------------------------------------------------------
class _BodyStructurePainter extends CustomPainter {
  final Color themeColor;
  final double growthFraction;

  _BodyStructurePainter({
    required this.themeColor,
    required this.growthFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Body Gradient Fill
    final bodyFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor.withValues(alpha: 0.18),
          themeColor.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Body Outline Stroke
    final bodyStrokePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Spine / Center Power Line
    final spinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor,
          themeColor.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Head
    final headRadius = w * 0.13;
    final headCenterY = headRadius + (h * 0.02);
    final headCenter = Offset(cx, headCenterY);

    // Draw Head Fill & Outline
    canvas.drawCircle(headCenter, headRadius, bodyFillPaint);
    canvas.drawCircle(headCenter, headRadius, bodyStrokePaint);

    // Dynamic Body Anatomy Path (Torso, Arms, Legs)
    final path = Path();

    final neckY = headCenterY + headRadius + (h * 0.015);
    final shoulderY = neckY + (h * 0.045);
    final shoulderHalfW = w * 0.40;

    final chestY = shoulderY + (h * 0.12);
    final waistY = chestY + (h * 0.12);
    final waistHalfW = w * 0.23;

    final hipY = waistY + (h * 0.10);
    final hipHalfW = w * 0.28;

    final crotchY = hipY + (h * 0.05);
    final kneeY = crotchY + (h * 0.24);
    final feetY = h - 4.0;

    // Build anatomical silhouette
    path.moveTo(cx - (w * 0.08), neckY);

    // Left shoulder
    path.quadraticBezierTo(cx - (w * 0.20), neckY + 2, cx - shoulderHalfW, shoulderY);

    // Left arm down to hand
    path.lineTo(cx - shoulderHalfW - 8, waistY + 10);
    path.quadraticBezierTo(cx - shoulderHalfW - 6, waistY + 16, cx - shoulderHalfW - 2, waistY + 14);
    path.lineTo(cx - waistHalfW - 8, chestY + 10);

    // Left torso / waist
    path.lineTo(cx - waistHalfW, waistY);

    // Left hip
    path.quadraticBezierTo(cx - hipHalfW, hipY, cx - (hipHalfW * 0.9), crotchY);

    // Left leg down to foot
    path.lineTo(cx - (w * 0.18), kneeY);
    path.lineTo(cx - (w * 0.14), feetY);

    // Left foot
    path.lineTo(cx - (w * 0.05), feetY);

    // Inner leg to crotch
    path.lineTo(cx - 3, crotchY);
    path.lineTo(cx + 3, crotchY);

    // Right inner leg down to foot
    path.lineTo(cx + (w * 0.05), feetY);
    path.lineTo(cx + (w * 0.14), feetY);

    // Right leg up to hip
    path.lineTo(cx + (w * 0.18), kneeY);
    path.lineTo(cx + (hipHalfW * 0.9), crotchY);
    path.quadraticBezierTo(cx + hipHalfW, hipY, cx + waistHalfW, waistY);

    // Right torso / arm
    path.lineTo(cx + waistHalfW + 8, chestY + 10);
    path.lineTo(cx + shoulderHalfW + 2, waistY + 14);
    path.quadraticBezierTo(cx + shoulderHalfW + 6, waistY + 16, cx + shoulderHalfW + 8, waistY + 10);
    path.lineTo(cx + shoulderHalfW, shoulderY);

    // Right shoulder to neck
    path.quadraticBezierTo(cx + (w * 0.20), neckY + 2, cx + (w * 0.08), neckY);
    path.close();

    // Draw Filled Anatomy & Stroke
    canvas.drawPath(path, bodyFillPaint);
    canvas.drawPath(path, bodyStrokePaint);

    // Draw Glowing Spine Line
    canvas.drawLine(
      Offset(cx, neckY + 4),
      Offset(cx, crotchY - 8),
      spinePaint,
    );

    // Draw Joint Accent Points (Shoulders, Knees, Feet)
    final jointPaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.fill;

    // Shoulder Nodes
    canvas.drawCircle(Offset(cx - (shoulderHalfW * 0.8), shoulderY + 4), 3.0, jointPaint);
    canvas.drawCircle(Offset(cx + (shoulderHalfW * 0.8), shoulderY + 4), 3.0, jointPaint);

    // Knee Nodes
    canvas.drawCircle(Offset(cx - (w * 0.14), kneeY), 3.0, jointPaint);
    canvas.drawCircle(Offset(cx + (w * 0.14), kneeY), 3.0, jointPaint);

    // Chest Core Node
    final pulseGlowPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, chestY), 6.5, pulseGlowPaint);
    canvas.drawCircle(Offset(cx, chestY), 3.5, jointPaint);
  }

  @override
  bool shouldRepaint(covariant _BodyStructurePainter oldDelegate) =>
      oldDelegate.themeColor != themeColor ||
      oldDelegate.growthFraction != growthFraction;
}

// -------------------------------------------------------------
// Laser Ruler Track Painter (Left side futuristic scale)
// -------------------------------------------------------------
class _LaserRulerTrackPainter extends CustomPainter {
  final Color themeColor;
  final double fraction;

  _LaserRulerTrackPainter({
    required this.themeColor,
    required this.fraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.0;

    final activeTrackPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;

    // Vertical line
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), trackPaint);

    // Active height track from bottom to fraction level
    final activeTopY = size.height * (1.0 - fraction);
    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width / 2, activeTopY),
      activeTrackPaint,
    );

    // Subtle horizontal ticks along track
    const totalTicks = 12;
    for (int i = 0; i <= totalTicks; i++) {
      final y = size.height * (i / totalTicks);
      final isMajor = i % 3 == 0;
      final w = isMajor ? 10.0 : 5.0;
      canvas.drawLine(
        Offset((size.width / 2) - (w / 2), y),
        Offset((size.width / 2) + (w / 2), y),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LaserRulerTrackPainter oldDelegate) =>
      oldDelegate.themeColor != themeColor ||
      oldDelegate.fraction != fraction;
}
