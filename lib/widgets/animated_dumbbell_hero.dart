import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedDumbbellHero extends StatefulWidget {
  final double size;

  const AnimatedDumbbellHero({
    super.key,
    this.size = 80.0,
  });

  @override
  State<AnimatedDumbbellHero> createState() => _AnimatedDumbbellHeroState();
}

class _AnimatedDumbbellHeroState extends State<AnimatedDumbbellHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatOffset = math.sin(_floatController.value * math.pi) * 4.0;
        final rotationAngle = -math.pi / 4 + (math.sin(_floatController.value * math.pi) * 0.05);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft Emerald Aura Glow
              Container(
                width: widget.size * 0.9,
                height: widget.size * 0.9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x4022C55E),
                      Color(0x2086EFAC),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
                ),
              ),

              // 2. Glassmorphic Sphere Background
              Container(
                width: widget.size * 0.76,
                height: widget.size * 0.76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFDCFCE7),
                      Color(0xFFBBF7D0),
                      Color(0xFF86EFAC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3322C55E),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),

              // 3. Floating 3D Metallic / White Dumbbell
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.rotate(
                  angle: rotationAngle,
                  child: CustomPaint(
                    size: Size(widget.size * 0.52, widget.size * 0.32),
                    painter: _Dumbbell3DPainter(),
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

class _Dumbbell3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Subtle drop shadow behind the dumbbell
    final shadowPaint = Paint()
      ..color = const Color(0x2A000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(1.5, 3), width: size.width * 0.9, height: size.height * 0.6),
        const Radius.circular(6),
      ),
      shadowPaint,
    );

    // 1. Center Handle
    final handleRect = Rect.fromCenter(center: center, width: size.width * 0.46, height: 6.0);
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(handleRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(3.0)),
      handlePaint,
    );

    // 2. Inner Weights
    final leftInnerWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.22, size.height / 2), width: 6.0, height: 20),
      const Radius.circular(2.5),
    );
    final rightInnerWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.78, size.height / 2), width: 6.0, height: 20),
      const Radius.circular(2.5),
    );

    final innerWeightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(leftInnerWeight, innerWeightPaint);
    canvas.drawRRect(rightInnerWeight, innerWeightPaint);

    // 3. Outer Heavy Weights
    final leftOuterWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.12, size.height / 2), width: 8.0, height: 26),
      const Radius.circular(3.5),
    );
    final rightOuterWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.88, size.height / 2), width: 8.0, height: 26),
      const Radius.circular(3.5),
    );

    final outerWeightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(leftOuterWeight, outerWeightPaint);
    canvas.drawRRect(rightOuterWeight, outerWeightPaint);

    // 4. White Specular Highlights
    final highlightPaint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.09, size.height * 0.18, 2.5, 10),
        const Radius.circular(1.2),
      ),
      highlightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.85, size.height * 0.18, 2.5, 10),
        const Radius.circular(1.2),
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
