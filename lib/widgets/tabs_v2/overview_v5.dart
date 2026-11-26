import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/active_workout_screen.dart';
import '../../screens/kemo_ai_screen.dart';
import '../../screens/log_meal_screen.dart';
import '../../screens/product_detail_screen.dart';
import '../../screens/rewards_screen.dart';
import '../../screens/shop_screen.dart';
import '../../screens/steps_screen.dart';
import '../../screens/streak_detail_screen.dart';
import '../../screens/trainers_screen.dart';
import '../../screens/transform_screen.dart';
import '../dashboard_motion.dart';
import '../kemo.dart';
import '../neuro_island_dock.dart';
import '../shop_home_sections.dart';
import 'kit.dart';

/// Overview tab built from square (1:1) cards in grids and carousels.
/// Headings and numbers only, no description lines.

const _p = Color(0xFF7C3AED);
const _gap = 12.0;
const _v4 = 'assets/images/overview_v4';
const _v3 = 'assets/images/overview_v3';
const _photos = 'assets/images';

void _push(BuildContext context, Widget screen) {
  HapticFeedback.lightImpact();
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

BoxDecoration _white({double r = 22}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: const Color(0xFFEFE9FB)),
      boxShadow: [
        BoxShadow(
          color: _p.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

BoxDecoration _tint(Color a, Color b, {double r = 22}) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      ),
      borderRadius: BorderRadius.circular(r),
      boxShadow: [
        BoxShadow(
          color: b.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );

/// Section heading with an optional link on the right.
class _Head extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const _Head(this.text, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(17, FontWeight.w900, kInk, spacing: -0.3),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(action!, style: jakarta(12.5, FontWeight.w800, _p)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: _p),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Lays children out as rows of [cols] square cells.
class _SquareGrid extends StatelessWidget {
  final List<Widget> children;
  final int cols;
  final double gap;
  const _SquareGrid({required this.children, this.cols = 2, this.gap = _gap});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(Row(
        children: [
          for (var j = 0; j < cols; j++) ...[
            if (j > 0) SizedBox(width: gap),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: i + j < children.length
                    ? children[i + j]
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ));
    }
    return Column(children: rows);
  }
}

/// Number that counts up from zero the first time it shows.
class _CountUp extends StatelessWidget {
  final double value;
  final int decimals;
  final String suffix;
  final TextStyle style;
  final bool grouping;
  const _CountUp(
    this.value, {
    required this.style,
    this.decimals = 0,
    this.suffix = '',
    this.grouping = false,
  });

  String _fmt(double v) {
    var s = v.toStringAsFixed(decimals);
    if (grouping) {
      final whole = s.split('.').first;
      final buf = StringBuffer();
      for (var i = 0; i < whole.length; i++) {
        if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
        buf.write(whole[i]);
      }
      s = buf.toString() + (s.contains('.') ? '.${s.split('.').last}' : '');
    }
    return '$s$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(_fmt(v), maxLines: 1, style: style),
    );
  }
}

/// Scales its child in once the section has been revealed.
class _PopIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _PopIn({required this.child, this.delay = 0});

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void initState() {
    super.initState();
    whenRevealed(context, () {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: _c, child: widget.child),
      );
}

/// Gentle up-and-down float for 3D icons.
class _Float extends StatefulWidget {
  final Widget child;
  final int phase;
  const _Float({required this.child, this.phase = 0});

  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _c.value = (widget.phase % 5) / 5;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -3 * Curves.easeInOut.transform(_c.value)),
          child: child,
        ),
        child: widget.child,
      );
}

// ===========================================================================
// Tab
// ===========================================================================

