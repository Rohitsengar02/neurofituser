part of '../nutrition_tab_v3.dart';

// =====================================================================
//  CALORIES GAUGE
// =====================================================================

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard();

  @override
  Widget build(BuildContext context) {
    final eaten = IslandStats.eaten, burned = IslandStats.burned, budget = IslandStats.budget;
    final left = IslandStats.left;
    return _glass(
      child: _Seen(
        duration: const Duration(milliseconds: 1700),
        builder: (_, t) => Column(children: [
          SizedBox(
            height: 150,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Positioned.fill(child: CustomPaint(painter: _Gauge(eaten / (budget + burned) * t, burned / (budget + burned) * t))),
              Positioned(
                bottom: 4,
                child: Column(children: [
                  Text('${(left * t).round()}', style: _n(46, w: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('kcal left', style: _t(13, w: FontWeight.w600, c: _muted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            _stat('Eaten', (eaten * t).round(), _orange, Icons.restaurant_rounded),
            _divider(),
            _stat('Burned', (burned * t).round(), _red, Icons.local_fire_department_rounded),
            _divider(),
            _stat('Goal', budget, _blue, Icons.flag_rounded),
          ]),
        ]),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: const Color(0xFFE5E7EB));

  Widget _stat(String l, int v, Color c, IconData i) => Expanded(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, size: 14, color: c),
            const SizedBox(width: 4),
            Text(l, style: _t(12, w: FontWeight.w600, c: _muted)),
          ]),
          const SizedBox(height: 4),
          Text('$v', style: _n(19)),
        ]),
      );
}

/// Half-circle gauge: eaten arc in orange, burned credit in soft red.
class _Gauge extends CustomPainter {
  final double eaten, burned;
  _Gauge(this.eaten, this.burned);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 16.0;
    final r = math.min(size.width / 2, size.height) - w;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height - 4), radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, p..color = const Color(0xFFEEF2F7));
    // Ticks.
    final tick = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k <= 20; k++) {
      final a = math.pi + math.pi * k / 20;
      final o = rect.center + Offset(math.cos(a), math.sin(a)) * (r - w - 4);
      final i = rect.center + Offset(math.cos(a), math.sin(a)) * (r - w - (k % 5 == 0 ? 12 : 8));
      canvas.drawLine(i, o, tick);
    }
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * eaten,
      false,
      p
        ..color = Colors.white
        ..shader = const SweepGradient(
          startAngle: math.pi,
          endAngle: 2 * math.pi,
          colors: [Color(0xFFFFB37A), _orange],
        ).createShader(rect),
    );
    p.shader = null;
    canvas.drawArc(rect, math.pi + math.pi * eaten, math.pi * burned, false, p..color = _red.withValues(alpha: 0.35));
    final end = math.pi + math.pi * eaten;
    final knob = rect.center + Offset(math.cos(end), math.sin(end)) * r;
    canvas.drawCircle(knob, 11, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 6, Paint()..color = _orange);
  }

  @override
  bool shouldRepaint(covariant _Gauge o) => o.eaten != eaten || o.burned != burned;
}
