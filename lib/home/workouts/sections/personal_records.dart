part of '../workout_tab_v2.dart';

// =====================================================================
//  PERSONAL RECORDS
// =====================================================================

class _Records extends StatelessWidget {
  const _Records();

  @override
  Widget build(BuildContext context) {
    const recs = [
      ('Bench', 80.0, '0025-EIeI8Vf.jpg', _orange, <double>[60, 65, 67.5, 70, 72.5, 75, 80]),
      ('Squat', 110.0, '0043-qXTaZnJ.jpg', _green, <double>[85, 90, 95, 100, 100, 105, 110]),
      ('Deadlift', 140.0, '0032-ila4NZS.jpg', _purple, <double>[110, 115, 120, 125, 130, 135, 140]),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        for (var i = 0; i < recs.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LayoutBuilder(
                  builder: (_, c) => Row(children: [
                    if (c.maxWidth > 104) ...[
                      _ExerciseThumb(recs[i].$3, size: 34),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(recs[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5, w: FontWeight.w800)),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedDotNumber(value: recs[i].$2, height: 22, color: recs[i].$4),
                ),
                Text('kg · best', style: _t(11, w: FontWeight.w600, c: _muted)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: _Seen(builder: (_, t) => CustomPaint(painter: _Spark(recs[i].$5, recs[i].$4, t))),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Spark extends CustomPainter {
  final List<double> v;
  final Color c;
  final double t;
  _Spark(this.v, this.c, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final mn = v.reduce(math.min), mx = v.reduce(math.max);
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(size.width * i / (v.length - 1), size.height - 3 - (v[i] - mn) / (mx - mn) * (size.height - 6)),
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (t > 0.98) canvas.drawCircle(pts.last, 3.5, Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _Spark o) => o.t != t;
}
