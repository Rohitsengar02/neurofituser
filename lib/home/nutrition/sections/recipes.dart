part of '../nutrition_tab_v3.dart';

// =====================================================================
//  RECIPES
// =====================================================================

const _recipes = [
  ('Green power bowl', '520 kcal · 15 min · 32g protein', '1512621776951-a57141f2eefd', _green),
  ('Protein smoothie', '310 kcal · 5 min · 28g protein', '1553530666-ba11a7da3888', _pink),
  ('Mediterranean plate', '580 kcal · 20 min · 30g protein', '1467003909585-2f8a72700288', _amber),
  ('Salmon poke', '540 kcal · 15 min · 36g protein', '1546069901-ba9599a7e63c', _orange),
];

class _Recipes extends StatelessWidget {
  const _Recipes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recipes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = _recipes[i];
          return ScrollReveal(
            delayMs: i * 80,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 12))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                _photo(r.$3, c: r.$4),
                Positioned(
                  right: 10,
                  top: 10,
                  child: LiquidGlass(
                    style: LiquidGlassStyle.clear,
                    shape: BoxShape.circle,
                    shadow: false,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.favorite_border_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: LiquidGlass(
                    style: LiquidGlassStyle.clear,
                    borderRadius: BorderRadius.circular(20),
                    colors: [Colors.black.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.42)],
                    shadow: false,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14.5, w: FontWeight.w800, c: Colors.white)),
                      const SizedBox(height: 2),
                      Text(r.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11, w: FontWeight.w600, c: Colors.white.withValues(alpha: 0.85))),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
