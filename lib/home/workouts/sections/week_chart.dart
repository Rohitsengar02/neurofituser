part of '../workout_tab_v2.dart';

// =====================================================================
//  WEEK CHART
// =====================================================================

class _WeekCard extends StatefulWidget {
  const _WeekCard();
  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> {
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _mins = [42.0, 0, 38, 51, 45, 48, 0];
  int _sel = 5;

  @override
  Widget build(BuildContext context) {
    const mx = 60.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AnimatedDotNumber(value: 224, height: 30, color: _ink),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('min trained', style: _t(12.5, w: FontWeight.w600, c: _muted)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('↑ 12%', style: _t(12, w: FontWeight.w800, c: _green)),
            ),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: _Seen(
              duration: const Duration(milliseconds: 1400),
              builder: (_, t) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sel = i);
                        },
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _sel == i ? 1 : 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(8)),
                              child: Text('${_mins[i].round()}m', style: _t(11, w: FontWeight.w800, c: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final stagger = ((t * 1.5) - i * 0.07).clamp(0.0, 1.0);
                            final grow = _spring.transform(stagger);
                            final h = _mins[i] == 0 ? 8.0 : math.max(8.0, (_mins[i] / mx) * 104 * grow);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _sel == i ? 26 : 22,
                              height: h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                gradient: _mins[i] == 0
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: _sel == i
                                            ? const [Color(0xFF4ADE80), _green]
                                            : [_green.withValues(alpha: 0.35), _green.withValues(alpha: 0.18)],
                                      ),
                                color: _mins[i] == 0 ? const Color(0xFFEDEFEE) : null,
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Text(_days[i],
                              style: _t(11.5, w: _sel == i ? FontWeight.w800 : FontWeight.w600, c: _sel == i ? _ink : _faint)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Avg heart rate per session', style: _t(12.5, w: FontWeight.w700, c: _muted)),
          const SizedBox(height: 6),
          const DottedLineChart(
            values: <double>[128, 134, 131, 142, 139, 146, 141, 149],
            color: _pink,
            label: '149 bpm',
            height: 96,
          ),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, w;
  final Color c;
  _RingPainter(this.v, this.c, this.w);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - w / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = c.withValues(alpha: 0.14));
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * v, false, p..color = c);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v;
}
