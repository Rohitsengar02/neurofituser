import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/product_detail_screen.dart';
import '../screens/shop_screen.dart';
import 'dashboard_motion.dart';
import 'kemo.dart';

/// Demo storefront for the Shop tab: greeting with Kemo peeking out, search,
/// a paged grid of glossy category icons, promo cards, filter chips and a
/// product list. All data is local demo data.

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _accent = Color(0xFF0284C7);
const _accentDeep = Color(0xFF0369A1);
const _price = Color(0xFFEF4444);

class ShopDemoProduct {
  final String title;
  final String category;
  final String image;
  final double price;
  final double oldPrice;
  final double rating;
  final String sold;
  final int minutes;
  final bool freeDelivery;
  final bool isNew;

  const ShopDemoProduct(
    this.title,
    this.category,
    this.image,
    this.price,
    this.oldPrice,
    this.rating,
    this.sold,
    this.minutes, {
    this.freeDelivery = false,
    this.isNew = false,
  });
}

const shopDemoProducts = [
  ShopDemoProduct('Gold Whey Protein 2 kg', 'Protein',
      'assets/images/product_1.png', 2899, 3499, 4.8, '2.1k', 25,
      freeDelivery: true),
  ShopDemoProduct('Performance Whey Isolate', 'Protein',
      'assets/images/product_2.png', 2499, 2999, 4.7, '1.4k', 30,
      freeDelivery: true),
  ShopDemoProduct('Nutrifit Premium Whey', 'Protein',
      'assets/images/nutrifit_whey_protein.jpg', 1999, 2599, 4.6, '980', 20,
      freeDelivery: true, isNew: true),
  ShopDemoProduct('Neon Smart Fitness Watch', 'Trackers',
      'assets/images/neon_green_smartwatch_1787819302325.jpg', 3499, 4999, 4.5,
      '640', 35,
      isNew: true),
  ShopDemoProduct('Cloud Runner Shoes', 'Shoes',
      'assets/images/neon_green_shoe_1787819288631.jpg', 2799, 3999, 4.7,
      '1.1k', 40,
      freeDelivery: true),
  ShopDemoProduct('Grip Yoga Mat 6 mm', 'Yoga',
      'assets/images/neon_green_yogamat_1787819327380.jpg', 899, 1299, 4.6,
      '2.3k', 20),
  ShopDemoProduct('Hex Dumbbell Pair 5 kg', 'Equipment',
      'assets/images/neon_green_dumbbell_1787819274202.jpg', 1299, 1799, 4.8,
      '870', 45,
      freeDelivery: true),
  ShopDemoProduct('Leak-proof Shaker 700 ml', 'Bottles',
      'assets/images/neon_orange_proteinshaker_1787819387813.jpg', 349, 499,
      4.4, '3.4k', 15,
      isNew: true),
  ShopDemoProduct('Speed Skipping Rope', 'Equipment',
      'assets/images/neon_orange_skippingrope_1787819351491.jpg', 299, 449,
      4.5, '1.9k', 15),
  ShopDemoProduct('Cast Iron Kettlebell 8 kg', 'Equipment',
      'assets/images/neon_orange_kettlebell_1787819340750.jpg', 1199, 1599,
      4.7, '520', 50,
      freeDelivery: true),
  ShopDemoProduct('Steel Water Bottle 1 L', 'Bottles',
      'assets/images/neon_green_waterbottle_1787819315145.jpg', 499, 799, 4.6,
      '2.7k', 20),
  ShopDemoProduct('Mass Gainer 3 kg', 'Protein',
      'assets/images/more_product_1.png', 1499, 1999, 4.3, '760', 30),
];

class _Cat {
  final String emoji;
  final String label;
  final Color a;
  final Color b;
  const _Cat(this.emoji, this.label, this.a, this.b);
}

