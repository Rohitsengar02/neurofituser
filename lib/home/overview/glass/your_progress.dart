part of '../overview_glass.dart';

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
/// Pauses the spinning border while the panel is off screen.
class _GlowBorderPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  const _GlowBorderPanel({required this.child, required this.padding, required this.color, this.radius = 30});
  @override
  Widget build(BuildContext context) =>
      TickerGate(child: _GlowBorderPanelCore(padding: padding, color: color, radius: radius, child: child));
}

class _GlowBorderPanelCore extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  const _GlowBorderPanelCore(
      {required this.child, required this.padding, required this.color, this.radius = 30});

  @override
  State<_GlowBorderPanelCore> createState() => _GlowBorderPanelState();
}

class _GlowBorderPanelState extends State<_GlowBorderPanelCore> with SingleTickerProviderStateMixin {
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
    return RepaintBoundary(child: AnimatedBuilder(
      animation: _spin,
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(r - 2),
        padding: widget.padding,
        tint: widget.color,
        shadow: false,
        child: widget.child,
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
    ));
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
