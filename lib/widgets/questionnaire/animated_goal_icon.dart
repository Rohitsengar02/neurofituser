import 'dart:math' as math;
import 'package:flutter/material.dart';

enum GoalType {
  loseWeight,
  buildMuscle,
  improveFitness,
  boostEnergy,
}

class AnimatedGoalIcon extends StatefulWidget {
  final GoalType goalType;
  final bool isSelected;
  final Color primaryColor;
  final double size;

  const AnimatedGoalIcon({
    super.key,
    required this.goalType,
    required this.isSelected,
    required this.primaryColor,
    this.size = 56.0,
  });

  @override
  State<AnimatedGoalIcon> createState() => _AnimatedGoalIconState();
}

class _AnimatedGoalIconState extends State<AnimatedGoalIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = _animController.value;

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: widget.isSelected
                  ? widget.primaryColor.withValues(alpha: 0.4)
                  : const Color(0xFFF1F5F9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? widget.primaryColor.withValues(alpha: 0.18)
                    : const Color(0xFF94A3B8).withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Virtual Background Energy Waves / Rings
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _VirtualIconEffectsPainter(
                  goalType: widget.goalType,
                  color: widget.primaryColor,
                  progress: progress,
                  isSelected: widget.isSelected,
                ),
              ),

              // 2. Animated Center Icon / Core Element
              _buildCoreIcon(progress),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoreIcon(double progress) {
    switch (widget.goalType) {
      case GoalType.loseWeight:
        // Flame breathing & floating motion
        final scale = 1.0 + (math.sin(progress * 2 * math.pi) * 0.08);
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.local_fire_department_rounded,
            color: widget.primaryColor,
            size: widget.size * 0.55,
          ),
        );

      case GoalType.buildMuscle:
        // Dumbbell subtle tilting & power glow
        final angle = math.sin(progress * 2 * math.pi) * 0.12;
        return Transform.rotate(
          angle: angle,
          child: Icon(
            Icons.fitness_center_rounded,
            color: widget.primaryColor,
            size: widget.size * 0.52,
          ),
        );

      case GoalType.improveFitness:
        // Heart pulse rhythm (two beats per cycle)
        final beatProgress = (progress * 2) % 1.0;
        final pulseScale = beatProgress < 0.2
            ? 1.0 + (math.sin(beatProgress * 5 * math.pi) * 0.18)
            : 1.0;
        return Transform.scale(
          scale: pulseScale,
          child: Icon(
            Icons.favorite_rounded,
            color: widget.primaryColor,
            size: widget.size * 0.52,
          ),
        );

      case GoalType.boostEnergy:
        // Lightning bolt energetic spark vibration
        final bounce = math.sin(progress * 4 * math.pi) * 2.0;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: Icon(
            Icons.bolt_rounded,
            color: widget.primaryColor,
            size: widget.size * 0.58,
          ),
        );
    }
  }
}

// -------------------------------------------------------------
// Virtual Icon Ambient Effects Custom Painter
// -------------------------------------------------------------
class _VirtualIconEffectsPainter extends CustomPainter {
  final GoalType goalType;
  final Color color;
  final double progress;
  final bool isSelected;

  _VirtualIconEffectsPainter({
    required this.goalType,
    required this.color,
    required this.progress,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (goalType) {
      case GoalType.loseWeight:
        // Rising ember particles
        if (isSelected) {
          final particlePaint = Paint()..color = color.withValues(alpha: 0.7);
          for (int i = 0; i < 3; i++) {
            final pProgress = (progress + (i * 0.33)) % 1.0;
            final pX = center.dx + (math.sin((pProgress + i) * 2 * math.pi) * (radius * 0.5));
            final pY = center.dy + (radius * 0.4) - (pProgress * radius * 0.9);
            final pRadius = (1.0 - pProgress) * 2.5;
            canvas.drawCircle(Offset(pX, pY), pRadius, particlePaint);
          }
        }
        break;

      case GoalType.buildMuscle:
        // Concentric expanding shockwave rings
        if (isSelected) {
          final ringPaint = Paint()
            ..color = color.withValues(alpha: (1.0 - progress) * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawCircle(center, radius * progress, ringPaint);
        }
        break;

      case GoalType.improveFitness:
        // Spinning energy orbit dot
        final orbitPaint = Paint()..color = color.withValues(alpha: isSelected ? 0.9 : 0.4);
        final angle = progress * 2 * math.pi;
        final orbitRadius = radius - 3.0;
        final orbitPos = Offset(
          center.dx + math.cos(angle) * orbitRadius,
          center.dy + math.sin(angle) * orbitRadius,
        );
        canvas.drawCircle(orbitPos, isSelected ? 2.5 : 1.8, orbitPaint);
        break;

      case GoalType.boostEnergy:
        // Rotating segmented electric ring
        final ringPaint = Paint()
          ..color = color.withValues(alpha: isSelected ? 0.6 : 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;

        final startAngle = progress * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 4),
          startAngle,
          math.pi * 0.6,
          false,
          ringPaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 4),
          startAngle + math.pi,
          math.pi * 0.6,
          false,
          ringPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _VirtualIconEffectsPainter oldDelegate) => true;
}
