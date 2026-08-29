import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';

class PlanGenerationScreen extends StatefulWidget {
  final String gender;
  final int age;
  final double currentWeight;
  final double targetWeight;
  final double height;
  final List<String> goals;
  final String activityLevel;

  const PlanGenerationScreen({
    super.key,
    required this.gender,
    required this.age,
    required this.currentWeight,
    required this.targetWeight,
    required this.height,
    required this.goals,
    required this.activityLevel,
  });

  @override
  State<PlanGenerationScreen> createState() => _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends State<PlanGenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  int _currentPhase = 0; // 0, 1, 2, 3, 4 (completed)
  bool _isComplete = false;

  final List<_PhaseData> _phases = [
    _PhaseData(
      title: 'Analyzing Body Metrics',
      subtitle: 'Calculating BMR, ideal body composition & starting baseline...',
      icon: Icons.monitor_heart_rounded,
      color: const Color(0xFF06B6D4), // Cyan
      badgeText: 'BIOMETRICS',
    ),
    _PhaseData(
      title: 'Generating Workout Protocol',
      subtitle: 'Building AI training splits & recovery schedules...',
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFF22C55E), // Neon Green
      badgeText: 'TRAINING',
    ),
    _PhaseData(
      title: 'Formulating Nutrition & Diet',
      subtitle: 'Customizing macro ratios, calories & meal timing...',
      icon: Icons.restaurant_menu_rounded,
      color: const Color(0xFFF59E0B), // Amber Gold
      badgeText: 'NUTRITION',
    ),
    _PhaseData(
      title: 'Finalizing Smart Dashboard',
      subtitle: 'Calibrating AI coach, daily targets & habit trackers...',
      icon: Icons.dashboard_customize_rounded,
      color: const Color(0xFF8B5CF6), // Royal Purple
      badgeText: 'DASHBOARD',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );

