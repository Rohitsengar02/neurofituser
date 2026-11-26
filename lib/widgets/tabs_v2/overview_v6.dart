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

/// Overview tab in two colours: neon green and black, on white.
/// The neon page colour runs from the top of the screen past the six stat
/// cards; everything below sits on a white sheet with a curved top.

const kOverviewNeon = Color(0xFFC6F432);
const _neon = kOverviewNeon;
const _ink = Color(0xFF0E0F0C);
const _muted = Color(0xFF6B7069);
const _tile = Color(0xFFF4F5F0); // light card on the white sheet
const _track = Color(0xFFE6E8E1);
const _gap = 12.0;
const _v4 = 'assets/images/overview_v4';
const _photos = 'assets/images';

TextStyle _display(double size, {FontWeight w = FontWeight.w800, Color c = _ink, double spacing = -0.4, double? height}) =>
    TextStyle(
      fontFamily: 'InterDisplay',
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: spacing,
      height: height,
    );

TextStyle _text(double size, {FontWeight w = FontWeight.w600, Color c = _muted, double? height, double spacing = 0}) =>
    TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: height,
      letterSpacing: spacing,
    );

void _push(BuildContext context, Widget screen) {
  HapticFeedback.lightImpact();
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _Head extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const _Head(this.text, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _display(19, spacing: -0.5)),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _tile,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(action!,
                        style: _text(12, w: FontWeight.w700, c: _ink)),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: _ink),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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

class _CountUp extends StatelessWidget {
  final double value;
  final int decimals;
  final String suffix;
  final TextStyle style;
  final TextStyle? suffixStyle;
  final bool grouping;
  const _CountUp(
    this.value, {
    required this.style,
    this.suffixStyle,
    this.decimals = 0,
    this.suffix = '',
    this.grouping = false,
  });

  String _fmt(double v) {
    var s = v.toStringAsFixed(decimals);
    if (grouping) {
      final parts = s.split('.');
      final whole = parts.first;
      final buf = StringBuffer();
      for (var i = 0; i < whole.length; i++) {
        if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
        buf.write(whole[i]);
      }
      s = buf.toString() + (parts.length > 1 ? '.${parts.last}' : '');
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text.rich(
        TextSpan(children: [
          TextSpan(text: _fmt(v), style: style),
          if (suffix.isNotEmpty)
            TextSpan(text: suffix, style: suffixStyle ?? style),
        ]),
        maxLines: 1,
      ),
    );
  }
}

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
    duration: const Duration(milliseconds: 520),
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
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(a),
        child: widget.child,
      ),
    );
  }
}

/// Thin progress bar, black on a light track (or neon on dark).
class _Bar extends StatelessWidget {
  final double value;
  final bool dark;
  final double height;
  const _Bar(this.value, {this.dark = false, this.height = 5});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                  color: dark ? Colors.white.withValues(alpha: 0.14) : _track),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? _neon : _ink,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color track;
  final Widget? center;
  static const color = _ink;
  const _Ring({
    required this.value,
    required this.size,
    required this.stroke,
    this.track = _track,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => CustomPaint(
        painter: _RingPainter(v, color, track, stroke),
        child: SizedBox.square(dimension: size, child: child),
      ),
      child: Center(child: center),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  final Color track;
  final double stroke;
  const _RingPainter(this.v, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * v,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color;
}

/// Round icon badge: neon circle with a black glyph, or the reverse.
class _IconDot extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool inverted;
  const _IconDot(this.icon, {required this.size, this.inverted = false});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: inverted ? _ink : _neon,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.52, color: inverted ? _neon : _ink),
      );
}

// ===========================================================================
// Tab
// ===========================================================================

class OverviewTabV6 extends StatelessWidget {
  const OverviewTabV6({super.key});

