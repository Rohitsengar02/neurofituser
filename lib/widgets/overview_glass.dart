import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/date_nutrition_detail_screen.dart';
import '../screens/log_meal_screen.dart';
import '../screens/steps_screen.dart';
import '../screens/streak_detail_screen.dart';
import 'side_island.dart' show IslandStats;

// Apple-widget style palette: light glass on the app's green.
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _green = Color(0xFF16A34A);
const _lime = Color(0xFFB5E550);
const _orange = Color(0xFFFF8A3D);
const _purple = Color(0xFF7C6CF2);
const _blue = Color(0xFF3B82F6);
const _pink = Color(0xFFF06292);
const _amber = Color(0xFFF5A524);

const Curve _spring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle _t(double s, {FontWeight w = FontWeight.w600, Color c = _ink, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

/// Frosted glass panel: blurred backdrop, soft white fill, hairline border.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<Color>? tint;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = tint ??
        [Colors.white.withValues(alpha: 0.82), Colors.white.withValues(alpha: 0.58)];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D24).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Springy press feedback, like tapping an iOS widget.
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, this.onTap});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? 0.955 : 1,
        duration: Duration(milliseconds: _down ? 120 : 420),
        curve: _down ? Curves.easeOut : _spring,
        child: widget.child,
      ),
    );
  }
}

/// Fades and springs a child up once, staggered by [order].
class _Rise extends StatelessWidget {
  final int order;
  final Widget child;
  const _Rise(this.order, this.child);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 700 + order * 110),
      curve: Interval((order * 110) / (700 + order * 110), 1, curve: _spring),
      builder: (context, t, c) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - t)),
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: c),
        ),
      ),
      child: child,
    );
  }
}

class _Head extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onTap;
  const _Head(this.text, {this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(text, style: _t(19, w: FontWeight.w800, ls: -0.4)),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action!, style: _t(13, w: FontWeight.w700, c: _green)),
            ),
        ],
      ),
    );
  }
}

Widget _iconBubble(IconData i, Color c, {bool alert = false, Color? bg}) => Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg ?? Colors.white.withValues(alpha: 0.9),
            border: Border.all(color: c.withValues(alpha: 0.18)),
          ),
          child: Icon(i, size: 19, color: c),
        ),
        if (alert)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
              child: const Icon(Icons.priority_high_rounded, size: 11, color: Colors.white),
            ),
          ),
      ],
    );

Widget _arrowChip({bool dark = false}) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? _ink : Colors.white.withValues(alpha: 0.75),
      ),
      child: Icon(Icons.north_east_rounded, size: 16, color: dark ? Colors.white : _ink),
    );

// =====================================================================
//  OVERVIEW GLASS SECTIONS
// =====================================================================

/// Everything below the bento grid on Overview: the Your Progress widget
/// carousel and a stack of Apple-style glass widgets.
class OverviewGlassSections extends StatelessWidget {
  const OverviewGlassSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Soft colour blobs give the frosted glass something to blur.
        const Positioned.fill(child: _AmbientBlobs()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Head('Your Progress'),
            const ProgressWidgetCarousel(),
            const SizedBox(height: 28),
            const _Head('Today'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _Rise(0, _TodaysFoodWidget()),
                  SizedBox(height: 14),
                  _Rise(1, _NetEnergyWidget()),
                  SizedBox(height: 14),
                  _Rise(2, _RingsRow()),
                  SizedBox(height: 14),
                  _Rise(3, _EnergyHydrationRow()),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _Head('Workout Timeline',
                action: 'Streak',
                onTap: () => _push(context, const StreakDetailScreen())),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _Rise(4, _WorkoutTimelineWidget()),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmbientBlobs extends StatelessWidget {
  const _AmbientBlobs();

  @override
  Widget build(BuildContext context) {
    Widget blob(Color c, double s) => Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withValues(alpha: 0.55), c.withValues(alpha: 0)]),
          ),
        );
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -80, top: 20, child: blob(const Color(0xFFB9F5CF), 300)),
          Positioned(right: -90, top: 260, child: blob(const Color(0xFFE2DBFF), 320)),
          Positioned(left: -60, top: 640, child: blob(const Color(0xFFFFE1C7), 300)),
          Positioned(right: -70, top: 980, child: blob(const Color(0xFFCFE6FF), 320)),
        ],
      ),
    );
  }
}

