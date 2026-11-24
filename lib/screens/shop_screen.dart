import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_backend_service.dart';
import '../services/products_backend_service.dart';
import '../services/banners_backend_service.dart';
import '../services/marketplace_home_layout_service.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  final String? initialCategory;
  const ShopScreen({super.key, this.initialCategory});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  final CategoryBackendService _catService = CategoryBackendService.instance;
  final ProductsBackendService _prodService = ProductsBackendService.instance;
  final BannersBackendService _banService = BannersBackendService.instance;
  final MarketplaceHomeLayoutService _layoutService = MarketplaceHomeLayoutService.instance;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _wishlistedProductIds = {};
  late String _selectedCategoryFilter;

  // Filter State
  RangeValues _priceRange = const RangeValues(0, 10000);
  String _selectedSortBy = 'Popularity'; // 'Popularity', 'Price: Low to High', 'Price: High to Low', 'Top Rated'
  double _minRatingFilter = 0.0;
  bool _onlyInStock = false;
  String _selectedBrandFilter = 'All';

  // 60% Top-to-Bottom Image Loading Gate
  bool _isInitialLoading = true;
  int _totalCriticalImages = 0;
  int _loadedCriticalImages = 0;
  bool _precacheStarted = false;
  late AnimationController _shimmerController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedCategoryFilter = widget.initialCategory ?? 'All';

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _catService.addListener(_onServiceUpdate);
    _prodService.addListener(_onServiceUpdate);
    _banService.addListener(_onServiceUpdate);
    _layoutService.addListener(_onServiceUpdate);

    _loadDataAndPrecache();
  }

  Future<void> _loadDataAndPrecache() async {
    await Future.wait([
      _catService.fetchCategoriesFromFirestore(),
      _prodService.fetchProductsFromFirestore(),
      _banService.fetchBannersFromFirestore(),
      _layoutService.fetchLayoutSectionsFromFirestore(),
    ]);

    if (mounted) {
      _startTopToBottomImagePrecache();
    }
  }

  void _startTopToBottomImagePrecache() {
    if (_precacheStarted) return;
    _precacheStarted = true;

    final List<String> criticalUrls = [];
    for (final c in _catService.categories.take(5)) {
      if (c.imageUrl.isNotEmpty) criticalUrls.add(c.imageUrl);
    }
    for (final p in _prodService.products.take(6)) {
      if (p.images.isNotEmpty) criticalUrls.add(p.images.first);
    }

    if (criticalUrls.isEmpty) {
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    _totalCriticalImages = criticalUrls.length;
    _loadedCriticalImages = 0;

    Timer(const Duration(milliseconds: 600), () {
      if (mounted && _isInitialLoading) {
        setState(() => _isInitialLoading = false);
      }
    });

    for (final url in criticalUrls) {
      final image = NetworkImage(url);
      image.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener(
          (ImageInfo info, bool synchronousCall) => _onImageLoaded(),
          onError: (dynamic exception, StackTrace? stackTrace) => _onImageLoaded(),
        ),
      );
    }
  }

  void _onImageLoaded() {
    if (!mounted || !_isInitialLoading) return;
    _loadedCriticalImages++;
    final progress = _loadedCriticalImages / (_totalCriticalImages > 0 ? _totalCriticalImages : 1);
    if (progress >= 0.60) {
      setState(() => _isInitialLoading = false);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _catService.removeListener(_onServiceUpdate);
    _prodService.removeListener(_onServiceUpdate);
    _banService.removeListener(_onServiceUpdate);
    _layoutService.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      if (_isInitialLoading && !_precacheStarted) {
        _startTopToBottomImagePrecache();
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

  // -------------------------------------------------------------
  // OPEN FILTER SIDEBAR / BOTTOM SLIDER
  // -------------------------------------------------------------
  void _openFilterSlider() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final allProducts = _prodService.products;
          final allBrands = {'All', ...allProducts.map((p) => p.brand).where((b) => b.isNotEmpty)}.toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters & Sort',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          _priceRange = const RangeValues(0, 10000);
                          _selectedSortBy = 'Popularity';
                          _minRatingFilter = 0.0;
                          _onlyInStock = false;
                          _selectedBrandFilter = 'All';
                        });
                        setState(() {});
                      },
                      child: Text(
                        'Reset All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(color: Color(0xFFF1F5F9), height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Sort Options
                        Text(
                          'Sort By',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Popularity',
                            'Price: Low to High',
                            'Price: High to Low',
                            'Top Rated',
                          ].map((sort) {
                            final isSel = _selectedSortBy == sort;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setModalState(() => _selectedSortBy = sort);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  sort,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 2. Price Range Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Price Range',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 10000,
                          divisions: 100,
                          activeColor: const Color(0xFF7C3AED),
                          inactiveColor: const Color(0xFFE2E8F0),
                          onChanged: (vals) {
                            setModalState(() => _priceRange = vals);
                          },
                        ),

                        const SizedBox(height: 16),

                        // 3. Brand Filter
                        if (allBrands.length > 1) ...[
                          Text(
                            'Brand / Manufacturer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allBrands.map((b) {
                              final isSel = _selectedBrandFilter == b;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => _selectedBrandFilter = b);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    b,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      color: isSel ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 4. Minimum Rating Filter
                        Text(
                          'Minimum Rating',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [0.0, 3.0, 4.0, 4.5].map((r) {
                            final isSel = _minRatingFilter == r;
                            final label = r == 0.0 ? 'All' : '${r.toStringAsFixed(1)}+ ⭐';
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => _minRatingFilter = r);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                        color: isSel ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 5. In Stock Only Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'In Stock Products Only',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Switch(
                                value: _onlyInStock,
                                activeColor: const Color(0xFF16A34A),
                                onChanged: (val) {
                                  setModalState(() => _onlyInStock = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: false,
          child: _buildFullSkeletonLayout(),
        ),
      );
    }

    final allProducts = _prodService.products;
    final categories = _catService.categories;

    // Apply Filter Pipeline
    List<ProductModel> filtered = allProducts;

    // 1. Category Filter
    if (_selectedCategoryFilter != 'All' && _selectedCategoryFilter != 'Discounts & Deals') {
      filtered = filtered
          .where((p) => p.category.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()))
          .toList();
    }

    // 2. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // 3. Price Range Filter
    filtered = filtered.where((p) {
      final price = p.salePrice > 0 ? p.salePrice : p.basePrice;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // 4. Rating Filter
    if (_minRatingFilter > 0.0) {
      filtered = filtered.where((p) => (p.rating > 0 ? p.rating : 4.8) >= _minRatingFilter).toList();
    }

    // 5. In Stock Only
    if (_onlyInStock) {
      filtered = filtered.where((p) => p.stock > 0).toList();
    }

    // 6. Brand Filter
    if (_selectedBrandFilter != 'All') {
      filtered = filtered.where((p) => p.brand.toLowerCase() == _selectedBrandFilter.toLowerCase()).toList();
    }

    // 7. Sort Order
    if (_selectedSortBy == 'Price: Low to High') {
      filtered.sort((a, b) => (a.salePrice > 0 ? a.salePrice : a.basePrice).compareTo(b.salePrice > 0 ? b.salePrice : b.basePrice));
    } else if (_selectedSortBy == 'Price: High to Low') {
      filtered.sort((a, b) => (b.salePrice > 0 ? b.salePrice : b.basePrice).compareTo(a.salePrice > 0 ? a.salePrice : a.basePrice));
    } else if (_selectedSortBy == 'Top Rated') {
      filtered.sort((a, b) => (b.rating).compareTo(a.rating));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Top Header with Back Button + Search Bar + Filter Slider Button
              _buildSearchAndFilterHeader(),

              const SizedBox(height: 12),

              // 2. Circular Categories Carousel
              _buildCircularCategoriesCarousel(categories),

              const SizedBox(height: 16),

              // 3. Products Catalog Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategoryFilter == 'All'
                          ? (_searchQuery.isNotEmpty ? 'Search Results (${filtered.length})' : 'All Products (${filtered.length})')
                          : '$_selectedCategoryFilter (${filtered.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_selectedCategoryFilter != 'All' || _searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategoryFilter = 'All';
                            _searchController.clear();
                            _searchQuery = '';
                            _priceRange = const RangeValues(0, 10000);
                            _selectedSortBy = 'Popularity';
                            _minRatingFilter = 0.0;
                            _onlyInStock = false;
                            _selectedBrandFilter = 'All';
                          });
                        },
                        child: Text(
                          'Clear Filters',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                _buildNoProductsFound()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
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
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DYNAMIC CMS LAYOUT SECTION RENDERER
  // -------------------------------------------------------------
  Widget _buildDynamicLayoutSection(LayoutSectionModel section) {
    if (!section.isActive) return const SizedBox.shrink();

    Widget contentWidget;
    if (section.type == 'banners') {
      contentWidget = _buildBannerSectionContent(section);
    } else if (section.type == 'categories') {
      contentWidget = _buildCategorySectionContent(section);
    } else {
      contentWidget = _buildProductSectionContent(section);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.showTitle && section.title.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                if (section.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        contentWidget,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBannerSectionContent(LayoutSectionModel section) {
    final banners = _banService.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    List<BannerModel> targetBanners = banners;
    if (section.selectedItemIds.isNotEmpty) {
      final selected = banners.where((b) => section.selectedItemIds.contains(b.bannerId) || section.selectedItemIds.contains(b.id)).toList();
      if (selected.isNotEmpty) targetBanners = selected;
    }

    final items = targetBanners.take(section.itemLimit).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    if (section.layoutMode == 'grid') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, idx) => _buildBannerCard(items[idx]),
        ),
      );
    }

    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, idx) => SizedBox(
          width: 280,
          child: _buildBannerCard(items[idx]),
        ),
      ),
    );
  }

  Widget _buildBannerCard(BannerModel b) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              CategoryBackendService.getDisplayableImageUrl(b.imageUrl),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE2E8F0)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (b.title.isNotEmpty)
                    Text(
                      b.title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (b.subtitle.isNotEmpty)
                    Text(
                      b.subtitle,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: Colors.white70),
                      maxLines: 1,
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

  Widget _buildCategorySectionContent(LayoutSectionModel section) {
    final categories = _catService.categories;
    if (categories.isEmpty) return const SizedBox.shrink();

    final items = categories.take(section.itemLimit).toList();

    if (section.layoutMode == 'grid') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, idx) {
            final cat = items[idx];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategoryFilter = cat.name);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: cat.imageUrl.isNotEmpty
                          ? Image.network(cat.imageUrl, width: 42, height: 42, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9)))
                          : Container(color: const Color(0xFFF1F5F9), width: 42, height: 42, child: const Icon(Icons.category_rounded, size: 20, color: Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildCircularCategoriesCarousel(categories);
  }

  Widget _buildProductSectionContent(LayoutSectionModel section) {
    List<ProductModel> sectionProducts = _prodService.products;

    if (section.filterSource == 'category' && section.filterId.isNotEmpty) {
      sectionProducts = sectionProducts.where((p) => p.categoryId == section.filterId || p.category.toLowerCase().contains(section.filterName.toLowerCase())).toList();
    } else if (section.filterSource == 'subcategory' && section.filterId.isNotEmpty) {
      sectionProducts = sectionProducts.where((p) => p.subcategoryId == section.filterId || p.subcategoryName.toLowerCase().contains(section.filterName.toLowerCase())).toList();
    } else if (section.filterSource == 'featured') {
      sectionProducts = sectionProducts.where((p) => p.isFeatured).toList();
    }

    if (sectionProducts.isEmpty) sectionProducts = _prodService.products;
    final items = sectionProducts.take(section.itemLimit).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    if (section.layoutMode == 'grid') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) => _buildProductCard(items[index]),
        ),
      );
    }

    return SizedBox(
      height: 255,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 165,
          child: _buildProductCard(items[index]),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP SEARCH & FILTER BUTTON HEADER
  // -------------------------------------------------------------
  Widget _buildSearchAndFilterHeader() {
    final bool hasActiveFilters = _priceRange.start > 0 || _priceRange.end < 10000 || _minRatingFilter > 0.0 || _onlyInStock || _selectedBrandFilter != 'All';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
            ),
          ),

          // Search Field
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search whey, gear, supplements...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Filter Button (Opens Sidebar Slider)
          GestureDetector(
            onTap: _openFilterSlider,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasActiveFilters ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: hasActiveFilters ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: hasActiveFilters ? Colors.white : const Color(0xFF0F172A),
                    size: 20,
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
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

  // -------------------------------------------------------------
  // 2. CIRCULAR CATEGORIES CAROUSEL (SAME EXACT UI AS SHOP TAB)
  // -------------------------------------------------------------
  Widget _buildCircularCategoriesCarousel(List<CategoryModel> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final List<Color> pastelBgs = [
      const Color(0xFFFFEDD5), // Peach / Orange
      const Color(0xFFEDE9FE), // Soft Lavender
      const Color(0xFFDCFCE7), // Soft Mint
      const Color(0xFFFCE7F3), // Soft Rose
      const Color(0xFFE0F2FE), // Soft Sky Blue
      const Color(0xFFFEF3C7), // Soft Amber
    ];

    return SizedBox(
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
          final isSelected = _selectedCategoryFilter == (isAll ? 'All' : catName);
          final bgColor = pastelBgs[index % pastelBgs.length];

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategoryFilter = isAll ? 'All' : catName;
              });
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
                        color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
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
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
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
                                    child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF475569), size: 22),
                                  ),
                                )
                              : Container(
                                  color: bgColor,
                                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF475569), size: 22),
                                )),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    catName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
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
    );
  }

  // -------------------------------------------------------------
  // 3. PRODUCT CARD (REVIEWS BETWEEN TITLE & PRICE)
  // -------------------------------------------------------------
  Widget _buildProductCard(ProductModel p) {
    final isWishlisted = _wishlistedProductIds.contains(p.id);
    final imageUrl = p.images.isNotEmpty ? p.images.first : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600';
    final double price = p.salePrice > 0 ? p.salePrice : p.basePrice;
    final double? oldPrice = p.salePrice > 0 && p.basePrice > p.salePrice ? p.basePrice : null;
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
                        child: Icon(Icons.fitness_center_rounded, color: Color(0xFF94A3B8), size: 32),
                      ),
                    ),
                  ),
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
                          border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF334155),
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
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
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

  Widget _buildNoProductsFound() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No matching products found',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your filters or price range',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSkeletonLayout() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerVal = _shimmerController.value;
        final baseColor = const Color(0xFFE2E8F0);
        final highlightColor = const Color(0xFFF8FAFC);

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Color.lerp(baseColor, highlightColor, (shimmerVal * 2 - 1).abs()),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (i) => Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(baseColor, highlightColor, (shimmerVal + (i * 0.15)) % 1.0),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 48,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color.lerp(baseColor, highlightColor, shimmerVal),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                          color: Color.lerp(baseColor, highlightColor, (shimmerVal + (index * 0.2)) % 1.0),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 110, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 4),
                    Container(height: 14, width: 60, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
