import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apple_kit.dart';
import 'liquid_glass.dart';

// Shop tab in the shared Apple style: banner carousel, category carousel,
// flash deals with a live countdown, product grids and rails, offers,
// bundles, brands, reviews and a membership banner. Product cards open a
// glass product page with a working cart counter.

const _green = Color(0xFF16A34A);
const _orange = Color(0xFFF97316);
const _red = Color(0xFFEF4444);
const _amber = Color(0xFFF59E0B);
const _violet = Color(0xFF8B5CF6);
const _blue = Color(0xFF3B82F6);
const _teal = Color(0xFF14B8A6);

const _img = 'assets/images/';

class Product {
  final String name, brand, image, cat;
  final int price, old;
  final double rating;
  final int reviews;
  final bool cover; // photo fills the card instead of sitting on white
  const Product(this.name, this.brand, this.image, this.cat, this.price, this.old, this.rating, this.reviews, {this.cover = false});
  int get off => old <= price ? 0 : ((old - price) / old * 100).round();
}

const _products = [
  Product('Gold Standard Whey + Creatine', 'Optimum Nutrition', '${_img}product_1.png', 'Protein', 6499, 8299, 4.8, 12840),
  Product('Performance Whey 2 kg', 'Optimum Nutrition', '${_img}product_2.png', 'Protein', 4299, 5199, 4.6, 6420),
  Product('NutriFit Premium Whey', 'NutriFit', '${_img}nutrifit_whey_protein.jpg', 'Protein', 2899, 3999, 4.7, 2210),
  Product('Air Bike Pro', 'NeuroFit Gear', '${_img}product_3.png', 'Equipment', 24999, 32999, 4.5, 640),
  Product('Home Gym Station', 'NeuroFit Gear', '${_img}product_5.png', 'Equipment', 38999, 49999, 4.4, 312),
  Product('Hex Dumbbell 10 kg', 'NeuroFit Gear', '${_img}neon_green_dumbbell_1787819274202.jpg', 'Equipment', 1899, 2499, 4.7, 3110, cover: true),
  Product('Cloud Run Shoes', 'Stride', '${_img}neon_green_shoe_1787819288631.jpg', 'Apparel', 5499, 7999, 4.6, 1980, cover: true),
  Product('Pulse Smartwatch', 'NeuroFit', '${_img}neon_green_smartwatch_1787819302325.jpg', 'Wearables', 8999, 12999, 4.5, 2740, cover: true),
  Product('Steel Bottle 1 L', 'NeuroFit', '${_img}neon_green_waterbottle_1787819315145.jpg', 'Accessories', 699, 999, 4.8, 5320, cover: true),
  Product('Grip Yoga Mat', 'Zen Flow', '${_img}neon_green_yogamat_1787819327380.jpg', 'Yoga', 1299, 1899, 4.7, 2860, cover: true),
  Product('Duffle Gym Bag', 'NeuroFit', '${_img}neon_orange_gymbag_1787819375587.jpg', 'Accessories', 1799, 2599, 4.6, 1420, cover: true),
  Product('Heart Rate Strap', 'Pulse', '${_img}neon_orange_heartrate_1787819363247.jpg', 'Wearables', 3299, 4499, 4.4, 880, cover: true),
  Product('Cast Kettlebell 12 kg', 'NeuroFit Gear', '${_img}neon_orange_kettlebell_1787819340750.jpg', 'Equipment', 2199, 2999, 4.8, 1760, cover: true),
  Product('Leakproof Shaker', 'NeuroFit', '${_img}neon_orange_proteinshaker_1787819387813.jpg', 'Accessories', 399, 599, 4.6, 6210, cover: true),
  Product('Speed Rope', 'NeuroFit', '${_img}neon_orange_skippingrope_1787819351491.jpg', 'Accessories', 549, 799, 4.5, 2390, cover: true),
];

class ShopCart {
  ShopCart._();
  static final count = ValueNotifier<int>(2);
  static final saved = ValueNotifier<Set<String>>({});
}

String _rs(int v) {
  final s = v.toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

void _open(BuildContext context, Product p) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ProductPage(p)));

void _addToCart(BuildContext context, Product p) {
  HapticFeedback.mediumImpact();
  ShopCart.count.value++;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: akInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      duration: const Duration(milliseconds: 1400),
      content: Text('${p.name} added to cart', style: akT(13.5, c: Colors.white)),
    ));
}

