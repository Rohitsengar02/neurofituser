part of '../nutrition_tab_v3.dart';

// =====================================================================
//  SMART SWAPS
// =====================================================================

class _Swaps extends StatelessWidget {
  const _Swaps();

  @override
  Widget build(BuildContext context) {
    const swaps = [
      ('White rice', 'Quinoa', '+6g protein · +3g fiber', Icons.rice_bowl_rounded, _amber),
      ('Soda', 'Sparkling water + lime', '−140 kcal · 0g sugar', Icons.local_drink_rounded, _sky),
      ('Chips', 'Roasted chickpeas', '+7g protein · −8g fat', Icons.cookie_rounded, _orange),
    ];
    return _glass(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(children: [
        for (var i = 0; i < swaps.length; i++) ...[
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: swaps[i].$5.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(swaps[i].$4, color: swaps[i].$5, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(swaps[i].$1,
                      style: _t(13.5, w: FontWeight.w600, c: _muted).copyWith(decoration: TextDecoration.lineThrough)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: _green),
                  ),
                  Text(swaps[i].$2, style: _t(13.5, w: FontWeight.w800)),
                ]),
                const SizedBox(height: 2),
                Text(swaps[i].$3, style: _t(11.5, w: FontWeight.w700, c: _green)),
              ]),
            ),
          ]),
          if (i < swaps.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
        ],
      ]),
    );
  }
}
