part of '../wellness_tab_v3.dart';

// =====================================================================
//  STRESS
// =====================================================================

class _StressCard extends StatelessWidget {
  const _StressCard();

  @override
  Widget build(BuildContext context) {
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AkSeen(
          duration: const Duration(milliseconds: 1800),
          builder: (_, t) => SizedBox(
            height: 150,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Positioned.fill(child: CustomPaint(painter: _StressGauge(0.32 * t))),
              Positioned(
                bottom: 6,
                child: Column(children: [
                  Text('${(32 * t).round()}', style: akN(42)),
                  const SizedBox(height: 4),
                  Text('Low · relaxed', style: akT(13, w: FontWeight.w700, c: _teal)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          for (final (l, c) in [('Calm', _teal), ('Mild', _green), ('Medium', _amber), ('High', _red)])
            Expanded(
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Flexible(child: Text(l, overflow: TextOverflow.ellipsis, style: akT(11.5, c: akMuted))),
              ]),
            ),
        ]),
        const SizedBox(height: 16),
        Text('What moved it today', style: akT(14, w: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _pill('Workout −12', _green),
          _pill('Meeting +9', _red),
          _pill('Breathing −6', _teal),
          _pill('Coffee +4', _amber),
          _pill('Walk −5', _sky),
        ]),
        const SizedBox(height: 16),
        const DottedLineChart(
          values: [58, 46, 52, 40, 44, 36, 32],
          color: _teal,
          label: 'Stress this week',
          xLabels: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
          height: 110,
        ),
      ]),
    );
  }
}

Widget _pill(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: akT(12, w: FontWeight.w700, c: Color.lerp(c, akInk, 0.25)!)),
    );

class _StressGauge extends CustomPainter {
  final double v;
  _StressGauge(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 4);
    final r = math.min(size.width / 2 - 10, size.height - 14);
    const segs = [_teal, _green, _amber, _red];
    const gap = 0.04;
    for (var i = 0; i < 4; i++) {
      final start = math.pi + i * math.pi / 4 + gap / 2;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        math.pi / 4 - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = segs[i].withValues(alpha: 0.85),
      );
    }
    final a = math.pi + math.pi * v;
    final tip = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(tip, 11, Paint()..color = Colors.white);
    canvas.drawCircle(tip, 11, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = akInk);
  }

  @override
  bool shouldRepaint(covariant _StressGauge o) => o.v != v;
}