// =====================================================================
//  YOUR PROGRESS: widgets that grow when tapped
// =====================================================================

enum _Viz { dots, circles, ticks, ring, bars }

class _ProgressData {
  final String title;
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String sub;
  final double progress;
  final List<double> week;
  final _Viz viz;
  final List<Color>? tint;
  final bool lightText;
  final String best;
  final String avg;
  const _ProgressData({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.sub,
    required this.progress,
    required this.week,
    required this.viz,
    required this.best,
    required this.avg,
    this.tint,
    this.lightText = false,
  });
}

const _progress = [
  _ProgressData(
    title: 'Calories',
    icon: Icons.local_fire_department_rounded,
    color: _orange,
    value: '461',
    unit: '/600',
    sub: 'kcal burned',
    progress: 461 / 600,
    week: [320, 410, 380, 520, 460, 590, 461],
    viz: _Viz.dots,
    best: '590',
    avg: '448',
  ),
  _ProgressData(
    title: 'Workouts',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFF65A30D),
    value: '12',
    unit: '/20',
    sub: 'this month',
    progress: 12 / 20,
    week: [1, 0, 1, 1, 0, 1, 1],
    viz: _Viz.circles,
    best: '5 / wk',
    avg: '3 / wk',
    tint: [Color(0xFFD9F99D), Color(0xFFA3E635)],
  ),
  _ProgressData(
    title: 'Steps',
    icon: Icons.directions_walk_rounded,
    color: _green,
    value: '8,542',
    unit: '',
    sub: '85% of 10k',
    progress: 0.85,
    week: [6200, 7400, 9100, 5600, 10400, 8800, 8542],
    viz: _Viz.ticks,
    best: '10.4k',
    avg: '8.0k',
  ),
  _ProgressData(
    title: 'Sleep',
    icon: Icons.bedtime_rounded,
    color: _purple,
    value: '7h 32',
    unit: 'm',
    sub: 'Goal 8h',
    progress: 7.53 / 8,
    week: [6.8, 7.2, 6.1, 7.9, 8.2, 7.0, 7.5],
    viz: _Viz.ring,
    best: '8h 12m',
    avg: '7h 14m',
    tint: [Color(0xFFEDE9FF), Color(0xFFD8D0FF)],
  ),
  _ProgressData(
    title: 'Daily Goals',
    icon: Icons.task_alt_rounded,
    color: _blue,
    value: '8',
    unit: '/10',
    sub: 'goals done',
    progress: 0.8,
    week: [6, 7, 9, 5, 8, 10, 8],
    viz: _Viz.bars,
    best: '10',
    avg: '7.6',
  ),
];

class ProgressWidgetCarousel extends StatefulWidget {
  const ProgressWidgetCarousel({super.key});

  @override
  State<ProgressWidgetCarousel> createState() => _ProgressWidgetCarouselState();
}

class _ProgressWidgetCarouselState extends State<ProgressWidgetCarousel> {
  int? _open;
  final _keys = List.generate(_progress.length, (_) => GlobalKey());

