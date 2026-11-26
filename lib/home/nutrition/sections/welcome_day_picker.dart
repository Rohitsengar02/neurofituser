part of '../nutrition_tab_v3.dart';

// =====================================================================
//  WELCOME + DAY PICKER
// =====================================================================

class _Welcome extends StatefulWidget {
  const _Welcome();
  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const words = ['Fuel', 'your', 'day,', 'Rohit'];
    Widget blurIn(int i, Widget w) {
      final a = CurvedAnimation(parent: _c, curve: Interval(0.06 * i, 0.5 + 0.08 * i, curve: _spring));
      return AnimatedBuilder(
        animation: a,
        child: w,
        builder: (_, c) {
          final o = a.value.clamp(0.0, 1.0);
          final b = (1 - o) * 10;
          Widget x = Transform.translate(offset: Offset(0, 22 * (1 - a.value)), child: c);
          if (b > 0.3 && !LiquidGlass.lite) x = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: x);
          return Opacity(opacity: o, child: x);
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        blurIn(0, Text('NUTRITION · ${IslandStats.left} KCAL TO GO', style: _t(11.5, w: FontWeight.w800, c: _faint, ls: 1.4))),
        const SizedBox(height: 6),
        Wrap(spacing: 9, children: [
          for (var i = 0; i < words.length; i++)
            blurIn(
              i + 1,
              Text(words[i], style: _t(32, w: FontWeight.w800, ls: -1.2, h: 1.1, c: i == 3 ? _blue : _ink)),
            ),
        ]),
      ]),
    );
  }
}

class _DayPicker extends StatefulWidget {
  const _DayPicker();
  @override
  State<_DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<_DayPicker> {
  int _sel = 3;
  static const _fill = [0.92, 1.0, 0.85, 0.79, 0.0, 0.0, 0.0];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = now.add(Duration(days: i - 3));
          final sel = i == _sel;
          return ScrollReveal(
            delayMs: i * 40,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sel = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: _spring,
                width: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: sel ? _ink : Colors.white.withValues(alpha: 0.6),
                  border: Border.all(color: Colors.white.withValues(alpha: sel ? 0 : 0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: (sel ? _ink : const Color(0xFF64748B)).withValues(alpha: sel ? 0.25 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(names[d.weekday - 1], style: _t(11.5, w: FontWeight.w700, c: sel ? Colors.white70 : _faint)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _fill[i]),
                      duration: Duration(milliseconds: 900 + i * 80),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => CustomPaint(
                        painter: _Ring(v, sel ? _mint : _blue, 3.2, track: sel ? Colors.white24 : null),
                        child: Center(
                          child: Text('${d.day}', style: _n(13, c: sel ? Colors.white : _ink)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Ring extends CustomPainter {
  final double v, w;
  final Color c;
  final Color? track;
  _Ring(this.v, this.c, this.w, {this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - w / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = track ?? c.withValues(alpha: 0.14));
    if (v > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        2 * math.pi * v,
        false,
        p
          ..color = Colors.white
          ..shader = SweepGradient(
            colors: [c.withValues(alpha: 0.6), c],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Ring o) => o.v != v || o.c != c;
}
