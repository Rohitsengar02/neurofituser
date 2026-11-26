part of '../shop_tab_v3.dart';

// =====================================================================
//  SEARCH + CART
// =====================================================================

class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                const Icon(Icons.search_rounded, color: akMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Search whey, shoes, mats…', overflow: TextOverflow.ellipsis, style: akT(14, w: FontWeight.w500, c: akFaint))),
                const Icon(Icons.mic_none_rounded, color: akMuted, size: 20),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          LiquidGlass(
            style: LiquidGlassStyle.material,
            borderRadius: BorderRadius.circular(20),
            onTap: () => shopPush(context, const CartPage()),
            child: SizedBox(
              width: 52,
              height: 50,
              child: Stack(alignment: Alignment.center, children: [
                const Icon(Icons.shopping_bag_outlined, color: akInk),
                Positioned(
                  top: 7,
                  right: 8,
                  child: ValueListenableBuilder<int>(
                    valueListenable: ShopCart.count,
                    builder: (_, n, _) => TweenAnimationBuilder<double>(
                      key: ValueKey(n),
                      tween: Tween(begin: 1.6, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: akSpring,
                      builder: (_, s, c) => Transform.scale(scale: s, child: c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(10)),
                        child: Text('$n', style: akT(10.5, w: FontWeight.w800, c: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
