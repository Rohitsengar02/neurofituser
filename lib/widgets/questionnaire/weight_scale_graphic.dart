import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightScaleGraphic extends StatelessWidget {
  final double weight;
  final double minWeight;
  final double maxWeight;
  final bool isNeonGreen;

  const WeightScaleGraphic({
    super.key,
    required this.weight,
    this.minWeight = 40.0,
    this.maxWeight = 140.0,
    this.isNeonGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: weight, end: weight),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, animatedWeight, child) {
        // Calculate needle angle between -135 deg to +135 deg based on weight range
        final fraction = ((animatedWeight - minWeight) / (maxWeight - minWeight)).clamp(0.0, 1.0);
        final needleAngle = (-math.pi * 0.75) + (fraction * math.pi * 1.5);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.18),
                    border: Border.all(
                      color: isNeonGreen ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF), 
                      width: size * 0.012,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isNeonGreen ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)).withValues(alpha: 0.1),
                        blurRadius: size * 0.1,
                        offset: Offset(0, size * 0.05),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(size * 0.05),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFB), // Very Light Inner Chassis
                      borderRadius: BorderRadius.circular(size * 0.14),
                      border: Border.all(
                        color: isNeonGreen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), 
                        width: size * 0.008,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: size * 0.06, vertical: size * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Top Analog Gauge Dial
                        Container(
                          width: size * 0.38,
                          height: size * 0.38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
                                blurRadius: size * 0.03,
                                offset: Offset(0, size * 0.015),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _ScaleDialPainter(needleAngle: needleAngle, isNeonGreen: isNeonGreen),
                          ),
                        ),

                        // 2. Center Tread Grip Lines
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (index) => Container(
                              width: size * 0.12,
                              height: size * 0.015,
                              margin: EdgeInsets.symmetric(horizontal: size * 0.012),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(size * 0.01),
                              ),
                            ),
                          ),
                        ),

                        // 3. Bottom LCD Digital Display
                        Container(
                          width: size * 0.65,
                          padding: EdgeInsets.symmetric(vertical: size * 0.035, horizontal: size * 0.05),
                          decoration: BoxDecoration(
                            color: isNeonGreen ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF), 
                            borderRadius: BorderRadius.circular(size * 0.06),
                            border: Border.all(
                              color: isNeonGreen ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE), 
                              width: size * 0.006,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  animatedWeight.toStringAsFixed(1),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: size * 0.095,
                                    fontWeight: FontWeight.w900,
                                    color: isNeonGreen ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8), 
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(width: size * 0.02),
                                Text(
                                  'kg',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: size * 0.055,
                                    fontWeight: FontWeight.w700,
                                    color: isNeonGreen ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
        );
      },
    );
  }
}

class _ScaleDialPainter extends CustomPainter {
  final double needleAngle;
  final bool isNeonGreen;

  _ScaleDialPainter({required this.needleAngle, this.isNeonGreen = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Dial Ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = radius * 0.025
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = radius * 0.045
      ..strokeCap = StrokeCap.round;

    const totalTicks = 28;
    for (int i = 0; i < totalTicks; i++) {
      final angle = (-math.pi * 0.75) + (i * (math.pi * 1.5) / (totalTicks - 1));
      final isMajor = i % 4 == 0;
      final innerR = radius - (isMajor ? radius * 0.25 : radius * 0.15);
      final outerR = radius - radius * 0.06;

      final p1 = Offset(center.dx + math.cos(angle) * innerR, center.dy + math.sin(angle) * innerR);
      final p2 = Offset(center.dx + math.cos(angle) * outerR, center.dy + math.sin(angle) * outerR);

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    // Draw Center Pivot
    final pivotPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(center, radius * 0.1, pivotPaint);

    // Draw Needle
    final needlePaint = Paint()
      ..color = isNeonGreen ? const Color(0xFF16A34A) : const Color(0xFFDC2626) // Green or Red Needle
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round;

    final needleLength = radius - radius * 0.22;
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * needleLength,
      center.dy + math.sin(needleAngle) * needleLength,
    );

    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _ScaleDialPainter oldDelegate) =>
      oldDelegate.needleAngle != needleAngle;
}
