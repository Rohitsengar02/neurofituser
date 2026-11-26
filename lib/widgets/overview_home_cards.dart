import 'ticker_gate.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/social_screen.dart';
import '../screens/steps_screen.dart';
import '../screens/trainers_screen.dart';
import 'liquid_glass.dart';
import 'side_island.dart' show IslandStats, iosZoomRoute;

// White, neumorphic Overview cards: a full-bleed workout streak hero, then
// Nutrition, Steps, Top trainers and Community. Each card zooms open into a
// bigger page with more detail.

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _faint = Color(0xFF6E7681); // secondary label, 4.6:1 on white
const _green = Color(0xFF16A34A);
const _mint = Color(0xFF22C55E);
const _orange = Color(0xFFFF7A3D);
const _blue = Color(0xFF3B82F6);
const _purple = Color(0xFF8B5CF6);
const _amber = Color(0xFFF59E0B);
const _pink = Color(0xFFEC4899);
const Curve _spring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle _t(
  double s, {
  FontWeight w = FontWeight.w600,
  Color c = _ink,
  double? h,
  double? ls,
}) => GoogleFonts.plusJakartaSans(
  fontSize: s,
  fontWeight: w,
  color: c,
  height: h,
  letterSpacing: ls,
);

/// Opens [page] with an iOS-style zoom growing out of the tapped widget.
void _openFrom(BuildContext context, Widget page) {
  final box = context.findRenderObject() as RenderBox?;
  final size = MediaQuery.of(context).size;
  var origin = Alignment.center;
  if (box != null && box.hasSize) {
    final c = box.localToGlobal(box.size.center(Offset.zero));
    origin = Alignment(
      (c.dx / size.width) * 2 - 1,
      (c.dy / size.height) * 2 - 1,
    );
  }
  Navigator.of(context).push(iosZoomRoute(page, origin));
}

// =====================================================================
//  PUBLIC SECTION
// =====================================================================

class OverviewHomeCards extends StatelessWidget {
  const OverviewHomeCards({super.key});

  /// The cards as separate sections, built lazily by the home scroll view.
  static const List<Widget> sections = [
    _Rise(0, StreakHeroCard()),
    SizedBox(height: 22),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(1, _NutritionCard())),
    SizedBox(height: 16),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(2, _StepsCard())),
    SizedBox(height: 16),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(3, _TrainersCard())),
    SizedBox(height: 16),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(4, _CommunityCard())),
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

/// Reveals a child with a spring when it scrolls into view.
class _Rise extends StatelessWidget {
  final int order;
  final Widget child;
  const _Rise(this.order, this.child);

  @override
  Widget build(BuildContext context) =>
      ScrollReveal(delayMs: (order % 3) * 70, child: child);
}

/// Fades, lifts and un-blurs a child once, staggered by [order].
class _RiseOld extends StatelessWidget {
  final int order;
  final Widget child;
  const _RiseOld(this.order, this.child);

  @override
  Widget build(BuildContext context) {
    final total = 750 + order * 120;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(order * 120 / total, 1, curve: _spring),
      child: child,
      builder: (context, t, c) {
        final o = t.clamp(0.0, 1.0);
        Widget w = Transform.translate(
          offset: Offset(0, 34 * (1 - t)),
          child: c,
        );
        final b = (1 - o) * 10;
        if (b > 0.2)
          w = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b),
            child: w,
          );
        return Opacity(opacity: o, child: w);
      },
    );
  }
}

/// White card with soft neumorphic light/shadow and a springy press.
class _NeuCard extends StatefulWidget {
  final Widget child;
  final Widget Function()? page;
  final EdgeInsets padding;
  final bool glass;
  const _NeuCard({
    required this.child,
    this.page,
    this.padding = const EdgeInsets.all(18),
    this.glass = false,
  });

  @override
  State<_NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<_NeuCard> {
  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      style: LiquidGlassStyle.material,
      borderRadius: BorderRadius.circular(28),
      padding: widget.padding,
      onTap: widget.page == null ? null : () => _openFrom(context, widget.page!()),
      child: widget.child,
    );
  }
}

Widget _cardHead(String title, IconData icon, Color c, {String? trailing}) =>
    Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(15.5, w: FontWeight.w800, ls: -0.2),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: _t(12, w: FontWeight.w600, c: _faint),
          ),
        const SizedBox(width: 6),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF3F5F4),
          ),
          child: const Icon(Icons.north_east_rounded, size: 15, color: _ink),
        ),
      ],
    );

/// Counts a number up from zero once.
class _Count extends StatelessWidget {
  final double value;
  final TextStyle style;
  final int decimals;
  final String suffix;
  final bool group;
  const _Count(
    this.value,
    this.style, {
    this.decimals = 0,
    this.suffix = '',
    this.group = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) {
        var s = v.toStringAsFixed(decimals);
        if (group) s = _grouped(v.round());
        return Text('$s$suffix', style: style, maxLines: 1);
      },
    );
  }
}

