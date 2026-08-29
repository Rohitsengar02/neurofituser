import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';

class VendorDashboardScreen extends StatefulWidget {
  final String storeName;
  final String category;

  const VendorDashboardScreen({
    super.key,
    this.storeName = 'FitFuel Nutrition',
    this.category = 'Supplements & Nutrition',
  });

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> with TickerProviderStateMixin {
  int _selectedBottomNavIndex = 0; // 0: Dashboard, 1: Orders, 2: Products, 3: Earnings, 4: More
  int _selectedSectionTabIndex = 0; // 0: Top Products, 1: Recent Orders

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Body Content based on Vendor Bottom Nav
            Expanded(
              child: IndexedStack(
                index: _selectedBottomNavIndex,
                children: [
                  _buildDashboardTabContent(),
                  _buildOrdersTabContent(),
                  _buildProductsTabContent(),
                  _buildEarningsTabContent(),
                  _buildMoreTabContent(),
                ],
              ),
            ),

            // Custom Vendor Bottom Bar (Only on Vendor Screens)
            _buildCustomVendorBottomBar(),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // 1. MAIN VENDOR DASHBOARD TAB CONTENT (RESPONSIVE & OVERFLOW-FREE)
  // =============================================================
  Widget _buildDashboardTabContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 1. Top Header Bar
          StaggeredSlideFade(index: 0, child: _buildTopHeaderBar()),

          const SizedBox(height: 16),

          // 2. Today's Overview Dark Bento Carousel Card
          StaggeredSlideFade(index: 1, child: _buildTodaysOverviewDarkCard()),

          const SizedBox(height: 16),

          // 3. Sales Overview Card with Spline Chart
          StaggeredSlideFade(index: 2, child: _buildSalesOverviewCard()),

          const SizedBox(height: 18),

          // 4. Order Status Responsive Horizontal Carousel
          StaggeredSlideFade(index: 3, child: _buildOrderStatusSection()),

          const SizedBox(height: 18),

          // 5. Responsive Dual-Card Section (Top Products & Recent Orders)
          StaggeredSlideFade(index: 4, child: _buildProductsAndOrdersSection()),

          const SizedBox(height: 18),

          // 6. "Grow Your Business 🚀" Promo Banner
          StaggeredSlideFade(index: 5, child: _buildGrowYourBusinessBanner()),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER BAR
  // -------------------------------------------------------------
  Widget _buildTopHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Hamburger Menu Icon / Back Button
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
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF0F172A),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Welcome Back & Store Name with Verified Vendor Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, 👋',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        widget.storeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 11),
                        const SizedBox(width: 3),
                        Text(
                          'Verified Vendor',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right Notification Bell & Avatar
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '8',
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
              const SizedBox(width: 8),

              // Store Avatar with Dropdown Arrow
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF141518),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/vendor_store_3d.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white),
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
  // 2. TODAY'S OVERVIEW DARK BENTO CAROUSEL CARD
  // -------------------------------------------------------------
  Widget _buildTodaysOverviewDarkCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF18191D), // Deep Charcoal Dark
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Today's Overview & Filter Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Overview",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '27 May 2025',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),

                // Filter Pill Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23242A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4-Column Horizontal Metric Carousel
            SizedBox(
              height: 105,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDarkOverviewCard(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: const Color(0xFF22C55E),
                    label: 'Total Orders',
                    value: '48',
                    comparison: '↑ 12% vs yesterday',
                    isPositive: true,
                  ),
                  const SizedBox(width: 10),
                  _buildDarkOverviewCard(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFF22C55E),
                    label: 'Total Sales',
                    value: '₹24,680',
                    comparison: '↑ 18% vs yesterday',
                    isPositive: true,
                  ),
                  const SizedBox(width: 10),
                  _buildDarkOverviewCard(
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    label: 'Total Customers',
                    value: '136',
                    comparison: '↑ 8% vs yesterday',
                    isPositive: true,
                  ),
                  const SizedBox(width: 10),
                  _buildDarkOverviewCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Pending Orders',
                    value: '7',
                    comparison: 'View all >',
                    isLink: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkOverviewCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String comparison,
    bool isPositive = true,
    bool isLink = false,
  }) {
    return Container(
      width: 136,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF23242A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFCBD5E1),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            comparison,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: isLink ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SALES OVERVIEW CARD WITH SPLINE CHART
  // -------------------------------------------------------------
  Widget _buildSalesOverviewCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Overview',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'This Week',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Revenue and Growth + Line Graph
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹1,24,680',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Total Sales',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '↑ 16.5%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Interactive Spline Chart
                Expanded(
                  child: SizedBox(
                    height: 85,
                    child: CustomPaint(
                      painter: _SalesChartPainter(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Day Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDayLabel('Mon'),
                _buildDayLabel('Tue'),
                _buildDayLabel('Wed', isActive: true),
                _buildDayLabel('Thu'),
                _buildDayLabel('Fri'),
                _buildDayLabel('Sat'),
                _buildDayLabel('Sun'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayLabel(String day, {bool isActive = false}) {
    return Text(
      day,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
        color: isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. ORDER STATUS RESPONSIVE HORIZONTAL CAROUSEL (NO OVERFLOW)
  // -------------------------------------------------------------
  Widget _buildOrderStatusSection() {
    final statuses = [
      {'label': 'Pending', 'count': '7', 'icon': Icons.shopping_bag_outlined, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
      {'label': 'Confirmed', 'count': '15', 'icon': Icons.assignment_turned_in_outlined, 'color': Color(0xFF2563EB), 'bg': Color(0xFFEFF6FF)},
      {'label': 'Shipped', 'count': '18', 'icon': Icons.local_shipping_outlined, 'color': Color(0xFF7C3AED), 'bg': Color(0xFFF5F3FF)},
      {'label': 'Delivered', 'count': '8', 'icon': Icons.check_circle_outline_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFF0FDF4)},
      {'label': 'Cancelled', 'count': '2', 'icon': Icons.cancel_outlined, 'color': Color(0xFFDC2626), 'bg': Color(0xFFFEF2F2)},
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
                'Order Status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Responsive Horizontal Scroll Carousel (Zero Overflow on Any Screen Size)
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: statuses.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final s = statuses[index];
              return Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                decoration: BoxDecoration(
                  color: s['bg'] as Color,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: (s['color'] as Color).withValues(alpha: 0.22), width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s['icon'] as IconData, size: 16, color: s['color'] as Color),
                    const SizedBox(height: 4),
                    Text(
                      s['count'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      s['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. RESPONSIVE SECTION: TOP PRODUCTS & RECENT ORDERS (CAROUSEL & TABS)
  // -------------------------------------------------------------
  Widget _buildProductsAndOrdersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Elegant Segmented Switcher for Mobile
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSectionTabIndex = 0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedSectionTabIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedSectionTabIndex == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: _selectedSectionTabIndex == 0 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Top Products',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: _selectedSectionTabIndex == 0 ? FontWeight.w900 : FontWeight.w600,
                              color: _selectedSectionTabIndex == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSectionTabIndex = 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedSectionTabIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedSectionTabIndex == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 15,
                            color: _selectedSectionTabIndex == 1 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Recent Orders',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: _selectedSectionTabIndex == 1 ? FontWeight.w900 : FontWeight.w600,
                              color: _selectedSectionTabIndex == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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
          const SizedBox(height: 12),

          // Animated Switcher between Full Width Top Products & Recent Orders (Zero Overflow!)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedSectionTabIndex == 0
                ? _buildFullWidthTopProductsCard(key: const ValueKey('top_products_card'))
                : _buildFullWidthRecentOrdersCard(key: const ValueKey('recent_orders_card')),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthTopProductsCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                'Top Selling Products',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildTopProductItem(1, 'Whey Protein', 'Chocolate Flavor • 2kg Tub', '125+ Sold', '₹2,399', 'assets/images/nutrifit_whey_protein.jpg'),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildTopProductItem(2, 'Creatine Monohydrate', 'Unflavoured • 250g Pouch', '98+ Sold', '₹999', 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=200&auto=format&fit=crop&q=80'),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildTopProductItem(3, 'BCAA 2:1:1 Energy', 'Watermelon Blast • 300g', '76+ Sold', '₹1,499', 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=200&auto=format&fit=crop&q=80'),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(int rank, String title, String subtitle, String sold, String price, String img) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: img.startsWith('assets')
              ? Image.asset(img, width: 44, height: 44, fit: BoxFit.cover)
              : Image.network(img, width: 44, height: 44, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sold,
                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullWidthRecentOrdersCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                'Recent Orders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildRecentOrderRow('#ORD24567', 'Rohit Verma', '10 mins ago', '₹2,199', 'Pending', const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildRecentOrderRow('#ORD24566', 'Aman Singh', '35 mins ago', '₹1,899', 'Confirmed', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildRecentOrderRow('#ORD24565', 'Neha Sharma', '1 hr ago', '₹2,499', 'Shipped', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildRecentOrderRow('#ORD24564', 'Vikram Patel', '2 hrs ago', '₹1,499', 'Delivered', const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
        ],
      ),
    );
  }

  Widget _buildRecentOrderRow(String id, String customer, String time, String price, String status, Color statusColor, Color statusBg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined, size: 16, color: statusColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                Text(
                  '$customer • $time',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: statusColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 6. "GROW YOUR BUSINESS 🚀" PROMO BANNER
  // -------------------------------------------------------------
  Widget _buildGrowYourBusinessBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF16A34A), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grow Your Business 🚀',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'List more products and run offers to increase your sales and reach.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Offer creation wizard launched!')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Create Offer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // 7. CUSTOM VENDOR BOTTOM BAR (ONLY ON VENDOR PANEL)
  // =============================================================
  Widget _buildCustomVendorBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVendorNavItem(0, Icons.home_rounded, 'Dashboard'),
          _buildVendorNavItem(1, Icons.shopping_bag_outlined, 'Orders'),
          _buildVendorNavItem(2, Icons.inventory_2_outlined, 'Products'),
          _buildVendorNavItem(3, Icons.currency_rupee_rounded, 'Earnings'),
          _buildVendorNavItem(4, Icons.grid_view_rounded, 'More'),
        ],
      ),
    );
  }

  Widget _buildVendorNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedBottomNavIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedBottomNavIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // OTHER TABS (ORDERS, PRODUCTS, EARNINGS, MORE)
  // -------------------------------------------------------------
  Widget _buildOrdersTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          Text(
            'Order Management Pipeline',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '48 Active Orders • 7 Pending Dispatch',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF2563EB)),
          const SizedBox(height: 12),
          Text(
            'Store Catalog & Stock Inventory',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '24 Active Products Listed',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.currency_rupee_rounded, size: 48, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          Text(
            'Settlement & Payouts',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Available Wallet Balance: ₹1,24,680',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFF0F172A)),
          const SizedBox(height: 12),
          Text(
            'Vendor Store Settings',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Store profile, logistics, bank details & support',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// CUSTOM PAINTER FOR SALES OVERVIEW SPLINE CHART
// -------------------------------------------------------------
class _SalesChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF16A34A).withValues(alpha: 0.25),
          const Color(0xFF16A34A).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final points = [
      Offset(0, size.height * 0.70),
      Offset(size.width * 0.18, size.height * 0.45),
      Offset(size.width * 0.36, size.height * 0.60),
      Offset(size.width * 0.54, size.height * 0.65),
      Offset(size.width * 0.72, size.height * 0.35),
      Offset(size.width * 0.88, size.height * 0.40),
      Offset(size.width, size.height * 0.20),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    final fillPath = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Draw dots on each point
    final dotPaint = Paint()..color = const Color(0xFF16A34A)..style = PaintingStyle.fill;
    final dotStroke = Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(p, 3.5, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
