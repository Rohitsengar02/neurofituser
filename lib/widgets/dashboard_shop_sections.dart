import '../widgets/staggered_slide_fade.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'dashboard_motion.dart';
import 'dashboard_highlights.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/marketplace_home_layout_service.dart';
import '../services/banners_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/products_backend_service.dart';
import '../screens/product_detail_screen.dart';
import '../screens/shop_screen.dart';

class DashboardShopTabContent extends StatefulWidget {
  const DashboardShopTabContent({super.key});

  @override
  State<DashboardShopTabContent> createState() =>
      _DashboardShopTabContentState();
}

class _DashboardShopTabContentState extends State<DashboardShopTabContent>
    with TickerProviderStateMixin {
  final MarketplaceHomeLayoutService _layoutService =
      MarketplaceHomeLayoutService.instance;
  final BannersBackendService _banService = BannersBackendService.instance;
  final CategoryBackendService _catService = CategoryBackendService.instance;
  final ProductsBackendService _prodService = ProductsBackendService.instance;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _wishlistedProductIds = {};
  String _selectedCategoryFilter = 'All';

  // Sequential Top 4 Sections Image Verification Gate & Skeleton State
  bool _isTop4SectionsLoaded = false;
  bool _precacheStarted = false;
  int _totalCriticalImages = 0;
  int _loadedCriticalImages = 0;
  Timer? _safetyTimeoutTimer;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _layoutService.addListener(_onUpdate);
    _banService.addListener(_onUpdate);
    _catService.addListener(_onUpdate);
    _prodService.addListener(_onUpdate);

    // Safety timeout: If network is slow, unlock skeleton after max 3.5s
    _safetyTimeoutTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_isTop4SectionsLoaded) {
        setState(() => _isTop4SectionsLoaded = true);
      }
    });

    _loadDataAndVerifyTopSections();
  }

  Future<void> _loadDataAndVerifyTopSections() async {
    // Force fresh data fetch from Firestore
    try {
      await Future.wait([
        _layoutService.fetchLayoutSectionsFromFirestore(),
        _banService.fetchBannersFromFirestore(),
        _catService.fetchCategoriesFromFirestore(),
        _prodService.fetchProductsFromFirestore(),
      ]).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Firestore fetch timeout/error in Shop tab: $e');
    }

    if (mounted) {
      setState(() {});
      _startSequentialTop4SectionsPrecache();
    }
  }

  void _startSequentialTop4SectionsPrecache() async {
    if (_precacheStarted) return;
    _precacheStarted = true;

    // Collect Section 1: Hero Banners
    final List<String> section1Banners = _banService.banners
        .take(2)
        .map((b) => b.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();

    // Collect Section 2: Quick Categories
    final List<String> section2Categories = _catService.categories
        .take(6)
        .map((c) => c.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();

    // Collect Section 3 & 4: Top Featured Products
    final List<String> section3And4Products = _prodService.products
        .take(4)
        .map((p) => p.images.isNotEmpty ? p.images.first : '')
        .where((url) => url.isNotEmpty)
        .toList();

    final List<String> allTop4SectionUrls = [
      ...section1Banners,
      ...section2Categories,
      ...section3And4Products,
    ];

    if (allTop4SectionUrls.isEmpty) {
      if (mounted) setState(() => _isTop4SectionsLoaded = true);
      return;
    }

    _totalCriticalImages = allTop4SectionUrls.length;
    _loadedCriticalImages = 0;

    // Verify images sequentially top section by top section
    for (final url in allTop4SectionUrls) {
      final image = NetworkImage(url);
      image
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (ImageInfo info, bool syncCall) => _onCriticalImageLoaded(),
              onError: (dynamic exc, StackTrace? st) =>
                  _onCriticalImageLoaded(),
            ),
          );
    }
  }

  void _onCriticalImageLoaded() {
    if (!mounted || _isTop4SectionsLoaded) return;
    _loadedCriticalImages++;

    // When all top section images are verified loaded, dismiss skeleton layout
    if (_loadedCriticalImages >= _totalCriticalImages) {
      _safetyTimeoutTimer?.cancel();
      setState(() {
        _isTop4SectionsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _safetyTimeoutTimer?.cancel();
    _shimmerController.dispose();
    _layoutService.removeListener(_onUpdate);
    _banService.removeListener(_onUpdate);
    _catService.removeListener(_onUpdate);
    _prodService.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) {
      if (!_isTop4SectionsLoaded && !_precacheStarted) {
        _startSequentialTop4SectionsPrecache();
      } else {
        setState(() {});
      }
    }
  }

  void _toggleWishlist(String productId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_wishlistedProductIds.contains(productId)) {
        _wishlistedProductIds.remove(productId);
      } else {
        _wishlistedProductIds.add(productId);
      }
    });

    final isAdded = _wishlistedProductIds.contains(productId);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded ? 'Added to Wishlist ❤️' : 'Removed from Wishlist',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTop4SectionsLoaded) {
      return _buildFullDashboardSkeleton();
    }

    final products = _prodService.products;
    final activeSections = _layoutService.activeSections;

    List<ProductModel> searchResults = [];
    if (_searchQuery.isNotEmpty) {
      searchResults = products
          .where(
            (p) =>
                p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // 1. Search Bar & Full Store CTA with Stagger Entrance (Index 0)
        StaggeredSlideFade(
          index: 0,
          duration: const Duration(milliseconds: 400),
          child: _buildSearchAndShopHeader(),
        ),

        const SizedBox(height: 14),

        if (_searchQuery.isEmpty) ...[
          const StaggeredSlideFade(
            index: 1,
            duration: Duration(milliseconds: 450),
            child: FlashDealStrip(),
          ),
          const SizedBox(height: 16),
        ],

        // 2. SEARCH MODE OR REAL-TIME LAYOUT CMS SECTIONS (Staggered Entrance)
        if (_searchQuery.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Search Results for "$_searchQuery" (${searchResults.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          if (searchResults.isEmpty)
            _buildNoSearchResults()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchResults.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) =>
                    _buildProductCard(searchResults[index]),
              ),
            ),
        ] else ...[
          // Render Dynamic Layout Sections with Staggered Entrance
          if (_layoutService.isLoading && activeSections.isEmpty)
            _buildFullDashboardSkeleton()
          else if (activeSections.isEmpty) ...[
            // Fallback default layout sections so Shop tab is never blank
            if (_banService.banners.isNotEmpty)
              _renderBannerSection(LayoutSectionModel(id: 'def_ban', title: 'Special Offers', showTitle: false, type: 'banners', layoutMode: 'carousel')),
            if (_catService.categories.isNotEmpty)
              _renderCategorySection(LayoutSectionModel(id: 'def_cat', title: 'Shop by Category 🏷️', type: 'categories', layoutMode: 'carousel')),
            _renderProductSection(LayoutSectionModel(id: 'def_prod', title: 'Trending Essentials 🔥', subtitle: 'Top rated gear loved by athletes', type: 'products', layoutMode: 'grid')),
          ] else
            ...List.generate(activeSections.length, (index) {
              return Reveal(
                delay: Duration(milliseconds: 60 * (index + 2)),
                child: _renderDynamicSection(activeSections[index]),
              );
            }),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // -------------------------------------------------------------
  // SHIMMER SKELETON PLACEHOLDER (TOP TO BOTTOM)
  // -------------------------------------------------------------
  Widget _buildFullDashboardSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerVal = _shimmerController.value;
        final baseColor = const Color(0xFFE2E8F0);
        final highlightColor = const Color(0xFFF8FAFC);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar Skeleton
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    baseColor,
                    highlightColor,
                    (shimmerVal * 2 - 1).abs(),
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              const SizedBox(height: 14),

              // Hero Banner Skeleton (180px)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Color.lerp(baseColor, highlightColor, shimmerVal),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),

              // Circular Categories Skeleton Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (i) => Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            baseColor,
                            highlightColor,
                            (shimmerVal + (i * 0.15)) % 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 48,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            baseColor,
                            highlightColor,
                            shimmerVal,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Products Grid Skeleton
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            baseColor,
                            highlightColor,
                            (shimmerVal + (index * 0.2)) % 1.0,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 110,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // DYNAMIC SECTION RENDERER DISPATCHER
  // -------------------------------------------------------------
  Widget _renderDynamicSection(LayoutSectionModel section) {
    if (section.type == 'banners') {
      return _renderBannerSection(section);
    } else if (section.type == 'categories') {
      return _renderCategorySection(section);
    } else if (section.type == 'products') {
      return _renderProductSection(section);
    }
    return const SizedBox.shrink();
  }

  // -------------------------------------------------------------
  // 1. BANNER SECTION (CAROUSEL VS 2X2 GRID)
  // -------------------------------------------------------------
  Widget _renderBannerSection(LayoutSectionModel sec) {
    final allBanners = _banService.banners;
    List<BannerModel> bannersToRender = [];

    if (sec.selectedItemIds.isNotEmpty) {
      bannersToRender = allBanners
          .where(
            (b) =>
                sec.selectedItemIds.contains(b.bannerId) ||
                sec.selectedItemIds.contains(b.id),
          )
          .toList();
    }
    if (bannersToRender.isEmpty) {
      bannersToRender = allBanners;
    }
    if (bannersToRender.isEmpty) return const SizedBox.shrink();

    if (sec.layoutMode == 'grid') {
      final gridBanners = bannersToRender.take(4).toList();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sec.title.isNotEmpty)
              _buildSectionHeader(sec.title, sec.subtitle),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridBanners.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (ctx, i) => _buildBannerGridCard(gridBanners[i]),
            ),
          ],
        ),
      );
    }

    // Carousel Mode - Clean Pure Image (NO header, NO 'See All')
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _DashBannerCarouselWidget(banners: bannersToRender),
    );
  }

  Widget _buildBannerGridCard(BannerModel b) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (b.discountCode.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: b.discountCode));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Promo Code "${b.discountCode}" copied! 🎉'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.network(
              CategoryBackendService.getDisplayableImageUrl(b.imageUrl),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF1E293B)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (b.badge.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        b.badge,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    b.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. CATEGORY CIRCULAR CAROUSEL (EXACT MATCH TO REFERENCE DESIGN)
  // -------------------------------------------------------------
  Widget _renderCategorySection(LayoutSectionModel sec) {
    final categories = _catService.categories;
    if (categories.isEmpty) return const SizedBox.shrink();

    final List<Color> pastelBgs = [
      const Color(0xFFFFEDD5), // Peach / Orange
      const Color(0xFFEDE9FE), // Soft Lavender
      const Color(0xFFDCFCE7), // Soft Mint
      const Color(0xFFFCE7F3), // Soft Rose
      const Color(0xFFE0F2FE), // Soft Sky Blue
      const Color(0xFFFEF3C7), // Soft Amber
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length + 1,
          separatorBuilder: (c, i) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final catName = isAll ? 'All' : categories[index - 1].name;
            final catImage = isAll ? '' : categories[index - 1].imageUrl;
            final isSelected =
                _selectedCategoryFilter == (isAll ? 'All' : catName);
            final bgColor = pastelBgs[index % pastelBgs.length];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShopScreen(initialCategory: isAll ? 'All' : catName),
                  ),
                );
              },
              child: SizedBox(
                width: 68,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : Colors.transparent,
                          width: isSelected ? 2.0 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: isAll
                            ? Center(
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  color: isSelected
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF475569),
                                  size: 24,
                                ),
                              )
                            : (catImage.isNotEmpty
                                  ? Image.network(
                                      CategoryBackendService.getDisplayableImageUrl(catImage),
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        color: bgColor,
                                        child: const Icon(
                                          Icons.fitness_center_rounded,
                                          color: Color(0xFF475569),
                                          size: 22,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: bgColor,
                                      child: const Icon(
                                        Icons.fitness_center_rounded,
                                        color: Color(0xFF475569),
                                        size: 22,
                                      ),
                                    )),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      catName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF334155),
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. PRODUCT SECTION (CAROUSEL VS 2-COL GRID)
  // -------------------------------------------------------------
  Widget _renderProductSection(LayoutSectionModel sec) {
    final allProducts = _prodService.products;
    List<ProductModel> filtered = allProducts;

    if (sec.filterSource == 'category' && sec.filterName.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.category.toLowerCase().contains(sec.filterName.toLowerCase()),
          )
          .toList();
    }
    if (_selectedCategoryFilter != 'All') {
      filtered = filtered
          .where(
            (p) => p.category.toLowerCase().contains(
              _selectedCategoryFilter.toLowerCase(),
            ),
          )
          .toList();
    }

    filtered = filtered.take(sec.itemLimit).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    if (sec.layoutMode == 'carousel') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionHeader(sec.title, sec.subtitle),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                separatorBuilder: (c, i) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 165,
                    child: _buildProductCard(filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(sec.title, sec.subtitle),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) => _buildProductCard(filtered[index]),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PRODUCT CARD COMPONENT (REVIEWS BETWEEN TITLE AND PRICE)
  // -------------------------------------------------------------
  Widget _buildProductCard(ProductModel p) {
    final isWishlisted = _wishlistedProductIds.contains(p.id);
    final imageUrl = p.images.isNotEmpty
        ? p.images.first
        : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600';
    final double price = p.salePrice > 0 ? p.salePrice : p.basePrice;
    final double? oldPrice = p.salePrice > 0 && p.basePrice > p.salePrice
        ? p.basePrice
        : null;
    final rating = p.rating > 0 ? p.rating : 4.8;
    final reviews = p.reviewsCount > 0 ? p.reviewsCount : 128;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: p,
              title: p.title,
              subtitle: '${p.category} – Lab Certified',
              price: price,
              oldPrice: oldPrice,
              image: imageUrl,
              rating: rating,
              reviewsCount: '$reviews',
              category: p.category,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Clean Product Image with Wishlist Button on Top Right (No Reviews in Image)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.network(
                    CategoryBackendService.getDisplayableImageUrl(imageUrl),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: Color(0xFF94A3B8),
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Top-Right Wishlist Button Only
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(p.id),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0)
                                .withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isWishlisted
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF334155),
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 2. Product Title
          Text(
            p.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 3),

          // 3. Reviews Rating (Between Title and Price)
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($reviews)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          // 4. Product Price (Bold Purple/Indigo)
          Row(
            children: [
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              if (oldPrice != null) ...[
                const SizedBox(width: 6),
                Text(
                  '₹${oldPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HEADER COMPONENTS
  // -------------------------------------------------------------
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShopScreen()),
            );
          },
          child: Text(
            'See All',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndShopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search whey, gear, supplements...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Full Store',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            'No matching products found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching with different keywords',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// DASHBOARD HERO CAROUSEL COMPONENT (PURE IMAGE, NO OVERLAY TEXT, HEIGHT 180)
// =========================================================================
class _DashBannerCarouselWidget extends StatefulWidget {
  final List<BannerModel> banners;
  const _DashBannerCarouselWidget({required this.banners});

  @override
  State<_DashBannerCarouselWidget> createState() =>
      _DashBannerCarouselWidgetState();
}

class _DashBannerCarouselWidgetState extends State<_DashBannerCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted || !_pageController.hasClients) return;
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleBannerTap(BannerModel b) {
    HapticFeedback.lightImpact();
    if (b.discountCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: b.discountCode));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo Code "${b.discountCode}" copied! 🎉'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShopScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final b = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () => _handleBannerTap(b),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      CategoryBackendService.getDisplayableImageUrl(b.imageUrl),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _currentPage == i ? 20 : 6,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
