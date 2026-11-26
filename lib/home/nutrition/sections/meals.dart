part of '../nutrition_tab_v3.dart';

// =====================================================================
//  MEALS
// =====================================================================

const _meals = [
  ('Breakfast', '8:10 AM', 'Avocado toast & eggs', 420, '1525351484163-7529414344d8', 22, 38, 18),
  ('Lunch', '1:05 PM', 'Chicken quinoa bowl', 610, '1546069901-ba9599a7e63c', 46, 62, 16),
  ('Snack', '4:30 PM', 'Berry yogurt parfait', 390, '1488477181946-6428a0291777', 20, 44, 12),
  ('Dinner', 'Suggested', 'Salmon & greens', 0, '1467003909585-2f8a72700288', 34, 18, 20),
];

class _Meals extends StatelessWidget {
  const _Meals();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        for (var i = 0; i < _meals.length; i++) ...[
          ScrollReveal(
            delayMs: (i % 2) * 70,
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(26),
              padding: const EdgeInsets.all(10),
              onTap: () => _openLog(context),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(width: 86, height: 86, child: _photo(_meals[i].$5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(_meals[i].$1, style: _t(15, w: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(_meals[i].$2,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11.5, w: FontWeight.w600, c: _faint)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(_meals[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5, w: FontWeight.w600, c: _muted)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _macroPill('P', _meals[i].$6, _purple),
                      const SizedBox(width: 5),
                      _macroPill('C', _meals[i].$7, _amber),
                      const SizedBox(width: 5),
                      _macroPill('F', _meals[i].$8, _pink),
                    ]),
                  ]),
                ),
                const SizedBox(width: 6),
                _meals[i].$4 == 0
                    ? Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: _ink),
                        child: const Icon(Icons.add_rounded, color: Colors.white),
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${_meals[i].$4}', style: _n(18)),
                        Text('kcal', style: _t(11, w: FontWeight.w600, c: _muted)),
                      ]),
              ]),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

Widget _macroPill(String l, int g, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text('$l ${g}g', style: _t(11, w: FontWeight.w700, c: Color.lerp(c, _ink, 0.35)!)),
    );