  void _toggle(int i) {
    setState(() => _open = _open == i ? null : i);
    if (_open == i) {
      Future.delayed(const Duration(milliseconds: 260), () {
        final ctx = _keys[i].currentContext;
        if (ctx != null && mounted) {
          Scrollable.ensureVisible(ctx,
              alignment: 0.5, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final big = math.min(screenW - 40, 330.0);
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _progress.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _Rise(
          i,
          _Press(
            onTap: () => _toggle(i),
            child: AnimatedContainer(
              key: _keys[i],
              duration: const Duration(milliseconds: 560),
              curve: _spring,
              width: _open == i ? big : 164,
              child: _ProgressWidget(data: _progress[i], open: _open == i),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressWidget extends StatelessWidget {
  final _ProgressData data;
  final bool open;
  const _ProgressWidget({required this.data, required this.open});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return _GlowBorderPanel(
      color: d.color,
      radius: 30,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(builder: (context, c) {
        final roomy = c.maxWidth > 230;
        final left = SizedBox(
          width: math.min(134.0, c.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconBubble(d.icon, d.color, alert: d.progress < 0.65),
                  const Spacer(),
                  AnimatedRotation(
                    turns: open ? 0.125 : 0,
                    duration: const Duration(milliseconds: 420),
                    curve: _spring,
                    child: _arrowChip(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(d.title, style: _t(13.5, w: FontWeight.w600, c: _ink.withValues(alpha: 0.75))),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: d.value, style: _t(30, w: FontWeight.w700, ls: -1, h: 1)),
                  TextSpan(text: d.unit, style: _t(13, w: FontWeight.w600, c: _muted)),
                ])),
              ),
              const SizedBox(height: 2),
              Text(d.sub, style: _t(11, w: FontWeight.w500, c: _muted)),
              const SizedBox(height: 10),
              SizedBox(height: 22, child: _MiniViz(d)),
            ],
          ),
        );
        return Row(
          children: [
            left,
            if (roomy)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _ExpandedChart(d),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// iPhone-style widget: green glass fill (like the Workouts card) inside a
/// slowly turning gradient border that glows softly.
class _GlowBorderPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  const _GlowBorderPanel(
      {required this.child, required this.padding, required this.color, this.radius = 30});

  @override
  State<_GlowBorderPanel> createState() => _GlowBorderPanelState();
}

class _GlowBorderPanelState extends State<_GlowBorderPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;
    return AnimatedBuilder(
      animation: _spin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r - 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r - 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(widget.color.withValues(alpha: 0.06), Colors.white).withValues(alpha: 0.9),
                  Color.alphaBlend(widget.color.withValues(alpha: 0.14), Colors.white).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
      builder: (context, inner) {
        final g = SweepGradient(
          colors: [
            widget.color.withValues(alpha: 0.85),
            widget.color.withValues(alpha: 0.25),
            Colors.white,
            widget.color.withValues(alpha: 0.45),
            widget.color.withValues(alpha: 0.85),
          ],
          transform: GradientRotation(_spin.value * 2 * math.pi),
        );
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            gradient: g,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: 0.12),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: inner,
        );
      },
    );
  }
}

/// The little visual at the bottom of a small widget.
class _MiniViz extends StatelessWidget {
  final _ProgressData d;
  const _MiniViz(this.d);

  @override
  Widget build(BuildContext context) {
    switch (d.viz) {
      case _Viz.dots:
        // 2 rows x 8 dots, filled by progress
        const n = 16;
        final on = (n * d.progress).round();
        return Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            for (var i = 0; i < n; i++)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < on ? d.color : Colors.transparent,
                  border: Border.all(color: d.color.withValues(alpha: i < on ? 1 : 0.3)),
                ),
              ),
          ],
        );
      case _Viz.circles:
        return Row(
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < 3 ? d.color.withValues(alpha: 0.12) : Colors.white,
                  border: Border.all(color: d.color.withValues(alpha: i < 3 ? 0.3 : 0.9), width: 1.4),
                ),
                child: i < 3 ? Icon(Icons.check_rounded, size: 12, color: d.color) : null,
              ),
          ],
        );
      case _Viz.ticks:
        return CustomPaint(painter: _TicksPainter(d.progress, d.color), size: const Size(double.infinity, 22));
      case _Viz.ring:
        return Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _RingP(d.progress, d.color, 3.5)),
            ),
            const SizedBox(width: 6),
            Text('${(d.progress * 100).round()}%', style: _t(12, w: FontWeight.w700, c: d.color)),
          ],
        );
      case _Viz.bars:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 10; i++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 22,
                  decoration: BoxDecoration(
                    color: i < (d.progress * 10).round() ? d.color : d.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        );
    }
  }
}

