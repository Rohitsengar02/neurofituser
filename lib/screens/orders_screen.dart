import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_backend_service.dart';
import '../services/orders_backend_service.dart';
import '../services/user_backend_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/staggered_slide_fade.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  int _badgeIconIndex = 0;
  Timer? _badgeIconTimer;
  int _selectedFilterIndex = 0;

  final List<IconData> _badgeIcons = [
    Icons.local_shipping_rounded,
    Icons.inventory_2_rounded,
    Icons.check_circle_rounded,
    Icons.shopping_bag_rounded,
  ];

  final List<String> _filters = [
    'All Orders',
    'Placed 📦',
    'Processing ⚙️',
    'Shipped 🚚',
    'Delivered ✅',
    'Cancelled ❌',
  ];

  @override
  void initState() {
    super.initState();
    _badgeIconTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _badgeIconIndex = (_badgeIconIndex + 1) % _badgeIcons.length;
        });
      }
    });

    _loadUserOrders();
    _setupRealtimeOrderListener();
  }

  void _loadUserOrders() {
    final user = UserBackendService.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      OrdersBackendService.instance.fetchUserOrders(user.uid);
    }
  }

  void _setupRealtimeOrderListener() {
    final socket = UserBackendService.instance.socket;
    if (socket != null) {
      socket.on('order:created', _onRealtimeOrderEvent);
      socket.on('order:user_created', _onRealtimeOrderEvent);
      socket.on('order:updated', _onRealtimeOrderEvent);
      socket.on('order:user_updated', _onRealtimeOrderEvent);
    }
  }

  void _onRealtimeOrderEvent(dynamic data) {
    debugPrint('⚡ Real-time order event received in OrdersScreen: $data');
    if (mounted) {
      _loadUserOrders();
    }
  }

  @override
  void dispose() {
    _badgeIconTimer?.cancel();
    final socket = UserBackendService.instance.socket;
    socket?.off('order:created', _onRealtimeOrderEvent);
    socket?.off('order:user_created', _onRealtimeOrderEvent);
    socket?.off('order:updated', _onRealtimeOrderEvent);
    socket?.off('order:user_updated', _onRealtimeOrderEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: OrdersBackendService.instance,
          builder: (context, _) {
            final ordersService = OrdersBackendService.instance;
            final userOrders = ordersService.userOrders;
            final isLoading = ordersService.isLoadingOrders;

            // 1. Sort all recent orders on top
            final sortedOrders = List<Map<String, dynamic>>.from(userOrders);
            sortedOrders.sort((a, b) {
              final dateA = a['createdAt'] ?? a['date'] ?? '';
              final dateB = b['createdAt'] ?? b['date'] ?? '';
              return dateB.toString().compareTo(dateA.toString());
            });

            // 2. Client-side local instant filter (0ms, no API request)
            List<Map<String, dynamic>> displayedOrders = sortedOrders;
            if (_selectedFilterIndex != 0) {
              final activeFilter = _filters[_selectedFilterIndex].toLowerCase();
              displayedOrders = sortedOrders.where((order) {
                final status = (order['status'] ?? order['orderStatus'] ?? '').toString().toLowerCase();
                if (activeFilter.contains('placed')) return status == 'placed';
                if (activeFilter.contains('processing')) return status == 'processing';
                if (activeFilter.contains('shipped')) return status == 'shipped' || status == 'out for delivery';
                if (activeFilter.contains('delivered')) return status == 'delivered';
                if (activeFilter.contains('cancelled')) return status == 'cancelled';
                return true;
              }).toList();
            }

            return RefreshIndicator(
              color: const Color(0xFF16A34A),
              backgroundColor: Colors.white,
              onRefresh: () async {
                final user = UserBackendService.instance.currentUser;
                if (user != null && user.uid.isNotEmpty) {
                  await OrdersBackendService.instance.fetchUserOrders(user.uid);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    StaggeredSlideFade(index: 0, child: _buildHeader()),
                    const SizedBox(height: 18),
                    StaggeredSlideFade(index: 1, child: _buildFilterChips(sortedOrders)),
                    const SizedBox(height: 16),

                    if (isLoading && userOrders.isEmpty)
                      const SkeletonOrdersList(count: 3)
                    else if (displayedOrders.isEmpty)
                      _buildEmptyOrdersState()
                    else
                      ...List.generate(displayedOrders.length, (index) {
                        final order = displayedOrders[index];
                        return StaggeredSlideFade(
                          index: index + 2,
                          child: _buildOrderCard(order),
                        );
                      }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'My Orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_badgeIcons[_badgeIconIndex], color: const Color(0xFF16A34A), size: 14),
                    ),
                  ],
                ),
                Text(
                  'Track and manage your orders',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<Map<String, dynamic>> allOrders) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;

          // Count per filter locally
          int count = allOrders.length;
          if (index != 0) {
            final filter = _filters[index].toLowerCase();
            count = allOrders.where((o) {
              final st = (o['status'] ?? o['orderStatus'] ?? '').toString().toLowerCase();
              if (filter.contains('placed')) return st == 'placed';
              if (filter.contains('processing')) return st == 'processing';
              if (filter.contains('shipped')) return st == 'shipped' || st == 'out for delivery';
              if (filter.contains('delivered')) return st == 'delivered';
              if (filter.contains('cancelled')) return st == 'cancelled';
              return false;
            }).length;
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilterIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _filters[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    final filterName = _filters[_selectedFilterIndex];
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilterIndex == 0 ? 'No Orders Placed Yet' : 'No $filterName Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedFilterIndex == 0
                  ? 'Your orders will appear here in real-time.'
                  : 'Try selecting a different filter tab.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] ?? order['orderId'] ?? 'NF-ORD';
    final date = order['date'] ?? 'Recent';
    final status = order['status'] ?? order['orderStatus'] ?? 'Placed';
    final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final title = order['title'] ?? 'Order Item';
    final image = order['image'] ?? 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400';

    Color statusBgColor = const Color(0xFFEDE9FE);
    Color statusTextColor = const Color(0xFF6366F1);

    switch (status.toLowerCase()) {
      case 'placed':
        statusBgColor = const Color(0xFFEEF2FF);
        statusTextColor = const Color(0xFF4F46E5);
        break;
      case 'processing':
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFD97706);
        break;
      case 'shipped':
      case 'out for delivery':
        statusBgColor = const Color(0xFFE0F2FE);
        statusTextColor = const Color(0xFF0284C7);
        break;
      case 'delivered':
        statusBgColor = const Color(0xFFDCFCE7);
        statusTextColor = const Color(0xFF16A34A);
        break;
      case 'cancelled':
        statusBgColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFDC2626);
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
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
                Expanded(
                  child: Text(
                    'Order #$orderId',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    CategoryBackendService.getDisplayableImageUrl(
                      image.isNotEmpty ? image : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
                    ),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order['items'] ?? 1} item(s) • Tap to view details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
