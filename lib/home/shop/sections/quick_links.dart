part of '../shop_tab_v3.dart';

// =====================================================================
//  PRODUCT PAGE
// =====================================================================
// =====================================================================
//  QUICK LINKS: orders, wishlist, offers, bag
// =====================================================================

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final active = store.orders.where((o) => o.active).length;
        final items = [
          (Icons.receipt_long_rounded, 'Orders', const Color(0xFF3B82F6), active, () => shopPush(context, const OrdersPage())),
          (Icons.favorite_rounded, 'Wishlist', _red, store.saved.value.length, () => shopPush(context, const WishlistPage())),
          (Icons.local_offer_rounded, 'Offers', _violet, coupons.length, () => shopPush(context, const OffersPage())),
          (Icons.shopping_bag_rounded, 'Bag', _orange, store.count, () => shopPush(context, const CartPage())),
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: ScrollReveal(
                  delayMs: i * 60,
                  child: LiquidGlass(
                    style: LiquidGlassStyle.material,
                    borderRadius: BorderRadius.circular(22),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onTap: items[i].$5,
                    child: Column(children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [items[i].$3.withValues(alpha: 0.7), items[i].$3],
                            ),
                            boxShadow: [BoxShadow(color: items[i].$3.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Icon(items[i].$1, color: Colors.white, size: 20),
                        ),
                        if (items[i].$4 > 0)
                          Positioned(right: -8, top: -6, child: CountBadge(items[i].$4, color: akInk)),
                      ]),
                      const SizedBox(height: 7),
                      Text(items[i].$2, style: akT(12, w: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }
}