class OverviewTabV5 extends StatelessWidget {
  const OverviewTabV5({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      const _StatGrid(),
      const _GoalChart(),
      const _KemoSection(),
      const _QuickActions(),
      const _BodyMetrics(),
      const _Products(),
      const _Achievements(),
      const _Habits(),
      const _Streak(),
      const _TrainToday(),
      const _Explore(),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 22),
            Reveal(
              delay: Duration(milliseconds: i < 3 ? 70 * i : 0),
              offset: 18,
              child: sections[i],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// 1. Six square stat cards
// ===========================================================================

class _Stat {
  final String label;
  final double value;
  final int decimals;
  final String suffix;
  final bool grouping;
  final String? image;
  final double progress;
  final Color color;
  final Color soft;
  final Widget Function(BuildContext)? open;
  const _Stat({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.soft,
    this.image,
    this.decimals = 0,
    this.suffix = '',
    this.grouping = false,
    this.open,
  });
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    return ValueListenableBuilder<int>(
      valueListenable: m.waterMl,
      builder: (context, ml, _) {
        final stats = [
          _Stat(
            label: 'Calories',
            value: m.calories.toDouble(),
            suffix: ' kcal',
            image: '$_v4/fire.png',
            progress: m.calorieProgress,
            color: const Color(0xFFF97316),
            soft: const Color(0xFFFFEDD5),
            open: (_) => const LogMealScreen(),
          ),
          _Stat(
            label: 'Workout',
            value: m.activeMinutes.toDouble(),
            suffix: ' min',
            image: '$_v3/workout_gear.png',
            progress: m.activeProgress,
            color: _p,
            soft: const Color(0xFFEDE4FF),
            open: (_) => const ActiveWorkoutScreen(
              dayTitle: 'Upper Body Strength',
              dayNumber: 3,
            ),
          ),
          _Stat(
            label: 'Goal',
            value: 65,
            suffix: '%',
            progress: 0.65,
            color: const Color(0xFF16A34A),
            soft: const Color(0xFFDCFCE7),
            open: (_) => const TransformScreen(),
          ),
          _Stat(
            label: 'Steps',
            value: m.steps.toDouble(),
            grouping: true,
            image: '$_v4/shoe.png',
            progress: m.stepProgress,
            color: const Color(0xFF65A30D),
            soft: const Color(0xFFECFCCB),
            open: (_) => const StepsScreen(),
          ),
          _Stat(
            label: 'Water',
            value: ml / 1000,
            decimals: 2,
            suffix: ' L',
            image: '$_v4/bottle.png',
            progress: (ml / m.waterGoalMl).clamp(0.0, 1.0),
            color: const Color(0xFF0EA5E9),
            soft: const Color(0xFFE0F2FE),
          ),
          _Stat(
            label: 'Sleep',
            value: 7.5,
            decimals: 1,
            suffix: ' h',
            image: '$_v4/moon.png',
            progress: 7.5 / 8,
            color: const Color(0xFF4F46E5),
            soft: const Color(0xFFE0E7FF),
          ),
        ];
        return _SquareGrid(
          cols: 3,
          gap: 10,
          children: [
            for (var i = 0; i < stats.length; i++)
              _PopIn(
                delay: 60 * i,
                child: _StatCard(
                  s: stats[i],
                  phase: i,
                  onTap: () {
                    final s = stats[i];
                    if (s.open != null) {
                      _push(context, s.open!(context));
                    } else if (s.label == 'Water') {
                      HapticFeedback.selectionClick();
                      m.waterMl.value = (ml + 250).clamp(0, 5000);
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _Stat s;
  final int phase;
  final VoidCallback onTap;
  const _StatCard({required this.s, required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth;
        final pad = side * 0.09;
        final icon = side * 0.32;
        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(side * 0.2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, s.soft],
            ),
            border: Border.all(color: s.soft),
            boxShadow: [
              BoxShadow(
                color: s.color.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: icon,
                    child: s.image != null
                        ? _Float(
                            phase: phase,
                            child: Image.asset(s.image!, cacheWidth: 160),
                          )
                        : GrowRing(
                            value: s.progress,
                            color: s.color,
                            size: icon,
                            stroke: icon * 0.13,
                            center: Icon(Icons.flag_rounded,
                                size: icon * 0.42, color: s.color),
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(s.progress * 100).round()}%',
                      style: jakarta(9, FontWeight.w900, s.color),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _CountUp(
                  s.value,
                  decimals: s.decimals,
                  suffix: s.suffix,
                  grouping: s.grouping,
                  style: jakarta(side * 0.145, FontWeight.w900, kInk,
                      spacing: -0.4, height: 1.15),
                ),
              ),
              Text(
                s.label,
                maxLines: 1,
                style: jakarta(side * 0.09, FontWeight.w700, kMuted, height: 1.2),
              ),
              SizedBox(height: side * 0.04),
              GrowBar(value: s.progress, color: s.color, height: 4),
            ],
          ),
        );
      }),
    );
  }
}

// ===========================================================================
// 2. Goal progress chart
// ===========================================================================

class _GoalChart extends StatefulWidget {
  const _GoalChart();

  @override
  State<_GoalChart> createState() => _GoalChartState();
}

class _GoalChartState extends State<_GoalChart>
    with SingleTickerProviderStateMixin {
  static const _weights = [71.0, 70.2, 69.6, 69.1, 68.2, 67.8, 67.1, 66.5];
  static const _target = 62.0;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    whenRevealed(context, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _figure(String value, String label, Color color) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: jakarta(16, FontWeight.w900, color)),
            ),
            Text(label, style: jakarta(11, FontWeight.w700, kMuted)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head('Goal Progress',
            action: 'Details',
            onAction: () => _push(context, const TransformScreen())),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: _white(r: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _figure('71 kg', 'Start', kMuted),
                  _figure('66.5 kg', 'Now', _p),
                  _figure('62 kg', 'Target', const Color(0xFF16A34A)),
                  GrowRing(
                    value: 0.65,
                    color: _p,
                    size: 52,
                    stroke: 6,
                    center: Text('65%',
                        style: jakarta(12, FontWeight.w900, _p)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 150,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: _ChartPainter(
                      values: _weights,
                      target: _target,
                      t: Curves.easeOutCubic.transform(_c.value),
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 1; i <= _weights.length; i++)
                    Text('W$i',
                        style: jakarta(10, FontWeight.w700,
                            i == _weights.length ? _p : kMuted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final double target;
  final double t;
  const _ChartPainter({
    required this.values,
    required this.target,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hi = values.reduce(math.max) + 0.8;
    final lo = target - 0.8;
    Offset pt(int i) => Offset(
          size.width * i / (values.length - 1),
          size.height * (hi - values[i]) / (hi - lo),
        );

    // grid lines
    final grid = Paint()
      ..color = const Color(0xFFF1EDFA)
      ..strokeWidth = 1;
    for (var k = 0; k <= 3; k++) {
      final y = size.height * k / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // target dashed line
    final ty = size.height * (hi - target) / (hi - lo);
    final dash = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 1.6;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, ty), Offset(math.min(x + 5, size.width), ty),
          dash);
    }
    final tp = TextPainter(
      text: TextSpan(
        text: 'Target 62 kg',
        style: jakarta(9.5, FontWeight.w800, const Color(0xFF16A34A)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, ty - tp.height - 3));

    // smooth line through points
    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = pt(i - 1), b = pt(i);
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -10, size.width * t + 2, size.height + 20));
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _p.withValues(alpha: 0.28),
            _p.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFFC084FC), _p],
        ).createShader(Offset.zero & size),
    );
    for (var i = 0; i < values.length; i++) {
      final o = pt(i);
      if (o.dx > size.width * t + 1) break;
      canvas.drawCircle(o, 3.4, Paint()..color = Colors.white);
      canvas.drawCircle(
          o,
          3.4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _p);
    }
    canvas.restore();

    if (t > 0.98) {
      final last = pt(values.length - 1);
      canvas.drawCircle(last, 10, Paint()..color = _p.withValues(alpha: 0.18));
      canvas.drawCircle(last, 5.5, Paint()..color = _p);
      canvas.drawCircle(last, 2.4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.t != t;
}

// ===========================================================================
// 3. Kemo AI
// ===========================================================================

class _KemoSection extends StatelessWidget {
  const _KemoSection();

  @override
  Widget build(BuildContext context) {
    void open() {
      HapticFeedback.lightImpact();
      Navigator.push(context, KemoAiScreen.route());
    }

    const chips = [
      ('🏋️', 'Plan my day'),
      ('🥗', 'Meal idea'),
      ('😴', 'Sleep tips'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Head('Kemo AI'),
        PressScale(
          onTap: open,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF4C1D95)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _p.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 70,
                      height: 70,
                      child: KemoFace(size: 70),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ask Kemo',
                              style:
                                  jakarta(20, FontWeight.w900, Colors.white)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBEF264),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('AI Coach · Online',
                                style: jakarta(
                                    10.5, FontWeight.w800, kInk)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < chips.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: open,
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('${chips[i].$1} ${chips[i].$2}',
                                  style: jakarta(
                                      11.5, FontWeight.w800, Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 4. Quick actions (four square buttons)
// ===========================================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    final actions = <(IconData, String, Color, Color, VoidCallback)>[
      (
        Icons.play_arrow_rounded,
        'Workout',
        const Color(0xFFA78BFA),
        _p,
        () => _push(
              context,
              const ActiveWorkoutScreen(
                  dayTitle: 'Upper Body Strength', dayNumber: 3),
            ),
      ),
      (
        Icons.restaurant_rounded,
        'Log Meal',
        const Color(0xFFFDBA74),
        const Color(0xFFF97316),
        () => _push(context, const LogMealScreen()),
      ),
      (
        Icons.water_drop_rounded,
        'Water',
        const Color(0xFF7DD3FC),
        const Color(0xFF0284C7),
        () {
          HapticFeedback.selectionClick();
          m.waterMl.value = (m.waterMl.value + 250).clamp(0, 5000);
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('+250 ml water added 💧'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(milliseconds: 1400),
            ));
        },
      ),
      (
        Icons.monitor_weight_rounded,
        'Weight',
        const Color(0xFF86EFAC),
        const Color(0xFF16A34A),
        () => _push(context, const TransformScreen()),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Head('Quick Actions'),
        _SquareGrid(
          cols: 4,
          gap: 10,
          children: [
            for (var i = 0; i < actions.length; i++)
              _PopIn(
                delay: 50 * i,
                child: PressScale(
                  onTap: actions[i].$5,
                  child: LayoutBuilder(builder: (context, c) {
                    final side = c.maxWidth;
                    return Container(
                      decoration: _tint(actions[i].$3, actions[i].$4,
                          r: side * 0.26),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: side * 0.42,
                            height: side * 0.42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(actions[i].$1,
                                color: Colors.white, size: side * 0.26),
                          ),
                          SizedBox(height: side * 0.07),
                          Text(
                            actions[i].$2,
                            maxLines: 1,
                            style: jakarta(
                                side * 0.13, FontWeight.w800, Colors.white),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// 5. Body metrics 2x2
// ===========================================================================

class _BodyMetrics extends StatelessWidget {
  const _BodyMetrics();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.monitor_weight_rounded,
        'Weight',
        66.5,
        1,
        ' kg',
        '▼ 2.4 kg',
        const Color(0xFF7C3AED),
        const Color(0xFFF3EEFF),
        const [71.0, 70.2, 69.6, 69.1, 68.2, 67.8, 67.1, 66.5],
      ),
      (
        Icons.speed_rounded,
        'BMI',
        22.9,
        1,
        '',
        'Normal',
        const Color(0xFF16A34A),
        const Color(0xFFEAFBF0),
        const [24.6, 24.3, 24.0, 23.8, 23.5, 23.3, 23.1, 22.9],
      ),
      (
        Icons.water_drop_outlined,
        'Body Fat',
        15.8,
        1,
        '%',
        '▼ 1.9%',
        const Color(0xFFF97316),
        const Color(0xFFFFF3E8),
        const [17.7, 17.4, 17.0, 16.8, 16.5, 16.2, 16.0, 15.8],
      ),
      (
        Icons.fitness_center_rounded,
        'Muscle',
        72.4,
        1,
        ' kg',
        '▲ 1.2 kg',
        const Color(0xFF0EA5E9),
        const Color(0xFFE8F6FE),
        const [71.2, 71.3, 71.5, 71.6, 71.9, 72.0, 72.2, 72.4],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head('Body Metrics',
            action: 'Track',
            onAction: () => _push(context, const TransformScreen())),
        _SquareGrid(
          cols: 2,
          children: [
            for (final it in items)
              PressScale(
                onTap: () => _push(context, const TransformScreen()),
                child: LayoutBuilder(builder: (context, c) {
                  final side = c.maxWidth;
                  return Container(
                    padding: EdgeInsets.all(side * 0.09),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, it.$8],
                      ),
                      border: Border.all(color: it.$8),
                      boxShadow: [
                        BoxShadow(
                          color: it.$7.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: side * 0.22,
                              height: side * 0.22,
                              decoration: BoxDecoration(
                                color: it.$7,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(it.$1,
                                  color: Colors.white, size: side * 0.13),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: it.$7.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(it.$6,
                                  style: jakarta(10, FontWeight.w800, it.$7)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _CountUp(
                            it.$3,
                            decimals: it.$4,
                            suffix: it.$5,
                            style: jakarta(side * 0.15, FontWeight.w900, kInk,
                                spacing: -0.5),
                          ),
                        ),
                        Text(it.$2,
                            style:
                                jakarta(side * 0.075, FontWeight.w700, kMuted)),
                        SizedBox(height: side * 0.05),
                        SizedBox(
                          height: side * 0.2,
                          width: double.infinity,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, _) => CustomPaint(
                              painter: _SparkPainter(it.$9, it.$7, t),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> v;
  final Color color;
  final double t;
  const _SparkPainter(this.v, this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final hi = v.reduce(math.max), lo = v.reduce(math.min);
    final span = (hi - lo).abs() < 0.001 ? 1.0 : hi - lo;
    Offset pt(int i) => Offset(size.width * i / (v.length - 1),
        size.height * 0.1 + size.height * 0.8 * (hi - v[i]) / span);
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      final a = pt(i - 1), b = pt(i);
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -4, size.width * t, size.height + 8));
    canvas.drawPath(
      Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.t != t;
}

// ===========================================================================
// 6. Recommended products
// ===========================================================================

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) {
    final picks = [
      shopDemoProducts[0],
      shopDemoProducts[3],
      shopDemoProducts[4],
      shopDemoProducts[6],
      shopDemoProducts[5],
      shopDemoProducts[2],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head('Recommended for You',
            action: 'Shop',
            onAction: () => _push(context, const ShopScreen())),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: picks.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) {
              final p = picks[i];
              final off = ((1 - p.price / p.oldPrice) * 100).round();
              return PressScale(
                onTap: () => _push(
                  context,
                  ProductDetailScreen(
                    title: p.title,
                    subtitle: '${p.category} · Lab certified',
                    price: p.price,
                    oldPrice: p.oldPrice,
                    image: p.image,
                    rating: p.rating,
                    reviewsCount: p.sold,
                    category: p.category,
                  ),
                ),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: _white(r: 22),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(p.image,
                                  fit: BoxFit.cover, cacheWidth: 420),
                            ),
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFF43F5E),
                                    Color(0xFFF97316),
                                  ]),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text('$off% OFF',
                                    style: jakarta(
                                        9.5, FontWeight.w900, Colors.white)),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: _p,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(12.5, FontWeight.w800, kInk)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('₹${p.price.round()}',
                              style: jakarta(13, FontWeight.w900, _p)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '₹${p.oldPrice.round()}',
                              maxLines: 1,
                              style: jakarta(11, FontWeight.w600, kMuted)
                                  .copyWith(
                                      decoration: TextDecoration.lineThrough),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 7. Achievements carousel
// ===========================================================================

class _Achievements extends StatelessWidget {
  const _Achievements();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('b_streak', '12 Days', 'Streak', Color(0xFFFBBF24), Color(0xFFF97316)),
      ('b_workouts', '25', 'Workouts', Color(0xFFA78BFA), Color(0xFF6D28D9)),
      ('b_steps', '10K', 'Steps', Color(0xFF4ADE80), Color(0xFF15803D)),
      ('b_water', '7 Days', 'Hydrated', Color(0xFF38BDF8), Color(0xFF1D4ED8)),
      ('b_clean', '5 Days', 'Clean Eating', Color(0xFFF472B6), Color(0xFFBE185D)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head('Achievements',
            action: 'View All',
            onAction: () => _push(context, const RewardsScreen())),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) {
              final a = items[i];
              return _PopIn(
                delay: 70 * i,
                child: PressScale(
                  onTap: () => _push(context, const RewardsScreen()),
                  child: Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(10),
                    decoration: _tint(a.$4, a.$5, r: 26),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          top: -18,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: _Float(
                                  phase: i,
                                  child: Image.asset('$_v4/${a.$1}.png',
                                      cacheWidth: 200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(a.$2,
                                maxLines: 1,
                                style: jakarta(
                                    14, FontWeight.w900, Colors.white)),
                            Text(a.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(10.5, FontWeight.w700,
                                    Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 8. Habit tracker (four square toggles)
// ===========================================================================

class _Habits extends StatefulWidget {
  const _Habits();

  @override
  State<_Habits> createState() => _HabitsState();
}

class _HabitsState extends State<_Habits> {
  final _done = [true, true, true, false];
  static const _items = [
    ('💪', 'Workout', Color(0xFF7C3AED)),
    ('🥗', 'Nutrition', Color(0xFF16A34A)),
    ('💧', 'Water', Color(0xFF0EA5E9)),
    ('😴', 'Sleep 8h', Color(0xFF4F46E5)),
  ];

  @override
  Widget build(BuildContext context) {
    final count = _done.where((d) => d).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head('Habit Tracker', action: '$count/4 done'),
        _SquareGrid(
          cols: 4,
          gap: 10,
          children: [
            for (var i = 0; i < _items.length; i++)
              PressScale(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _done[i] = !_done[i]);
                },
                child: LayoutBuilder(builder: (context, c) {
                  final side = c.maxWidth;
                  final on = _done[i];
                  final col = _items[i].$3;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(side * 0.26),
                      gradient: on
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [col.withValues(alpha: 0.75), col],
                            )
                          : null,
                      color: on ? null : Colors.white,
                      border: Border.all(
                          color: on ? col : const Color(0xFFE9E3F7),
                          width: 1.4),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                color: col.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: side * 0.08,
                          top: side * 0.08,
                          child: AnimatedScale(
                            scale: on ? 1 : 0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: side * 0.22,
                              height: side * 0.22,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_rounded,
                                  size: side * 0.16, color: col),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_items[i].$1,
                                  style: TextStyle(fontSize: side * 0.3)),
                              SizedBox(height: side * 0.04),
                              Text(
                                _items[i].$2,
                                maxLines: 1,
                                style: jakarta(side * 0.12, FontWeight.w800,
                                    on ? Colors.white : kInk),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// 9. Streak
// ===========================================================================

class _Streak extends StatelessWidget {
  const _Streak();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Head('Streak'),
        PressScale(
          onTap: () => _push(context, const StreakDetailScreen()),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _tint(const Color(0xFFFB923C), const Color(0xFFE11D48),
                r: 26),
            child: Column(
              children: [
                Row(
                  children: [
                    _Float(
                      child: Image.asset('$_v4/fire.png',
                          width: 64, height: 64, cacheWidth: 200),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CountUp(
                            m.streak.toDouble(),
                            suffix: ' days',
                            style: jakarta(30, FontWeight.w900, Colors.white,
                                spacing: -0.8),
                          ),
                          Text('Best 21 days',
                              style: jakarta(12, FontWeight.w700,
                                  Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('🔥 On fire',
                          style:
                              jakarta(11.5, FontWeight.w800, Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i <= today
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.2),
                                ),
                                child: FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(i <= today ? '🔥' : '·',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(days[i],
                                style: jakarta(10.5, FontWeight.w800,
                                    Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Photo card shared by the last two sections
// ===========================================================================

class _PhotoCard extends StatelessWidget {
  final String image;
  final String title;
  final String tag;
  final Color color;
  final VoidCallback onTap;
  final bool play;
  final Alignment focus;
  const _PhotoCard({
    required this.image,
    required this.title,
    required this.tag,
    required this.color,
    required this.onTap,
    this.play = false,
    this.focus = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(image,
                    fit: BoxFit.cover, alignment: focus, cacheWidth: 600),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1],
                      colors: [
                        color.withValues(alpha: 0),
                        color.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(tag,
                        style: jakarta(10, FontWeight.w800, color)),
                  ),
                ),
                Positioned(
                  left: side * 0.08,
                  right: side * 0.08,
                  bottom: side * 0.08,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          style: jakarta(side * 0.1, FontWeight.w900,
                              Colors.white,
                              height: 1.1),
                        ),
                      ),
                      if (play)
                        Container(
                          width: side * 0.22,
                          height: side * 0.22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow_rounded,
                              color: color, size: side * 0.15),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ===========================================================================
// 10. Train today
// ===========================================================================

class _TrainToday extends StatelessWidget {
  const _TrainToday();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Head('Train Today'),
        _SquareGrid(
          cols: 2,
          children: [
            _PhotoCard(
              image: '$_photos/workout_exercise_cutout.jpg',
              title: 'Full Body HIIT',
              tag: '25 min',
              color: const Color(0xFF6D28D9),
              play: true,
              onTap: () => _push(
                context,
                const ActiveWorkoutScreen(
                    dayTitle: 'Full Body HIIT', dayNumber: 3),
              ),
            ),
            _PhotoCard(
              image: '$_photos/category_yoga_model.png',
              title: 'Yoga Flow',
              tag: '20 min',
              color: const Color(0xFFDB2777),
              play: true,
              focus: Alignment.topCenter,
              onTap: () => _push(
                context,
                const ActiveWorkoutScreen(dayTitle: 'Yoga Flow', dayNumber: 3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// 11. Explore
// ===========================================================================

class _Explore extends StatelessWidget {
  const _Explore();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Head('Explore'),
        _SquareGrid(
          cols: 2,
          children: [
            _PhotoCard(
              image: '$_photos/transform_hero.jpg',
              title: 'Transformation',
              tag: 'Before · After',
              color: const Color(0xFF16A34A),
              focus: Alignment.topCenter,
              onTap: () => _push(context, const TransformScreen()),
            ),
            _PhotoCard(
              image: '$_photos/trainers_hero_banner.jpg',
              title: 'Personal Trainers',
              tag: '500+ coaches',
              color: const Color(0xFF0F172A),
              onTap: () => _push(context, const TrainersScreen()),
            ),
            _PhotoCard(
              image: '$_photos/steps_walking_person.jpg',
              title: 'Live Walk',
              tag: 'Steps',
              color: const Color(0xFF0284C7),
              onTap: () => _push(context, const StepsScreen()),
            ),
            _PhotoCard(
              image: '$_photos/rewards_gold_trophy_3d.jpg',
              title: 'Rewards',
              tag: '1,250 pts',
              color: const Color(0xFFB45309),
              onTap: () => _push(context, const RewardsScreen()),
            ),
          ],
        ),
      ],
    );
  }
}