/// The chart that slides in when a widget grows.
class _ExpandedChart extends StatelessWidget {
  final _ProgressData d;
  const _ExpandedChart(this.d);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Opacity(
        opacity: t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('7 days', style: _t(11, w: FontWeight.w600, c: _muted)),
                Text('${(d.progress * 100).round()}%', style: _t(12, w: FontWeight.w800, c: d.color)),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: CustomPaint(
                painter: _LineChartPainter(d.week, d.color, t),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Text(l, style: _t(9.5, w: FontWeight.w600, c: _muted)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _stat('Best', d.best)),
                Expanded(child: _stat('Avg', d.avg)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String l, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: _t(10, w: FontWeight.w500, c: _muted)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(v, style: _t(14, w: FontWeight.w800)),
          ),
        ],
      );
}

class _LineChartPainter extends CustomPainter {
  final List<double> v;
  final Color c;
  final double t;
  _LineChartPainter(this.v, this.c, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.isEmpty) return;
    final mx = v.reduce(math.max), mn = v.reduce(math.min);
    final span = (mx - mn) == 0 ? 1 : (mx - mn);
    final pts = <Offset>[
      for (var i = 0; i < v.length; i++)
        Offset(
          size.width * i / (v.length - 1),
          size.height - (size.height * 0.15 + size.height * 0.7 * ((v[i] - mn) / span)) * t,
        ),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1], p1 = pts[i];
      final mid = (p0.dx + p1.dx) / 2;
      path.cubicTo(mid, p0.dy, mid, p1.dy, p1.dx, p1.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.withValues(alpha: 0.28), c.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = c,
    );
    final last = pts.last;
    canvas.drawCircle(last, 6, Paint()..color = Colors.white);
    canvas.drawCircle(last, 4, Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter o) => o.t != t;
}

class _TicksPainter extends CustomPainter {
  final double p;
  final Color c;
  _TicksPainter(this.p, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 22;
    final gap = size.width / n;
    final mark = (n * p).round();
    for (var i = 0; i < n; i++) {
      final x = gap * (i + 0.5);
      final isMark = i == mark;
      canvas.drawLine(
        Offset(x, isMark ? 0 : size.height * 0.25),
        Offset(x, size.height),
        Paint()
          ..strokeWidth = isMark ? 2.6 : 1.6
          ..strokeCap = StrokeCap.round
          ..color = isMark ? c : c.withValues(alpha: i < mark ? 0.55 : 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingP extends CustomPainter {
  final double v;
  final Color c;
  final double s;
  final bool dashedTrack;
  _RingP(this.v, this.c, this.s, {this.dashedTrack = false});

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(s / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s
      ..strokeCap = StrokeCap.round;
    if (dashedTrack) {
      const n = 40;
      for (var i = 0; i < n; i++) {
        canvas.drawArc(r, 2 * math.pi * i / n, 2 * math.pi / n * 0.45, false,
            p..color = c.withValues(alpha: 0.25));
      }
    } else {
      canvas.drawArc(r, 0, 2 * math.pi, false, p..color = c.withValues(alpha: 0.14));
    }
    if (v > 0) {
      canvas.drawArc(r, -math.pi / 2, 2 * math.pi * v.clamp(0.0, 1.0), false,
          p..color = Colors.white..shader = SweepGradient(
            startAngle: 0,
            endAngle: 2 * math.pi,
            colors: [c.withValues(alpha: 0.65), c],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(r));
    }
  }

  @override
  bool shouldRepaint(covariant _RingP o) => o.v != v;
}

/// Ring whose value springs in from zero.
class _AnimRing extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  final double stroke;
  final bool dashed;
  final Widget? center;
  const _AnimRing(this.value, this.color,
      {required this.size, this.stroke = 7, this.dashed = false, this.center});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingP(v, color, stroke, dashedTrack: dashed),
          child: Center(child: center ?? Text('${(v * 100).round()}%', style: _t(size * 0.2, w: FontWeight.w800))),
        ),
      ),
    );
  }
}

// =====================================================================
//  TODAY WIDGETS
// =====================================================================

class _TodaysFoodWidget extends StatelessWidget {
  const _TodaysFoodWidget();

