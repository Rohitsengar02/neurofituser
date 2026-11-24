import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_backend_service.dart';
import '../services/discounts_backend_service.dart';
import '../services/orders_backend_service.dart';
import '../services/user_backend_service.dart';
import '../widgets/skeleton_loader.dart';
import 'address_management_screen.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double initialDiscount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    this.initialDiscount = 0.0,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _items;
  double _discount = 0.0;
  bool _isProcessingOrder = false;
  final TextEditingController _promoController = TextEditingController();
  DiscountItem? _appliedDiscountModel;

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems.map((e) => Map<String, dynamic>.from(e)));
    _discount = widget.initialDiscount;

    if (_items.isEmpty) {
      _items.add({
        'id': 'prod_1',
        'title': 'Gold Standard 100% Whey Isolate',
        'variant': 'Double Rich Chocolate • 2kg',
        'price': 3499.0,
        'quantity': 1,
        'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
      });
    }

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    DiscountsBackendService.instance.fetchDiscounts();

    final user = UserBackendService.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      OrdersBackendService.instance.fetchUserAddress(user.uid);
    }
  }

  void _applyCoupon(DiscountItem item) {
    if (_subtotal < item.minOrderValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum order value for ${item.code} is ₹${item.minOrderValue.toInt()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final calculated = item.calculateDiscount(_subtotal);
    setState(() {
      _appliedDiscountModel = item;
      _discount = calculated;
      _promoController.text = item.code;
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon "${item.code}" applied! Saved ₹${calculated.toInt()} 🎉'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedDiscountModel = null;
      _discount = 0.0;
      _promoController.clear();
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _applyCustomPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final result = await DiscountsBackendService.instance.validateCoupon(code, _subtotal);
    if (result != null && result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'].toString()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (result != null) {
      final type = result['type'] ?? 'percentage';
      final val = (result['value'] as num?)?.toDouble() ?? 0.0;
      double calc = 0.0;
      if (type == 'percentage') {
        calc = (_subtotal * (val / 100.0)).clamp(0.0, _subtotal);
      } else {
        calc = val.clamp(0.0, _subtotal);
      }

      setState(() {
        _discount = calc;
        _appliedDiscountModel = DiscountItem(
          discountId: result['discountId'] ?? 'custom',
          title: result['title'] ?? code,
          code: code.toUpperCase(),
          type: type,
          value: val,
        );
      });

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coupon "$code" applied successfully! Saved ₹${calc.toInt()} 🎉'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double total = 0;
    for (final item in _items) {
      total += ((item['price'] as num?)?.toDouble() ?? 0.0) * ((item['quantity'] as num?)?.toInt() ?? 1);
    }
    return total;
  }

  double get _totalPayable => (_subtotal - _discount).clamp(0.0, double.infinity);

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

        final blurVal = ((1 - anim) * 8.0).clamp(0.0, 8.0);
        final slideY = (20.0 * (1 - anim));

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

  void _openAddressManagementScreen() async {
    HapticFeedback.mediumImpact();
    final AddressModel? selected = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressManagementScreen(
          currentSelectedId: OrdersBackendService.instance.savedAddress?['id']?.toString() ?? '',
        ),
      ),
    );

    if (selected != null && mounted) {
      OrdersBackendService.instance.savedAddress = selected.toMap();
      setState(() {});
    }
  }

  void _updateQuantity(int index, int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      final currentQty = (_items[index]['quantity'] as num?)?.toInt() ?? 1;
      final newQty = currentQty + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index]['quantity'] = newQty;
      }
    });
  }

  void _proceedToOrderPlacement(String paymentMethod) async {
    final user = UserBackendService.instance.currentUser;
    final address = OrdersBackendService.instance.savedAddress;

    if (user == null || user.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your checkout cart is empty!')),
      );
      return;
    }

    if (address == null || (address['streetAddress'] as String? ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address first! 📍'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      _openAddressManagementScreen();
      return;
    }

    setState(() => _isProcessingOrder = true);

    final orderId = 'NF-ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final success = await OrdersBackendService.instance.placeOrder(
      orderId: orderId,
      uid: user.uid,
      userEmail: user.email,
      shippingAddress: address,
      items: _items,
      subtotal: _subtotal,
      totalAmount: _totalPayable,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'Cash on Delivery' ? 'Pending' : 'Paid',
    );

    if (!mounted) return;
    setState(() => _isProcessingOrder = false);

    if (success) {
      _showOrderSuccessModal(orderId, paymentMethod);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  void _showOrderSuccessModal(String orderId, String paymentMethod) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Order Placed Successfully! 🎉',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Thank you for your purchase! We are preparing your order.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order ID', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12)),
                        Text(orderId, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Method', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12)),
                        Text(paymentMethod, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF22C55E), fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12)),
                        Text('₹${_totalPayable.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'View My Orders 📦',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: _isProcessingOrder
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF16A34A)),
                  const SizedBox(height: 18),
                  Text(
                    'Processing your order...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please wait while we confirm your purchase',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. DELIVERY ADDRESS CARD (REAL MONGODB DATA)
                        _buildStaggeredSection(
                          startInterval: 0.0,
                          endInterval: 0.30,
                          child: AnimatedBuilder(
                            animation: OrdersBackendService.instance,
                            builder: (context, _) {
                              if (OrdersBackendService.instance.isLoadingAddress &&
                                  OrdersBackendService.instance.savedAddress == null) {
                                return const ShimmerEffect(child: SkeletonAddressCard());
                              }
                              final address = OrdersBackendService.instance.savedAddress;
                              return _buildDeliveryAddressCard(address);
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 2. BEAUTIFUL PRODUCTS IN CART LIST (WITH QUANTITY CONTROLS)
                        _buildStaggeredSection(
                          startInterval: 0.20,
                          endInterval: 0.50,
                          child: _buildBeautifulProductsList(),
                        ),

                        const SizedBox(height: 16),

                        // 3. DISCOUNTS & OFFERS SLIDER
                        _buildStaggeredSection(
                          startInterval: 0.35,
                          endInterval: 0.65,
                          child: _buildDiscountsSection(),
                        ),

                        const SizedBox(height: 16),

                        // 4. BILLING SUMMARY CARD
                        _buildStaggeredSection(
                          startInterval: 0.50,
                          endInterval: 0.85,
                          child: _buildBillDetailsCard(),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 4. BOTTOM ACTION PAYMENT BAR
                _buildStaggeredSection(
                  startInterval: 0.60,
                  endInterval: 1.0,
                  child: _buildBottomPaymentBar(),
                ),
              ],
            ),
    );
  }

  // -------------------------------------------------------------
  // 1. DELIVERY ADDRESS CARD
  // -------------------------------------------------------------
  Widget _buildDeliveryAddressCard(Map<String, dynamic>? address) {
    final bool hasAddress = address != null && (address['streetAddress'] as String? ?? '').isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAddress ? const Color(0xFF22C55E).withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: hasAddress ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Delivery Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _openAddressManagementScreen(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasAddress ? 'Change' : '+ Add Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasAddress) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (address['tag'] as String? ?? 'HOME').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
                if (address['latitude'] != null && address['longitude'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location_rounded, size: 10, color: Color(0xFF16A34A)),
                        const SizedBox(width: 3),
                        Text(
                          'GPS Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${address['fullName'] ?? address['name'] ?? 'Athlete'} • ${address['phoneNumber'] ?? address['phone'] ?? ''}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              (address['streetAddress'] as String? ?? '').isNotEmpty
                  ? address['streetAddress']
                  : '${address['flat'] ?? ''}, ${address['building'] ?? ''}, ${address['area'] ?? ''}, ${address['city'] ?? ''} - ${address['pincode'] ?? ''}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No delivery address added. Please add your address to proceed.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. BEAUTIFUL PRODUCTS LIST WITH QUANTITY CONTROLS (- / +)
  // -------------------------------------------------------------
  Widget _buildBeautifulProductsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
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
                'Order Items (${_items.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Editable Quantities',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Cart is empty',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = _items[index];
                final double unitPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
                final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                final double lineTotal = unitPrice * quantity;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Image
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        image: DecorationImage(
                          image: NetworkImage(
                            CategoryBackendService.getDisplayableImageUrl(
                              (item['image'] as String? ?? '').isNotEmpty
                                  ? item['image']
                                  : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
                            ),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Price Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? 'Item',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((item['variant'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item['variant'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '₹${lineTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Interactive Quantity Stepper (- 1 +)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _updateQuantity(index, -1),
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              child: Icon(
                                quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                size: 16,
                                color: quantity == 1 ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$quantity',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _updateQuantity(index, 1),
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DISCOUNTS & OFFERS SECTION
  // -------------------------------------------------------------
  Widget _buildDiscountsSection() {
    return AnimatedBuilder(
      animation: DiscountsBackendService.instance,
      builder: (context, _) {
        final service = DiscountsBackendService.instance;
        final discounts = service.discounts;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 12,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_offer_rounded, color: Color(0xFFD97706), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offers & Coupons',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (discounts.isNotEmpty)
                    GestureDetector(
                      onTap: _showAllCouponsBottomSheet,
                      child: Text(
                        'View All (${discounts.length}) →',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_appliedDiscountModel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coupon "${_appliedDiscountModel!.code}" Applied!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            Text(
                              'You saved ₹${_discount.toInt()} on this order',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: const Color(0xFF166534),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _removeCoupon,
                        child: Text(
                          'REMOVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Promo Code Input Box
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter Promo Code (e.g. NEURO10)',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyCustomPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                if (discounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // Horizontal Slider Cards for Available Discounts
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: discounts.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final disc = discounts[index];
                        final isEligible = _subtotal >= disc.minOrderValue;
                        final discountText = disc.type == 'percentage'
                            ? '${disc.value.toInt()}% OFF'
                            : '₹${disc.value.toInt()} OFF';

                        return Container(
                          width: 170,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isEligible ? const Color(0xFF22C55E) : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      disc.code,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF4ADE80),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    discountText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      disc.minOrderValue > 0
                                          ? 'Min ₹${disc.minOrderValue.toInt()}'
                                          : 'No Min Spend',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _applyCoupon(disc),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'APPLY',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAllCouponsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final discounts = DiscountsBackendService.instance.discounts;

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Coupons & Offers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: discounts.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final disc = discounts[index];
                    final isEligible = _subtotal >= disc.minOrderValue;
                    final discountText = disc.type == 'percentage'
                        ? '${disc.value.toInt()}% OFF'
                        : '₹${disc.value.toInt()} OFF';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEligible ? const Color(0xFF22C55E).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.discount_rounded, color: Color(0xFF16A34A), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      disc.code,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        discountText,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  disc.title.isNotEmpty ? disc.title : 'Use code ${disc.code} to save on your order',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                if (disc.minOrderValue > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Min. order amount: ₹${disc.minOrderValue.toInt()}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isEligible ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _applyCoupon(disc);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEligible ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: Text(
                              'APPLY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 3. BILLING DETAILS CARD
  // -------------------------------------------------------------
  Widget _buildBillDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildBillRow('Item Subtotal', '₹${_subtotal.toStringAsFixed(0)}'),
          if (_discount > 0)
            _buildBillRow('Discount Savings', '-₹${_discount.toStringAsFixed(0)}', isGreen: true),
          _buildBillRow('Delivery Fee', 'FREE', isGreen: true),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildBillRow('To Pay', '₹${_totalPayable.toStringAsFixed(0)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isGreen = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isBold ? 14 : 12.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: isGreen
                  ? const Color(0xFF16A34A)
                  : (isBold ? const Color(0xFF0F172A) : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. BOTTOM PAYMENT BAR
  // -------------------------------------------------------------
  Widget _buildBottomPaymentBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Payable',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                '₹${_totalPayable.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => _openPaymentOptionsModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: Text(
                  'Select Payment & Pay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPaymentOptionsModal() {
    final address = OrdersBackendService.instance.savedAddress;
    if (address == null || (address['streetAddress'] as String? ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address before selecting payment! 📍'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      _openAddressManagementScreen();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Payment Method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOptionTile(
                icon: Icons.qr_code_2_rounded,
                title: 'UPI (GPay / PhonePe / Paytm)',
                subtitle: 'Instant & Secure Payment',
                onTap: () {
                  Navigator.pop(ctx);
                  _proceedToOrderPlacement('UPI');
                },
              ),
              const SizedBox(height: 10),
              _buildPaymentOptionTile(
                icon: Icons.local_shipping_rounded,
                title: 'Cash on Delivery (COD)',
                subtitle: 'Pay cash upon delivery at doorstep',
                onTap: () {
                  Navigator.pop(ctx);
                  _proceedToOrderPlacement('Cash on Delivery');
                },
              ),
              const SizedBox(height: 10),
              _buildPaymentOptionTile(
                icon: Icons.credit_card_rounded,
                title: 'Credit / Debit Card',
                subtitle: 'Visa, Mastercard, RuPay',
                onTap: () {
                  Navigator.pop(ctx);
                  _proceedToOrderPlacement('Credit/Debit Card');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF16A34A), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
          ],
        ),
      ),
    );
  }
}