const _cats = [
  _Cat('💪', 'Protein', Color(0xFFFFE08A), Color(0xFFFFB020)),
  _Cat('⚡', 'Pre-workout', Color(0xFFFFD1DC), Color(0xFFFF6B8B)),
  _Cat('💊', 'Vitamins', Color(0xFFCDEBFF), Color(0xFF4AA8FF)),
  _Cat('🍫', 'Snacks', Color(0xFFFFE2C6), Color(0xFFFF9A4A)),
  _Cat('🏋️', 'Equipment', Color(0xFFDCD3FF), Color(0xFF8B6CFF)),
  _Cat('👟', 'Shoes', Color(0xFFD2F7E6), Color(0xFF2CCB8A)),
  _Cat('👕', 'Apparel', Color(0xFFE0E7FF), Color(0xFF6474F0)),
  _Cat('🧘', 'Yoga', Color(0xFFFCE1F4), Color(0xFFE56BC4)),
  _Cat('⌚', 'Trackers', Color(0xFFD5F3FF), Color(0xFF22B8E6)),
  _Cat('🏷️', 'Offers', Color(0xFFFFD9D2), Color(0xFFFF5A3C)),
  _Cat('🥛', 'Gainers', Color(0xFFFFF1C9), Color(0xFFF2B600)),
  _Cat('🧪', 'Creatine', Color(0xFFE3FFD0), Color(0xFF6FD62F)),
  _Cat('💧', 'Bottles', Color(0xFFD0EEFF), Color(0xFF2E9BFF)),
  _Cat('🎒', 'Bags', Color(0xFFFFE3CF), Color(0xFFE77B2F)),
  _Cat('🧊', 'Recovery', Color(0xFFD6F6FF), Color(0xFF3CC4E8)),
  _Cat('🪢', 'Ropes', Color(0xFFF3E1FF), Color(0xFFB065F0)),
  _Cat('🔔', 'Kettlebells', Color(0xFFFFE7C2), Color(0xFFE79A1C)),
  _Cat('🥗', 'Healthy food', Color(0xFFDFFFD6), Color(0xFF3FBF4F)),
  _Cat('😴', 'Sleep', Color(0xFFE4DEFF), Color(0xFF7A6BE6)),
  _Cat('🛍️', 'All', Color(0xFFE2E8F0), Color(0xFF64748B)),
];

class ShopHomeSections extends StatefulWidget {
  final String userName;
  const ShopHomeSections({super.key, this.userName = 'Rohit'});

  @override
  State<ShopHomeSections> createState() => _ShopHomeSectionsState();
}

class _ShopHomeSectionsState extends State<ShopHomeSections> {
  final _search = TextEditingController();
  final _pages = PageController();
  int _page = 0;
  int _filter = 0;
  String _query = '';
  final Set<String> _inCart = {};

  static const _filters = [
    '🚚 Free Delivery',
    '⭐ Top Rated',
    '💸 Under ₹999',
    '✨ New',
    '⏱ Under 25 min',
  ];

  @override
  void dispose() {
    _search.dispose();
    _pages.dispose();
    super.dispose();
  }

  List<ShopDemoProduct> get _visible {
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      return shopDemoProducts
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    switch (_filter) {
      case 0:
        return shopDemoProducts.where((p) => p.freeDelivery).toList();
      case 1:
        return [...shopDemoProducts.where((p) => p.rating >= 4.6)]
          ..sort((a, b) => b.rating.compareTo(a.rating));
      case 2:
        return shopDemoProducts.where((p) => p.price < 999).toList();
      case 3:
        return shopDemoProducts.where((p) => p.isNew).toList();
      default:
        return shopDemoProducts.where((p) => p.minutes <= 25).toList();
    }
  }

