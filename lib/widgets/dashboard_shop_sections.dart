import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/product_detail_screen.dart';

class DashboardShopTabContent extends StatefulWidget {
  const DashboardShopTabContent({super.key});

  @override
  State<DashboardShopTabContent> createState() => _DashboardShopTabContentState();
}

class _DashboardShopTabContentState extends State<DashboardShopTabContent>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  int _cartCount = 2;
  int _selectedCategoryIndex = 0;
  int _activeHeroDot = 0;

  late AnimationController _staggerController;
  late AnimationController _shimmerController;
  late PageController _heroPageController;
  Timer? _heroTimer;

  final List<String> _heroBanners = [
    'assets/images/hero_banner_1.png',
    'assets/images/hero_banner_2.png',
    'assets/images/hero_banner_3.png',
    'assets/images/hero_banner_4.png',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Supplements', 'icon': Icons.medical_services_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
    {'name': 'Protein', 'icon': Icons.local_drink_rounded, 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFE0F2FE)},
    {'name': 'Vitamins', 'icon': Icons.medication_liquid_rounded, 'color': const Color(0xFFEA580C), 'bg': const Color(0xFFFFF7ED)},
    {'name': 'Accessories', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFF3E8FF)},
    {'name': 'Apparel', 'icon': Icons.checkroom_rounded, 'color': const Color(0xFF15803D), 'bg': const Color(0xFFF0FDF4)},
    {'name': 'Wellness', 'icon': Icons.spa_rounded, 'color': const Color(0xFFE11D48), 'bg': const Color(0xFFFFEEF1)},
    {'name': 'Bundles', 'icon': Icons.card_giftcard_rounded, 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)},
  ];

  @override
  void initState() {
    super.initState();

    _heroPageController = PageController(initialPage: 0);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _staggerController.forward();
        _startHeroAutoScroll();
      }
    });
  }

  void _startHeroAutoScroll() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted || !_heroPageController.hasClients) return;
      final nextPage = (_activeHeroDot + 1) % _heroBanners.length;
      _heroPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    _shimmerController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _addToCart(String productName) {
    HapticFeedback.mediumImpact();
    setState(() => _cartCount++);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName added to cart!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStaggeredSection({
    required double startInterval,
    required double endInterval,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final anim = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
        ).value;

        final blurVal = ((1 - anim) * 12.0).clamp(0.0, 12.0);
        final slideY = (24.0 * (1 - anim));

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoadingView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // 1. Header (Shop Title + Search + Cart with Badge)
        _buildStaggeredSection(
          startInterval: 0.0,
          endInterval: 0.16,
          child: _buildShopHeader(),
        ),

        const SizedBox(height: 18),

        // 2. Hero Launch Banner Carousel
        _buildStaggeredSection(
          startInterval: 0.08,
          endInterval: 0.26,
          child: _buildHeroLaunchBanner(),
        ),

        const SizedBox(height: 20),

        // 3. Quick Category Squircles Row
        _buildStaggeredSection(
          startInterval: 0.16,
          endInterval: 0.34,
          child: _buildCategorySquirclesRow(),
        ),

        const SizedBox(height: 24),

        // 3.5. Featured Supplements Carousel
        _buildStaggeredSection(
          startInterval: 0.20,
          endInterval: 0.38,
          child: _buildFeaturedSupplementsSection(),
        ),

        const SizedBox(height: 24),

        // 4. New Arrivals Horizontal Carousel
        _buildStaggeredSection(
          startInterval: 0.24,
          endInterval: 0.44,
          child: _buildNewArrivalsSection(),
        ),

        const SizedBox(height: 24),

        // 5. Promo Bento Grid (Flat 20% OFF + 4 mini cards)
        _buildStaggeredSection(
          startInterval: 0.34,
          endInterval: 0.54,
          child: _buildPromoBentoGridSection(),
        ),

        const SizedBox(height: 24),

        // 6. Best Sellers Carousel
        _buildStaggeredSection(
          startInterval: 0.44,
          endInterval: 0.64,
          child: _buildBestSellersSection(),
        ),

        const SizedBox(height: 24),

        // 7. Elevate Your Wellness Promo Banner
        _buildStaggeredSection(
          startInterval: 0.54,
          endInterval: 0.74,
          child: _buildWellnessBanner(),
        ),

        const SizedBox(height: 24),

        // 8. Top Picks For You (4 Bento Cards)
        _buildStaggeredSection(
          startInterval: 0.64,
          endInterval: 0.84,
          child: _buildTopPicksSection(),
        ),

        const SizedBox(height: 24),



        // 9. Trust & Guarantee Badges Footer
        _buildStaggeredSection(
          startInterval: 0.74,
          endInterval: 1.0,
          child: _buildTrustBadgesFooter(),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // -------------------------------------------------------------
  // SHIMMER SKELETON LOADING VIEW (SHOP TAB)
  // -------------------------------------------------------------
  Widget _buildSkeletonLoadingView() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 90, height: 28, borderRadius: 8),
                      const SizedBox(height: 6),
                      _buildShimmerBox(width: 180, height: 16, borderRadius: 6),
                    ],
                  ),
                  Row(
                    children: [
                      _buildShimmerBox(width: 40, height: 40, borderRadius: 20),
                      const SizedBox(width: 10),
                      _buildShimmerBox(width: 40, height: 40, borderRadius: 20),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 190, borderRadius: 26),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 75, borderRadius: 18),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 230,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildShimmerBox(width: 155, height: 230, borderRadius: 22),
                  const SizedBox(width: 12),
                  _buildShimmerBox(width: 155, height: 230, borderRadius: 22),
                ],
              ),
            ),
            const SizedBox(height: 26),
          ],
        );
      },
    );
  }

  Widget _buildShimmerBox({double? width, required double height, double borderRadius = 12}) {
    final double shimmerPos = _shimmerController.value;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + (3.0 * shimmerPos), -0.3),
          end: Alignment(1.5 + (3.0 * shimmerPos), 0.3),
          colors: const [
            Color(0xFFF1F5F9),
            Color(0xFFFFFFFF),
            Color(0xFFF1F5F9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. SHOP HEADER
  // -------------------------------------------------------------
  Widget _buildShopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Everything you need for a better you.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              // Search Button
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 10),

              // Cart Button with Green Count Badge
              GestureDetector(
                onTap: () => HapticFeedback.mediumImpact(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFF0F172A)),
                    ),
                    if (_cartCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              '$_cartCount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. HERO LAUNCH BANNER AUTO-SCROLLING CAROUSEL
  // -------------------------------------------------------------
  Widget _buildHeroLaunchBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          SizedBox(
            height: 195,
            child: PageView.builder(
              controller: _heroPageController,
              itemCount: _heroBanners.length,
              onPageChanged: (index) {
                setState(() => _activeHeroDot = index);
              },
              itemBuilder: (context, index) {
                final bannerImage = _heroBanners[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    image: DecorationImage(
                      image: AssetImage(bannerImage),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 4 Carousel Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_heroBanners.length, (index) {
              final isSel = _activeHeroDot == index;
              return GestureDetector(
                onTap: () {
                  _heroPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSel ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTrustBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. QUICK CATEGORY SQUIRCLES ROW
  // -------------------------------------------------------------
  Widget _buildCategorySquirclesRow() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSel = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategoryIndex = index);
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cat['bg'] as Color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSel ? (cat['color'] as Color) : Colors.transparent,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (cat['color'] as Color).withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    size: 24,
                    color: cat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                    color: isSel ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCardOutsideImage(Map<String, String> prod) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              title: prod['name'],
              subtitle: 'Nutrition & Performance',
              image: prod['image'],
              rating: double.tryParse(prod['rating'] ?? '4.8') ?? 4.8,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 155,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The image card
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image perfectly contained inside
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      prod['image']!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Rating Badge (top right of white card)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          prod['rating']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Discount Badge (top left)
                if (prod.containsKey('discount'))
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        prod['discount']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Title and Price below the image card (transparent background)
          Text(
            prod['name']!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prod.containsKey('originalPrice'))
                    Text(
                      prod['originalPrice']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                        height: 1.0,
                      ),
                    ),
                  Text(
                    prod['price']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _addToCart(prod['name']!),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  // -------------------------------------------------------------
  // 4. NEW ARRIVALS CAROUSEL
  // -------------------------------------------------------------
  Widget _buildNewArrivalsSection() {
    final newArrivals = [
      {
        'name': 'Gold Standard Whey + Creatine',
        'price': '₹3,499',
        'rating': '4.9',
        'image': 'assets/images/product_1.png',
      },
      {
        'name': 'ON Performance Whey',
        'price': '₹2,199',
        'rating': '4.8',
        'image': 'assets/images/product_2.png',
      },

      {
        'name': 'Energie Fitness Air Bike',
        'price': '₹14,999',
        'originalPrice': '₹18,999',
        'discount': '-21%',
        'rating': '4.7',
        'image': 'assets/images/product_3.png',
      },
      {
        'name': 'Cockatoo Multi Gym',
        'price': '₹24,499',
        'originalPrice': '₹29,999',
        'discount': '-18%',
        'rating': '4.9',
        'image': 'assets/images/product_4.png',
      },
      {
        'name': 'SincMill Multi Gym',
        'price': '₹32,999',
        'originalPrice': '₹39,999',
        'discount': '-17%',
        'rating': '4.8',
        'image': 'assets/images/product_5.png',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Arrivals',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        SizedBox(
          height: 245,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: newArrivals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _buildProductCardOutsideImage(newArrivals[index]);
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. PROMO OFFERS SECTION (3 IMAGE CARDS)
  // -------------------------------------------------------------
  Widget _buildPromoBentoGridSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/offer_1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/offer_2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/offer_3.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. BEST SELLERS CAROUSEL
  // -------------------------------------------------------------
  Widget _buildBestSellersSection() {
    final bestSellers = [
      {
        'name': 'Energie Fitness Air Bike',
        'price': '₹14,999',
        'originalPrice': '₹18,999',
        'discount': '-21%',
        'rating': '4.7',
        'image': 'assets/images/product_3.png',
      },
      {
        'name': 'Cockatoo Multi Gym',
        'price': '₹24,499',
        'originalPrice': '₹29,999',
        'discount': '-18%',
        'rating': '4.9',
        'image': 'assets/images/product_4.png',
      },
      {
        'name': 'SincMill Multi Gym',
        'price': '₹32,999',
        'originalPrice': '₹39,999',
        'discount': '-17%',
        'rating': '4.8',
        'image': 'assets/images/product_5.png',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best Sellers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        SizedBox(
          height: 245,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: bestSellers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _buildProductCardOutsideImage(bestSellers[index]);
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 7. ELEVATE YOUR WELLNESS BANNER
  // -------------------------------------------------------------
  Widget _buildWellnessBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: AspectRatio(
        aspectRatio: 2.8,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/images/elevate_banner.png'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 8. TOP PICKS FOR YOU SECTION (4 CARDS)
  // -------------------------------------------------------------
  Widget _buildTopPicksSection() {
    final topPicks = [
      'assets/images/top_pick_1.png',
      'assets/images/top_pick_2.jpg',
      'assets/images/top_pick_3.jpg',
      'assets/images/top_pick_4.png',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Picks For You',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topPicks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(topPicks[index]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 8.5. FEATURED SUPPLEMENTS SECTION
  // -------------------------------------------------------------
  
  Widget _buildFeaturedProductCard(Map<String, String> prod) {
    return SizedBox(
      width: 155,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The image card (no padding, BoxFit.cover, 3:4 ratio)
          Container(
            height: 206,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.5),
              child: Stack(
                children: [
                  // Full cover image
                  Positioned.fill(
                    child: Image.asset(
                      prod['image']!,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Rating Badge (top right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            prod['rating']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Discount Badge (top left)
                  if (prod.containsKey('discount'))
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prod['discount']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Title and Price below the image card
          Text(
            prod['name']!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prod.containsKey('originalPrice'))
                    Text(
                      prod['originalPrice']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                        height: 1.0,
                      ),
                    ),
                  Text(
                    prod['price']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _addToCart(prod['name']!),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSupplementsSection() {
    final featuredSupplements = [
      {
        'name': 'Mass Gainer Gold',
        'price': '₹4,999',
        'rating': '4.8',
        'image': 'assets/images/more_product_1.png',
      },
      {
        'name': 'Tropical Mango Whey',
        'price': '₹2,599',
        'rating': '4.9',
        'image': 'assets/images/more_product_2.png',
      },
      {
        'name': 'Strawberry Rush Whey',
        'price': '₹2,599',
        'rating': '4.7',
        'image': 'assets/images/more_product_3.png',
      },
      {
        'name': 'Creatine Fruit Punch',
        'price': '₹1,299',
        'rating': '4.8',
        'image': 'assets/images/more_product_4.jpg',
      },
      {
        'name': 'Ultima Whey Protein',
        'price': '₹3,199',
        'rating': '4.6',
        'image': 'assets/images/more_product_5.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'More Products',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        SizedBox(
          height: 310,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: featuredSupplements.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _buildFeaturedProductCard(featuredSupplements[index]);
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 9. TRUST & GUARANTEE BADGES FOOTER
  // -------------------------------------------------------------
  Widget _buildTrustBadgesFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTrustFooterItem(Icons.verified_outlined, "100% Original", "Products", const Color(0xFF16A34A)),
            _buildTrustFooterItem(Icons.local_shipping_outlined, "Fast & Secure", "Delivery", const Color(0xFF0284C7)),
            _buildTrustFooterItem(Icons.replay_rounded, "Easy Returns", "14 Days Return", const Color(0xFFEA580C)),
            _buildTrustFooterItem(Icons.credit_card_rounded, "Secure", "Payments", const Color(0xFF7C3AED)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustFooterItem(IconData icon, String line1, String line2, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line1,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              line2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
