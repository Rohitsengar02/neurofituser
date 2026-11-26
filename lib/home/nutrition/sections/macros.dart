part of '../nutrition_tab_v3.dart';

// =====================================================================
//  MACROS
// =====================================================================

const _macros = [
  ('Protein', 100, 140, _purple),
  ('Carbs', 245, 350, _amber),
  ('Fat', 48, 65, _pink),
  ('Fiber', 18, 30, _green),
];

class _MacrosCard extends StatelessWidget {
  const _MacrosCard();

  @override
  Widget build(BuildContext context) {
    return _glass(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      child: _Seen(
        duration: const Duration(milliseconds: 1600),
        builder: (_, t) => Row(children: [
          for (var i = 0; i < _macros.length; i++)
            Expanded(
              child: Column(children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _Ring(
                      _macros[i].$2 / _macros[i].$3 * Curves.easeOutCubic.transform(((t * 1.3) - i * 0.08).clamp(0.0, 1.0)),
                      _macros[i].$4,
                      7,
                    ),
                    child: Center(child: Text('${(_macros[i].$2 * t).round()}', style: _n(16))),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_macros[i].$1, style: _t(12.5, w: FontWeight.w700)),
                Text('${_macros[i].$3 - _macros[i].$2} g left', style: _t(11, w: FontWeight.w600, c: _muted)),
              ]),
            ),
        ]),
      ),
    );
  }
}
