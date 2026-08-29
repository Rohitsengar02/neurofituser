import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBlackDumbbellHero extends StatefulWidget {
  final double size;

  const AnimatedBlackDumbbellHero({
    super.key,
    this.size = 86.0,
  });

  @override
  State<AnimatedBlackDumbbellHero> createState() => _AnimatedBlackDumbbellHeroState();
}

class _AnimatedBlackDumbbellHeroState extends State<AnimatedBlackDumbbellHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
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
        final floatOffset = math.sin(_floatController.value * math.pi) * 4.5;
        final rotationAngle = -math.pi / 4 + (math.sin(_floatController.value * math.pi) * 0.05);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft Emerald Aura Glow
              Container(
                width: widget.size * 0.95,
                height: widget.size * 0.95,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x3522C55E),
                      Color(0x1586EFAC),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
                ),
              ),

              // 2. Glassmorphic Sphere Background
              Container(
                width: widget.size * 0.78,
                height: widget.size * 0.78,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE8FDF0),
                      Color(0xFFDCFCE7),
                      Color(0xFFBBF7D0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x2822C55E),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),

              // 3. Floating 3D Obsidian Black & Green Dumbbell
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.rotate(
                  angle: rotationAngle,
                  child: CustomPaint(
                    size: Size(widget.size * 0.54, widget.size * 0.34),
                    painter: _BlackDumbbell3DPainter(),
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

class _BlackDumbbell3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Drop shadow behind dumbbell
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(1.5, 3.5), width: size.width * 0.9, height: size.height * 0.65),
        const Radius.circular(6),
      ),
      shadowPaint,
    );

    // 1. Center Handle (Vibrant Emerald Green Bar)
    final handleRect = Rect.fromCenter(center: center, width: size.width * 0.48, height: 6.5);
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(handleRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(3.0)),
      handlePaint,
    );

    // Handle end caps
    final leftCap = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.05, size.height / 2), width: 4.5, height: 8),
      const Radius.circular(2),
    );
    final rightCap = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.95, size.height / 2), width: 4.5, height: 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(leftCap, handlePaint);
    canvas.drawRRect(rightCap, handlePaint);

    // 2. Inner Weights (Matte Charcoal Black)
    final leftInnerWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.22, size.height / 2), width: 6.5, height: 22),
      const Radius.circular(2.5),
    );
    final rightInnerWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.78, size.height / 2), width: 6.5, height: 22),
      const Radius.circular(2.5),
    );

    final innerWeightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF374151), Color(0xFF1F2937), Color(0xFF111827)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(leftInnerWeight, innerWeightPaint);
    canvas.drawRRect(rightInnerWeight, innerWeightPaint);

    // 3. Outer Heavy Weights (Deep Black with 3D bevel)
    final leftOuterWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.12, size.height / 2), width: 8.5, height: 28),
      const Radius.circular(3.5),
    );
    final rightOuterWeight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.88, size.height / 2), width: 8.5, height: 28),
      const Radius.circular(3.5),
    );

    final outerWeightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4B5563), Color(0xFF1F2937), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(leftOuterWeight, outerWeightPaint);
    canvas.drawRRect(rightOuterWeight, outerWeightPaint);

    // 4. Subtle Specular Highlight Rim on Black Weights
    final rimPaint = Paint()
      ..color = const Color(0x669CA3AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(leftOuterWeight, rimPaint);
    canvas.drawRRect(rightOuterWeight, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
