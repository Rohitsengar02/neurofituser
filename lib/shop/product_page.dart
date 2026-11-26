import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import 'cart_page.dart';
import 'checkout_page.dart';
import 'shop_data.dart';
import 'shop_ui.dart';

// Product detail: swipeable gallery on tinted stages, price with the best
// coupon price, option chips, quantity, delivery date by PIN code,
// highlights, details, reviews, a bought-together bundle, similar items
// and a sticky Add to bag / Buy now bar. Adding opens the bag slider.

void openProduct(BuildContext context, Product p) => shopPush(context, ProductPage(p));

/// Adds to the bag and shows the "Added to bag" bottom slider.
void addToBag(BuildContext context, Product p, {String? option, int qty = 1}) {
  HapticFeedback.mediumImpact();
  ShopStore.I.add(p, option: option, qty: qty);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (_) => _AddedSheet(p: p, option: option ?? p.options.first, qty: qty),
  );
}

class ProductPage extends StatefulWidget {
  final Product p;
  const ProductPage(this.p, {super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _pc = PageController();
  final _pin = TextEditingController(text: '110016');
  int option = 0, qty = 1, page = 0;
  String? delivery;
  bool showMore = false;

  static const _stages = [
    [Color(0xFFFFF1E6), Color(0xFFFFE0C7)],
    [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
    [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
  ];

  @override
  void initState() {
    super.initState();
    _checkPin();
    ShopStore.I.markViewed(widget.p);
  }

  @override
  void dispose() {
    _pc.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _checkPin() {
    final pin = _pin.text.trim();
    setState(() {
      if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin)) {
        delivery = null;
      } else {
        final days = 2 + int.parse(pin.substring(0, 1)) % 3;
        delivery = shortDate(DateTime.now().add(Duration(days: days)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final store = ShopStore.I;
    final similar = shopProducts.where((x) => x != p && (x.cat == p.cat || x.brand == p.brand)).toList();
    final more = similar.length < 4 ? [...similar, ...shopProducts.where((x) => x != p && !similar.contains(x)).take(4 - similar.length)] : similar;
    final buddy = shopProducts.where((x) => x.cat == 'Accessories' && x != p).firstOrNull ?? shopProducts.where((x) => x != p).firstOrNull;
    final deal = store.bestDealFor(p);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: shopBg,
      body: Stack(children: [
        const Positioned.fill(child: ShopBackdrop()),
        CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
          SliverToBoxAdapter(child: _gallery(p, top)),
          SliverToBoxAdapter(
            child: Rise(
              child: ShopCard(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                radius: 28,
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(p.brand.toUpperCase(), style: akT(11.5, w: FontWeight.w800, c: akFaint, ls: 1.2))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: shopGreen, borderRadius: BorderRadius.circular(9)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${p.rating}', style: akT(12, w: FontWeight.w800, c: Colors.white)),
                        const SizedBox(width: 2),
                        const Icon(Icons.star_rounded, size: 13, color: Colors.white),
                      ]),
                    ),
                    const SizedBox(width: 6),
                    Text('${p.reviews} ratings', style: akT(12, w: FontWeight.w600, c: akMuted)),
                  ]),
                  const SizedBox(height: 6),
                  Text(p.name, style: akT(23, w: FontWeight.w800, ls: -0.6, h: 1.15)),
                  const SizedBox(height: 12),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 8, children: [
                    Text(rs(p.price), style: akN(30)),
                    if (p.off > 0) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('MRP ${rs(p.old)}', style: akT(13, c: akFaint).copyWith(decoration: TextDecoration.lineThrough)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('${p.off}% off', style: akT(13.5, w: FontWeight.w800, c: shopGreen)),
                      ),
                    ],
                  ]),
                  Text('Inclusive of all taxes', style: akT(11.5, w: FontWeight.w500, c: akFaint)),
                  if (deal != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: deal.$1.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: deal.$1.color.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        Icon(Icons.local_offer_rounded, color: deal.$1.color, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: 'Get it for ', style: akT(13, w: FontWeight.w600, c: akMuted)),
                            TextSpan(text: rs(p.price - deal.$2), style: akT(13.5, w: FontWeight.w800)),
                            TextSpan(text: ' with ', style: akT(13, w: FontWeight.w600, c: akMuted)),
                            TextSpan(text: deal.$1.code, style: akT(13, w: FontWeight.w800, c: deal.$1.color)),
                          ])),
                        ),
                        GestureDetector(
                          onTap: () => shopPush(context, const OffersPage()),
                          child: Text('All offers', style: akT(12.5, w: FontWeight.w800, c: deal.$1.color)),
                        ),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _options(p)),
          SliverToBoxAdapter(child: _deliveryCard()),
          SliverToBoxAdapter(child: _highlights()),
          SliverToBoxAdapter(child: _details(p)),
          SliverToBoxAdapter(child: _reviews(p)),
          if (buddy != null) SliverToBoxAdapter(child: _together(p, buddy)),
          if (more.isNotEmpty) const SliverToBoxAdapter(child: AkHead('You may also like')),
          if (more.isNotEmpty) SliverToBoxAdapter(child: ProductRail(items: more)),
          SliverToBoxAdapter(child: SizedBox(height: 120 + MediaQuery.paddingOf(context).bottom)),
        ]),
        // Top bar
        Positioned(
          top: top + 8,
          left: 12,
          right: 12,
          child: Row(children: [
            GlassIcon(Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).maybePop()),
            const Spacer(),
            ValueListenableBuilder<Set<String>>(
              valueListenable: store.saved,
              builder: (_, s, _) => GlassIcon(
                s.contains(p.name) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: s.contains(p.name) ? shopRed : akInk,
                onTap: () {
                  HapticFeedback.selectionClick();
                  store.toggleSave(p);
                  shopToast(context, store.isSaved(p) ? 'Saved to your wishlist' : 'Removed from wishlist',
                      icon: Icons.favorite_rounded,
                      action: store.isSaved(p) ? 'View' : null,
                      onAction: () => shopPush(context, const WishlistPage()));
                },
              ),
            ),
            const SizedBox(width: 8),
            CartIconButton(onTap: () => shopPush(context, const CartPage())),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ShopBottomBar(
            child: Row(children: [
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                QtyStepper(qty: qty, small: true, onChanged: (q) => setState(() => qty = math.max(1, q))),
              ]),
              const SizedBox(width: 10),
              Expanded(
                child: ShopButton('Add to bag',
                    outline: true,
                    color: akInk,
                    height: 50,
                    onTap: () => addToBag(context, p, option: p.options[option], qty: qty)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShopButton('Buy now', color: shopOrange, height: 50, onTap: () {
                  HapticFeedback.mediumImpact();
                  ShopStore.I.add(p, option: p.options[option], qty: qty);
                  shopPush(context, const CheckoutPage());
                }),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _gallery(Product p, double top) {
    return SizedBox(
      height: 360 + top,
      child: Stack(children: [
        PageView.builder(
          controller: _pc,
          itemCount: 3,
          onPageChanged: (i) {
            HapticFeedback.selectionClick();
            setState(() => page = i);
          },
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _pc,
            builder: (_, child) {
              final pos = _pc.hasClients && _pc.position.haveDimensions ? (_pc.page ?? 0) - i : 0.0;
              return Transform.translate(
                offset: Offset(pos * 80, 0),
                child: Transform.scale(scale: 1 - pos.abs() * 0.1, child: child),
              );
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(16, top + 62, 16, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _stages[i]),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.35)),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(p.cover ? 0 : 22),
                    child: Hero(
                      tag: i == 0 ? 'p-${p.name}' : 'p-${p.name}-$i',
                      child: p.cover
                          ? productImage(p.image, fit: BoxFit.cover, alignment: [Alignment.center, Alignment.topCenter, Alignment.bottomCenter][i])
                          : Transform.rotate(angle: [0.0, -0.06, 0.06][i], child: productImage(p.image, fit: BoxFit.contain)),
                    ),
                  ),
                ),
                if (p.off > 0)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: shopRed, borderRadius: BorderRadius.circular(10)),
                      child: Text('${p.off}% OFF', style: akT(11, w: FontWeight.w800, c: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 22,
          left: 0,
          right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: akSpring,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == page ? akInk : akInk.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _options(Product p) => Rise(
        delay: 60,
        child: ShopCard(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(p.optionLabel, style: akT(15, w: FontWeight.w800)),
              const SizedBox(width: 6),
              Text('· ${p.options[option]}', style: akT(14, w: FontWeight.w600, c: akMuted)),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < p.options.length; i++)
                AkPress(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => option = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: akSpring,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: i == option ? akInk : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: i == option ? akInk : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(p.options[i], style: akT(13.5, w: FontWeight.w700, c: i == option ? Colors.white : akInk)),
                  ),
                ),
            ]),
          ]),
        ),
      );

  Widget _deliveryCard() => Rise(
        delay: 100,
        child: ShopCard(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Delivery', style: akT(15, w: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.location_on_outlined, size: 18, color: akMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _pin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: akT(14.5, w: FontWeight.w700),
                    decoration: const InputDecoration(border: InputBorder.none, counterText: '', hintText: 'PIN code'),
                    onSubmitted: (_) => _checkPin(),
                  ),
                ),
                TextButton(onPressed: _checkPin, child: Text('Check', style: akT(13.5, w: FontWeight.w800, c: shopOrange))),
              ]),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: delivery == null
                  ? Text('Enter a valid 6-digit PIN code', key: const ValueKey('x'), style: akT(13, w: FontWeight.w600, c: shopRed))
                  : Row(key: ValueKey(delivery), children: [
                      const Icon(Icons.local_shipping_rounded, size: 18, color: shopGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: 'Delivery by ', style: akT(13, w: FontWeight.w600, c: akMuted)),
                          TextSpan(text: delivery, style: akT(13, w: FontWeight.w800)),
                          TextSpan(
                              text: widget.p.price >= ShopStore.freeOver ? ' · Free' : ' · Free over ₹999',
                              style: akT(13, w: FontWeight.w700, c: shopGreen)),
                        ])),
                      ),
                    ]),
            ),
          ]),
        ),
      );

  Widget _highlights() {
    const items = [
      (Icons.verified_rounded, '100% genuine', Color(0xFF3B82F6)),
      (Icons.autorenew_rounded, '7-day returns', Color(0xFF8B5CF6)),
      (Icons.payments_rounded, 'Cash on delivery', Color(0xFF16A34A)),
      (Icons.bolt_rounded, 'Ships in 24 h', Color(0xFFF97316)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Rise(
              delay: 120 + i * 50,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: items[i].$3.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(items[i].$1, size: 18, color: items[i].$3),
                  ),
                  const SizedBox(height: 6),
                  Text(items[i].$2, textAlign: TextAlign.center, maxLines: 2, style: akT(10.5, w: FontWeight.w700, h: 1.2)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _details(Product p) => ShopCard(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('About this item', style: akT(15, w: FontWeight.w800)),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Text(p.blurb,
                maxLines: showMore ? null : 2,
                overflow: showMore ? null : TextOverflow.ellipsis,
                style: akT(13.5, w: FontWeight.w500, c: akMuted, h: 1.5)),
          ),
          GestureDetector(
            onTap: () => setState(() => showMore = !showMore),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(showMore ? 'Show less' : 'Read more', style: akT(13, w: FontWeight.w800, c: shopOrange)),
            ),
          ),
          const SizedBox(height: 12),
          for (final s in p.specs)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F2F4)))),
              child: Row(children: [
                Expanded(child: Text(s.$1, style: akT(13, w: FontWeight.w500, c: akMuted))),
                Text(s.$2, style: akT(13, w: FontWeight.w700)),
              ]),
            ),
        ]),
      );

  Widget _reviews(Product p) {
    final dist = [0.68, 0.19, 0.08, 0.03, 0.02];
    return ShopCard(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ratings & reviews', style: akT(15, w: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Column(children: [
            Text('${p.rating}', style: akN(40)),
            Row(children: [
              for (var k = 0; k < 5; k++) Icon(Icons.star_rounded, size: 14, color: k < p.rating.round() ? shopAmber : Colors.black12),
            ]),
            const SizedBox(height: 2),
            Text('${p.reviews} ratings', style: akT(11, w: FontWeight.w600, c: akFaint)),
          ]),
          const SizedBox(width: 18),
          Expanded(
            child: AkSeen(
              builder: (_, t) => Column(children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(children: [
                      SizedBox(width: 12, child: Text('${5 - i}', style: akT(11.5, w: FontWeight.w700, c: akMuted))),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: dist[i] * t,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1F2F4),
                            color: i < 2 ? shopGreen : (i == 2 ? shopAmber : shopRed),
                          ),
                        ),
                      ),
                    ]),
                  ),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        for (final r in const [
          ('Aarav M.', 5, 'Exactly as shown and arrived a day early. Quality feels premium.'),
          ('Priya S.', 4, 'Great value for the price. Packaging could be a little better.'),
        ])
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: shopOrange.withValues(alpha: 0.15),
                  child: Text(r.$1[0], style: akT(12, w: FontWeight.w800, c: shopOrange)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(r.$1, style: akT(13, w: FontWeight.w700))),
                for (var k = 0; k < 5; k++) Icon(Icons.star_rounded, size: 13, color: k < r.$2 ? shopAmber : Colors.black12),
              ]),
              const SizedBox(height: 6),
              Text(r.$3, style: akT(13, w: FontWeight.w500, c: akMuted, h: 1.4)),
              const SizedBox(height: 4),
              Text('Verified buyer', style: akT(11, w: FontWeight.w700, c: shopGreen)),
            ]),
          ),
      ]),
    );
  }

  Widget _together(Product p, Product b) {
    final total = p.price + b.price;
    return ShopCard(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bought together', style: akT(15, w: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          ProductThumb(p, size: 70),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.add_rounded, color: akMuted)),
          GestureDetector(onTap: () => openProduct(context, b), child: ProductThumb(b, size: 70)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Both for', style: akT(12, w: FontWeight.w600, c: akMuted)),
              Text(rs(total), style: akN(20)),
              Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, w: FontWeight.w600, c: akFaint)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        ShopButton('Add both to bag', icon: Icons.shopping_bag_rounded, height: 46, onTap: () {
          ShopStore.I.add(b);
          addToBag(context, p, option: p.options[option]);
        }),
      ]),
    );
  }
}