String _grouped(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

// =====================================================================
//  DOTTED LINE CHART
// =====================================================================

class DottedLineChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final String? label;
  final List<String>? xLabels;
  final double height;
  const DottedLineChart({
    super.key,
    required this.values,
    required this.color,
    this.label,
    this.xLabels,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOutCubic,
      builder: (_, p, _) => Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _DottedLinePainter(values, color, p, label),
            ),
          ),
          if (xLabels != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < xLabels!.length; i++)
                  Expanded(
                    child: Text(
                      xLabels![i],
                      textAlign: TextAlign.center,
                      style: _t(11,
                        w: i == xLabels!.length - 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        c: i == xLabels!.length - 1 ? _ink : _faint,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final List<double> v;
  final Color c;
  final double p;
  final String? label;
  _DottedLinePainter(this.v, this.c, this.p, this.label);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    final top = label != null ? 30.0 : 8.0;
    final h = size.height - top - 6;
    final mx = v.reduce(math.max) * 1.1;
    final mn = v.reduce(math.min) * 0.7;
    final step = size.width / v.length;
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(step * (i + 0.5), top + h - (v[i] - mn) / (mx - mn) * h),
    ];

    // Dotted grid.
    final grid = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.25);
    for (var g = 0; g < 4; g++) {
      final y = top + h * g / 3;
      for (var x = 2.0; x < size.width; x += 7) {
        canvas.drawCircle(Offset(x, y), 0.8, grid);
      }
    }

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1];
      final p3 = pts[math.min(pts.length - 1, i + 2)];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final metric = path.computeMetrics().first;
    final drawn = metric.length * p;

    // Soft fill under the drawn part.
    final reveal = Rect.fromLTWH(
      0,
      0,
      pts.first.dx + (pts.last.dx - pts.first.dx) * p,
      size.height,
    );
    canvas.save();
    canvas.clipRect(reveal);
    final fill = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.withValues(alpha: 0.16), c.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();

    // The line itself as round dots.
    final dot = Paint()..color = c;
    for (var d = 0.0; d <= drawn; d += 6.5) {
      final tan = metric.getTangentForOffset(d);
      if (tan != null) canvas.drawCircle(tan.position, 1.9, dot);
    }

    // Data points.
    for (var i = 0; i < pts.length - 1; i++) {
      if (pts[i].dx > reveal.right) break;
      canvas.drawCircle(pts[i], 2.6, Paint()..color = Colors.white);
      canvas.drawCircle(
        pts[i],
        2.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = c.withValues(alpha: 0.6),
      );
    }

    // Highlight the latest value.
    if (p > 0.97) {
      final last = pts.last;
      canvas.drawLine(
        Offset(last.dx, last.dy + 8),
        Offset(last.dx, size.height),
        Paint()
          ..color = c.withValues(alpha: 0.25)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(last, 11, Paint()..color = c.withValues(alpha: 0.18));
      canvas.drawCircle(last, 6, Paint()..color = Colors.white);
      canvas.drawCircle(last, 4, Paint()..color = c);
      if (label != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: _t(11, w: FontWeight.w800, c: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final w = tp.width + 16;
        final left = (last.dx - w / 2).clamp(0.0, size.width - w);
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, last.dy - 36, w, 22),
          const Radius.circular(11),
        );
        canvas.drawRRect(r, Paint()..color = _ink);
        tp.paint(canvas, Offset(left + 8, last.dy - 36 + (22 - tp.height) / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter o) => o.p != p || o.v != v;
}

// =====================================================================
//  1. WORKOUT STREAK HERO (full bleed, square corners)
// =====================================================================

const _streakMinutes = <double>[
  32.0,
  40,
  28,
  45,
  38,
  0,
  42,
  50,
  36,
  44,
  30,
  46,
  41,
  48,
];
const _todayPlan = [
  ('Bench Press', '4 × 10', Icons.fitness_center_rounded),
  ('Incline Dumbbell Press', '3 × 12', Icons.fitness_center_rounded),
  ('Shoulder Press', '3 × 10', Icons.accessibility_new_rounded),
  ('Lateral Raises', '3 × 15', Icons.open_with_rounded),
  ('Tricep Dips', '3 × 12', Icons.sports_gymnastics_rounded),
  ('Push-up Finisher', '2 × max', Icons.bolt_rounded),
];

class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => _openFrom(context, const _StreakDetailPage()),
          child: LiquidGlass(
          style: LiquidGlassStyle.material,
          borderRadius: BorderRadius.zero,
          shadow: false,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'WORKOUT STREAK',
                          style: _t(
                            11.5,
                            w: FontWeight.w800,
                            c: _faint,
                            ls: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 15,
                                color: _orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '12 day streak',
                                style: _t(12, w: FontWeight.w800, c: _orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Day ',
                          style: _t(30, w: FontWeight.w300, c: _ink, h: 1),
                        ),
                        _Count(13, _t(44, w: FontWeight.w800, h: 1, ls: -1.5)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              'of 30 · Muscle Builder',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(12.5, w: FontWeight.w600, c: _muted),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upper Body Push · 45 min · 6 exercises',
                      style: _t(13.5, w: FontWeight.w600, c: _muted),
                    ),
                    const SizedBox(height: 16),
                    const DottedLineChart(
                      values: _streakMinutes,
                      color: _green,
                      label: '48 min',
                      height: 118,
                    ),
                    const SizedBox(height: 14),
                    const _WeekStrip(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'Continue Day 13',
                            onTap: () =>
                                _openFrom(context, const _StreakDetailPage()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Plan',
                            style: _t(14, w: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const done = [true, true, false, true, true, true, false];
    const today = 5;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: [
                Text(
                  days[i],
                  style: _t(
                    11,
                    w: FontWeight.w700,
                    c: i == today ? _ink : _faint,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + i * 90),
                  curve: _spring,
                  builder: (_, s, c) => Transform.scale(scale: s, child: c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == today
                          ? _ink
                          : done[i]
                          ? _green.withValues(alpha: 0.12)
                          : const Color(0xFFF3F4F6),
                      border: i > today
                          ? Border.all(color: const Color(0xFFE5E7EB))
                          : null,
                    ),
                    child: Icon(
                      i == today
                          ? Icons.play_arrow_rounded
                          : done[i]
                          ? Icons.check_rounded
                          : i < today
                          ? Icons.close_rounded
                          : null,
                      size: 15,
                      color: i == today
                          ? Colors.white
                          : done[i]
                          ? _green
                          : _faint,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _mint,
                ),
                child: Icon(widget.icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(14.5, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  2. NUTRITION
// =====================================================================

const _macros = [
  ('Protein', 100.0, 140.0, 'g', _purple),
  ('Carbs', 245.0, 350.0, 'g', _amber),
  ('Fat', 48.0, 65.0, 'g', _pink),
  ('Fiber', 18.0, 30.0, 'g', _green),
];

class _NutritionCard extends StatelessWidget {
  const _NutritionCard();

  @override
  Widget build(BuildContext context) {
    final eaten = IslandStats.eaten.toDouble();
    final budget = IslandStats.budget.toDouble();
    return _NeuCard(
      page: () => const _NutritionDetailPage(),
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(
            'Nutrition',
            Icons.restaurant_rounded,
            _orange,
            trailing: 'Today',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 118,
                height: 118,
                child: _AnimRing(
                  value: eaten / budget,
                  color: _orange,
                  stroke: 11,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Count(eaten, _t(24, w: FontWeight.w800, ls: -0.8)),
                      Text(
                        'of ${budget.round()} kcal',
                        style: _t(11, w: FontWeight.w600, c: _faint),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final m in _macros) ...[
                      _MacroBar(
                        name: m.$1,
                        value: m.$2,
                        goal: m.$3,
                        unit: m.$4,
                        color: m.$5,
                      ),
                      if (m != _macros.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(
                Icons.water_drop_rounded,
                _blue,
                '1.25 / 2.5 L',
                'Water',
              ),
              const SizedBox(width: 10),
              _miniStat(Icons.lunch_dining_rounded, _green, '3 of 4', 'Meals'),
              const SizedBox(width: 10),
              _miniStat(
                Icons.local_fire_department_rounded,
                _orange,
                '${IslandStats.left}',
                'kcal left',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _miniStat(IconData i, Color c, String v, String l) => Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(i, size: 15, color: c),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v, style: _t(12, w: FontWeight.w800)),
              ),
              Text(
                l,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

class _MacroBar extends StatelessWidget {
  final String name, unit;
  final double value, goal;
  final Color color;
  const _MacroBar({
    required this.name,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: _t(12, w: FontWeight.w700)),
            ),
            Text('${value.round()}', style: _t(12, w: FontWeight.w800)),
            Text(
              '/${goal.round()}$unit',
              style: _t(11, w: FontWeight.w600, c: _faint),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (value / goal).clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1300),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => LayoutBuilder(
            builder: (_, c) => Stack(
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: 7,
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.6), color],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimRing extends StatelessWidget {
  final double value, stroke;
  final Color color;
  final Widget? child;
  const _AnimRing({
    required this.value,
    required this.color,
    this.stroke = 10,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => CustomPaint(
        painter: _RingPainter(v, color, stroke),
        child: Center(child: c),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, w;
  final Color c;
  _RingPainter(this.v, this.c, this.w);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - w / 2,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      p..color = c.withValues(alpha: 0.12),
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * v,
      false,
      p
        ..color = Colors.white
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [c.withValues(alpha: 0.55), c],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v;
}

// =====================================================================
//  3. STEPS
// =====================================================================

const _hourly = <double>[
  0.0,
  0,
  0,
  0,
  0,
  0,
  120,
  640,
  980,
  420,
  310,
  520,
  760,
  380,
  290,
  450,
  610,
  880,
  1040,
  520,
  220,
  0,
  0,
  0,
];

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    final steps = IslandStats.steps.toDouble();
    return _NeuCard(
      page: () => const _StepsDetailPage(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(
            'Steps',
            Icons.directions_walk_rounded,
            _green,
            trailing: 'Live',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Count(
                      steps,
                      _t(38, w: FontWeight.w800, ls: -1.4, h: 1),
                      group: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of 10,000 steps · 85%',
                      style: _t(12.5, w: FontWeight.w600, c: _muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _inline(Icons.route_rounded, '6.1 km'),
                        _inline(
                          Icons.local_fire_department_rounded,
                          '320 kcal',
                        ),
                        _inline(Icons.timer_outlined, '54 min'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                height: 92,
                child: _AnimRing(
                  value: steps / 10000,
                  color: _green,
                  stroke: 9,
                  child: const Icon(
                    Icons.directions_run_rounded,
                    color: _green,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(
            height: 54,
            child: _HourBars(values: _hourly, color: _green),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '12 AM',
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
              const Spacer(),
              Text(
                '12 PM',
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
              const Spacer(),
              Text(
                'Now',
                style: _t(11, w: FontWeight.w800, c: _ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _inline(IconData i, String s) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(i, size: 14, color: _faint),
    const SizedBox(width: 4),
    Text(s, style: _t(12, w: FontWeight.w700)),
  ],
);

class _HourBars extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _HourBars({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final mx = values.reduce(math.max);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, p, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  height: math.max(4, (values[i] / mx) * 54 * p),
                  decoration: BoxDecoration(
                    color: values[i] == 0
                        ? const Color(0xFFEEF1EF)
                        : color.withValues(alpha: 0.35 + 0.65 * values[i] / mx),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
//  4. TOP TRAINERS
// =====================================================================

const _trainers = [
  (
    'Rahul Sharma',
    'Strength & Muscle',
    '4.9',
    '1.2K clients',
    'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=400&auto=format&fit=crop&q=80',
    _green,
    '98% match',
  ),
  (
    'Anjali Mehta',
    'Weight Loss',
    '4.8',
    '980 clients',
    'https://images.unsplash.com/photo-1548690312-e3b507d8c110?w=400&auto=format&fit=crop&q=80',
    _orange,
    '94% match',
  ),
  (
    'Vikram Singh',
    'Muscle Gain',
    '4.9',
    '1.5K clients',
    'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&auto=format&fit=crop&q=80',
    _blue,
    '91% match',
  ),
  (
    'Neha Patel',
    'Yoga & Wellness',
    '4.7',
    '760 clients',
    'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&auto=format&fit=crop&q=80',
    _purple,
    '88% match',
  ),
];

Widget _photo(String url, String name, Color c, {double radius = 18}) =>
    ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0.6)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            name.split(' ').map((e) => e[0]).join(),
            style: _t(20, w: FontWeight.w800, c: Colors.white),
          ),
        ),
      ),
    );

class _TrainersCard extends StatelessWidget {
  const _TrainersCard();

  @override
  Widget build(BuildContext context) {
    return _NeuCard(
      page: () => const _TrainersDetailPage(),
      padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _cardHead(
              'Top trainers for you',
              Icons.workspace_premium_rounded,
              _purple,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              'Picked for your Muscle Builder goal',
              style: _t(11.5, w: FontWeight.w600, c: _faint),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 18),
              itemCount: _trainers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final tr = _trainers[i];
                return Container(
                  width: 138,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 110,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _photo(tr.$5, tr.$1, tr.$6, radius: 15),
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  tr.$7,
                                  style: _t(11, w: FontWeight.w800, c: tr.$6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(13, w: FontWeight.w800),
                            ),
                            Text(
                              tr.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(11, w: FontWeight.w600, c: _muted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: _amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  tr.$3,
                                  style: _t(11.5, w: FontWeight.w800),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    tr.$4,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(11,
                                      w: FontWeight.w600,
                                      c: _faint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  5. COMMUNITY
// =====================================================================

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    return _NeuCard(
      page: () => const _CommunityDetailPage(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead('Community', Icons.groups_rounded, _blue),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 34,
                child: Stack(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Positioned(
                        left: i * 22.0,
                        child: Container(
                          width: 34,
                          height: 34,
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: _photo(
                              _trainers[i].$5,
                              _trainers[i].$1,
                              _trainers[i].$6,
                              radius: 0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TickerGate(child: _LiveDot()),
                        const SizedBox(width: 6),
                        Text(
                          '2.4k active now',
                          style: _t(13, w: FontWeight.w800),
                        ),
                      ],
                    ),
                    Text(
                      '128 workouts shared today',
                      style: _t(11, w: FontWeight.w600, c: _faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: _photo(
                    _trainers[3].$5,
                    'Neha Patel',
                    _purple,
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: _t(12.5, w: FontWeight.w600, c: _muted),
                          children: [
                            TextSpan(
                              text: 'Neha ',
                              style: _t(12.5, w: FontWeight.w800),
                            ),
                            const TextSpan(
                              text: 'finished the 30-day plank challenge 🎉',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 13,
                            color: _pink,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '342',
                            style: _t(11, w: FontWeight.w700, c: _muted),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chat_bubble_rounded,
                            size: 12,
                            color: _faint,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '48',
                            style: _t(11, w: FontWeight.w700, c: _muted),
                          ),
                          const Spacer(),
                          Text(
                            '12m',
                            style: _t(11, w: FontWeight.w600, c: _faint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _blue.withValues(alpha: 0.2)),
              color: _blue.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, size: 18, color: _blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '10K Steps Weekend · 312 joined',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(12.5, w: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Join',
                    style: _t(12, w: FontWeight.w800, c: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 6 * _c.value,
              height: 6 + 6 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mint.withValues(alpha: 0.4 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  DETAIL PAGES (opened with a zoom from the card)
// =====================================================================

class _DetailScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? bottom;
  const _DetailScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: Stack(
        children: [
          const Positioned.fill(
            child: FurBlobsBackdrop(blobCount: 3, doodles: false),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: _t(20, w: FontWeight.w800, ls: -0.4),
                            ),
                            Text(
                              subtitle,
                              style: _t(12, w: FontWeight.w600, c: _faint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      bottom != null ? 100 : 32,
                    ),
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        _Rise(i, children[i]),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (bottom != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(top: false, child: bottom!),
            ),
        ],
      ),
    );
  }
}

Widget _panel(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) =>
    Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7D948A).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

Widget _statRow(List<(String, String, Color)> items) => Row(
  children: [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const SizedBox(width: 10),
      Expanded(
        child: _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  items[i].$1,
                  style: _t(20, w: FontWeight.w800, c: items[i].$3, ls: -0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                items[i].$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
        ),
      ),
    ],
  ],
);

Widget _sectionTitle(String s) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(s, style: _t(16, w: FontWeight.w800, ls: -0.2)),
);

class _StreakDetailPage extends StatelessWidget {
  const _StreakDetailPage();

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Day 13 · Upper Body Push',
      subtitle: 'Muscle Builder · 30 day plan',
      bottom: _PrimaryButton(
        icon: Icons.play_arrow_rounded,
        label: 'Start workout',
        onTap: () {},
      ),
      children: [
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Minutes trained', style: _t(14, w: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    'Last 14 days',
                    style: _t(12, w: FontWeight.w600, c: _faint),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const DottedLineChart(
                values: _streakMinutes,
                color: _green,
                label: '48 min',
                height: 170,
                xLabels: [
                  '13',
                  '14',
                  '15',
                  '16',
                  '17',
                  '18',
                  '19',
                  '20',
                  '21',
                  '22',
                  '23',
                  '24',
                  '25',
                  '26',
                ],
              ),
            ],
          ),
        ),
        _statRow(const [
          ('12', 'Day streak', _orange),
          ('41', 'Avg min', _green),
          ('18', 'Best streak', _purple),
        ]),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Today's exercises"),
              for (var i = 0; i < _todayPlan.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_todayPlan[i].$3, size: 19, color: _green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _todayPlan[i].$1,
                          style: _t(13.5, w: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _todayPlan[i].$2,
                        style: _t(12.5, w: FontWeight.w700, c: _muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _panel(
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: _amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kemo: rest 90 s between sets today. Your pressing volume is up 12% this week.',
                  style: _t(12.5, w: FontWeight.w600, c: _muted, h: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionDetailPage extends StatelessWidget {
  const _NutritionDetailPage();

  @override
  Widget build(BuildContext context) {
    const meals = [
      (
        'Breakfast',
        'Oats, banana, whey',
        420,
        Icons.free_breakfast_rounded,
        _amber,
      ),
      ('Lunch', 'Chicken rice bowl', 610, Icons.lunch_dining_rounded, _green),
      ('Snack', 'Greek yogurt, almonds', 390, Icons.icecream_rounded, _pink),
      ('Dinner', 'Not logged yet', 0, Icons.dinner_dining_rounded, _faint),
    ];
    return _DetailScaffold(
      title: 'Nutrition',
      subtitle: 'Today · ${IslandStats.left} kcal left',
      children: [
        _panel(
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: _AnimRing(
                  value: IslandStats.eaten / IslandStats.budget,
                  color: _orange,
                  stroke: 13,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Count(
                        IslandStats.eaten.toDouble(),
                        _t(26, w: FontWeight.w800),
                      ),
                      Text(
                        'kcal eaten',
                        style: _t(11, w: FontWeight.w600, c: _faint),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final m in _macros) ...[
                      _MacroBar(
                        name: m.$1,
                        value: m.$2,
                        goal: m.$3,
                        unit: m.$4,
                        color: m.$5,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Calories this week'),
              const DottedLineChart(
                values: <double>[1650, 1820, 1540, 1760, 1900, 1610, 1420],
                color: _orange,
                label: '1,420',
                height: 150,
                xLabels: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Today'],
              ),
            ],
          ),
        ),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Meals'),
              for (final m in meals)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: m.$5.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(m.$4, size: 20, color: m.$5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.$1, style: _t(13.5, w: FontWeight.w800)),
                            Text(
                              m.$2,
                              style: _t(11.5, w: FontWeight.w600, c: _faint),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        m.$3 == 0 ? '+ Add' : '${m.$3} kcal',
                        style: _t(
                          12.5,
                          w: FontWeight.w800,
                          c: m.$3 == 0 ? _green : _ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _statRow(const [
          ('1.25 L', 'Water', _blue),
          ('18 g', 'Fiber', _green),
          ('42 mg', 'Sodium ok', _purple),
        ]),
      ],
    );
  }
}

class _StepsDetailPage extends StatelessWidget {
  const _StepsDetailPage();

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Steps',
      subtitle: 'Today · goal 10,000',
      bottom: _PrimaryButton(
        icon: Icons.directions_walk_rounded,
        label: 'Open step tracker',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StepsScreen())),
      ),
      children: [
        _panel(
          Column(
            children: [
              SizedBox(
                width: 190,
                height: 190,
                child: _AnimRing(
                  value: IslandStats.steps / 10000,
                  color: _green,
                  stroke: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Count(
                        IslandStats.steps.toDouble(),
                        _t(34, w: FontWeight.w800, ls: -1),
                        group: true,
                      ),
                      Text(
                        'steps today',
                        style: _t(12, w: FontWeight.w600, c: _faint),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                height: 80,
                child: _HourBars(values: _hourly, color: _green),
              ),
            ],
          ),
        ),
        _statRow(const [
          ('6.1 km', 'Distance', _blue),
          ('320', 'kcal burned', _orange),
          ('54 min', 'Active', _green),
        ]),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('This week'),
              const DottedLineChart(
                values: <double>[7200, 9100, 6400, 10300, 8800, 11200, 8542],
                color: _green,
                label: '8,542',
                height: 150,
                xLabels: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Today'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainersDetailPage extends StatelessWidget {
  const _TrainersDetailPage();

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Top trainers for you',
      subtitle: 'Matched to your goal and schedule',
      bottom: _PrimaryButton(
        icon: Icons.search_rounded,
        label: 'See all trainers',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TrainersScreen())),
      ),
      children: [
        for (final tr in _trainers)
          _panel(
            Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 96,
                  child: _photo(tr.$5, tr.$1, tr.$6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr.$1,
                              style: _t(15, w: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tr.$6.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tr.$7,
                              style: _t(11, w: FontWeight.w800, c: tr.$6),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${tr.$2} coach',
                        style: _t(12, w: FontWeight.w600, c: _muted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: _amber,
                          ),
                          Text(' ${tr.$3}', style: _t(12, w: FontWeight.w800)),
                          Text(
                            '  ·  ${tr.$4}',
                            style: _t(11.5, w: FontWeight.w600, c: _faint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Book session',
                              style: _t(
                                11.5,
                                w: FontWeight.w700,
                                c: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Free intro call',
                            style: _t(11, w: FontWeight.w600, c: _green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
          ),
      ],
    );
  }
}

class _CommunityDetailPage extends StatelessWidget {
  const _CommunityDetailPage();

  @override
  Widget build(BuildContext context) {
    const posts = [
      (
        'Neha Patel',
        'Finished the 30-day plank challenge 🎉 Day 1 was 40 s, today 3 min 10 s!',
        342,
        48,
        '12m',
        3,
      ),
      (
        'Rahul Sharma',
        'New PR on deadlift: 180 kg × 3. Slow eccentrics really work.',
        518,
        71,
        '1h',
        0,
      ),
      (
        'Anjali Mehta',
        'Meal prep Sunday: 5 high-protein bowls under 500 kcal. Recipe in comments.',
        289,
        36,
        '3h',
        1,
      ),
    ];
    const challenges = [
      (
        '10K Steps Weekend',
        '312 joined · ends Sun',
        Icons.directions_walk_rounded,
        _green,
      ),
      (
        'Push-up Ladder',
        '1.1K joined · 7 days',
        Icons.fitness_center_rounded,
        _orange,
      ),
      (
        'Mindful Mornings',
        '640 joined · 14 days',
        Icons.self_improvement_rounded,
        _purple,
      ),
    ];
    return _DetailScaffold(
      title: 'Community',
      subtitle: '2.4k people active now',
      bottom: _PrimaryButton(
        icon: Icons.groups_rounded,
        label: 'Open community',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SocialScreen())),
      ),
      children: [
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Challenges'),
              for (final c in challenges)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: c.$4.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(c.$3, size: 20, color: c.$4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.$1, style: _t(13.5, w: FontWeight.w800)),
                            Text(
                              c.$2,
                              style: _t(11.5, w: FontWeight.w600, c: _faint),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: c.$4.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Join',
                          style: _t(12, w: FontWeight.w800, c: c.$4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        for (final p in posts)
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: _photo(
                        _trainers[p.$6].$5,
                        p.$1,
                        _trainers[p.$6].$6,
                        radius: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.$1, style: _t(13.5, w: FontWeight.w800)),
                    ),
                    Text(
                      p.$5,
                      style: _t(11, w: FontWeight.w600, c: _faint),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p.$2,
                  style: _t(13, w: FontWeight.w500, c: _ink, h: 1.45),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 16, color: _pink),
                    Text(
                      ' ${p.$3}',
                      style: _t(12, w: FontWeight.w700, c: _muted),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 15,
                      color: _faint,
                    ),
                    Text(
                      ' ${p.$4}',
                      style: _t(12, w: FontWeight.w700, c: _muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =====================================================================
//  FURRY BLOB + DOODLE BACKGROUND
// =====================================================================

/// Soft, furry-edged circles in pastel tints drift slowly around behind
/// the content, with faint hand-drawn doodles floating between them.
class FurBlobsBackdrop extends StatefulWidget {
  final int blobCount;
  final bool doodles;

  /// Food theme: blobs become furry fruit (stems, leaves, kiwi seeds, citrus
  /// segments) and the doodles become food sketches.
  final bool food;
  /// When set, the backdrop sits behind the scroll view (viewport sized)
  /// and follows this controller, so only what's on screen is painted.
  final ScrollController? scroll;
  const FurBlobsBackdrop({super.key, this.blobCount = 7, this.doodles = true, this.food = false, this.scroll});

  @override
  State<FurBlobsBackdrop> createState() => _FurBlobsBackdropState();
}

class _FurBlobsBackdropState extends State<FurBlobsBackdrop> {
  // The drift is very slow (one loop a minute), so 15 updates a second look
  // the same as 60 and leave the browser free for scrolling.
  final _t = ValueNotifier<double>(0);
  final _clock = Stopwatch();
  Timer? _timer;

  void _sync(bool still) {
    if (still) {
      _timer?.cancel();
      _timer = null;
      _clock.stop();
    } else if (_timer == null) {
      _clock.start();
      _timer = Timer.periodic(const Duration(milliseconds: 66), (_) {
        // Skip while another page covers the home screen.
        if (mounted && TickerMode.valuesOf(context).enabled) {
          _t.value = (_clock.elapsedMilliseconds / 60000) % 1.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce Motion: keep the blobs but stop them drifting.
    _sync(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FurPainter(_t, widget.blobCount, widget.doodles, widget.food, widget.scroll),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _FurPainter extends CustomPainter {
  final ValueListenable<double> t;
  final int count;
  final bool doodles;
  final bool food;
  final ScrollController? scroll;
  _FurPainter(this.t, this.count, this.doodles, this.food, this.scroll)
      : super(repaint: scroll == null ? t : Listenable.merge([t, scroll]));

  static const _foodTints = [
    Color(0xFFFDBA74), // orange
    Color(0xFFBEF264), // kiwi
    Color(0xFFFCA5A5), // apple
    Color(0xFFFDE68A), // lemon
    Color(0xFFC4B5FD), // berry
    Color(0xFF86EFAC), // avocado
    Color(0xFFF9A8D4), // watermelon
  ];

  static const _tints = [
    Color(0xFF86EFAC),
    Color(0xFFC4B5FD),
    Color(0xFFFDBA74),
    Color(0xFF93C5FD),
    Color(0xFFFDE68A),
    Color(0xFFF9A8D4),
    Color(0xFF5EEAD4),
  ];

  static final Map<String, ui.Image> _sprites = {};

  ui.Image _sprite(int i, double r, Color c, double ph) {
    final rq = (r / 8).round() * 8.0;
    final key = '$food-$i-${c.toARGB32()}-$rq';
    final hit = _sprites[key];
    if (hit != null) return hit;
    final side = (rq * 2 * 1.35).ceilToDouble();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final center = Offset(side / 2, side / 2);
    final rr = rq;
    final r2 = math.Random(i * 31 + 5);
      // Soft body.
      canvas.drawCircle(
        center,
        rr,
        Paint()
          ..shader = RadialGradient(
            colors: [
              c.withValues(alpha: 0.68),
              c.withValues(alpha: 0.42),
              c.withValues(alpha: 0),
            ],
            stops: const [0, 0.7, 1],
          ).createShader(Rect.fromCircle(center: center, radius: rr))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Fur: short soft strands around the rim, gently swaying.
      final fur = Paint()
        ..color = c.withValues(alpha: 0.6)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      final strands = 90;
      for (var k = 0; k < strands; k++) {
        final ang = k / strands * 2 * math.pi + r2.nextDouble() * 0.05;
        final sway = math.sin(k * 0.7 + ph) * 0.08;
        final len = rr * (0.1 + r2.nextDouble() * 0.12);
        final p0 = center + Offset(math.cos(ang), math.sin(ang)) * (rr * 0.78);
        final p1 =
            center +
            Offset(math.cos(ang + sway), math.sin(ang + sway)) *
                (rr * 0.78 + len);
        canvas.drawLine(p0, p1, fur);
      }
      if (food) _fruit(canvas, center, rr, i % 4, c, ph);
    final img = rec.endRecording().toImageSync(side.toInt(), side.toInt());
    _sprites[key] = img;
    return img;
  }

  @override
  void paint(Canvas canvas, Size size0) {
    var size = size0;
    final a = t.value * 2 * math.pi;
    final rnd = math.Random(7);
    final unit = math.min(size.width, 430.0);
    final view = size0;
    final sc = scroll;
    final hasPos = sc != null && sc.hasClients && sc.positions.length == 1 && sc.position.hasContentDimensions;
    final off = hasPos ? sc.offset : 0.0;
    // Paint in content coordinates, but only what's inside the viewport.
    if (hasPos) {
      size = Size(size.width, sc.position.maxScrollExtent + sc.position.viewportDimension);
    }
    canvas.save();
    canvas.clipRect(Offset.zero & view);
    canvas.translate(0, -off);
    final top = off - unit * 0.7, bottom = off + view.height + unit * 0.7;

    final total = math.max(count, (size.height / 290).ceil());
    for (var i = 0; i < total; i++) {
      final bx = i.isEven ? 0.1 + rnd.nextDouble() * 0.35 : 0.55 + rnd.nextDouble() * 0.35;
      final byPx = 40 + i * 290.0 + (rnd.nextDouble() - 0.5) * 120;
      final by = byPx / math.max(1, size.height);
      final r = unit * (0.24 + rnd.nextDouble() * 0.12);
      final f1 = 1 + rnd.nextInt(3), f2 = 1 + rnd.nextInt(2);
      final ph = rnd.nextDouble() * 6.28;
      final cx = bx * size.width + math.sin(a * f1 + ph) * unit * 0.16;
      final cy = by * size.height + math.cos(a * f2 + ph * 1.3) * unit * 0.18;
      final c = food ? _foodTints[i % _foodTints.length] : _tints[i % _tints.length];
      final center = Offset(cx, cy);
      final breathe = (1 + 0.06 * math.sin(a * 3 + ph)) * r / ((r / 8).round() * 8.0);
      if (cy < top || cy > bottom) continue;

      // Each blob is drawn once into a cached sprite; per frame it only
      // moves and breathes, which keeps the animated background cheap.
      final img = _sprite(i, r, c, ph);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(breathe);
      canvas.drawImage(img, Offset(-img.width / 2, -img.height / 2), Paint()..filterQuality = FilterQuality.low);
      canvas.restore();
    }

    if (!doodles) {
      canvas.restore();
      return;
    }
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF475569).withValues(alpha: 0.42);
    final n = (size.height / 150).clamp(8, 40).round();
    for (var i = 0; i < n; i++) {
      final bx = 0.08 + rnd.nextDouble() * 0.84;
      final by = (i + rnd.nextDouble()) / n;
      final ph = rnd.nextDouble() * 6.28;
      final pos = Offset(
        bx * size.width + math.sin(a * 2 + ph) * 18,
        by * size.height + math.cos(a * 2 + ph) * 22,
      );
      final dsz = 20 + rnd.nextDouble() * 12;
      if (pos.dy < top || pos.dy > bottom) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.sin(a + ph) * 0.6);
      ink.color = [
        const Color(0xFF16A34A),
        const Color(0xFF8B5CF6),
        const Color(0xFFF97316),
        const Color(0xFF3B82F6),
        const Color(0xFF475569),
      ][i % 5].withValues(alpha: 0.38);
      if (food) {
        _foodDoodle(canvas, i % 8, dsz, ink);
      } else {
        _doodle(canvas, i % 8, dsz - 2, ink);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  /// Fruit details on a fur blob: stem and leaf, kiwi seeds, berry shine or
  /// citrus segments, kept soft so they read through glass.
  void _fruit(Canvas canvas, Offset o, double r, int kind, Color c, double a) {
    final soft = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    switch (kind) {
      case 0: // apple / orange: stem and swaying leaf
        final top = o + Offset(0, -r * 0.8);
        canvas.drawLine(top, top + Offset(r * 0.04, -r * 0.22),
            Paint()
              ..color = const Color(0xFF92400E).withValues(alpha: 0.55)
              ..strokeWidth = r * 0.05
              ..strokeCap = StrokeCap.round);
        canvas.save();
        canvas.translate(top.dx + r * 0.05, top.dy - r * 0.16);
        canvas.rotate(-0.6 + 0.15 * math.sin(a * 2));
        canvas.drawOval(Rect.fromLTWH(0, -r * 0.07, r * 0.32, r * 0.14),
            soft..color = const Color(0xFF16A34A).withValues(alpha: 0.55));
        canvas.restore();
      case 1: // kiwi: pale core and seed ring
        canvas.drawCircle(o, r * 0.5, soft..color = Colors.white.withValues(alpha: 0.35));
        canvas.drawCircle(o, r * 0.16, soft..color = const Color(0xFFFEFCE8).withValues(alpha: 0.7));
        for (var k = 0; k < 14; k++) {
          final ang = k / 14 * 2 * math.pi;
          canvas.drawOval(
            Rect.fromCenter(center: o + Offset(math.cos(ang), math.sin(ang)) * r * 0.32, width: r * 0.05, height: r * 0.09),
            Paint()..color = const Color(0xFF1F2937).withValues(alpha: 0.4),
          );
        }
      case 2: // berry: glossy highlights
        for (final d in [const Offset(-0.3, -0.3), const Offset(0.25, -0.1), const Offset(-0.05, 0.3)]) {
          canvas.drawCircle(o + d * r, r * 0.08, soft..color = Colors.white.withValues(alpha: 0.55));
        }
      default: // citrus slice: segments
        canvas.drawCircle(o, r * 0.62, soft..color = Colors.white.withValues(alpha: 0.28));
        final seg = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = r * 0.03
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 8; k++) {
          final ang = k / 8 * 2 * math.pi + a * 0.1;
          canvas.drawLine(o, o + Offset(math.cos(ang), math.sin(ang)) * r * 0.6, seg);
        }
    }
  }

  void _foodDoodle(Canvas c, int kind, double s, Paint p) {
    switch (kind) {
      case 0: // apple
        final path = Path()
          ..moveTo(0, -s * 0.3)
          ..cubicTo(-s * 0.7, -s * 0.6, -s * 0.75, s * 0.5, 0, s * 0.5)
          ..cubicTo(s * 0.75, s * 0.5, s * 0.7, -s * 0.6, 0, -s * 0.3);
        c.drawPath(path, p);
        c.drawLine(Offset(0, -s * 0.3), Offset(s * 0.08, -s * 0.6), p);
      case 1: // carrot
        final path = Path()
          ..moveTo(-s * 0.18, -s * 0.3)
          ..lineTo(0, s * 0.6)
          ..lineTo(s * 0.18, -s * 0.3)
          ..close();
        c.drawPath(path, p);
        for (final dx in [-0.12, 0.0, 0.12]) {
          c.drawLine(Offset(dx * s, -s * 0.32), Offset(dx * s * 2, -s * 0.6), p);
        }
      case 2: // leaf
        final path = Path()
          ..moveTo(-s * 0.5, s * 0.3)
          ..quadraticBezierTo(-s * 0.4, -s * 0.5, s * 0.5, -s * 0.3)
          ..quadraticBezierTo(s * 0.3, s * 0.4, -s * 0.5, s * 0.3);
        c.drawPath(path, p);
        c.drawLine(Offset(-s * 0.5, s * 0.3), Offset(s * 0.2, -s * 0.15), p);
      case 3: // cherries
        c.drawCircle(Offset(-s * 0.25, s * 0.3), s * 0.18, p);
        c.drawCircle(Offset(s * 0.22, s * 0.35), s * 0.18, p);
        final path = Path()
          ..moveTo(-s * 0.25, s * 0.12)
          ..quadraticBezierTo(-s * 0.1, -s * 0.3, s * 0.1, -s * 0.5)
          ..moveTo(s * 0.22, s * 0.17)
          ..quadraticBezierTo(s * 0.2, -s * 0.2, s * 0.1, -s * 0.5);
        c.drawPath(path, p);
      case 4: // avocado
        final path = Path()
          ..moveTo(0, -s * 0.55)
          ..cubicTo(-s * 0.3, -s * 0.5, -s * 0.5, s * 0.5, 0, s * 0.5)
          ..cubicTo(s * 0.5, s * 0.5, s * 0.3, -s * 0.5, 0, -s * 0.55);
        c.drawPath(path, p);
        c.drawCircle(Offset(0, s * 0.18), s * 0.17, p);
      case 5: // fish
        final path = Path()
          ..moveTo(-s * 0.5, 0)
          ..quadraticBezierTo(0, -s * 0.4, s * 0.35, 0)
          ..quadraticBezierTo(0, s * 0.4, -s * 0.5, 0)
          ..moveTo(s * 0.35, 0)
          ..lineTo(s * 0.6, -s * 0.22)
          ..lineTo(s * 0.6, s * 0.22)
          ..close();
        c.drawPath(path, p);
      case 6: // egg
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.75, height: s), p);
      default: // fork
        c.drawLine(Offset(0, -s * 0.1), Offset(0, s * 0.6), p);
        for (final dx in [-0.15, -0.05, 0.05, 0.15]) {
          c.drawLine(Offset(dx * s, -s * 0.55), Offset(dx * s, -s * 0.15), p);
        }
        c.drawLine(Offset(-s * 0.15, -s * 0.15), Offset(s * 0.15, -s * 0.15), p);
    }
  }

  void _doodle(Canvas c, int kind, double s, Paint p) {
    switch (kind) {
      case 0: // squiggle
        final path = Path()..moveTo(-s, 0);
        for (var i = 0; i < 4; i++) {
          path.quadraticBezierTo(
            -s + s * 0.5 * (i * 2 + 1) / 2,
            i.isEven ? -s * 0.5 : s * 0.5,
            -s + s * 0.5 * (i + 1),
            0,
          );
        }
        c.drawPath(path, p);
      case 1: // sparkle
        for (var k = 0; k < 4; k++) {
          final ang = k * math.pi / 4;
          c.drawLine(
            Offset(math.cos(ang), math.sin(ang)) * -s * 0.6,
            Offset(math.cos(ang), math.sin(ang)) * s * 0.6,
            p,
          );
        }
      case 2: // ring
        c.drawCircle(Offset.zero, s * 0.55, p);
      case 3: // zigzag
        final path = Path()..moveTo(-s, s * 0.2);
        for (var i = 1; i <= 4; i++) {
          path.lineTo(-s + i * s * 0.5, i.isEven ? s * 0.2 : -s * 0.3);
        }
        c.drawPath(path, p);
      case 4: // plus
        c.drawLine(Offset(-s * 0.45, 0), Offset(s * 0.45, 0), p);
        c.drawLine(Offset(0, -s * 0.45), Offset(0, s * 0.45), p);
      case 5: // heart
        final path = Path()
          ..moveTo(0, s * 0.45)
          ..cubicTo(-s * 0.9, -s * 0.1, -s * 0.35, -s * 0.75, 0, -s * 0.25)
          ..cubicTo(s * 0.35, -s * 0.75, s * 0.9, -s * 0.1, 0, s * 0.45);
        c.drawPath(path, p);
      case 6: // dumbbell
        c.drawLine(Offset(-s * 0.5, 0), Offset(s * 0.5, 0), p);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(-s * 0.55, 0),
              width: s * 0.22,
              height: s * 0.6,
            ),
            const Radius.circular(2),
          ),
          p,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(s * 0.55, 0),
              width: s * 0.22,
              height: s * 0.6,
            ),
            const Radius.circular(2),
          ),
          p,
        );
      default: // spiral
        final path = Path();
        for (var i = 0; i <= 40; i++) {
          final ang = i / 40 * 4 * math.pi;
          final rr = s * 0.08 + s * 0.5 * i / 40;
          final o = Offset(math.cos(ang), math.sin(ang)) * rr;
          if (i == 0) {
            path.moveTo(o.dx, o.dy);
          } else {
            path.lineTo(o.dx, o.dy);
          }
        }
        c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _FurPainter o) => false;
}