  @override
  Widget build(BuildContext context) {
    final sheet = <Widget>[
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: const Reveal(offset: 14, child: _StatGrid()),
        ),
        const SizedBox(height: 22),
        // White sheet with a curved top over the neon page colour.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 130),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: _track,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              for (var i = 0; i < sheet.length; i++) ...[
                if (i > 0) const SizedBox(height: 26),
                Reveal(
                  delay: Duration(milliseconds: i < 2 ? 80 * (i + 1) : 0),
                  offset: 18,
                  child: sheet[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 1. Six square stat cards (on the neon page colour)
// ===========================================================================

class _Stat {
  final String label;
  final IconData icon;
  final double value;
  final int decimals;
  final String suffix;
  final bool grouping;
  final double progress;
  final bool dark;
  final VoidCallback? onTap;
  const _Stat({
    required this.label,
    required this.icon,
    required this.value,
    required this.progress,
    this.decimals = 0,
    this.suffix = '',
    this.grouping = false,
    this.dark = false,
    this.onTap,
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
            icon: Icons.local_fire_department_rounded,
            value: m.calories.toDouble(),
            suffix: ' kcal',
            progress: m.calorieProgress,
            dark: true,
            onTap: () => _push(context, const LogMealScreen()),
          ),
          _Stat(
            label: 'Workout',
            icon: Icons.fitness_center_rounded,
            value: m.activeMinutes.toDouble(),
            suffix: ' min',
            progress: m.activeProgress,
            onTap: () => _push(
              context,
              const ActiveWorkoutScreen(
                  dayTitle: 'Upper Body Strength', dayNumber: 3),
            ),
          ),
          _Stat(
            label: 'Goal',
            icon: Icons.flag_rounded,
            value: 65,
            suffix: '%',
            progress: 0.65,
            onTap: () => _push(context, const TransformScreen()),
          ),
          _Stat(
            label: 'Steps',
            icon: Icons.directions_walk_rounded,
            value: m.steps.toDouble(),
            grouping: true,
            progress: m.stepProgress,
            onTap: () => _push(context, const StepsScreen()),
          ),
          _Stat(
            label: 'Water',
            icon: Icons.water_drop_rounded,
            value: ml / 1000,
            decimals: 2,
            suffix: ' L',
            progress: (ml / m.waterGoalMl).clamp(0.0, 1.0),
            dark: true,
            onTap: () {
              HapticFeedback.selectionClick();
              m.waterMl.value = (ml + 250).clamp(0, 5000);
            },
          ),
          _Stat(
            label: 'Sleep',
            icon: Icons.bedtime_rounded,
            value: 7.5,
            decimals: 1,
            suffix: ' h',
            progress: 7.5 / 8,
          ),
        ];
        return _SquareGrid(
          cols: 3,
          gap: 10,
          children: [
            for (var i = 0; i < stats.length; i++)
              _PopIn(delay: 50 * i, child: _StatCard(stats[i])),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _Stat s;
  const _StatCard(this.s);

  @override
  Widget build(BuildContext context) {
    final fg = s.dark ? Colors.white : _ink;
    final sub = s.dark ? Colors.white.withValues(alpha: 0.6) : _muted;
    return PressScale(
      onTap: s.onTap ?? () {},
      child: LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth;
        return Container(
          padding: EdgeInsets.all(side * 0.1),
          decoration: BoxDecoration(
            color: s.dark ? _ink : Colors.white,
            borderRadius: BorderRadius.circular(side * 0.2),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.label == 'Goal')
                    _Ring(
                      value: s.progress,
                      size: side * 0.3,
                      stroke: side * 0.045,
                      center: Icon(s.icon, size: side * 0.13, color: _ink),
                    )
                  else
                    _IconDot(s.icon, size: side * 0.3),
                  const Spacer(),
                  Text('${(s.progress * 100).round()}%',
                      style: _text(side * 0.085, w: FontWeight.w700, c: sub)),
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
                  style: _display(side * 0.17, c: fg, height: 1.1),
                  suffixStyle: _display(side * 0.1,
                      w: FontWeight.w700, c: sub, height: 1.1),
                ),
              ),
              Text(s.label,
                  maxLines: 1,
                  style: _text(side * 0.09, w: FontWeight.w600, c: sub,
                      height: 1.25)),
              SizedBox(height: side * 0.05),
              _Bar(s.progress, dark: s.dark, height: 4),
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

  Widget _figure(String v, String unit, String label, {bool strong = false}) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: v,
                    style: _display(20, c: strong ? _ink : _muted)),
                TextSpan(
                    text: unit,
                    style: _display(12, w: FontWeight.w700, c: _muted)),
              ])),
            ),
            const SizedBox(height: 2),
            Text(label, style: _text(11.5)),
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
          decoration: BoxDecoration(
            color: _tile,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _figure('71', ' kg', 'Start'),
                  _figure('66.5', ' kg', 'Now', strong: true),
                  _figure('62', ' kg', 'Target'),
                  _Ring(
                    value: 0.65,
                    size: 54,
                    stroke: 6,
                    track: Colors.white,
                    center: Text('65%',
                        style: _display(13, spacing: -0.2)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _ChartPainter(
                      values: _weights,
                      target: _target,
                      t: Curves.easeOutCubic.transform(_c.value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 1; i <= _weights.length; i++)
                    Text('W$i',
                        style: _text(10.5,
                            w: i == _weights.length
                                ? FontWeight.w700
                                : FontWeight.w500,
                            c: i == _weights.length ? _ink : _muted)),
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
  const _ChartPainter(
      {required this.values, required this.target, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final hi = values.reduce(math.max) + 0.8;
    final lo = target - 0.8;
    Offset pt(int i) => Offset(size.width * i / (values.length - 1),
        size.height * (hi - values[i]) / (hi - lo));

    final grid = Paint()
      ..color = _track
      ..strokeWidth = 1;
    for (var k = 0; k <= 3; k++) {
      final y = size.height * k / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final ty = size.height * (hi - target) / (hi - lo);
    final dash = Paint()
      ..color = _ink.withValues(alpha: 0.45)
      ..strokeWidth = 1.4;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(
          Offset(x, ty), Offset(math.min(x + 4, size.width), ty), dash);
    }
    final tp = TextPainter(
      text: TextSpan(text: 'Target', style: _text(10, w: FontWeight.w700, c: _ink)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, ty - tp.height - 3));

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = pt(i - 1), b = pt(i);
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    canvas.save();
    canvas.clipRect(
        Rect.fromLTWH(0, -10, size.width * t + 2, size.height + 20));
    canvas.drawPath(
      Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_neon.withValues(alpha: 0.75), _neon.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );
    canvas.restore();

    if (t > 0.98) {
      final last = pt(values.length - 1);
      canvas.drawCircle(last, 8, Paint()..color = _ink);
      canvas.drawCircle(last, 4, Paint()..color = _neon);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter o) => o.t != t;
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

    const chips = ['Plan my day', 'Meal idea', 'Sleep tips'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Head('Kemo AI'),
        PressScale(
          onTap: open,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(
                        width: 64, height: 64, child: KemoFace(size: 64)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ask Kemo',
                              style: _display(21, c: Colors.white)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: _neon, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text('AI Coach · Online',
                                  style: _text(11.5,
                                      c: Colors.white
                                          .withValues(alpha: 0.65))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const _IconDot(Icons.arrow_outward_rounded, size: 42),
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
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(chips[i],
                                  style: _text(12,
                                      w: FontWeight.w600,
                                      c: Colors.white)),
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
// 4. Quick actions
// ===========================================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    final actions = <(IconData, String, VoidCallback)>[
      (
        Icons.play_arrow_rounded,
        'Workout',
        () => _push(
              context,
              const ActiveWorkoutScreen(
                  dayTitle: 'Upper Body Strength', dayNumber: 3),
            ),
      ),
      (
        Icons.restaurant_rounded,
        'Log Meal',
        () => _push(context, const LogMealScreen()),
      ),
      (
        Icons.water_drop_rounded,
        'Water',
        () {
          HapticFeedback.selectionClick();
          m.waterMl.value = (m.waterMl.value + 250).clamp(0, 5000);
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('+250 ml water added'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(milliseconds: 1400),
            ));
        },
      ),
      (
        Icons.monitor_weight_rounded,
        'Weight',
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
                  onTap: actions[i].$3,
                  child: LayoutBuilder(builder: (context, c) {
                    final side = c.maxWidth;
                    final first = i == 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: first ? _neon : _ink,
                        borderRadius: BorderRadius.circular(side * 0.26),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _IconDot(actions[i].$1,
                              size: side * 0.42, inverted: first),
                          SizedBox(height: side * 0.08),
                          Text(actions[i].$2,
                              maxLines: 1,
                              style: _text(side * 0.135,
                                  w: FontWeight.w700,
                                  c: first ? _ink : Colors.white)),
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
// 5. Body metrics 2x2 (no line charts)
// ===========================================================================

class _BodyMetrics extends StatelessWidget {
  const _BodyMetrics();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.monitor_weight_rounded, 'Weight', 66.5, ' kg', '−2.4 kg', 0.65, 'Goal 62 kg'),
      (Icons.speed_rounded, 'BMI', 22.9, '', 'Normal', 0.55, '18.5 – 24.9'),
      (Icons.opacity_rounded, 'Body Fat', 15.8, '%', '−1.9%', 0.62, 'Goal 14%'),
      (Icons.fitness_center_rounded, 'Muscle', 72.4, ' kg', '+1.2 kg', 0.8, 'Goal 74 kg'),
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
            for (var i = 0; i < items.length; i++)
              PressScale(
                onTap: () => _push(context, const TransformScreen()),
                child: LayoutBuilder(builder: (context, c) {
                  final it = items[i];
                  final side = c.maxWidth;
                  final dark = i == 0;
                  final fg = dark ? Colors.white : _ink;
                  final sub =
                      dark ? Colors.white.withValues(alpha: 0.6) : _muted;
                  return Container(
                    padding: EdgeInsets.all(side * 0.09),
                    decoration: BoxDecoration(
                      color: dark ? _ink : _tile,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _IconDot(it.$1, size: side * 0.24),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(it.$5,
                                  style:
                                      _text(10.5, w: FontWeight.w700, c: fg)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _CountUp(
                            it.$3,
                            decimals: 1,
                            suffix: it.$4,
                            style: _display(side * 0.19, c: fg, height: 1.1),
                            suffixStyle: _display(side * 0.1,
                                w: FontWeight.w700, c: sub, height: 1.1),
                          ),
                        ),
                        Text(it.$2,
                            style: _text(side * 0.08, c: sub, height: 1.3)),
                        SizedBox(height: side * 0.06),
                        _Bar(it.$6, dark: dark, height: 5),
                        SizedBox(height: side * 0.04),
                        Text(it.$7,
                            maxLines: 1,
                            style: _text(side * 0.065,
                                w: FontWeight.w600, c: sub)),
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
          height: 208,
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
                  width: 142,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 142,
                        height: 142,
                        decoration: BoxDecoration(
                          color: _tile,
                          borderRadius: BorderRadius.circular(22),
                        ),
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
                                  color: _ink,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text('-$off%',
                                    style: _text(10.5,
                                        w: FontWeight.w700, c: _neon)),
                              ),
                            ),
                            const Positioned(
                              right: 8,
                              bottom: 8,
                              child: _IconDot(Icons.add_rounded, size: 30),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(13, w: FontWeight.w600, c: _ink)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('₹${p.price.round()}',
                              style: _display(15, spacing: -0.2)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('₹${p.oldPrice.round()}',
                                maxLines: 1,
                                style: _text(11.5, w: FontWeight.w500)
                                    .copyWith(
                                        decoration:
                                            TextDecoration.lineThrough)),
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
// 7. Achievements carousel (black and neon cards)
// ===========================================================================

class _Achievements extends StatelessWidget {
  const _Achievements();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('b_streak', '12 Days', 'Streak'),
      ('b_workouts', '25', 'Workouts'),
      ('b_steps', '10K', 'Steps'),
      ('b_water', '7 Days', 'Hydrated'),
      ('b_clean', '5 Days', 'Clean eating'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head('Achievements',
            action: 'View all',
            onAction: () => _push(context, const RewardsScreen())),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) {
              final a = items[i];
              final neon = i.isOdd;
              return _PopIn(
                delay: 60 * i,
                child: PressScale(
                  onTap: () => _push(context, const RewardsScreen()),
                  child: Container(
                    width: 136,
                    height: 136,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: neon ? _neon : _ink,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Image.asset('$_v4/${a.$1}.png',
                                cacheWidth: 200),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(a.$2,
                            maxLines: 1,
                            style: _display(16,
                                c: neon ? _ink : Colors.white)),
                        Text(a.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(11,
                                c: neon
                                    ? _ink.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.6))),
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
// 8. Habit tracker
// ===========================================================================

class _Habits extends StatefulWidget {
  const _Habits();

  @override
  State<_Habits> createState() => _HabitsState();
}

class _HabitsState extends State<_Habits> {
  final _done = [true, true, true, false];
  static const _items = [
    (Icons.fitness_center_rounded, 'Workout'),
    (Icons.restaurant_rounded, 'Nutrition'),
    (Icons.water_drop_rounded, 'Water'),
    (Icons.bedtime_rounded, 'Sleep 8h'),
  ];

  @override
  Widget build(BuildContext context) {
    final count = _done.where((d) => d).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head('Habit Tracker', action: '$count/4'),
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
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: on ? _neon : _tile,
                      borderRadius: BorderRadius.circular(side * 0.26),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: side * 0.09,
                          top: side * 0.09,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            width: side * 0.2,
                            height: side * 0.2,
                            decoration: BoxDecoration(
                              color: on ? _ink : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: on ? _ink : _track, width: 1.6),
                            ),
                            child: on
                                ? Icon(Icons.check_rounded,
                                    size: side * 0.14, color: _neon)
                                : null,
                          ),
                        ),
                        Positioned(
                          left: side * 0.12,
                          right: side * 0.08,
                          bottom: side * 0.12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_items[i].$1,
                                  size: side * 0.26,
                                  color: on ? _ink : _muted),
                              SizedBox(height: side * 0.06),
                              Text(_items[i].$2,
                                  maxLines: 1,
                                  style: _text(side * 0.125,
                                      w: FontWeight.w700,
                                      c: on ? _ink : _muted)),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const _IconDot(Icons.local_fire_department_rounded,
                        size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CountUp(
                            m.streak.toDouble(),
                            suffix: ' days',
                            style: _display(32, c: Colors.white, spacing: -1),
                            suffixStyle: _display(16,
                                w: FontWeight.w700,
                                c: Colors.white.withValues(alpha: 0.6)),
                          ),
                          Text('Best 21 days',
                              style: _text(12,
                                  c: Colors.white.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i <= today
                                      ? _neon
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                                child: i <= today
                                    ? const FittedBox(
                                        child: Padding(
                                          padding: EdgeInsets.all(5),
                                          child: Icon(
                                              Icons
                                                  .local_fire_department_rounded,
                                              color: _ink),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(days[i],
                                style: _text(11,
                                    w: FontWeight.w600,
                                    c: i == today
                                        ? _neon
                                        : Colors.white
                                            .withValues(alpha: 0.55))),
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
// Photo card: real photo, black fade, neon tag
// ===========================================================================

class _PhotoCard extends StatelessWidget {
  final String image;
  final String title;
  final String tag;
  final VoidCallback onTap;
  final bool play;
  final Alignment focus;
  const _PhotoCard({
    required this.image,
    required this.title,
    required this.tag,
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
        return ClipRRect(
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
                    stops: const [0.4, 1],
                    colors: [
                      _ink.withValues(alpha: 0),
                      _ink.withValues(alpha: 0.85),
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
                    color: _neon,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(tag,
                      style: _text(10.5, w: FontWeight.w700, c: _ink)),
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
                      child: Text(title,
                          maxLines: 2,
                          style: _display(side * 0.1,
                              c: Colors.white, height: 1.1)),
                    ),
                    if (play)
                      _IconDot(Icons.play_arrow_rounded, size: side * 0.22),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

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
              focus: Alignment.topCenter,
              onTap: () => _push(context, const TransformScreen()),
            ),
            _PhotoCard(
              image: '$_photos/trainers_hero_banner.jpg',
              title: 'Personal Trainers',
              tag: '500+ coaches',
              onTap: () => _push(context, const TrainersScreen()),
            ),
            _PhotoCard(
              image: '$_photos/steps_walking_person.jpg',
              title: 'Live Walk',
              tag: 'Steps',
              onTap: () => _push(context, const StepsScreen()),
            ),
            _PhotoCard(
              image: '$_photos/rewards_gold_trophy_3d.jpg',
              title: 'Rewards',
              tag: '1,250 pts',
              onTap: () => _push(context, const RewardsScreen()),
            ),
          ],
        ),
      ],
    );
  }
}