  void _openProduct(ShopDemoProduct p) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          title: p.title,
          subtitle: '${p.category} · Lab certified',
          price: p.price,
          oldPrice: p.oldPrice,
          image: p.image,
          rating: p.rating,
          reviewsCount: p.sold,
          category: p.category,
        ),
      ),
    );
  }

  void _openStore([String? cat]) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopScreen(
          initialCategory: cat == null || cat == 'All' ? null : cat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(child: _greetingAndSearch()),
        if (_query.isEmpty) ...[
          const SizedBox(height: 18),
          Reveal(
            delay: const Duration(milliseconds: 80),
            child: _categoryGrid(),
          ),
          const SizedBox(height: 18),
          Reveal(
            delay: const Duration(milliseconds: 140),
            child: _promoRow(),
          ),
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 180),
            child: _filterChips(),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Results for "$_query"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
        const SizedBox(height: 12),
        _productList(),
        const SizedBox(height: 6),
        Center(
          child: PressScale(
            onTap: _openStore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 1.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Browse the full store',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _accentDeep,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: _accentDeep),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Greeting, Kemo peeking and the search pill
  // ---------------------------------------------------------------
  Widget _greetingAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, c) {
        final kemoH = (c.maxWidth * 0.3).clamp(96.0, 130.0);
        return SizedBox(
          height: 70 + 54 + 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 2,
                top: 6,
                right: kemoH * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hi, ${widget.userName}!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'What are we gearing up for today?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              // Kemo peeking over the search bar
              Positioned(
                right: 4,
                bottom: 30,
                child: KemoBody(height: kemoH, walking: false),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _searchPill(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _searchPill() {
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 18, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search protein, shoes, mats…',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _search.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
            ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF38BDF8), _accent],
              ),
            ),
            child: const Icon(Icons.search_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Paged 2 x 5 category grid
  // ---------------------------------------------------------------
  Widget _categoryGrid() {
    return LayoutBuilder(builder: (context, c) {
      final cell = (c.maxWidth - 24) / 5;
      final icon = (cell * 0.78).clamp(44.0, 62.0);
      final rowH = icon + 24;
      return Column(
        children: [
          SizedBox(
            height: rowH * 2 + 10,
            child: PageView.builder(
              controller: _pages,
              itemCount: (_cats.length / 10).ceil(),
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, pg) {
                final items = _cats.skip(pg * 10).take(10).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        SizedBox(
                          width: cell,
                          height: rowH,
                          child: _CatIcon(
                            cat: items[i],
                            size: icon,
                            delay: i * 45,
                            onTap: () => _openStore(items[i].label),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate((_cats.length / 10).ceil(), (i) {
              final on = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: on ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: on ? _accent : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------
  // Two promo cards
  // ---------------------------------------------------------------
  Widget _promoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _PromoCard(
              title: 'Protein Week',
              tag: 'Up to 30% off',
              tagColor: const Color(0xFFFFB020),
              image: 'assets/images/product_1.png',
              price: '₹2,899',
              bg: const [Color(0xFFFFF7E0), Colors.white],
              onTap: () => _openProduct(shopDemoProducts[0]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PromoCard(
              title: 'Home Gym',
              tag: 'Free install',
              tagColor: const Color(0xFF8B6CFF),
              image: 'assets/images/product_3.png',
              price: '₹18,999',
              bg: const [Color(0xFFF1EDFF), Colors.white],
              onTap: () => _openProduct(const ShopDemoProduct(
                'Air Bike Pro',
                'Equipment',
                'assets/images/product_3.png',
                18999,
                24999,
                4.8,
                '310',
                60,
                freeDelivery: true,
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Filter chips and product list
  // ---------------------------------------------------------------
  Widget _filterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final on = i == _filter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filter = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: on
                    ? const LinearGradient(
                        colors: [Color(0xFF38BDF8), _accent],
                      )
                    : null,
                color: on ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: on ? Colors.transparent : const Color(0xFFE2E8F0),
                ),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: on ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productList() {
    final items = _visible;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(a),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      child: Column(
        key: ValueKey('$_filter|$_query'),
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'Nothing here yet. Try another search.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ),
          for (final p in items)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _StoreCard(
                p: p,
                inCart: _inCart.contains(p.title),
                onTap: () => _openProduct(p),
                onAdd: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    if (!_inCart.remove(p.title)) _inCart.add(p.title);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Glossy 3D-style category icon: a puffy gradient bubble with a highlight,
/// soft shadow and an emoji, popping in with a small bounce.
class _CatIcon extends StatefulWidget {
  final _Cat cat;
  final double size;
  final int delay;
  final VoidCallback onTap;
  const _CatIcon({
    required this.cat,
    required this.size,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_CatIcon> createState() => _CatIconState();
}

class _CatIconState extends State<_CatIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 120 + widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final cat = widget.cat;
    return PressScale(
      onTap: widget.onTap,
      pressedScale: 0.9,
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(s * 0.34),
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  radius: 1.1,
                  colors: [Colors.white, cat.a, cat.b],
                  stops: const [0.0, 0.45, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: cat.b.withValues(alpha: 0.38),
                    blurRadius: s * 0.22,
                    offset: Offset(0, s * 0.12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // glossy highlight
                  Positioned(
                    left: s * 0.14,
                    top: s * 0.08,
                    child: Container(
                      width: s * 0.42,
                      height: s * 0.2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      cat.emoji,
                      style: TextStyle(
                        fontSize: s * 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                cat.label,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  final String image;
  final String price;
  final List<Color> bg;
  final VoidCallback onTap;

  const _PromoCard({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.image,
    required this.price,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bg,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: tagColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.white,
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _price,
                    ),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: _ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final ShopDemoProduct p;
  final bool inCart;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _StoreCard({
    required this.p,
    required this.inCart,
    required this.onTap,
    required this.onAdd,
  });

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    if (s.length <= 3) return '₹$s';
    return '₹${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final off = ((1 - p.price / p.oldPrice) * 100).round();
    final meta = GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _muted,
    );
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 84,
                height: 84,
                color: const Color(0xFFF1F5F9),
                child: Image.asset(p.image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      if (p.isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(p.rating.toStringAsFixed(1),
                              style: meta.copyWith(color: _ink)),
                        ],
                      ),
                      Text('${p.sold} sold', style: meta),
                      Text('${p.minutes} min', style: meta),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (p.freeDelivery)
                    Text(
                      'Free delivery',
                      style: meta.copyWith(color: const Color(0xFF16A34A)),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _fmt(p.price),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: _price,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _fmt(p.oldPrice),
                                style: meta.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$off% off',
                                style: meta.copyWith(
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onAdd,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: inCart ? const Color(0xFF16A34A) : _accent,
                            boxShadow: [
                              BoxShadow(
                                color: (inCart
                                        ? const Color(0xFF16A34A)
                                        : _accent)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Icon(
                              inCart ? Icons.check_rounded : Icons.add_rounded,
                              key: ValueKey(inCart),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
