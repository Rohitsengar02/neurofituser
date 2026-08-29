import 'dart:math' as math;
import 'package:flutter/material.dart';

// -------------------------------------------------------------
// 1. OVERVIEW: 3D Green Equalizer Bars
// -------------------------------------------------------------
class Overview3DIcon extends StatelessWidget {
  final double size;
  const Overview3DIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Overview3DPainter(),
      ),
    );
  }
}

class _Overview3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final barWidth = w * 0.22;
    final spacing = w * 0.10;
    final radius = Radius.circular(barWidth / 2);

    final bars = [
      {'height': h * 0.65, 'left': w * 0.08, 'color1': const Color(0xFF4ADE80), 'color2': const Color(0xFF16A34A)},
      {'height': h * 0.95, 'left': w * 0.08 + barWidth + spacing, 'color1': const Color(0xFF22C55E), 'color2': const Color(0xFF15803D)},
      {'height': h * 0.50, 'left': w * 0.08 + (barWidth + spacing) * 2, 'color1': const Color(0xFF86EFAC), 'color2': const Color(0xFF16A34A)},
    ];

    for (final bar in bars) {
      final barH = bar['height'] as double;
      final left = bar['left'] as double;
      final color1 = bar['color1'] as Color;
      final color2 = bar['color2'] as Color;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, h - barH, barWidth, barH),
        radius,
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color1, color2],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);

      // Top Highlight Gloss
      final highlightRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 1.5, h - barH + 1.5, barWidth - 3, barWidth * 0.8),
        Radius.circular((barWidth - 3) / 2),
      );
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45);
      canvas.drawRRect(highlightRect, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// 2. WORKOUTS: 3D Purple Dumbbell
// -------------------------------------------------------------
class Workouts3DIcon extends StatelessWidget {
  final double size;
  const Workouts3DIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Workouts3DPainter(),
      ),
    );
  }
}

class _Workouts3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2;

    // Center Bar
    final barPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC084FC), Color(0xFF7E22CE)],
      ).createShader(Rect.fromLTWH(w * 0.25, cy - 3, w * 0.50, 6))
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, cy - 3, w * 0.50, 6),
        const Radius.circular(3),
      ),
      barPaint,
    );

    // Left & Right Weight Plates
    void drawPlate(double left, double width, double height) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, cy - (height / 2), width, height),
        Radius.circular(width * 0.4),
      );
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA855F7), Color(0xFF6B21A8)],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);

      // Inner Accent Rim
      final rim = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 1.5, cy - (height / 2) + 1.5, width - 3, height - 3),
        Radius.circular((width - 3) * 0.4),
      );
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(rim, rimPaint);
    }

    drawPlate(w * 0.05, w * 0.22, h * 0.75);
    drawPlate(w * 0.73, w * 0.22, h * 0.75);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// 3. NUTRITION: 3D Golden Yellow Salad Bowl & Sprout
// -------------------------------------------------------------
class Nutrition3DIcon extends StatelessWidget {
  final double size;
  const Nutrition3DIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Nutrition3DPainter(),
      ),
    );
  }
}

class _Nutrition3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Green Sprouting Leaves (Top)
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF86EFAC), Color(0xFF16A34A)],
      ).createShader(Rect.fromLTWH(w * 0.3, 0, w * 0.4, h * 0.4));

    final leafPath1 = Path()
      ..moveTo(w * 0.5, h * 0.42)
      ..quadraticBezierTo(w * 0.25, h * 0.25, w * 0.35, h * 0.10)
      ..quadraticBezierTo(w * 0.55, h * 0.20, w * 0.5, h * 0.42);
    canvas.drawPath(leafPath1, leafPaint);

    final leafPath2 = Path()
      ..moveTo(w * 0.5, h * 0.42)
      ..quadraticBezierTo(w * 0.75, h * 0.25, w * 0.65, h * 0.10)
      ..quadraticBezierTo(w * 0.45, h * 0.20, w * 0.5, h * 0.42);
    canvas.drawPath(leafPath2, leafPaint);

    // Golden Yellow Bowl (Bottom)
    final bowlRect = Rect.fromLTWH(w * 0.10, h * 0.38, w * 0.80, h * 0.54);
    final bowlPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ).createShader(bowlRect);

    final bowlPath = Path()
      ..moveTo(w * 0.12, h * 0.42)
      ..lineTo(w * 0.88, h * 0.42)
      ..quadraticBezierTo(w * 0.85, h * 0.88, w * 0.50, h * 0.92)
      ..quadraticBezierTo(w * 0.15, h * 0.88, w * 0.12, h * 0.42)
      ..close();

    canvas.drawPath(bowlPath, bowlPaint);

    // Bowl Rim Highlight
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.14, h * 0.43), Offset(w * 0.86, h * 0.43), rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// 4. MENTAL HEALTH: 3D Glowing Pink Lotus
// -------------------------------------------------------------
class MentalHealth3DIcon extends StatelessWidget {
  final double size;
  const MentalHealth3DIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MentalHealth3DPainter(),
      ),
    );
  }
}

