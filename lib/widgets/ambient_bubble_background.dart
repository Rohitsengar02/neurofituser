import 'dart:math' as math;
import 'package:flutter/material.dart';

class AmbientBubbleBackground extends StatefulWidget {
  final Widget child;

  const AmbientBubbleBackground({
    super.key,
    required this.child,
  });

  @override
  State<AmbientBubbleBackground> createState() => _AmbientBubbleBackgroundState();
}

class _AmbientBubbleBackgroundState extends State<AmbientBubbleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        final progress = _bubbleController.value;
        final float1 = math.sin(progress * math.pi) * 12.0;
        final float2 = math.cos(progress * math.pi) * 10.0;
        final scale1 = 1.0 + (progress * 0.08);
        final scale2 = 1.0 + ((1.0 - progress) * 0.08);

        return Stack(
          children: [
            // 1. Top-Right Dark Obsidian Floating Ambient Bubble
            Positioned(
              top: -40 + float1,
              right: -30 + float2,
              child: Transform.scale(
                scale: scale1,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x1C111318),
                        Color(0x0E1F2937),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Top-Left Soft Emerald / Dark Mint Glowing Bubble
            Positioned(
              top: -30 - float2,
              left: -40 + float1,
              child: Transform.scale(
                scale: scale2,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x1A22C55E),
                        Color(0x0C16A34A),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Center-Top Floating Micro Dark Bubble
            Positioned(
              top: 50 + (float1 * 0.6),
              right: 90 + (float2 * 0.8),
              child: Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x180F172A),
                      Color(0x08334155),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // Main Content
            widget.child,
          ],
        );
      },
    );
  }
}