// =====================================================================
//  PRODUCT RAIL (used here, in the cart and in the bag slider)
// =====================================================================

class ProductRail extends StatelessWidget {
  final List<Product> items;
  final double width;
  const ProductRail({super.key, required this.items, this.width = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: width * 1.42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Rise(delay: math.min(i, 4) * 60, child: MiniProductCard(items[i], width: width)),
      ),
    );
  }
}

class MiniProductCard extends StatelessWidget {
  final Product p;
  final double width;
  const MiniProductCard(this.p, {super.key, this.width = 150});

  @override
  Widget build(BuildContext context) => AkPress(
        onTap: () => openProduct(context, p),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: ProductThumb(p, size: width - 16, radius: 16)),
            const SizedBox(height: 8),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12.5, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(rs(p.price), style: akN(14)))),
              AkPress(
                onTap: () => addToBag(context, p),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: akInk, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 17),
                ),
              ),
            ]),
          ]),
        ),
      );
}

// =====================================================================
//  ADDED-TO-BAG SLIDER
// =====================================================================

class _AddedSheet extends StatelessWidget {
  final Product p;
  final String option;
  final int qty;
  const _AddedSheet({required this.p, required this.option, required this.qty});

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    final picks = shopProducts.where((x) => x != p && x.price < 2500).take(6).toList();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final b = store.bill;
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
          padding: EdgeInsets.fromLTRB(0, 10, 0, 16 + MediaQuery.paddingOf(context).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 38, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: akSpring,
                  builder: (_, v, _) => Transform.scale(
                    scale: v,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(color: shopGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('Added to bag', style: akT(19, w: FontWeight.w800, ls: -0.4))),
                Text('${store.count} items', style: akT(13, w: FontWeight.w700, c: akMuted)),
              ]),
            ),
            const SizedBox(height: 14),
            Rise(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  ProductThumb(p, size: 64, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14.5, w: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('$option · Qty $qty', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
                    ]),
                  ),
                  Text(rs(p.price * qty), style: akN(16)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(18)),
                child: FreeDeliveryBar(b.subtotal),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Complete your kit', style: akT(15, w: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            ProductRail(items: picks, width: 120),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                  child: ShopButton('View bag', outline: true, height: 52, onTap: () {
                    Navigator.of(context).pop();
                    shopPush(context, const CartPage());
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ShopButton('Checkout · ${rs(b.total)}', color: shopOrange, height: 52, onTap: () {
                    Navigator.of(context).pop();
                    shopPush(context, const CheckoutPage());
                  }),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

/// Used by shop cards that want the glass look.
class GlassTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const GlassTile({super.key, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: child,
      );
}