// =====================================================================

class ShopTabV3 extends StatelessWidget {
  const ShopTabV3({super.key});

  @override
  Widget build(BuildContext context) {
    final protein = _products.where((p) => p.cat == 'Protein').toList();
    final gear = _products.where((p) => p.cover).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        const AkWelcome(caption: 'SHOP · FREE DELIVERY OVER ₹999', words: ['Gear', 'up,', 'Rohit'], accent: _orange),
        const SizedBox(height: 14),
        const _SearchRow(),
        const SizedBox(height: 16),
        const _HeroCarousel(),
        const AkHead('Categories'),
        const _Categories(),
        const AkHead('Flash deals', caption: 'Ends tonight'),
        const _FlashDeals(),
        AkHead('Best sellers', action: 'See all', onAction: () {}),
        _Grid(items: [_products[0], _products[5], _products[7], _products[2]]),
        const AkHead('Offers for you'),
        const _Offers(),
        const AkHead('Shop by goal'),
        const _Goals(),
        const AkHead('New arrivals'),
        _Rail(items: [_products[6], _products[9], _products[11], _products[12], _products[14]]),
        const AkHead('Bundle & save'),
        const ScrollReveal(child: _Bundle()),
        const AkHead('Top brands'),
        const _Brands(),
        const AkHead('Trending now'),
        const _Trending(),
        AkHead('Protein & supplements', action: 'See all', onAction: () {}),
        _Grid(items: protein),
        AkHead('Gym gear', action: 'See all', onAction: () {}),
        _Grid(items: gear.take(6).toList()),
        const AkHead('Picked by Kemo', caption: 'Based on your workouts and goals'),
        const _KemoPicks(),
        const AkHead('Home gym'),
        _Rail(items: [_products[3], _products[4], _products[5], _products[12]]),
        const AkHead('What people say'),
        const _Reviews(),
        const SizedBox(height: 18),
        const ScrollReveal(child: _Membership()),
        const AkHead('Recently viewed'),
        _Rail(items: [_products[1], _products[8], _products[13], _products[10]], small: true),
        const SizedBox(height: 18),
        const ScrollReveal(child: _Trust()),
        const SizedBox(height: 24),
      ],
    );
  }
}

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
            onTap: () {},
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

