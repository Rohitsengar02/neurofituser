import 'checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/products_backend_service.dart';
import 'product_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductItem? product;
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
    this.product,
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
  final ProductsBackendService _prodService = ProductsBackendService();
  late PageController _pageController;
  int _selectedImageIndex = 0;
  int _selectedVariantIndex = 0;
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _isDescriptionExpanded = false;

  late List<String> _allImages;
  late double _activePrice;
  late double? _activeOldPrice;
  late String _activeTitle;
  late String _activeCategory;
  late String _activeDescription;
  late double _activeRating;
  late int _activeReviewCount;
  late int _activeStock;
  late List<ProductVariant> _variants;

  // Real-time Community Reviews List
  final List<Map<String, dynamic>> _userReviews = [
    {
      'name': 'Rahul Sharma',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'rating': 5.0,
      'date': '2 days ago',
      'verified': true,
      'comment': 'Exceptional mixability and authentic taste. Noticed solid recovery within a week of use! Highly recommended.',
    },
    {
      'name': 'Priya Patel',
      'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      'rating': 5.0,
      'date': '1 week ago',
      'verified': true,
      'comment': 'Lab certification QR code verified immediately. Zero bloat, great protein-to-calorie ratio.',
    },
    {
      'name': 'Aman Verma',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'rating': 4.5,
      'date': '2 weeks ago',
      'verified': true,
      'comment': 'Top notch packaging and fast delivery. Chocolate flavor is rich without being overly sweet.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (_prodService.products.isEmpty) {
      _prodService.fetchProductsFromFirestore();
    }
    _prodService.addListener(_onServiceUpdate);

    final p = widget.product;
    if (p != null) {
      _activeTitle = p.title;
      _activeCategory = p.categoryName.isNotEmpty ? p.categoryName : (widget.category ?? 'Supplements');
      _activeDescription = p.description.isNotEmpty
          ? p.description
          : 'Premium lab-certified formula designed for peak athletic performance, sustained energy, and rapid muscle recovery. Crafted with ultra-pure ingredients and verified for quality.';
      _activePrice = p.salePrice > 0 ? p.salePrice : p.price;
      _activeOldPrice = p.regularPrice > _activePrice ? p.regularPrice : null;
      _activeRating = p.rating > 0 ? p.rating : 4.8;
      _activeReviewCount = p.reviewCount > 0 ? p.reviewCount : 128;
      _activeStock = p.stock > 0 ? p.stock : 25;
      _variants = p.variants;

      final List<String> imgs = [];
      if (p.mainImageUrl.isNotEmpty) imgs.add(p.mainImageUrl);
      for (final img in p.additionalImages) {
        if (img.isNotEmpty && !imgs.contains(img)) imgs.add(img);
      }
      for (final v in p.variants) {
        if (v.imageUrl.isNotEmpty && !imgs.contains(v.imageUrl)) imgs.add(v.imageUrl);
      }
      if (imgs.isEmpty && widget.image != null) imgs.add(widget.image!);
      _allImages = imgs.isNotEmpty ? imgs : ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800'];
    } else {
      _activeTitle = widget.title ?? 'Gold Standard 100% Whey Isolate';
      _activeCategory = widget.category ?? 'Supplements';
      _activeDescription = 'Premium lab-certified formula designed for peak athletic performance, sustained energy, and rapid muscle recovery. Crafted with ultra-pure ingredients and verified for quality.';
      _activePrice = widget.price ?? 3499.0;
      _activeOldPrice = widget.oldPrice;
      _activeRating = widget.rating ?? 4.8;
      _activeReviewCount = int.tryParse(widget.reviewsCount ?? '128') ?? 128;
      _activeStock = 25;
      _variants = [
        ProductVariant(name: 'Double Rich Chocolate', price: 3499.0, stock: 20, sku: 'NF-CHO-01', imageUrl: widget.image ?? 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800'),
        ProductVariant(name: 'Vanilla Ice Cream', price: 3499.0, stock: 15, sku: 'NF-VAN-02', imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800'),
        ProductVariant(name: 'Delicious Strawberry', price: 3499.0, stock: 12, sku: 'NF-STR-03', imageUrl: 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=800'),
      ];
      _allImages = [
        widget.image ?? 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800',
        'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=800',
      ];
    }
  }

  @override
  void dispose() {
    _prodService.removeListener(_onServiceUpdate);
    _pageController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _selectImage(int index) {
    if (index >= 0 && index < _allImages.length) {
      setState(() => _selectedImageIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _selectVariant(int index) {
    if (index < 0 || index >= _variants.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedVariantIndex = index;
      final v = _variants[index];
      if (v.price > 0) _activePrice = v.price;
      if (v.stock > 0) _activeStock = v.stock;

      // When variant is selected, automatically switch main image carousel to that variant's image!
      if (v.imageUrl.isNotEmpty) {
        final imgIdx = _allImages.indexOf(v.imageUrl);
        if (imgIdx != -1) {
          _selectImage(imgIdx);
        } else {
          _allImages.add(v.imageUrl);
          _selectImage(_allImages.length - 1);
        }
      }
    });
  }

  void _toggleWishlist() {
    HapticFeedback.mediumImpact();
    setState(() => _isWishlisted = !_isWishlisted);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWishlisted ? 'Added to Wishlist ❤️' : 'Removed from Wishlist',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  // Cart Items Collection
  final List<Map<String, dynamic>> _cartItems = [];
  final TextEditingController _promoController = TextEditingController();
  double _appliedDiscount = 0.0;
  String _appliedPromoCode = '';

  void _addToCart() {
    HapticFeedback.heavyImpact();

    // Add or update current product in cart
    final String currentVariantName = _variants.isNotEmpty ? _variants[_selectedVariantIndex].name : 'Standard Edition';
    final String currentImage = _allImages.isNotEmpty ? _allImages[_selectedImageIndex] : '';

    final existingIdx = _cartItems.indexWhere((item) =>
        item['title'] == _activeTitle &&
        item['variant'] == currentVariantName);

    if (existingIdx != -1) {
      _cartItems[existingIdx]['quantity'] = (_cartItems[existingIdx]['quantity'] as int) + _quantity;
    } else {
      _cartItems.add({
        'title': _activeTitle,
        'variant': currentVariantName,
        'price': _activePrice,
        'quantity': _quantity,
        'image': currentImage,
      });
    }

    // Immediately open Slide-From-Right Cart Sidebar Drawer
    _openCartSlider();
  }

  // -------------------------------------------------------------
  // SLIDE-FROM-RIGHT CART SIDEBAR DRAWER
  // -------------------------------------------------------------
  void _openCartSlider() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CartDrawer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, anim2, child) {
        final slideAnim = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        return SlideTransition(
          position: slideAnim,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setCartState) {
                  double subtotal = 0;
                  int totalItems = 0;
                  for (final item in _cartItems) {
                    subtotal += (item['price'] as double) * (item['quantity'] as int);
                    totalItems += item['quantity'] as int;
                  }
                  final double finalTotal = (subtotal - _appliedDiscount).clamp(0.0, double.infinity);

                  return Container(
                    width: MediaQuery.of(context).size.width * 0.88,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'My Cart ($totalItems)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFE2E8F0)),

                          // 2. Free Delivery Badge
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping_rounded, color: Color(0xFF16A34A), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Free Express Delivery Applied 🎉',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Cart Items List
                          Expanded(
                            child: _cartItems.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.shopping_cart_outlined, size: 54, color: Color(0xFF94A3B8)),
                                        const SizedBox(height: 12),
                                        Text('Your cart is empty', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _cartItems.length,
                                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final item = _cartItems[index];
                                      final itemTotal = (item['price'] as double) * (item['quantity'] as int);

                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.02),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Thumbnail
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                item['image'] as String,
                                                width: 58,
                                                height: 58,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(
                                                  width: 58,
                                                  height: 58,
                                                  color: const Color(0xFFF1F5F9),
                                                  child: const Icon(Icons.fitness_center_rounded, size: 20),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            // Title & Variant
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title'] as String,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if ((item['variant'] as String).isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item['variant'] as String,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFF64748B),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '₹${itemTotal.toStringAsFixed(0)}',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: const Color(0xFF7C3AED),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Quantity Controls (- QTY +)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      HapticFeedback.selectionClick();
                                                      setCartState(() {
                                                        if ((item['quantity'] as int) > 1) {
                                                          item['quantity'] = (item['quantity'] as int) - 1;
                                                        } else {
                                                          _cartItems.removeAt(index);
                                                        }
                                                      });
                                                    },
                                                    icon: const Icon(Icons.remove_rounded, size: 14),
                                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  Text(
                                                    '${item['quantity']}',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      HapticFeedback.selectionClick();
                                                      setCartState(() {
                                                        item['quantity'] = (item['quantity'] as int) + 1;
                                                      });
                                                    },
                                                    icon: const Icon(Icons.add_rounded, size: 14),
                                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // 4. Promo Code Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: TextField(
                                      controller: _promoController,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                                      decoration: InputDecoration(
                                        hintText: 'Promo Code (e.g. NEURO10)',
                                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.only(top: 8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    final code = _promoController.text.trim().toUpperCase();
                                    if (code.isNotEmpty) {
                                      HapticFeedback.selectionClick();
                                      setCartState(() {
                                        _appliedDiscount = subtotal * 0.10;
                                        _appliedPromoCode = code;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Apply',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 5. Order Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Subtotal', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                                    Text('₹${subtotal.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                if (_appliedDiscount > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Discount ($_appliedPromoCode)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF16A34A))),
                                      Text('-₹${_appliedDiscount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Estimated Delivery', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                                    Text('FREE', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
                                  ],
                                ),
                                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Payable', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                                    Text('₹${finalTotal.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF7C3AED))),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 6. Checkout Now Button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _cartItems.isNotEmpty
                                    ? () {
                                        HapticFeedback.heavyImpact();
                                        Navigator.pop(context); // Close cart drawer
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CheckoutScreen(
                                              cartItems: _cartItems,
                                              initialDiscount: _appliedDiscount,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Checkout Now • ₹${finalTotal.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
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
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // WRITE / GIVE A REVIEW MODAL
  // -------------------------------------------------------------
  void _openGiveReviewModal() {
    double tempRating = 5.0;
    final TextEditingController commentCtrl = TextEditingController();
    final TextEditingController nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Write a Verified Review',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Share your athletic experience with $_activeTitle',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              // Star Rating Selector
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setModalState(() => tempRating = starNum.toDouble());
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          starNum <= tempRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 38,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 18),

              // Your Name Input
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g. Vikram Singh',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),

              // Comment Input
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  hintText: 'How is the performance, taste, mixability, and results?',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (commentCtrl.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _userReviews.insert(0, {
                        'name': nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Athlete User',
                        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                        'rating': tempRating,
                        'date': 'Just now',
                        'verified': true,
                        'comment': commentCtrl.text.trim(),
                      });
                      _activeReviewCount++;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you! Your verified review has been posted 🎉'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Submit Review',
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = _prodService.products;

    // 3 Carousel Products Sections:
    // 1. Similar / Frequently Bought Together
    final similarProducts = allProducts.where((p) => p.id != widget.product?.id).take(6).toList();
    // 2. Trending in Category
    final trendingProducts = allProducts.where((p) => p.categoryName == _activeCategory || p.category == _activeCategory).take(6).toList();
    // 3. Customers Also Viewed
    final alsoViewedProducts = allProducts.reversed.take(6).toList();

    final double discountPercent = _activeOldPrice != null && _activeOldPrice! > _activePrice
        ? (((_activeOldPrice! - _activePrice) / _activeOldPrice!) * 100)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopNavBar(),

            // Scrollable Product Detail Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 1. HERO SWIPEABLE MAIN IMAGE VIEWER (FINGER CAROUSEL)
                    _buildMainHeroImageViewer(),

                    const SizedBox(height: 12),

                    // 2. IMAGE THUMBNAIL GALLERY BELOW MAIN IMAGE
                    if (_allImages.length > 1) _buildThumbnailGalleryRow(),

                    const SizedBox(height: 18),

                    // 3. PRODUCT INFO & DETAILS CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & In Stock Badge Row (Without Ratings Badge)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _activeCategory.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6D28D9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _activeStock > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _activeStock > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _activeStock > 0 ? 'In Stock ($_activeStock)' : 'Out of Stock',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _activeStock > 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Product Title
                          Text(
                            _activeTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Price & Discount Savings Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '₹${_activePrice.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                              if (_activeOldPrice != null) ...[
                                const SizedBox(width: 10),
                                Text(
                                  '₹${_activeOldPrice!.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (discountPercent > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${discountPercent.toStringAsFixed(0)}% OFF',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 4. VARIANTS SELECTOR WITH IMAGES (FLAVORS / SIZES / EDITIONS)
                          if (_variants.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select Variant / Option',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  _variants[_selectedVariantIndex].name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 60,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _variants.length,
                                separatorBuilder: (c, i) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final v = _variants[index];
                                  final isSelected = _selectedVariantIndex == index;

                                  return GestureDetector(
                                    onTap: () => _selectVariant(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? const Color(0xFF0F172A).withValues(alpha: 0.15)
                                                : Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Variant Image Thumbnail
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              v.imageUrl.isNotEmpty ? v.imageUrl : _allImages.first,
                                              width: 38,
                                              height: 38,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(
                                                width: 38,
                                                height: 38,
                                                color: const Color(0xFFF1F5F9),
                                                child: const Icon(Icons.fitness_center_rounded, size: 18),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                v.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              if (v.price > 0)
                                                Text(
                                                  '₹${v.price.toStringAsFixed(0)}',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSelected ? const Color(0xFFCBD5E1) : const Color(0xFF7C3AED),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 5. PRODUCT DESCRIPTION
                          Text(
                            'Description',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _activeDescription,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                              height: 1.5,
                            ),
                            maxLines: _isDescriptionExpanded ? 100 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _isDescriptionExpanded ? 'Show Less' : 'Read More',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // 6. HIGHLIGHTS & SPECIFICATIONS
                          _buildHighlightsGrid(),

                          const SizedBox(height: 28),

                          // 7. VERIFIED REVIEWS SECTION (WITH "GIVE REVIEW" CTA)
                          _buildReviewsSection(),

                          const SizedBox(height: 28),

                          // 8. CAROUSEL SECTION 1: Frequently Bought Together
                          if (similarProducts.isNotEmpty)
                            _buildProductsCarouselSection(
                              title: 'Frequently Bought Together',
                              subtitle: 'Pairs well with this supplement',
                              products: similarProducts,
                            ),

                          const SizedBox(height: 24),

                          // 9. CAROUSEL SECTION 2: Trending in Category
                          if (trendingProducts.isNotEmpty)
                            _buildProductsCarouselSection(
                              title: 'Trending in $_activeCategory',
                              subtitle: 'Top rated in this category',
                              products: trendingProducts,
                            ),

                          const SizedBox(height: 24),

                          // 10. CAROUSEL SECTION 3: Customers Also Viewed
                          if (alsoViewedProducts.isNotEmpty)
                            _buildProductsCarouselSection(
                              title: 'Customers Also Viewed',
                              subtitle: 'Popular choices among athletes',
                              products: alsoViewedProducts,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 11. STICKY BOTTOM BAR (QUANTITY SELECTOR + ADD TO CART)
            _buildStickyBottomBar(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. MAIN HERO IMAGE VIEWER (SWIPEABLE FINGER CAROUSEL)
  // -------------------------------------------------------------
  Widget _buildMainHeroImageViewer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: [
          Container(
            height: 330,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedImageIndex = index),
              itemCount: _allImages.length,
              itemBuilder: (context, index) {
                return Image.network(
                  _allImages[index],
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Center(
                      child: Icon(Icons.fitness_center_rounded, color: Color(0xFF94A3B8), size: 48),
                    ),
                  ),
                );
              },
            ),
          ),

          // Image Counter Pill (Bottom Right)
          if (_allImages.length > 1)
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_selectedImageIndex + 1} / ${_allImages.length}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. IMAGE THUMBNAIL GALLERY BELOW MAIN IMAGE
  // -------------------------------------------------------------
  Widget _buildThumbnailGalleryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _allImages.length,
          separatorBuilder: (c, i) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isSelected = _selectedImageIndex == index;

            return GestureDetector(
              onTap: () => _selectImage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF0F172A).withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  _allImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.broken_image_rounded, size: 20, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. VERIFIED REVIEWS SECTION (WITH "GIVE REVIEW" CTA)
  // -------------------------------------------------------------
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Reviews',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_activeRating.toStringAsFixed(1)} based on $_activeReviewCount reviews',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: _openGiveReviewModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rate_review_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Give Review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Reviews List Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _userReviews.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final r = _userReviews[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(r['avatar'] as String),
                        backgroundColor: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  r['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (r['verified'] == true) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF10B981)),
                                ],
                              ],
                            ),
                            Text(
                              r['date'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(
                          (r['rating'] as double).toInt(),
                          (i) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r['comment'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // REUSABLE CAROUSEL PRODUCTS SECTION
  // -------------------------------------------------------------
  Widget _buildProductsCarouselSection({
    required String title,
    required String subtitle,
    required List<ProductItem> products,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (c, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = products[index];
              return SizedBox(
                width: 165,
                child: _buildRelatedProductCard(p),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(ProductItem p) {
    final imageUrl = p.images.isNotEmpty ? p.images.first : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600';
    final double price = p.salePrice > 0 ? p.salePrice : p.price;
    final double? oldPrice = p.regularPrice > price ? p.regularPrice : null;
    final rating = p.rating > 0 ? p.rating : 4.8;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: p),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: const Color(0xFFE2E8F0)),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 11),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
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
          Text(
            p.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              if (oldPrice != null) ...[
                const SizedBox(width: 5),
                Text(
                  '₹${oldPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
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
  // 6. HIGHLIGHTS & SPECIFICATIONS GRID
  // -------------------------------------------------------------
  Widget _buildHighlightsGrid() {
    final highlights = [
      {'icon': Icons.verified_rounded, 'title': '100% Authentic', 'sub': 'Lab Certified'},
      {'icon': Icons.local_shipping_rounded, 'title': 'Fast Delivery', 'sub': 'Dispatch in 24h'},
      {'icon': Icons.refresh_rounded, 'title': 'Easy Returns', 'sub': '7 Days Policy'},
      {'icon': Icons.security_rounded, 'title': 'Safe Checkout', 'sub': 'Direct Razorpay'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: highlights.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final h = highlights[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(h['icon'] as IconData, color: const Color(0xFF0F172A), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      h['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      h['sub'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
  // TOP NAV BAR
  // -------------------------------------------------------------
  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
            ),
          ),
          Text(
            'Product Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          GestureDetector(
            onTap: _toggleWishlist,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 11. STICKY BOTTOM BAR (QUANTITY SELECTOR + ADD TO CART)
  // -------------------------------------------------------------
  Widget _buildStickyBottomBar() {
    final totalPrice = _activePrice * _quantity;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity Selector Counter (- QTY +)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _quantity--);
                        }
                      : null,
                  icon: const Icon(Icons.remove_rounded, size: 18, color: Color(0xFF0F172A)),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                Text(
                  '$_quantity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: _quantity < _activeStock
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _quantity++);
                        }
                      : null,
                  icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF0F172A)),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Add to Cart Button with Dynamic Price Total
          Expanded(
            child: GestureDetector(
              onTap: _activeStock > 0 ? _addToCart : null,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _activeStock > 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (_activeStock > 0)
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _activeStock > 0 ? 'Add to Cart • ₹${totalPrice.toStringAsFixed(0)}' : 'Out of Stock',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
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
