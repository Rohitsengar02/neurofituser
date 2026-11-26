part of '../nutrition_tab_v3.dart';

// =====================================================================
//  WEEK
// =====================================================================

class _WeekCard extends StatefulWidget {
  const _WeekCard();
  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> {
  static const _days = ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Today'];
  static const _kcal = [1650.0, 1820, 1540, 1760, 1900, 1610, 1420];
  int _sel = 6;

  @override
  Widget build(BuildContext context) {
    const goal = 1800.0, mx = 2100.0;
    return _glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_kcal[_sel].round()}', style: _n(32, w: FontWeight.w800)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('kcal · ${_days[_sel]}', style: _t(12.5, w: FontWeight.w600, c: _muted)),
          ),
          const Spacer(),
          Text('Avg 1,671', style: _t(12.5, w: FontWeight.w700, c: _muted)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: _Seen(
            duration: const Duration(milliseconds: 1400),
            builder: (_, t) => LayoutBuilder(builder: (_, c) {
              final goalY = c.maxHeight - 22 - (goal / mx) * (c.maxHeight - 30);
              return Stack(children: [
                // Goal line.
                Positioned(
                  left: 0,
                  right: 0,
                  top: goalY,
                  child: Row(children: [
                    Expanded(child: CustomPaint(size: const Size(double.infinity, 1), painter: _Dash())),
                    const SizedBox(width: 4),
                    Text('Goal', style: _t(11, w: FontWeight.w700, c: _blue)),
                  ]),
                ),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sel = i);
                        },
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Builder(builder: (_) {
                            final g = _spring.transform(((t * 1.5) - i * 0.07).clamp(0.0, 1.0));
                            final over = _kcal[i] > goal;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _sel == i ? 24 : 18,
                              height: math.max(6, (_kcal[i] / mx) * (c.maxHeight - 30) * g),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: _sel == i
                                      ? [over ? _orange : _sky, over ? const Color(0xFFEA580C) : _blue]
                                      : [(over ? _orange : _blue).withValues(alpha: 0.35), (over ? _orange : _blue).withValues(alpha: 0.18)],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          Text(_days[i],
                              maxLines: 1,
                              style: _t(11, w: _sel == i ? FontWeight.w800 : FontWeight.w600, c: _sel == i ? _ink : _faint)),
                        ]),
                      ),
                    ),
                ]),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}

class _Dash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _blue.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 3.5, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
