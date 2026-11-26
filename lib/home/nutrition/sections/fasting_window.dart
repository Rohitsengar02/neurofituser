part of '../nutrition_tab_v3.dart';

// =====================================================================
//  FASTING WINDOW
// =====================================================================

class _FastingCard extends StatelessWidget {
  const _FastingCard();

  @override
  Widget build(BuildContext context) {
    return _glass(
      child: Row(children: [
        SizedBox(
          width: 130,
          height: 130,
          child: _Seen(
            duration: const Duration(milliseconds: 1800),
            builder: (_, t) => CustomPaint(
              painter: _Clock(t),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('5:20', style: _n(24, w: FontWeight.w800)),
                  Text('left to eat', style: _t(11, w: FontWeight.w600, c: _muted)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('16 : 8', style: _n(22, w: FontWeight.w800)),
            Text('Intermittent fasting', style: _t(12.5, w: FontWeight.w600, c: _muted)),
            const SizedBox(height: 12),
            _legend(_green, 'Eating', '12 PM – 8 PM'),
            const SizedBox(height: 6),
            _legend(const Color(0xFFCBD5E1), 'Fasting', '8 PM – 12 PM'),
            const SizedBox(height: 10),
            Text('6-day streak', style: _t(12, w: FontWeight.w800, c: _orange)),
          ]),
        ),
      ]),
    );
  }

  Widget _legend(Color c, String a, String b) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(a, style: _t(12, w: FontWeight.w700)),
        const SizedBox(width: 6),
        Flexible(child: Text(b, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11.5, w: FontWeight.w600, c: _muted))),
      ]);
}

/// 24-hour dial: fasting track, eating window in green, a "now" knob.
class _Clock extends CustomPainter {
  final double t;
  _Clock(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 12.0;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - w / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    double ang(double h) => -math.pi / 2 + h / 24 * 2 * math.pi;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, p..color = const Color(0xFFE2E8F0));
    canvas.drawArc(rect, ang(12), (8 / 24) * 2 * math.pi * t, false, p..color = _green);
    final now = ang(14.67);
    final k = c + Offset(math.cos(now), math.sin(now)) * r;
    if (t > 0.9) {
      canvas.drawCircle(k, 9, Paint()..color = Colors.white);
      canvas.drawCircle(k, 5, Paint()..color = _ink);
    }
    for (var h = 0; h < 24; h += 6) {
      final a = ang(h.toDouble());
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r - 16), 1.8, Paint()..color = _faint);
    }
  }

  @override
  bool shouldRepaint(covariant _Clock o) => o.t != t;
}