    _progressController.addListener(() {
      final val = _progressController.value;
      int newPhase = 0;
      if (val >= 0.88) {
        newPhase = 3;
      } else if (val >= 0.58) {
        newPhase = 2;
      } else if (val >= 0.28) {
        newPhase = 1;
      } else {
        newPhase = 0;
      }

      if (newPhase != _currentPhase) {
        HapticFeedback.mediumImpact();
        setState(() {
          _currentPhase = newPhase;
        });
      }
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isComplete = true;
        });
      }
    });

    // Start simulation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePhaseData = _phases[_currentPhase.clamp(0, 3)];

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F), // Deep Dark Cinematic Background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Glow Orbs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activePhaseData.color.withValues(alpha: 0.18),
                boxShadow: [
                  BoxShadow(
                    color: activePhaseData.color.withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Processing Content Area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Top Brand / Processing Status Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isComplete
                                  ? const Color(0xFF22C55E)
                                  : activePhaseData.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: activePhaseData.color.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isComplete ? 'PLAN GENERATED' : 'AI CALIBRATION ENGINE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),

                      // Phase Badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: activePhaseData.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: activePhaseData.color.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _isComplete ? 'READY' : activePhaseData.badgeText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: _isComplete ? const Color(0xFF22C55E) : activePhaseData.color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Center Holographic Orbital Icon Portal
                  _buildHologramPortal(activePhaseData),

                  const SizedBox(height: 28),

                  // Dynamic Title & Subtitle Animated Switcher
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Column(
                      key: ValueKey<int>(_isComplete ? 99 : _currentPhase),
                      children: [
                        Text(
                          _isComplete
                              ? 'Your Personalized Plan is Ready!'
                              : activePhaseData.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isComplete
                              ? 'Tailored workout schedule, nutrition targets & analytics are live.'
                              : activePhaseData.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Animated Progress Bar & Percentage
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      final percentage = (_progressController.value * 100).toInt();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isComplete ? 'Synthesis Complete' : 'Optimizing routine...',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: activePhaseData.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Custom Glowing Progress Track
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: constraints.maxWidth * _progressController.value,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF06B6D4),
                                            activePhaseData.color,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: activePhaseData.color.withValues(alpha: 0.6),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Multi-Step Checklist
                  _buildChecklist(),

                  const Spacer(flex: 1),

                  // Bottom Action Button (Appears on completion with looping animation)
                  if (_isComplete)
                    _buildCompletionButton()
                  else
                    const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Center Hologram Portal with Rotating Rings & Virtual Icon
  // -------------------------------------------------------------
  Widget _buildHologramPortal(_PhaseData activePhase) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        final rot = _rotationController.value * 2 * math.pi;
        final pulse = 1.0 + (_pulseController.value * 0.06);

        return SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Rotating Segmented Neon Ring
              Transform.rotate(
                angle: rot,
                child: CustomPaint(
                  size: const Size(170, 170),
                  painter: _OrbitalRingPainter(
                    color: _isComplete ? const Color(0xFF22C55E) : activePhase.color,
                  ),
                ),
              ),

              // Counter-Rotating Inner Particle Ring
              Transform.rotate(
                angle: -rot * 1.5,
                child: CustomPaint(
                  size: const Size(130, 130),
                  painter: _OrbitalParticlePainter(
                    color: _isComplete ? const Color(0xFF22C55E) : activePhase.color,
                  ),
                ),
              ),

              // Glowing Core Orb with Virtual Icon
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (_isComplete ? const Color(0xFF22C55E) : activePhase.color)
                            .withValues(alpha: 0.3),
                        const Color(0xFF13151F),
                      ],
                    ),
                    border: Border.all(
                      color: (_isComplete ? const Color(0xFF22C55E) : activePhase.color)
                          .withValues(alpha: 0.8),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isComplete ? const Color(0xFF22C55E) : activePhase.color)
                            .withValues(alpha: 0.45),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: Icon(
                      _isComplete ? Icons.check_circle_rounded : activePhase.icon,
                      key: ValueKey<int>(_isComplete ? 99 : _currentPhase),
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Live Checklist Items
  // -------------------------------------------------------------
  Widget _buildChecklist() {
    final items = [
      'Biometric profile & metabolic rate calibrated',
      'Targeted workout splits & exercise pool generated',
      'Macro targets & dietary schedule formulated',
      'Live AI dashboard & analytics initialized',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final isDone = _currentPhase > index || _isComplete;
          final isCurrent = _currentPhase == index && !_isComplete;

          return Padding(
            padding: EdgeInsets.only(bottom: index < items.length - 1 ? 10.0 : 0.0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF22C55E)
                        : (isCurrent
                            ? _phases[index].color.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05)),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF22C55E)
                          : (isCurrent ? _phases[index].color : Colors.white.withValues(alpha: 0.15)),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : (isCurrent
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _phases[index].color,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isDone
                          ? Colors.white
                          : (isCurrent
                              ? _phases[index].color
                              : Colors.white.withValues(alpha: 0.35)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // -------------------------------------------------------------
  // Final Completion Enter Dashboard Button with Looping Arrow
  // -------------------------------------------------------------
  Widget _buildCompletionButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                (route) => false,
              );
            },
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF22C55E), // Neon Green
                    Color(0xFF16A34A),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter My Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _LoopingGlowArrow(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Helper Phase Data Class
// -------------------------------------------------------------
class _PhaseData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String badgeText;

  _PhaseData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badgeText,
  });
}

// -------------------------------------------------------------
// Orbital Outer Neon Ring Painter
// -------------------------------------------------------------
class _OrbitalRingPainter extends CustomPainter {
  final Color color;

  _OrbitalRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Segmented Arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      0,
      math.pi * 0.4,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      math.pi * 0.7,
      math.pi * 0.4,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      math.pi * 1.4,
      math.pi * 0.4,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

// -------------------------------------------------------------
// Orbital Particle Painter
// -------------------------------------------------------------
class _OrbitalParticlePainter extends CustomPainter {
  final Color color;

  _OrbitalParticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    const totalDots = 6;
    for (int i = 0; i < totalDots; i++) {
      final angle = i * (2 * math.pi / totalDots);
      final dotPos = Offset(
        center.dx + math.cos(angle) * (radius - 2),
        center.dy + math.sin(angle) * (radius - 2),
      );
      canvas.drawCircle(dotPos, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalParticlePainter oldDelegate) =>
      oldDelegate.color != color;
}

// -------------------------------------------------------------
// Looping Animated Glow Arrow for the Final Action Button
// -------------------------------------------------------------
class _LoopingGlowArrow extends StatefulWidget {
  const _LoopingGlowArrow();

  @override
  State<_LoopingGlowArrow> createState() => _LoopingGlowArrowState();
}

class _LoopingGlowArrowState extends State<_LoopingGlowArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = 5.0 * _controller.value;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 20,
          ),
        );
      },
    );
  }
}
