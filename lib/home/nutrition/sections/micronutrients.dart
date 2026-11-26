part of '../nutrition_tab_v3.dart';

// =====================================================================
//  MICRONUTRIENTS
// =====================================================================

class _MicrosCard extends StatelessWidget {
  const _MicrosCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Vitamin C', 0.82, '74 / 90 mg', _orange),
      ('Iron', 0.64, '11.5 / 18 mg', _red),
      ('Calcium', 0.48, '480 / 1000 mg', _sky),
      ('Vitamin D', 0.3, '4.5 / 15 µg', _amber),
      ('Potassium', 0.71, '2.5 / 3.5 g', _green),
      ('Magnesium', 0.55, '230 / 420 mg', _purple),
    ];
    return _glass(
      child: _Seen(
        duration: const Duration(milliseconds: 1600),
        builder: (_, t) => Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(children: [
              Expanded(child: Text(rows[i].$1, style: _t(13.5, w: FontWeight.w700))),
              Text(rows[i].$3, style: _t(11.5, w: FontWeight.w600, c: _muted)),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text('${(rows[i].$2 * 100 * t).round()}%',
                    textAlign: TextAlign.right, style: _n(13, c: rows[i].$4)),
              ),
            ]),
            const SizedBox(height: 6),
            LayoutBuilder(builder: (_, c) {
              final v = rows[i].$2 * Curves.easeOutCubic.transform(((t * 1.4) - i * 0.07).clamp(0.0, 1.0));
              return Stack(children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(color: rows[i].$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                ),
                Container(
                  height: 8,
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [rows[i].$4.withValues(alpha: 0.55), rows[i].$4]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ]);
            }),
            if (i < rows.length - 1) const SizedBox(height: 14),
          ],
        ]),
      ),
    );
  }
}