// =====================================================================
//  HERO CAROUSEL
// =====================================================================

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _pc = PageController(viewportFraction: 0.9);
  int _page = 0;
  Timer? _t;

  static const _slides = [
    ('${_img}hero_banner_1.png', 'Mega protein week', 'Up to 40% off whey', _orange),
    ('${_img}hero_banner_2.png', 'Build your home gym', 'No-cost EMI from ₹2,083/mo', _blue),
    ('${_img}hero_banner_3.png', 'Run lighter', 'New Cloud Run shoes', _green),
    ('${_img}hero_banner_4.png', 'Recovery essentials', 'Buy 2, get 1 free', _violet),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pc.hasClients) return;
      _pc.animateToPage((_page + 1) % _slides.length, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Column(children: [
        AspectRatio(
          aspectRatio: 1.85,
          child: PageView.builder(
            controller: _pc,
            itemCount: _slides.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (_, i) => AnimatedBuilder(
              animation: _pc,
              builder: (_, c) {
                final d = _pc.hasClients && _pc.positions.length == 1 && _pc.position.haveDimensions ? (_pc.page ?? 0) - i : (_page - i).toDouble();
                return Transform.scale(scale: 1 - 0.06 * d.abs().clamp(0.0, 1.0), child: c);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(_slides[i].$1, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xB3000000), Color(0x00000000)],
                          stops: [0, 0.7],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 14,
                      right: 90,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _slides[i].$4, borderRadius: BorderRadius.circular(8)),
                          child: Text('LIMITED', style: akT(10, w: FontWeight.w800, c: Colors.white, ls: 1)),
                        ),
                        const SizedBox(height: 6),
                        Text(_slides[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(19, w: FontWeight.w800, c: Colors.white)),
                        Text(_slides[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12.5, c: Colors.white70)),
                      ]),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: LiquidGlass(
                        style: LiquidGlassStyle.clear,
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shadow: false,
                        onTap: () {},
                        child: Text('Shop', style: akT(13, w: FontWeight.w800, c: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _slides.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == _page ? _orange : Colors.black12, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
      ]),
    );
  }
}

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

// =====================================================================
//  PRODUCT CARDS
// =====================================================================

class _ProductCard extends StatelessWidget {
  final Product p;
  final bool compact;
  const _ProductCard(this.p, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      style: LiquidGlassStyle.material,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(8),
      onTap: () => _open(context, p),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: p.cover
                    ? Image.asset(p.image, fit: BoxFit.cover)
                    : ColoredBox(
                        color: Colors.white,
                        child: Padding(padding: const EdgeInsets.all(8), child: Image.asset(p.image, fit: BoxFit.contain)),
                      ),
              ),
            ),
            if (p.off > 0)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(8)),
                  child: Text('${p.off}% OFF', style: akT(10, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            Positioned(right: 6, top: 6, child: _Heart(p)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!compact) Text(p.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(10.5, w: FontWeight.w700, c: akFaint)),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(13, w: FontWeight.w800)),
            const SizedBox(height: 3),
            if (!compact)
              Row(children: [
                const Icon(Icons.star_rounded, color: _amber, size: 14),
                const SizedBox(width: 2),
                Text('${p.rating}', style: akT(11.5, w: FontWeight.w700)),
                Flexible(child: Text(' (${p.reviews})', overflow: TextOverflow.ellipsis, style: akT(11, c: akFaint))),
              ]),
            const SizedBox(height: 4),
            Row(children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_rs(p.price), style: akN(15)))),
              const SizedBox(width: 5),
              if (p.off > 0 && !compact)
                Flexible(
                  child: Text(_rs(p.old),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: akT(11, c: akFaint).copyWith(decoration: TextDecoration.lineThrough)),
                ),
              if (!compact) ...[
                const Spacer(),
                AkPress(
                  onTap: () => _addToCart(context, p),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: akInk, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Heart extends StatelessWidget {
  final Product p;
  const _Heart(this.p);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ShopCart.saved,
      builder: (_, s, _) {
        final on = s.contains(p.name);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ShopCart.saved.value = on ? ({...s}..remove(p.name)) : {...s, p.name};
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
              child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(on), size: 16, color: on ? _red : akMuted),
            ),
          ),
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Product> items;
  const _Grid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 262,
        ),
        itemBuilder: (_, i) => ScrollReveal(delayMs: (i % 2) * 80, child: _ProductCard(items[i])),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final List<Product> items;
  final bool small;
  const _Rail({required this.items, this.small = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: small ? 190 : 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ScrollReveal(
          delayMs: math.min(i, 3) * 70,
          child: SizedBox(width: small ? 140 : 170, child: _ProductCard(items[i], compact: small)),
        ),
      ),
    );
  }
}

// =====================================================================
//  FLASH DEALS
// =====================================================================

class _FlashDeals extends StatefulWidget {
  const _FlashDeals();
  @override
  State<_FlashDeals> createState() => _FlashDealsState();
}

