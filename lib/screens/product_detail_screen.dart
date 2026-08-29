import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final double? price;
  final double? oldPrice;
  final String? image;
  final double? rating;
  final String? reviewsCount;
  final String? category;

  const ProductDetailScreen({
    super.key,
    this.title,
    this.subtitle,
    this.price,
    this.oldPrice,
    this.image,
    this.rating,
    this.reviewsCount,
    this.category,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isWishlisted = false;
  int _currentImageIndex = 0;
  int _selectedFlavorIndex = 0;
  int _selectedSizeIndex = 1; // 2kg default

  final List<Map<String, dynamic>> _flavors = [
    {'name': 'Chocolate', 'emoji': '🍫', 'color': Color(0xFF78350F)},
    {'name': 'Vanilla', 'emoji': '🍦', 'color': Color(0xFFFDE68A)},
    {'name': 'Strawberry', 'emoji': '🍓', 'color': Color(0xFFE11D48)},
    {'name': 'Cookies & Cream', 'emoji': '🍪', 'color': Color(0xFF525252)},
    {'name': 'Mango', 'emoji': '🥭', 'color': Color(0xFFF59E0B)},
  ];

  final List<Map<String, dynamic>> _sizes = [
    {'size': '1kg', 'price': 1349, 'oldPrice': 1699, 'servings': '30 Servings'},
    {'size': '2kg', 'price': 2399, 'oldPrice': 2999, 'servings': '60 Servings'},
    {'size': '3kg', 'price': 3499, 'oldPrice': 4299, 'servings': '90 Servings'},
    {'size': '5kg', 'price': 5499, 'oldPrice': 6799, 'servings': '150 Servings'},
  ];

  final List<String> _productImages = [
    'assets/images/nutrifit_whey_protein.jpg',
    'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1546483875-ad9014c88eba?w=800&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.image != null && widget.image!.isNotEmpty) {
      if (!_productImages.contains(widget.image)) {
        _productImages.insert(0, widget.image!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'NutriFit Whey Protein';
    final subtitle = widget.subtitle ?? 'Premium Blend – Chocolate Flavor';
    final currentSize = _sizes[_selectedSizeIndex];
    final price = currentSize['price'] as int;
    final oldPrice = currentSize['oldPrice'] as int;
    final rating = widget.rating ?? 4.8;
    final reviewsCount = widget.reviewsCount ?? '1,256';

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Top App Bar
                StaggeredSlideFade(index: 0, child: _buildTopAppBar()),

                // Scrollable Body Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 2. Product Image Carousel Showcase
                        StaggeredSlideFade(index: 1, child: _buildImageShowcase()),

                        const SizedBox(height: 16),

                        // 3. Product Header (Title, Rating, Price)
                        StaggeredSlideFade(
                          index: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildTitleAndPriceSection(
                              title: title,
                              subtitle: subtitle,
                              price: price,
                              oldPrice: oldPrice,
                              rating: rating,
                              reviewsCount: reviewsCount,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 4. Flavor Selector
                        StaggeredSlideFade(index: 3, child: _buildFlavorSelector()),

                        const SizedBox(height: 20),

                        // 5. Size Selector
                        StaggeredSlideFade(index: 4, child: _buildSizeSelector()),

                        const SizedBox(height: 20),

                        // 6. Key Nutritional Highlights Card (4 Pills)
                        StaggeredSlideFade(
                          index: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildNutritionalHighlightsCard(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 7. Highlights & Benefits Accordion
                        StaggeredSlideFade(
                          index: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildHighlightsAccordion(),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 8. Fixed Bottom Action Bar (Add to Cart & Buy Now)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFixedBottomBar(title, price),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP APP BAR
  // -------------------------------------------------------------
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
          Text(
            'Product Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Product link copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: const Color(0xFF0F172A),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: Color(0xFF0F172A),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isWishlisted = !_isWishlisted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isWishlisted ? 'Added to Wishlist!' : 'Removed from Wishlist'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: _isWishlisted ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isWishlisted ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. PRODUCT IMAGE SHOWCASE CAROUSEL
  // -------------------------------------------------------------
  Widget _buildImageShowcase() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 330,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // PageView Carousel of Images
            PageView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _productImages.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                final img = _productImages[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: img.startsWith('assets')
                      ? Image.asset(
                          img,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.medication_liquid_rounded,
                            size: 100,
                            color: Color(0xFF94A3B8),
                          ),
                        )
                      : Image.network(
                          img,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.medication_liquid_rounded,
                            size: 100,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                );
              },
            ),

            // Top-Left "Bestseller" Badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Bestseller',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-Right "-20%" Badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  '-20%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ),

            // Bottom Pagination Dots
            Positioned(
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_productImages.length, (index) {
                  final isCurrent = _currentImageIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isCurrent ? 14 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. TITLE & PRICE SECTION
  // -------------------------------------------------------------
  Widget _buildTitleAndPriceSection({
    required String title,
    required String subtitle,
    required int price,
    required int oldPrice,
    required double rating,
    required String reviewsCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // Rating and Sold Row
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 4),
            Text(
              '$rating',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($reviewsCount Reviews)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
            const SizedBox(width: 10),
            Text(
              '10K+ Sold',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pricing Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₹$price',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE11D48), // Coral / Red price
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹$oldPrice',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '20% OFF',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Inclusive of all taxes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. FLAVOR SELECTOR
  // -------------------------------------------------------------
  Widget _buildFlavorSelector() {
    final selectedFlavor = _flavors[_selectedFlavorIndex]['name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flavor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Choose your favorite flavor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    selectedFlavor,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF64748B)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Flavors Horizontal List
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _flavors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final f = _flavors[index];
              final isSelected = _selectedFlavorIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFlavorIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(f['emoji'] as String, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        f['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. SIZE SELECTOR
  // -------------------------------------------------------------
  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Size',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Choose your pack size',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Size cards row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: _sizes.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;
              final isSelected = _selectedSizeIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSizeIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: index < _sizes.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          s['size'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${s['price']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 6. KEY NUTRITIONAL HIGHLIGHTS CARD (4 METRIC PILLS)
  // -------------------------------------------------------------
  Widget _buildNutritionalHighlightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNutritionMetric(Icons.fitness_center_rounded, '24g', 'Protein', 'Per Serving'),
          _buildNutritionMetric(Icons.grain_rounded, '5.5g', 'BCAAs', 'Per Serving'),
          _buildNutritionMetric(Icons.bolt_rounded, '4g', 'Glutamine', 'Per Serving'),
          _buildNutritionMetric(Icons.block_rounded, 'No', 'Added', 'Sugar'),
        ],
      ),
    );
  }

  Widget _buildNutritionMetric(IconData icon, String value, String label, String sub) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF16A34A)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 7. HIGHLIGHTS & BENEFITS ACCORDION
  // -------------------------------------------------------------
  Widget _buildHighlightsAccordion() {
    final benefits = [
      'Supports Muscle Growth & Recovery',
      'High Quality Whey Protein',
      'Instant Mixability & Great Taste',
      'Tested for Purity & Quality',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Highlights',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 12),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 8. FIXED BOTTOM ACTION BAR
  // -------------------------------------------------------------
  Widget _buildFixedBottomBar(String title, int price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Add to Cart Button (White)
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title added to your cart!'),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 18, color: Color(0xFF0F172A)),
                    const SizedBox(width: 6),
                    Text(
                      'Add to Cart',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Buy Now Button (Vivid Green)
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Proceeding to checkout for ₹$price...'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Buy Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
