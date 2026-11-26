part of '../workout_tab_v2.dart';

// =====================================================================
//  BROWSE BY TYPE
// =====================================================================

const _types = [
  ('Strength', '42 workouts', '0043-qXTaZnJ.jpg', _green),
  ('Cardio', '28 workouts', '0685-oLrKqDH.jpg', _orange),
  ('HIIT', '19 workouts', '1160-dK9394r.jpg', _pink),
  ('Core', '24 workouts', '0274-TFqbd8t.jpg', _amber),
  ('Mobility', '16 workouts', '1460-IZVHb27.jpg', _purple),
  ('Back', '21 workouts', '0027-eZyBC3j.jpg', _blue),
];

class _TypeGrid extends StatelessWidget {
  const _TypeGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < _types.length; i++)
            SizedBox(
              width: w,
              child: ScrollReveal(
                delayMs: (i % 2) * 90,
                child: LiquidGlass(
                  style: LiquidGlassStyle.material,
                  borderRadius: BorderRadius.circular(24),
                  tint: _types[i].$4,
                  padding: const EdgeInsets.all(12),
                  onTap: () {},
                  child: SizedBox(
                    height: 128,
                    child: Stack(children: [
                      Positioned(
                        right: -6,
                        bottom: -6,
                        width: w * 0.58,
                        height: w * 0.58,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(_ex(_types[i].$3), fit: BoxFit.contain),
                        ),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _types[i].$4),
                        ),
                        const SizedBox(height: 8),
                        Text(_types[i].$1, style: _t(16, w: FontWeight.w800, ls: -0.3)),
                        Text(_types[i].$2, style: _t(11.5, w: FontWeight.w600, c: _muted)),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}
