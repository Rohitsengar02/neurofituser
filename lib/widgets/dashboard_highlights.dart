import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/active_workout_screen.dart';
import '../screens/date_nutrition_detail_screen.dart';
import '../screens/shop_screen.dart';
import 'dashboard_motion.dart';

// Shared text helpers ---------------------------------------------------------
TextStyle _jakarta(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
  double spacing = 0,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: spacing,
);

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);

// =============================================================================
// OVERVIEW: This week's activity, an animated bar chart with a metric switch.
// =============================================================================
class WeeklyActivityCard extends StatefulWidget {
  const WeeklyActivityCard({super.key});

  @override
  State<WeeklyActivityCard> createState() => _WeeklyActivityCardState();
}

class _WeeklyActivityCardState extends State<WeeklyActivityCard>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF16A34A);
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const _metrics = [
    _Metric(
      'Steps',
      '',
      [6200, 8100, 7400, 10350, 9200, 5600, 8542],
      10000,
      Icons.directions_walk_rounded,
    ),
    _Metric(
      'Kcal',
      'kcal',
      [410, 520, 380, 610, 560, 300, 461],
      600,
      Icons.local_fire_department_rounded,
    ),
    _Metric(
      'Minutes',
      'min',
      [35, 48, 30, 62, 55, 20, 42],
      60,
      Icons.timer_rounded,
    ),
  ];

  int _metric = 0;
  late int _selectedDay;
  late final AnimationController _grow;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday - 1;
    _grow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        whenRevealed(context, () {
          if (mounted) _grow.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  void _switch(int i) {
    if (i == _metric) return;
    HapticFeedback.selectionClick();
    setState(() => _metric = i);
    _grow.forward(from: 0.0);
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics[_metric];
    final total = m.values.reduce((a, b) => a + b);
    final avg = (total / 7).round();
    final maxV = math.max(m.goal, m.values.reduce(math.max)).toDouble();
    final goalHits = m.values.where((v) => v >= m.goal).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: _green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This Week',
                    style: _jakarta(16, FontWeight.w900, _ink, spacing: -0.4),
                  ),
                ),
                _Segmented(
                  labels: _metrics.map((e) => e.label).toList(),
                  index: _metric,
                  color: _green,
                  onChanged: _switch,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(a),
                        child: c,
                      ),
                    ),
                    child: Column(
                      key: ValueKey('$_metric-$_selectedDay'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDay == DateTime.now().weekday - 1
                              ? 'Today'
                              : const [
                                  'Monday',
                                  'Tuesday',
                                  'Wednesday',
                                  'Thursday',
                                  'Friday',
                                  'Saturday',
                                  'Sunday',
                                ][_selectedDay],
                          style: _jakarta(11.5, FontWeight.w700, _muted),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _fmt(m.values[_selectedDay]),
                                  style: _jakarta(
                                    26,
                                    FontWeight.w900,
                                    _ink,
                                    spacing: -0.8,
                                  ),
                                ),
                                TextSpan(
                                  text: m.unit.isEmpty
                                      ? ' steps'
                                      : ' ${m.unit}',
                                  style: _jakarta(12, FontWeight.w700, _muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _miniStat('Avg', _fmt(avg)),
                const SizedBox(width: 8),
                _miniStat('Goal hit', '$goalHits/7'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 136,
              child: AnimatedBuilder(
                animation: _grow,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, c) {
                      final goalY = 8 + 104 * (1 - m.goal / maxV);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Goal line
                          Positioned(
                            left: 0,
                            right: 0,
                            top: goalY,
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 1),
                                    painter: _DashPainter(
                                      _green.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (i) {
                              final t = Curves.easeOutBack.transform(
                                ((_grow.value - i * 0.06) / 0.6).clamp(
                                  0.0,
                                  1.0,
                                ),
                              );
                              final h = math.min(112.0, (104 * m.values[i] / maxV) * t);
                              final sel = i == _selectedDay;
                              final hit = m.values[i] >= m.goal;
                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedDay = i);
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        width: sel ? 22 : 16,
                                        height: math.max(6, h),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: sel
                                                ? const [
                                                    Color(0xFF15803D),
                                                    Color(0xFF4ADE80),
                                                  ]
                                                : hit
                                                ? [
                                                    _green.withValues(
                                                      alpha: 0.55,
                                                    ),
                                                    _green.withValues(
                                                      alpha: 0.35,
                                                    ),
                                                  ]
                                                : const [
                                                    Color(0xFFE2E8F0),
                                                    Color(0xFFF1F5F9),
                                                  ],
                                          ),
                                          boxShadow: sel
                                              ? [
                                                  BoxShadow(
                                                    color: _green.withValues(
                                                      alpha: 0.4,
                                                    ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _days[i],
                                        style: _jakarta(
                                          11,
                                          sel
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          sel ? _green : _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _jakarta(9.5, FontWeight.w700, _muted)),
          Text(value, style: _jakarta(12.5, FontWeight.w900, _ink)),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final String unit;
  final List<int> values;
  final int goal;
  final IconData icon;
  const _Metric(this.label, this.unit, this.values, this.goal, this.icon);
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final Color color;
  final ValueChanged<int> onChanged;

  const _Segmented({
    required this.labels,
    required this.index,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final sel = i == index;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[i],
                style: _jakarta(10.5, FontWeight.w800, sel ? color : _muted),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 5, size.width), 0), p);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}

// =============================================================================
// WORKOUT: weekly goal with day checks, a progress ring and a resume button.
// =============================================================================
class WorkoutWeekGoalCard extends StatefulWidget {
  const WorkoutWeekGoalCard({super.key});

  @override
  State<WorkoutWeekGoalCard> createState() => _WorkoutWeekGoalCardState();
}

class _WorkoutWeekGoalCardState extends State<WorkoutWeekGoalCard>
    with TickerProviderStateMixin {
  static const _done = [true, true, false, true, false, false, false];
  static const _goal = 5;
  late final AnimationController _in;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        whenRevealed(context, () {
          if (mounted) _in.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _done.where((d) => d).length;
    final today = DateTime.now().weekday - 1;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B0764), Color(0xFF6D28D9), Color(0xFF9333EA)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -50,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -60,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'WEEKLY GOAL',
                                  style: _jakarta(
                                    9.5,
                                    FontWeight.w900,
                                    Colors.white,
                                    spacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$doneCount',
                                        style: _jakarta(
                                          30,
                                          FontWeight.w900,
                                          Colors.white,
                                          spacing: -1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / $_goal workouts',
                                        style: _jakarta(
                                          14,
                                          FontWeight.w700,
                                          Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                '${_goal - doneCount} more to keep your streak alive',
                                maxLines: 2,
                                style: _jakarta(
                                  11.5,
                                  FontWeight.w600,
                                  Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: AnimatedBuilder(
                            animation: _in,
                            builder: (_, __) => CustomPaint(
                              painter: _RingPainter(
                                Curves.easeOutCubic.transform(_in.value) *
                                    doneCount /
                                    _goal,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      '${(100 * doneCount / _goal * _in.value).round()}%',
                                      style: _jakarta(
                                        12,
                                        FontWeight.w900,
                                        Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Day chips pop in one by one
                    Row(
                      children: List.generate(7, (i) {
                        return Expanded(
                          child: AnimatedBuilder(
                            animation: _in,
                            builder: (_, __) {
                              final t = Curves.easeOutBack.transform(
                                ((_in.value - 0.2 - i * 0.07) / 0.4).clamp(
                                  0.0,
                                  1.0,
                                ),
                              );
                              final isToday = i == today;
                              return Transform.scale(
                                scale: 0.4 + 0.6 * t,
                                child: Opacity(
                                  opacity: t.clamp(0.0, 1.0),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _done[i]
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                          border: isToday && !_done[i]
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 1.6,
                                                )
                                              : null,
                                        ),
                                        child: _done[i]
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 17,
                                                color: Color(0xFF7C3AED),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        days[i],
                                        style: _jakarta(
                                          10.5,
                                          FontWeight.w800,
                                          Colors.white.withValues(
                                            alpha: isToday ? 1 : 0.65,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    PressScale(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActiveWorkoutScreen(
                              dayTitle: 'Upper Body Strength',
                              dayNumber: 3,
                            ),
                          ),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _shine,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment(-2 + 4 * _shine.value, 0),
                                end: Alignment(-1 + 4 * _shine.value, 0),
                                colors: const [
                                  Colors.white,
                                  Color(0xFFF3E8FF),
                                  Colors.white,
                                ],
                              ),
                            ),
                            child: child,
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFA855F7),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resume Upper Body Strength',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _jakarta(13, FontWeight.w800, _ink),
                                  ),
                                  Text(
                                    'Day 3 · 12 min left · 320 kcal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _jakarta(
                                      11,
                                      FontWeight.w600,
                                      _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  _RingPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 5;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * v.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v;
}

// =============================================================================
// NUTRITION: next meal with a live countdown and a suggested plate.
// =============================================================================
class NextMealCard extends StatefulWidget {
  const NextMealCard({super.key});

  @override
  State<NextMealCard> createState() => _NextMealCardState();
}

class _NextMealCardState extends State<NextMealCard>
    with SingleTickerProviderStateMixin {
  static const _amber = Color(0xFFD97706);
  late final AnimationController _float;
  Timer? _timer;

  static const _meals = [
    (8, 0, 'Breakfast', 'Masala oats & berries', 380, 18, '🥣'),
    (13, 0, 'Lunch', 'Grilled paneer power bowl', 540, 32, '🥗'),
    (17, 0, 'Snack', 'Greek yogurt & almonds', 220, 15, '🥜'),
    (20, 30, 'Dinner', 'Salmon, quinoa & greens', 610, 41, '🐟'),
  ];

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var next = _meals.first;
    var at = DateTime(now.year, now.month, now.day + 1, next.$1, next.$2);
    for (final m in _meals) {
      final t = DateTime(now.year, now.month, now.day, m.$1, m.$2);
      if (t.isAfter(now)) {
        next = m;
        at = t;
        break;
      }
    }
    final diff = at.difference(now);
    final h = diff.inHours;
    final min = diff.inMinutes % 60;
    final inText = h > 0 ? 'in ${h}h ${min}m' : 'in ${min}m';
    final hh = next.$1 > 12 ? next.$1 - 12 : next.$1;
    final ampm = next.$1 >= 12 ? 'PM' : 'AM';
    final timeText = '$hh:${next.$2.toString().padLeft(2, '0')} $ampm';
    // How far through the gap since the previous meal we are.
    final progress = (1 - diff.inMinutes / 300).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: PressScale(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DateNutritionDetailScreen(initialDate: now),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
            ),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: _amber.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _float,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, -4 + 8 * _float.value),
                  child: Transform.rotate(
                    angle: -0.06 + 0.12 * _float.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _amber.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(next.$7, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Next: ${next.$3}',
                          style: _jakarta(11.5, FontWeight.w800, _amber),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$timeText · $inText',
                            style: _jakarta(9.5, FontWeight.w800, Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      next.$4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _jakarta(15, FontWeight.w900, _ink, spacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _chip('${next.$5} kcal', const Color(0xFFEA580C)),
                        const SizedBox(width: 6),
                        _chip('${next.$6}g protein', const Color(0xFF16A34A)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 5,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation(_amber),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _jakarta(10, FontWeight.w800, color),
        ),
      ),
    );
  }
}

// =============================================================================
// WELLNESS: a one-minute calm moment with a breathing orb.
// =============================================================================
class CalmMomentCard extends StatefulWidget {
  const CalmMomentCard({super.key});

  @override
  State<CalmMomentCard> createState() => _CalmMomentCardState();
}

class _CalmMomentCardState extends State<CalmMomentCard>
    with TickerProviderStateMixin {
  static const _rose = Color(0xFFE11D48);
  // 4s in, 4s hold, 4s out (box-style rhythm, simplified)
  late final AnimationController _breath;
  late final AnimationController _idle;
  bool _running = false;
  int _cycles = 0;

  @override
  void initState() {
    super.initState();
    _breath =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed && _running) {
              setState(() => _cycles++);
              if (_cycles >= 5) {
                _stop();
              } else {
                _breath.forward(from: 0);
              }
            }
          });
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    if (_running) {
      _stop();
    } else {
      setState(() {
        _running = true;
        _cycles = 0;
      });
      _breath.forward(from: 0);
    }
  }

  void _stop() {
    _breath.stop();
    setState(() => _running = false);
  }

  (String, double) _phase(double t) {
    // returns label and orb scale 0..1
    if (t < 1 / 3) return ('Breathe in', Curves.easeInOut.transform(t * 3));
    if (t < 2 / 3) return ('Hold', 1.0);
    return ('Breathe out', 1 - Curves.easeInOut.transform((t - 2 / 3) * 3));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F2), Color(0xFFFCE7F3), Color(0xFFEDE9FE)],
          ),
          border: Border.all(color: const Color(0xFFFBCFE8), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: _rose.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: AnimatedBuilder(
                animation: Listenable.merge([_breath, _idle]),
                builder: (_, __) {
                  final p = _running
                      ? _phase(_breath.value)
                      : ('Ready', 0.35 + 0.15 * _idle.value);
                  final s = 0.55 + 0.45 * p.$2;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          width: 112 * (s + (2 - i) * 0.0) * (0.7 + i * 0.15),
                          height: 112 * s * (0.7 + i * 0.15),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              const Color(0xFFF9A8D4),
                              const Color(0xFFC4B5FD),
                              i / 2,
                            )!.withValues(alpha: 0.28 - i * 0.07),
                          ),
                        ),
                      Container(
                        width: 58 * s + 14,
                        height: 58 * s + 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFB7185), Color(0xFFA78BFA)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _rose.withValues(alpha: 0.35),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: FittedBox(
                            child: Text(
                              p.$1,
                              style: _jakarta(
                                10.5,
                                FontWeight.w900,
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'One-minute calm',
                    style: _jakarta(16, FontWeight.w900, _ink, spacing: -0.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _running
                        ? 'Breath ${_cycles + 1} of 5 · follow the circle'
                        : 'Five slow breaths to reset your nervous system.',
                    style: _jakarta(
                      11.5,
                      FontWeight.w600,
                      _muted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressScale(
                    onTap: _toggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _running ? Colors.white : _rose,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _rose, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: _rose.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                            color: _running ? _rose : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _running ? 'Pause' : 'Start',
                            style: _jakarta(
                              12.5,
                              FontWeight.w800,
                              _running ? _rose : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHOP: a flash sale strip with a live countdown and a light sweep.
// =============================================================================
class FlashDealStrip extends StatefulWidget {
  const FlashDealStrip({super.key});

  @override
  State<FlashDealStrip> createState() => _FlashDealStripState();
}

class _FlashDealStripState extends State<FlashDealStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day + 1);
    final left = end.difference(now);
    String two(int n) => n.toString().padLeft(2, '0');
    final parts = [
      two(left.inHours),
      two(left.inMinutes % 60),
      two(left.inSeconds % 60),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PressScale(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ShopScreen(initialCategory: 'Supplements'),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0C4A6E), Color(0xFF0369A1), Color(0xFF0EA5E9)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Moving light sweep
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (_, __) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-3 + 5 * _sweep.value, -1),
                          end: Alignment(-2 + 5 * _sweep.value, 1),
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFACC15,
                              ).withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF0C4A6E),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flash Sale',
                              style: _jakarta(
                                15,
                                FontWeight.w900,
                                Colors.white,
                                spacing: -0.3,
                              ),
                            ),
                            Text(
                              'Up to 40% off supplements',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jakarta(
                                11,
                                FontWeight.w600,
                                Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  ':',
                                  style: _jakarta(
                                    14,
                                    FontWeight.w900,
                                    Colors.white,
                                  ),
                                ),
                              ),
                            _timeBox(parts[i]),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeBox(String v) {
    return Container(
      width: 30,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(a),
          child: FadeTransition(opacity: a, child: c),
        ),
        child: Text(
          v,
          key: ValueKey(v),
          style: _jakarta(12.5, FontWeight.w900, const Color(0xFF0C4A6E)),
        ),
      ),
    );
  }
}
