part of '../workout_tab_v2.dart';

// =====================================================================
//  WELCOME
// =====================================================================

class _Welcome extends StatefulWidget {
  const _Welcome();
  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b, [Curve curve = _spring]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  Widget _blurIn(Animation<double> a, Widget child, {Offset from = const Offset(0, 22)}) => AnimatedBuilder(
        animation: a,
        child: child,
        builder: (_, c) {
          final v = a.value;
          final o = v.clamp(0.0, 1.0);
          final b = (1 - o) * 10;
          Widget w = Transform.translate(offset: from * (1 - v), child: c);
          if (b > 0.3 && !LiquidGlass.lite) w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: w);
          return Opacity(opacity: o, child: w);
        },
      );

  @override
  Widget build(BuildContext context) {
    const words = ['Ready', 'for', 'Day', '13?'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _blurIn(
            _seg(0, 0.35, Curves.easeOut),
            Text('WEEK 3 · MUSCLE BUILDER', style: _t(11.5, w: FontWeight.w800, c: _faint, ls: 1.4)),
            from: const Offset(0, 8),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 9, children: [
            for (var i = 0; i < words.length; i++)
              _blurIn(
                _seg(0.08 + i * 0.08, 0.55 + i * 0.08),
                Text(words[i],
                    style: _t(32, w: FontWeight.w800, ls: -1.2, h: 1.1, c: i == 3 ? _green : _ink)),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      _blurIn(_seg(0.25, 0.95), const _SessionHero(), from: const Offset(0, 40)),
    ]);
  }
}

class _SessionHero extends StatelessWidget {
  const _SessionHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(30),
        colors: const [Color(0xFFFFFFFF), Color(0xFFF7FBF8)],
        onTap: () => _showExercise(context, _today.first),
        child: SizedBox(
          height: 236,
          child: Stack(children: [
            // Athlete art sliding in from the right.
            Positioned(
              right: -18,
              top: 6,
              bottom: 0,
              width: 190,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                curve: _spring,
                builder: (_, v, c) => Transform.translate(
                  offset: Offset(60 * (1 - v), 0),
                  child: Opacity(opacity: v.clamp(0.0, 1.0), child: c),
                ),
                child: Image.asset('assets/images/workout_exercise_cutout.jpg', fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("TODAY'S SESSION", style: _t(11, w: FontWeight.w800, c: _green, ls: 0.8)),
                ),
                const SizedBox(height: 10),
                Text('Upper Body\nPush', style: _t(27, w: FontWeight.w800, ls: -0.8, h: 1.05)),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _chip(Icons.timer_outlined, '45 min'),
                  _chip(Icons.fitness_center_rounded, '6 moves'),
                  _chip(Icons.local_fire_department_rounded, '380 kcal'),
                ]),
                const Spacer(),
                Row(children: [
                  _DarkButton(label: 'Start', onTap: () => _showExercise(context, _today.first)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: _Seen(
                      builder: (_, t) => CustomPaint(
                        painter: _RingPainter(0.43 * t, _green, 5),
                        child: Center(child: Text('43%', style: _t(11, w: FontWeight.w800))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('of plan', style: _t(11.5, w: FontWeight.w600, c: _muted)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget _chip(IconData i, String s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 13, color: _muted),
        const SizedBox(width: 4),
        Text(s, style: _t(11.5, w: FontWeight.w700)),
      ]),
    );

class _DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DarkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _ink.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _mint),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(label, style: _t(14, w: FontWeight.w800, c: Colors.white)),
        ]),
      ),
    );
  }
}
