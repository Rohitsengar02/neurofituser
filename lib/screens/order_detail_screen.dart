import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_backend_service.dart';
import '../services/orders_backend_service.dart';
import '../services/user_backend_service.dart';
import '../widgets/staggered_slide_fade.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> _currentOrder;
  bool _isCancelling = false;

  final List<String> _cancelReasons = [
    'Ordered by mistake',
    'Found a better price elsewhere',
    'Delivery time is taking too long',
    'Want to change delivery address or phone number',
    'Need to modify items or change flavor/variant',
    'Other reason',
  ];

  @override
  void initState() {
    super.initState();
    _currentOrder = Map<String, dynamic>.from(widget.order);
    _setupSocketListener();
  }

  @override
  void dispose() {
    final socket = UserBackendService.instance.socket;
    socket?.off('order:updated', _onRealtimeUpdate);
    socket?.off('order:user_updated', _onRealtimeUpdate);
    super.dispose();
  }

  void _setupSocketListener() {
    final socket = UserBackendService.instance.socket;
    socket?.on('order:updated', _onRealtimeUpdate);
    socket?.on('order:user_updated', _onRealtimeUpdate);
  }

  void _onRealtimeUpdate(dynamic data) {
    if (!mounted || data == null) return;
    try {
      final updatedData = Map<String, dynamic>.from(data as Map);
      final updatedId = updatedData['orderId'] ?? updatedData['id'] ?? updatedData['_id'];
      if (updatedId != null && updatedId.toString() == _orderId.toString()) {
        setState(() {
          _currentOrder = updatedData;
        });
      }
    } catch (_) {}
  }

  String get _orderId => _currentOrder['id'] ?? _currentOrder['orderId'] ?? 'NF-ORD';
  String get _orderStatus => _currentOrder['status'] ?? _currentOrder['orderStatus'] ?? 'Placed';
  String get _paymentMethod => _currentOrder['paymentMethod'] ?? 'UPI';
  String get _paymentStatus => _currentOrder['paymentStatus'] ?? 'Paid';
  String get _dateStr => _currentOrder['date'] ?? _currentOrder['createdAt'] ?? 'Recent';
  double get _totalAmount => (_currentOrder['totalAmount'] as num?)?.toDouble() ?? 0.0;
  String get _cancellationReason => _currentOrder['cancellationReason'] ?? '';

  List<Map<String, dynamic>> get _items {
    if (_currentOrder['itemList'] is List) {
      return (_currentOrder['itemList'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (_currentOrder['items'] is List) {
      return (_currentOrder['items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> get _shippingAddress {
    if (_currentOrder['shippingAddress'] is Map) {
      return Map<String, dynamic>.from(_currentOrder['shippingAddress']);
    }
    if (_currentOrder['address'] is Map) {
      return Map<String, dynamic>.from(_currentOrder['address']);
    }
    return {};
  }

  bool get _isCancellable {
    final s = _orderStatus.toLowerCase();
    return s == 'placed' || s == 'processing' || s == 'pending';
  }

  Color _getStatusColor() {
    switch (_orderStatus.toLowerCase()) {
      case 'placed':
        return const Color(0xFF6366F1);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'shipped':
        return const Color(0xFF0EA5E9);
      case 'out for delivery':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  // -------------------------------------------------------------
  // CANCEL ORDER WHITE BOTTOM SHEET MODAL
  // -------------------------------------------------------------
  void _openCancelOrderBottomSheet() {
    HapticFeedback.mediumImpact();
    String selectedReason = _cancelReasons.first;
    final otherReasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancel Order',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Order #$_orderId',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                'Please select a reason for cancelling this order:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),

              // Reason Radio Options
              ...List.generate(_cancelReasons.length, (index) {
                final reason = _cancelReasons[index];
                final isSelected = selectedReason == reason;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setModalState(() => selectedReason = reason);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF991B1B) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Other reason custom text field
              if (selectedReason == 'Other reason') ...[
                const SizedBox(height: 6),
                TextField(
                  controller: otherReasonCtrl,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Describe your reason...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Keep Order',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCancelling
                          ? null
                          : () async {
                              final finalReason = selectedReason == 'Other reason' &&
                                      otherReasonCtrl.text.trim().isNotEmpty
                                  ? otherReasonCtrl.text.trim()
                                  : selectedReason;

                              Navigator.pop(context);
                              _handleCancelOrder(finalReason);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCancelOrder(String reason) async {
    setState(() => _isCancelling = true);
    HapticFeedback.heavyImpact();

    final success = await OrdersBackendService.instance.cancelOrder(_orderId, reason);

    if (mounted) {
      setState(() {
        _isCancelling = false;
        if (success) {
          _currentOrder['status'] = 'Cancelled';
          _currentOrder['orderStatus'] = 'Cancelled';
          _currentOrder['cancellationReason'] = reason;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Order #$_orderId has been cancelled.',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StaggeredSlideFade(index: 0, child: _buildStatusBanner()),
                    const SizedBox(height: 16),
                    StaggeredSlideFade(index: 1, child: _buildTrackingStepper()),
                    const SizedBox(height: 16),
                    StaggeredSlideFade(index: 2, child: _buildItemsCard()),
                    const SizedBox(height: 16),
                    StaggeredSlideFade(index: 3, child: _buildDeliveryAddressCard()),
                    const SizedBox(height: 16),
                    StaggeredSlideFade(index: 4, child: _buildPaymentSummaryCard()),
                    const SizedBox(height: 24),
                    if (_isCancellable)
                      StaggeredSlideFade(index: 5, child: _buildCancelButton()),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP APP BAR
  // -------------------------------------------------------------
  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, _currentOrder);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'ID: #$_orderId',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _orderId));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ID #$_orderId copied! 📋'),
                  backgroundColor: const Color(0xFF0F172A),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: Color(0xFF64748B), size: 18),
            tooltip: 'Copy Order ID',
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. STATUS BANNER
  // -------------------------------------------------------------
  Widget _buildStatusBanner() {
    final isCancelled = _orderStatus.toLowerCase() == 'cancelled';
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCancelled
                  ? Icons.cancel_rounded
                  : _orderStatus.toLowerCase() == 'delivered'
                      ? Icons.check_circle_rounded
                      : Icons.local_shipping_rounded,
              color: statusColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order $_orderStatus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _orderStatus.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isCancelled
                      ? (_cancellationReason.isNotEmpty
                          ? 'Reason: $_cancellationReason'
                          : 'This order was cancelled by athlete request.')
                      : 'Placed on $_dateStr',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isCancelled ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                    fontWeight: isCancelled ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. TRACKING STEPPER
  // -------------------------------------------------------------
  Widget _buildTrackingStepper() {
    final isCancelled = _orderStatus.toLowerCase() == 'cancelled';
    if (isCancelled) return const SizedBox.shrink();

    final steps = ['Placed', 'Processing', 'Shipped', 'Delivered'];
    final currentIdx = steps.indexWhere((s) => s.toLowerCase() == _orderStatus.toLowerCase());
    final activeStep = currentIdx != -1 ? currentIdx : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Tracking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Line
                final stepNum = index ~/ 2;
                final isDone = stepNum < activeStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  ),
                );
              } else {
                // Node
                final stepNum = index ~/ 2;
                final isDone = stepNum <= activeStep;
                final isCurrent = stepNum == activeStep;

                return Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF10B981) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                            : Text(
                                '${stepNum + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[stepNum],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. ORDERED ITEMS CARD
  // -------------------------------------------------------------
  Widget _buildItemsCard() {
    final items = _items;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items in Order',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${items.length} ${items.length == 1 ? 'Item' : 'Items'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _currentOrder['title'] ?? 'NeuroFit Performance Supplement',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final title = item['title'] ?? 'Item';
              final variant = item['variant'] ?? '';
              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final image = item['image'] ?? item['imageUrl'] ?? '';
              final itemTotal = price * qty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        CategoryBackendService.getDisplayableImageUrl(image),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 52,
                          height: 52,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF94A3B8), size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (variant.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              variant,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            'Qty: $qty × ₹${price.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${itemTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. DELIVERY ADDRESS CARD
  // -------------------------------------------------------------
  Widget _buildDeliveryAddressCard() {
    final addr = _shippingAddress;
    final name = addr['fullName'] ?? addr['name'] ?? 'Athlete';
    final phone = addr['phoneNumber'] ?? addr['phone'] ?? '';
    final street = addr['streetAddress'] ?? '${addr['flat'] ?? ''} ${addr['building'] ?? ''} ${addr['area'] ?? ''}'.trim();
    final city = addr['city'] ?? '';
    final state = addr['state'] ?? '';
    final pin = addr['pincode'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 6),
              Text(
                'Delivery Address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$name • $phone',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            [street, city, state, pin].where((s) => s.isNotEmpty).join(', '),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. PAYMENT SUMMARY CARD
  // -------------------------------------------------------------
  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment & Bill Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildRow('Item Total', '₹${_totalAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildRow('Delivery Fee', 'FREE', valueColor: const Color(0xFF16A34A)),
          const SizedBox(height: 6),
          _buildRow('Payment Mode', '$_paymentMethod ($_paymentStatus)'),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 7. CANCEL ORDER BUTTON
  // -------------------------------------------------------------
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isCancelling ? null : _openCancelOrderBottomSheet,
        icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
        label: Text(
          'Cancel Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFEF4444),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFFEF2F2),
        ),
      ),
    );
  }
}