  @override
  Widget build(BuildContext context) {
    Widget matrix(Color c, double fill, String g, IconData i) {
      const cols = 8, rows = 4;
      final on = (cols * rows * fill).round();
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 3.5,
              runSpacing: 3.5,
              children: [
                for (var k = 0; k < cols * rows; k++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + k * 22),
                    builder: (context, t, _) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (cols * rows - 1 - k) < on && t > 0.9 ? c : c.withValues(alpha: 0.13),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(i, size: 13, color: c),
                const SizedBox(width: 3),
                Text(g, style: _t(12, w: FontWeight.w700, c: c)),
              ],
            ),
          ],
        ),
      );
    }

    Widget action(IconData i, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(height: 44, child: Icon(i, size: 20, color: _ink.withValues(alpha: 0.75))),
          ),
        );
    Widget divider() => Container(width: 1, height: 22, color: _ink.withValues(alpha: 0.08));

    return _Press(
      onTap: () => _push(context, DateNutritionDetailScreen(initialDate: DateTime.now())),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Today's food", style: _t(14, w: FontWeight.w700)),
                            const Spacer(),
                            Text('1,420 kcal', style: _t(14, w: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            matrix(_blue, 0.62, '92g', Icons.egg_alt_rounded),
                            const SizedBox(width: 8),
                            matrix(_amber, 0.8, '160g', Icons.grain_rounded),
                            const SizedBox(width: 8),
                            matrix(_pink, 0.55, '48g', Icons.water_drop_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _AnimRing(
                    0.72,
                    _purple,
                    size: 70,
                    stroke: 4,
                    dashed: true,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('72', style: _t(22, w: FontWeight.w800, h: 1)),
                        Text('good', style: _t(10, w: FontWeight.w600, c: _purple)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _ink.withValues(alpha: 0.06)),
            Row(
              children: [
                action(Icons.add_photo_alternate_outlined, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.photo_camera_outlined, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.qr_code_scanner_rounded, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.auto_awesome_outlined, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.search_rounded, () => _push(context, const LogMealScreen())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetEnergyWidget extends StatelessWidget {
  const _NetEnergyWidget();

  @override
  Widget build(BuildContext context) {
    const burned = 1720, eaten = 1420;
    const net = eaten - burned; // -300
    final pos = ((net + 500) / 1000).clamp(0.0, 1.0);
    return _Press(
      onTap: () => _push(context, DateNutritionDetailScreen(initialDate: DateTime.now())),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: net.toDouble()),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) =>
                            Text('${v.round()} kcal', style: _t(26, w: FontWeight.w700, ls: -0.8)),
                      ),
                      Text('Net energy', style: _t(12.5, w: FontWeight.w500, c: _muted)),
                    ],
                  ),
                ),
                const Icon(Icons.local_fire_department_rounded, size: 16, color: _orange),
                Text(' 1,720', style: _t(14, w: FontWeight.w700, c: _orange)),
                const SizedBox(width: 10),
                const Icon(Icons.apple_rounded, size: 16, color: _purple),
                Text(' 1,420', style: _t(14, w: FontWeight.w700, c: _purple)),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B3D), Color(0xFFFFB86B), Color(0xFFDCE7F5), Color(0xFF8FA8FF), _purple],
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: pos),
                      duration: const Duration(milliseconds: 1300),
                      curve: _spring,
                      builder: (context, p, _) => Positioned(
                        left: (c.maxWidth - 22) * p,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in const ['-500', '-250', '0', '250', '500'])
                  Text(l, style: _t(10.5, w: FontWeight.w500, c: _muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingsRow extends StatelessWidget {
  const _RingsRow();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Press(
              onTap: () => _push(context, const StepsScreen()),
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(days[now.weekday - 1], style: _t(12, w: FontWeight.w500, c: _muted)),
                              Text(months[now.month - 1], style: _t(16, w: FontWeight.w700, h: 1.1)),
                              Text('${now.day}', style: _t(16, w: FontWeight.w700, h: 1.1)),
                            ],
                          ),
                        ),
                        const _AnimRing(0.42, _amber, size: 54, stroke: 6, dashed: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          _AnimRing(0.86, _green, size: 56, stroke: 6),
                          SizedBox(width: 8),
                          _AnimRing(0.65, _purple, size: 56, stroke: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Press(
              onTap: () => _push(context, const StreakDetailScreen()),
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _AnimRing(
                      0.75,
                      _orange,
                      size: 92,
                      stroke: 8,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('75%', style: _t(19, w: FontWeight.w800, h: 1)),
                          Text('workout', style: _t(9.5, w: FontWeight.w600, c: _muted)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duration', style: _t(10.5, w: FontWeight.w500, c: _muted)),
                              Text('34m', style: _t(14, w: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Energy', style: _t(10.5, w: FontWeight.w500, c: _muted)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('320 kcal', style: _t(14, w: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyHydrationRow extends StatelessWidget {
  const _EnergyHydrationRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _energyBank(context)),
          const SizedBox(width: 12),
          const Expanded(child: _HydrationWidget()),
        ],
      ),
    );
  }

  Widget _energyBank(BuildContext context) {
    return _Press(
      onTap: () => _push(context, const StreakDetailScreen()),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        tint: const [Color(0xFF4ADE80), Color(0xFF16A34A)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 2),
                Text('Energy Bank', style: _t(12.5, w: FontWeight.w700, c: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 93),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) =>
                  Text('${v.round()}%', style: _t(30, w: FontWeight.w700, c: Colors.white, ls: -1, h: 1)),
            ),
            const SizedBox(height: 4),
            Text('Recovered after sleep',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(10.5, w: FontWeight.w500, c: Colors.white70)),
            const Spacer(),
            const SizedBox(height: 10),
            Container(
              height: 26,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 16; i++)
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 300 + i * 60),
                        builder: (context, t, _) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: i < 15 && t > 0.95 ? _green : _green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pill('+40%', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                _pill('-7%', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: _t(10.5, w: FontWeight.w800, c: fg)),
      );
}

class _HydrationWidget extends StatelessWidget {
  const _HydrationWidget();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: IslandStats.waterMl,
      builder: (context, ml, _) {
        final p = ml / IslandStats.waterGoal;
        return GlassPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop_rounded, size: 15, color: _blue),
                  const SizedBox(width: 3),
                  Text('Hydration', style: _t(12.5, w: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('${_fmtInt(ml)} ml', style: _t(22, w: FontWeight.w700, ls: -0.6)),
              ),
              Text('${(p * 100).round()}% complete', style: _t(11, w: FontWeight.w600, c: _blue)),
              const Spacer(),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 110,
                  height: 62,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: p.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 900),
                    curve: _spring,
                    builder: (context, v, child) => CustomPaint(
                      painter: _ArcGauge(v, _blue),
                      child: child,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          IslandStats.waterMl.value = (ml + 250).clamp(0, IslandStats.waterGoal);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: _blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: _ink),
                        ),
                      ),
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
}

String _fmtInt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _ArcGauge extends CustomPainter {
  final double v;
  final Color c;
  _ArcGauge(this.v, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    const s = 11.0;
    final r = Rect.fromCircle(
        center: Offset(size.width / 2, size.height - 4), radius: size.width / 2 - s / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, math.pi, math.pi, false, p..color = c.withValues(alpha: 0.14));
    canvas.drawArc(r, math.pi, math.pi * v, false,
        p..color = Colors.white..shader = LinearGradient(colors: [c.withValues(alpha: 0.6), c]).createShader(r));
  }

  @override
  bool shouldRepaint(covariant _ArcGauge o) => o.v != v;
}

// =====================================================================
//  WORKOUT TIMELINE (month grid with checks)
// =====================================================================

class _WorkoutTimelineWidget extends StatefulWidget {
  const _WorkoutTimelineWidget();

  @override
  State<_WorkoutTimelineWidget> createState() => _WorkoutTimelineWidgetState();
}

class _WorkoutTimelineWidgetState extends State<_WorkoutTimelineWidget> {
  int? _sel;
  static const _m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  // Workouts done per month (goal 16). 0 = missed, -1 = not yet.
  static const _done = [6, 17, 16, 18, 15, 17, 16, 19, 4, 16, 12, -1];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final paid = _done.where((d) => d >= 15).length;
    return GlassPanel(
      tint: [const Color(0xFFF7FEE7).withValues(alpha: 0.9), const Color(0xFFECFCCB).withValues(alpha: 0.7)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workouts this year', style: _t(12.5, w: FontWeight.w500, c: _muted)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('156', style: _t(34, w: FontWeight.w700, ls: -1.2)),
                        const SizedBox(width: 6),
                        Text('sessions', style: _t(12, w: FontWeight.w600, c: _muted)),
                      ],
                    ),
                  ],
                ),
              ),
              _AnimRing(
                paid / 11,
                const Color(0xFF65A30D),
                size: 62,
                stroke: 5,
                center: Text('$paid/11', style: _t(13, w: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('${now.year}', style: _t(13, w: FontWeight.w700, c: _muted)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 5 * 6) / 6;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 12; i++)
                  _monthTile(i, w),
              ],
            );
          }),
          AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: _spring,
            child: _sel == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _done[_sel!] >= 15 ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
                            color: _done[_sel!] >= 15 ? const Color(0xFF65A30D) : _orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _done[_sel!] < 0
                                  ? '${_m[_sel!]} is coming up. Plan 16 sessions to keep the streak.'
                                  : '${_m[_sel!]}: ${_done[_sel!]} of 16 workouts${_done[_sel!] >= 15 ? ', goal reached!' : '. Missed the goal.'}',
                              style: _t(12.5, w: FontWeight.w600, h: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _monthTile(int i, double w) {
    final d = _done[i];
    final ok = d >= 15;
    final future = d < 0;
    final sel = _sel == i;
    return _Press(
      onTap: () => setState(() => _sel = sel ? null : i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: w,
        height: w * 1.15,
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white.withValues(alpha: future ? 0.35 : 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? const Color(0xFF65A30D) : Colors.white.withValues(alpha: 0.9),
            width: sel ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(_m[i], style: _t(10.5, w: FontWeight.w600, c: future ? _muted : _ink)),
            Container(
              width: w * 0.48,
              height: w * 0.48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ok ? _lime : (future ? Colors.transparent : const Color(0xFFE5E7EB)),
                border: future ? Border.all(color: const Color(0xFFD1D5DB)) : null,
              ),
              child: future
                  ? null
                  : Icon(ok ? Icons.check_rounded : Icons.close_rounded,
                      size: w * 0.3, color: ok ? const Color(0xFF365314) : _muted),
            ),
          ],
        ),
      ),
    );
  }
}