class _FlashDealsState extends State<_FlashDeals> {
  Timer? _t;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _end = DateTime(n.year, n.month, n.day, 23, 59, 59);
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = _end.difference(DateTime.now());
    String two(int v) => v.toString().padLeft(2, '0');
    final parts = [two(left.inHours), two(left.inMinutes % 60), two(left.inSeconds % 60)];
    final deals = [_products[1], _products[7], _products[12], _products[6], _products[9]];
    const claimed = [0.72, 0.48, 0.85, 0.6, 0.35];
    return Column(children: [
      ScrollReveal(
        child: AkGlass(
          colors: const [Color(0xFFFF8A3D), Color(0xFFEF4444)],
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            const Icon(Icons.bolt_rounded, color: Colors.white),
            const SizedBox(width: 6),
            Expanded(child: Text('Lightning deals', style: akT(15, w: FontWeight.w800, c: Colors.white))),
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: 34,
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                child: Text(parts[i], style: akN(14, c: _red)),
              ),
              if (i < 2) Text(' : ', style: akT(14, w: FontWeight.w800, c: Colors.white)),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 238,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: deals.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final p = deals[i];
            return ScrollReveal(
              delayMs: math.min(i, 3) * 70,
              child: SizedBox(
                width: 158,
                child: LiquidGlass(
                  style: LiquidGlassStyle.material,
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(8),
                  onTap: () => _open(context, p),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox.expand(
                          child: p.cover
                              ? Image.asset(p.image, fit: BoxFit.cover)
                              : ColoredBox(color: Colors.white, child: Image.asset(p.image, fit: BoxFit.contain)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12.5, w: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(_rs(p.price), style: akN(14.5, c: _red)),
                          const SizedBox(width: 5),
                          Text('-${p.off}%', style: akT(11, w: FontWeight.w800, c: _green)),
                        ]),
                        const SizedBox(height: 6),
                        AkSeen(
                          builder: (_, t) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: claimed[i] * t,
                              minHeight: 5,
                              color: _orange,
                              backgroundColor: _orange.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${(claimed[i] * 100).round()}% claimed', style: akT(10.5, c: akFaint)),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// =====================================================================
//  OFFERS / GOALS / BUNDLE / BRANDS / TRENDING
// =====================================================================

class _Offers extends StatelessWidget {
  const _Offers();

  @override
  Widget build(BuildContext context) {
    const posters = ['offer_1.png', 'offer_2.png', 'offer_3.png', 'more_product_2.png', 'more_product_3.png'];
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: posters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ScrollReveal(
          delayMs: math.min(i, 3) * 70,
          child: AkPress(
            child: Container(
              width: 175,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset('$_img${posters[i]}', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Goals extends StatelessWidget {
  const _Goals();

  @override
  Widget build(BuildContext context) {
    const goals = [
      ('Build muscle', 'Whey, creatine, weights', Icons.fitness_center_rounded, [Color(0xFFC4B5FD), Color(0xFF7C3AED)]),
      ('Lose fat', 'Cardio gear, shakers', Icons.local_fire_department_rounded, [Color(0xFFFDBA74), Color(0xFFEA580C)]),
      ('Endurance', 'Shoes, watches, ropes', Icons.directions_run_rounded, [Color(0xFF93C5FD), Color(0xFF2563EB)]),
      ('Recovery', 'Mats, rollers, sleep', Icons.spa_rounded, [Color(0xFF5EEAD4), Color(0xFF0D9488)]),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          for (var i = 0; i < goals.length; i++)
            ScrollReveal(
              delayMs: (i % 2) * 80,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(24),
                colors: goals[i].$4,
                padding: const EdgeInsets.all(14),
                onTap: () {},
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(goals[i].$3, color: Colors.white, size: 26),
                  const Spacer(),
                  Text(goals[i].$1, style: akT(15.5, w: FontWeight.w800, c: Colors.white)),
                  Text(goals[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, c: Colors.white70)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bundle extends StatelessWidget {
  const _Bundle();

  @override
  Widget build(BuildContext context) {
    final items = [_products[2], _products[13], _products[8]];
    final total = items.fold(0, (a, p) => a + p.price);
    final bundle = (total * 0.8).round();
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Starter stack', style: akT(17, w: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Text('Save 20%', style: akT(11.5, w: FontWeight.w800, c: _green)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: items[i].cover
                      ? Image.asset(items[i].image, fit: BoxFit.cover)
                      : ColoredBox(color: Colors.white, child: Image.asset(items[i].image, fit: BoxFit.contain)),
                ),
              ),
            ),
            if (i < items.length - 1)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.add_rounded, color: akMuted, size: 18)),
          ],
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_rs(bundle), style: akN(24)),
            Text(_rs(total), style: akT(12, c: akFaint).copyWith(decoration: TextDecoration.lineThrough)),
          ]),
          const Spacer(),
          AkPress(
            onTap: () {
              for (final p in items) {
                _addToCart(context, p);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(color: akInk, borderRadius: BorderRadius.circular(16)),
              child: Text('Add bundle', style: akT(14, w: FontWeight.w800, c: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Brands extends StatelessWidget {
  const _Brands();

  @override
  Widget build(BuildContext context) {
    const brands = [
      ('NeuroFit', _green), ('Optimum', _red), ('NutriFit', akInk), ('Stride', _blue),
      ('Zen Flow', _teal), ('Pulse', _orange), ('IronCore', _violet),
    ];
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ScrollReveal(
          delayMs: math.min(i, 4) * 50,
          child: LiquidGlass(
            style: LiquidGlassStyle.material,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onTap: () {},
            child: SizedBox(
              height: 58,
              child: Center(
                child: Text(brands[i].$1, style: akT(16, w: FontWeight.w900, c: brands[i].$2, ls: -0.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Trending extends StatefulWidget {
  const _Trending();
  @override
  State<_Trending> createState() => _TrendingState();
}

class _TrendingState extends State<_Trending> {
  final _pc = PageController(viewportFraction: 0.62);
  static const _posters = [
    ('top_pick_1.png', '#1 Strawberry whey'),
    ('spotlight_1.png', 'Iso Legend'),
    ('top_pick_3.png', 'Plant protein'),
    ('spotlight_2.png', 'Pre-workout'),
    ('top_pick_4.png', 'Bone broth'),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: SizedBox(
        height: 300,
        child: PageView.builder(
          controller: _pc,
          padEnds: false,
          itemCount: _posters.length,
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _pc,
            builder: (_, c) {
              final d = _pc.hasClients && _pc.positions.length == 1 && _pc.position.haveDimensions ? (_pc.page ?? 0) - i : i.toDouble();
              return Transform.scale(scale: 1 - 0.08 * d.abs().clamp(0.0, 1.0), alignment: Alignment.centerLeft, child: c);
            },
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('$_img${_posters[i].$1}', fit: BoxFit.cover),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: LiquidGlass(
                      style: LiquidGlassStyle.regular,
                      borderRadius: BorderRadius.circular(18),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shadow: false,
                      child: Row(children: [
                        Text('${i + 1}', style: akN(20, c: _orange)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_posters[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(13, w: FontWeight.w800))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  KEMO PICKS / REVIEWS / MEMBERSHIP / TRUST
// =====================================================================

class _KemoPicks extends StatelessWidget {
  const _KemoPicks();

  @override
  Widget build(BuildContext context) {
    final picks = [
      (_products[12], 'Fits your Day 13 strength plan'),
      (_products[2], 'You are 34 g short on protein today'),
      (_products[9], 'Pairs with your evening stretch'),
    ];
    return Column(children: [
      for (final (p, why) in picks)
        ScrollReveal(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AkGlass(
              padding: const EdgeInsets.all(10),
              onTap: () => _open(context, p),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: p.cover
                        ? Image.asset(p.image, fit: BoxFit.cover)
                        : ColoredBox(color: Colors.white, child: Image.asset(p.image, fit: BoxFit.contain)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14, w: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded, size: 13, color: _teal),
                      const SizedBox(width: 4),
                      Expanded(child: Text(why, maxLines: 2, style: akT(11.5, c: akMuted, h: 1.3))),
                    ]),
                    const SizedBox(height: 4),
                    Text(_rs(p.price), style: akN(15)),
                  ]),
                ),
                AkPress(
                  onTap: () => _addToCart(context, p),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: _teal.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: _teal, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews();

  @override
  Widget build(BuildContext context) {
    const reviews = [
      ('Aarav S.', 'Gold Standard Whey', 'Mixes clean, no lumps. Recovery feels faster after leg day.', 5),
      ('Meera K.', 'Grip Yoga Mat', 'Doesn\'t slide even in hot yoga. Worth every rupee.', 5),
      ('Kabir P.', 'Pulse Smartwatch', 'Battery lasts 9 days and the HRV readings match my strap.', 4),
      ('Ishita R.', 'Cloud Run Shoes', 'Super light. Did my first 10K in them without blisters.', 5),
    ];
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: reviews.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = reviews[i];
          return ScrollReveal(
            delayMs: math.min(i, 3) * 70,
            child: SizedBox(
              width: 250,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: [_violet, _orange, _blue, _teal][i].withValues(alpha: 0.18),
                      child: Text(r.$1[0], style: akT(13, w: FontWeight.w800, c: [_violet, _orange, _blue, _teal][i])),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.$1, style: akT(13, w: FontWeight.w800)),
                        Text(r.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11, c: akFaint)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (var k = 0; k < 5; k++)
                      Icon(Icons.star_rounded, size: 15, color: k < r.$4 ? _amber : Colors.black12),
                  ]),
                  const SizedBox(height: 6),
                  Text(r.$3, maxLines: 3, overflow: TextOverflow.ellipsis, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.4)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Membership extends StatelessWidget {
  const _Membership();

  @override
  Widget build(BuildContext context) {
    return AkGlass(
      colors: const [Color(0xFF111827), Color(0xFF374151)],
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEUROFIT PLUS', style: akT(11, w: FontWeight.w800, c: const Color(0xFFFDE68A), ls: 1.4)),
            const SizedBox(height: 6),
            Text('Free delivery, extra 10% off and early access', style: akT(16, w: FontWeight.w800, c: Colors.white, h: 1.3)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: const Color(0xFFFDE68A), borderRadius: BorderRadius.circular(14)),
              child: Text('Join for ₹99/mo', style: akT(13, w: FontWeight.w800, c: akInk)),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        const Text('👑', style: TextStyle(fontSize: 54)),
      ]),
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_rounded, 'Free delivery', _blue),
      (Icons.verified_rounded, '100% authentic', _green),
      (Icons.autorenew_rounded, '7-day returns', _orange),
      (Icons.payments_rounded, 'Cash on delivery', _violet),
    ];
    return AkGlass(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(children: [
        for (final (ic, t, c) in items)
          Expanded(
            child: Column(children: [
              Icon(ic, color: c, size: 24),
              const SizedBox(height: 6),
              Text(t, textAlign: TextAlign.center, style: akT(10.5, w: FontWeight.w700, c: akMuted)),
            ]),
          ),
      ]),
    );
  }
}

// =====================================================================
//  PRODUCT PAGE
// =====================================================================

class _ProductPage extends StatefulWidget {
  final Product p;
  const _ProductPage(this.p);
  @override
  State<_ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<_ProductPage> {
  int option = 0, qty = 1;

  List<String> get _options => switch (widget.p.cat) {
        'Protein' => ['Chocolate', 'Vanilla', 'Strawberry'],
        'Apparel' => ['UK 7', 'UK 8', 'UK 9', 'UK 10'],
        'Equipment' => ['Standard', 'Pro'],
        _ => ['Black', 'Green', 'Orange'],
      };

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return AkPage(
      title: p.name,
      caption: p.brand,
      tint: _orange,
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: akSpring,
                builder: (_, s, c) => Transform.scale(scale: s, child: c),
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: p.cover
                        ? Image.asset(p.image, fit: BoxFit.cover)
                        : ColoredBox(color: Colors.white, child: Padding(padding: const EdgeInsets.all(20), child: Image.asset(p.image))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AkGlass(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(_rs(p.price), style: akN(30)),
                  const SizedBox(width: 8),
                  if (p.off > 0) ...[
                    Text(_rs(p.old), style: akT(13, c: akFaint).copyWith(decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 8),
                    Text('${p.off}% off', style: akT(13, w: FontWeight.w800, c: _green)),
                  ],
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  for (var k = 0; k < 5; k++) Icon(Icons.star_rounded, size: 17, color: k < p.rating.round() ? _amber : Colors.black12),
                  const SizedBox(width: 6),
                  Text('${p.rating} · ${p.reviews} reviews', style: akT(12.5, c: akMuted)),
                ]),
                const SizedBox(height: 16),
                Text('Choose', style: akT(14, w: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < _options.length; i++)
                    AkPress(
                      onTap: () => setState(() => option = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: i == option ? akInk : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: i == option ? akInk : Colors.black12),
                        ),
                        child: Text(_options[i], style: akT(13, w: FontWeight.w700, c: i == option ? Colors.white : akInk)),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            AkGlass(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Why you\'ll like it', style: akT(15, w: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final f in [
                  'Lab tested and 100% authentic',
                  'Picked for your current training plan',
                  'Ships in 24 hours, free over ₹999',
                  '7-day easy returns',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: _green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: akT(13.5, w: FontWeight.w500, c: akMuted))),
                    ]),
                  ),
              ]),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: LiquidGlass(
              style: LiquidGlassStyle.regular,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                IconButton(onPressed: () => setState(() => qty = math.max(1, qty - 1)), icon: const Icon(Icons.remove_rounded)),
                Text('$qty', style: akN(18)),
                IconButton(onPressed: () => setState(() => qty++), icon: const Icon(Icons.add_rounded)),
                const SizedBox(width: 6),
                Expanded(
                  child: AkPress(
                    onTap: () {
                      for (var k = 0; k < qty; k++) {
                        _addToCart(context, p);
                      }
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(18)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Add · ${_rs(p.price * qty)}', style: akT(15, w: FontWeight.w800, c: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