class _MentalHealth3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final petalPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Left Petal
    final leftPath = Path()
      ..moveTo(cx, h * 0.88)
      ..quadraticBezierTo(w * 0.05, h * 0.60, w * 0.18, h * 0.35)
      ..quadraticBezierTo(w * 0.42, h * 0.55, cx, h * 0.88);
    canvas.drawPath(leftPath, petalPaint);

    // Right Petal
    final rightPath = Path()
      ..moveTo(cx, h * 0.88)
      ..quadraticBezierTo(w * 0.95, h * 0.60, w * 0.82, h * 0.35)
      ..quadraticBezierTo(w * 0.58, h * 0.55, cx, h * 0.88);
    canvas.drawPath(rightPath, petalPaint);

    // Center Main Petal (Front)
    final centerPetalPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF9A8D4), Color(0xFFBE185D)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final centerPath = Path()
      ..moveTo(cx, h * 0.15)
      ..quadraticBezierTo(w * 0.72, h * 0.48, cx, h * 0.88)
      ..quadraticBezierTo(w * 0.28, h * 0.48, cx, h * 0.15);
    canvas.drawPath(centerPath, centerPetalPaint);

    // Center Glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.10, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// 5. SHOP: 3D Blue Shopping Bag
// -------------------------------------------------------------
class Shop3DIcon extends StatelessWidget {
  final double size;
  const Shop3DIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Shop3DPainter(),
      ),
    );
  }
}

class _Shop3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bag Handle (Arch)
    final handlePaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.32, h * 0.08, w * 0.36, h * 0.36),
      math.pi,
      math.pi,
      false,
      handlePaint,
    );

    // Bag Body
    final bagPath = Path()
      ..moveTo(w * 0.22, h * 0.32)
      ..lineTo(w * 0.78, h * 0.32)
      ..lineTo(w * 0.85, h * 0.88)
      ..quadraticBezierTo(w * 0.85, h * 0.94, w * 0.78, h * 0.94)
      ..lineTo(w * 0.22, h * 0.94)
      ..quadraticBezierTo(w * 0.15, h * 0.94, w * 0.15, h * 0.88)
      ..close();

    final bagPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(bagPath, bagPaint);

    // Front Fold / Highlight
    final foldPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.5, h * 0.34), Offset(w * 0.5, h * 0.75), foldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// SUB CATEGORY 3D/STYLIZED VECTOR ICONS
// -------------------------------------------------------------
class SubCategory3DIcon extends StatelessWidget {
  final int index; // 0: All, 1: Strength, 2: Cardio, 3: Yoga, 4: HIIT, 5: Mobility
  final Color themeColor;
  final bool isSelected;
  final double size;

  const SubCategory3DIcon({
    super.key,
    required this.index,
    required this.themeColor,
    this.isSelected = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      // "All" Tab: Squircle with 4 dots
      return Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: themeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                4,
                (i) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Other Subcategories: White background circle with 3D/Color adapted vector icon
    IconData iconData;
    switch (index) {
      case 1:
        iconData = Icons.fitness_center_rounded; // Strength / Bicep
        break;
      case 2:
        iconData = Icons.favorite_rounded; // Cardio / Heartbeat
        break;
      case 3:
        iconData = Icons.self_improvement_rounded; // Yoga / Lotus
        break;
      case 4:
        iconData = Icons.bolt_rounded; // HIIT / Lightning
        break;
      case 5:
      default:
        iconData = Icons.directions_run_rounded; // Mobility / Running
        break;
    }

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? themeColor : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: isSelected ? themeColor : themeColor.withValues(alpha: 0.85),
          size: size,
        ),
      ),
    );
  }
}
