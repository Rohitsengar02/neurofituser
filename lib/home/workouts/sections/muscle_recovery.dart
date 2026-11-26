part of '../workout_tab_v2.dart';

// =====================================================================
//  MUSCLE RECOVERY
// =====================================================================

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Chest', 0.62, _orange, 'Trained today'),
      ('Shoulders', 0.55, _orange, 'Trained today'),
      ('Back', 0.9, _green, 'Ready'),
      ('Legs', 1.0, _green, 'Fully recovered'),
      ('Arms', 0.74, _amber, 'Almost ready'),
      ('Core', 0.86, _green, 'Ready'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(18),
        child: _Seen(
          duration: const Duration(milliseconds: 1600),
          builder: (_, t) => Column(children: [
            for (var i = 0; i < rows.length; i++) ...[
              Row(children: [
                SizedBox(width: 82, child: Text(rows[i].$1, style: _t(13.5, w: FontWeight.w700))),
                Expanded(
                  child: LayoutBuilder(builder: (_, c) {
                    final v = rows[i].$2 * Curves.easeOutCubic.transform(((t * 1.4) - i * 0.08).clamp(0.0, 1.0));
                    // Segmented capsule meter.
                    const seg = 14;
                    return Row(children: [
                      for (var k = 0; k < seg; k++)
                        Expanded(
                          child: Container(
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 1.2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: k / seg < v ? rows[i].$3 : rows[i].$3.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                    ]);
                  }),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text('${(rows[i].$2 * 100 * t).round()}%',
                      textAlign: TextAlign.right, style: _t(12.5, w: FontWeight.w800, c: rows[i].$3)),
                ),
              ]),
              if (i < rows.length - 1) const SizedBox(height: 12),
            ],
          ]),
        ),
      ),
    );
  }
}
