part of '../shop_tab_v3.dart';

// =====================================================================
//  CATEGORIES
// =====================================================================

class _Categories extends StatefulWidget {
  const _Categories();
  @override
  State<_Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<_Categories> {
  int sel = 0;
  static const _cats = [
    ('All', Icons.apps_rounded, _orange),
    ('Protein', Icons.science_rounded, _violet),
    ('Equipment', Icons.fitness_center_rounded, _blue),
    ('Wearables', Icons.watch_rounded, _teal),
    ('Apparel', Icons.checkroom_rounded, Color(0xFFEC4899)),
    ('Yoga', Icons.self_improvement_rounded, _green),
    ('Accessories', Icons.backpack_rounded, _amber),
    ('Recovery', Icons.spa_rounded, Color(0xFF6366F1)),
    ('Pre-workout', Icons.bolt_rounded, _red),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = _cats[i];
          final on = i == sel;
          return ScrollReveal(
            delayMs: math.min(i, 5) * 50,
            child: AkPress(
              onTap: () => setState(() => sel = i),
              child: SizedBox(
                width: 66,
                child: Column(children: [
                  LiquidGlass(
                    style: LiquidGlassStyle.material,
                    shape: BoxShape.circle,
                    shadow: on,
                    colors: on ? [c.$3.withValues(alpha: 0.8), c.$3] : [c.$3.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.7)],
                    child: SizedBox(width: 60, height: 60, child: Icon(c.$2, color: on ? Colors.white : c.$3, size: 26)),
                  ),
                  const SizedBox(height: 8),
                  Text(c.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, w: FontWeight.w700, c: on ? akInk : akMuted)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
