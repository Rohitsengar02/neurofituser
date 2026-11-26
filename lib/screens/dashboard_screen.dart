import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/side_island.dart';
import '../widgets/ticker_gate.dart';
import '../home/home_tabs.dart';
import '../home/overview/overview_home_cards.dart';
import '../widgets/ios_header.dart';
import '../widgets/smooth_scroll.dart';
import '../widgets/category_tab_bar.dart';
import '../widgets/custom_floating_bottom_bar.dart';
import 'steps_screen.dart';
import 'kemo_ai_screen.dart';
import 'water_screen.dart';
import '../services/widget_sync.dart';
import '../trainer/trainer_data.dart';
import '../trainer/trainer_hub.dart';
import '../trainer/trainers_page.dart';
import '../trainer/panel_data.dart';
import '../trainer/panel_onboarding.dart';
import '../trainer/trainer_panel.dart';
import '../community/community_page.dart';
import '../shop/cart_page.dart';
import '../shop/orders_page.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'ai_coach_screen.dart';
import 'challenges_screen.dart';
import 'vendor_registration_screen.dart';
import 'streak_detail_screen.dart';
import '../backend/me.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // One scroll controller per home tab screen, plus the pager between them.
  final _scrolls = List.generate(5, (_) => SmoothScrollController());
  final _pager = PageController();
  int _selectedCategoryIndex =
      0; // 0: Overview, 1: Workouts, 2: Nutrition, 3: Mental Health, 4: Shop
  int _selectedOverviewCardIndex = 0;
  int _selectedBottomNavIndex = 0;

  late AnimationController _entranceController;

  // Category Configuration with Top Tabs Images
  final List<_CategoryItem> _categories = [
    _CategoryItem(
      title: 'Overview',
      imagePath: 'assets/images/top tabs/overview.png',
      bgColor: const Color(0xFFE8F8EE), // Light Green
      subBgColor: const Color(0xFFF0FDF4),
      activeColor: const Color(0xFF16A34A),
    ),
    _CategoryItem(
      title: 'Workouts',
      imagePath: 'assets/images/top tabs/workout.png',
      bgColor: const Color(0xFFF5EEFF), // Light Purple
      subBgColor: const Color(0xFFFAF5FF),
      activeColor: const Color(0xFF9333EA),
    ),
    _CategoryItem(
      title: 'Nutrition',
      imagePath: 'assets/images/top tabs/nutrition.png',
      bgColor: const Color(0xFFE3EEFF), // Soft blue
      subBgColor: const Color(0xFFF0F6FF),
      activeColor: const Color(0xFF3B82F6),
    ),
    _CategoryItem(
      title: 'Mental Health',
      imagePath: 'assets/images/top tabs/mental health.png',
      bgColor: const Color(0xFFFFEEF1), // Light Pink
      subBgColor: const Color(0xFFFFF1F2),
      activeColor: const Color(0xFFE11D48),
    ),
    _CategoryItem(
      title: 'Shop',
      imagePath: 'assets/images/top tabs/shop.png',
      bgColor: const Color(0xFFEBF5FF), // Light Blue
      subBgColor: const Color(0xFFF0F9FF),
      activeColor: const Color(0xFF0284C7),
    ),
  ];

  bool _isOverviewLoading = false;
  late AnimationController _shimmerController;

  // First-Time Registration & Interactive Demo State
  bool _isDemoActive = false;
  bool _showAppTour = false;
  int _tourStep = 0;
  int _demoStep = 0;
  int _demoSecondsRemaining = 5;
  Timer? _demoCountdownTimer;
  late AnimationController _demoPulseController;

  final List<Map<String, dynamic>> _tourSteps = [
    {
      'title': 'Overview & Daily Health',
      'desc':
          'Track your daily wellness score, steps, active calories, water intake, and habit streaks in one unified place.',
      'categoryIndex': 0,
      'icon': Icons.space_dashboard_rounded,
      'color': Color(0xFF16A34A),
    },
    {
      'title': 'AI Workouts & Training',
      'desc':
          'Discover custom AI workout splits, guided exercise videos, rep counters, and recovery schedules tailored to your goals.',
      'categoryIndex': 1,
      'icon': Icons.fitness_center_rounded,
      'color': Color(0xFF9333EA),
    },
    {
      'title': 'Nutrition & Meal Tracking',
      'desc':
          'Log your daily meals, track macronutrients (protein, carbs, fats), and follow lab-formulated nutrition plans.',
      'categoryIndex': 2,
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'title': 'Mental Health & Mindfulness',
      'desc':
          'Practice guided breathwork, stress-relief meditations, sleep stories, and nervous system recovery routines.',
      'categoryIndex': 3,
      'icon': Icons.spa_rounded,
      'color': Color(0xFFE11D48),
    },
    {
      'title': 'Shop & Lab Certified Gear',
      'desc':
          'Order authentic supplements, high-performance athletic apparel, and certified fitness gear with doorstep delivery.',
      'categoryIndex': 4,
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFF0284C7),
    },
  ];

  // ---------------------------------------------------------------
  // HOME TABS: each of the 5 tabs is its own screen in a PageView (swipe
  // between them). Every screen repeats the shared header and tab bar on top
  // and lists its own section components in a lazy sliver list. A screen is
  // built the first time it is opened and then kept, so switching back is
  // instant and keeps its scroll position; hidden screens' animations pause.
  // ---------------------------------------------------------------

  Widget _homeHeader(BuildContext context, _CategoryItem activeCategory) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          TickerGate(
            child: IosHeader(
              name: Me.first,
              streak: 12,
              onStreak: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakDetailScreen())),
              onAvatar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ),
          const SizedBox(height: 16),
          _buildTopCategoryTabs(activeCategory),
        ],
      );

  Widget _homeScroll(BuildContext context, _CategoryItem activeCategory) {
    final current = _selectedCategoryIndex;
    // Tab taps, the tour and widget links change the index; move the pager
    // to match (a jump: the section fade-in is the transition).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pager.hasClients) return;
      final pos = _pager.position;
      if (pos.isScrollingNotifier.value) return;
      if ((_pager.page ?? 0).round() != _selectedCategoryIndex) _pager.jumpToPage(_selectedCategoryIndex);
    });
    final header = _homeHeader(context, activeCategory);
    return PageView.builder(
      controller: _pager,
      itemCount: _categories.length,
      onPageChanged: (i) {
        if (i != _selectedCategoryIndex && !_isDemoActive) setState(() => _selectedCategoryIndex = i);
      },
      itemBuilder: (context, tab) => TickerMode(
        enabled: tab == current,
        child: HomeTabScreen(
          key: PageStorageKey('home-tab-$tab'),
          controller: _scrolls[tab],
          header: header,
          sections: homeTabSections(context, tab),
        ),
      ),
    );
  }

  void _onPanel() {
    if (mounted) setState(() {});
  }

  // A tap on an Android home screen widget opens the matching screen.
  void _onWidgetRoute() {
    final r = WidgetSync.route.value;
    if (r == null || !mounted) return;
    WidgetSync.route.value = null;
    if (PanelStore.I.panelMode) PanelStore.I.exitPanel();
    Navigator.of(context).popUntil((x) => x.isFirst);
    setState(() {
      switch (r) {
        case 'steps':
          _selectedBottomNavIndex = 1;
        case 'meal':
          _selectedBottomNavIndex = 0;
          _selectedCategoryIndex = 2;
        case 'workout':
          _selectedBottomNavIndex = 0;
          _selectedCategoryIndex = 1;
        case 'trainer':
          _selectedBottomNavIndex = 2;
        default:
          _selectedBottomNavIndex = 0;
          _selectedCategoryIndex = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (r == 'water') openWaterScreen(context);
      if (r == 'kemo') Navigator.push(context, MaterialPageRoute(builder: (_) => const KemoAiScreen()));
      if (r == 'trainer' && TrainerStore.I.active) Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutPlanPage()));
    });
  }

  @override
  void initState() {
    super.initState();
    PanelStore.I.addListener(_onPanel);
    WidgetSync.route.addListener(_onWidgetRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onWidgetRoute());
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _demoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Initial skeleton loading simulation, then check for first-time user tour
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) {
        setState(() {
          _isOverviewLoading = false;
        });
        // Nothing shows the skeleton or demo pulse after loading; a repeating
        // controller would keep the app drawing frames forever.
        _shimmerController.stop();
        _demoPulseController.stop();
        _entranceController.forward(from: 0.0);

        // Eagerly preload all Shop Products, Banners, and Images in the background
        // The Shop tab now uses bundled demo data, so no network preload.
      }
    });
  }

  @override
  void dispose() {
    PanelStore.I.removeListener(_onPanel);
    WidgetSync.route.removeListener(_onWidgetRoute);
    for (final c in _scrolls) {
      c.dispose();
    }
    _pager.dispose();
    _demoCountdownTimer?.cancel();
    _demoPulseController.dispose();
    _shimmerController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trainer panel mode swaps the whole home for the coach panel.
    if (PanelStore.I.panelMode) return const TrainerPanelShell();
    final activeCategory = _categories[_selectedCategoryIndex];

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by AnimatedContainer
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.45, 1.0],
            colors: [
              activeCategory.bgColor, // Slightly darker/richer shade
              activeCategory.subBgColor, // Fading to pastel shade
              const Color(0xFFFBFBFD), // Blending into clean background
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Furry blurred circles and doodles drift behind the content.
              // Painted at viewport size and moved with the scroll offset, so
              // only what's on screen is drawn each frame.
              if (_selectedBottomNavIndex == 0 || _selectedBottomNavIndex > 4)
                Positioned.fill(
                  child: FurBlobsBackdrop(food: _selectedCategoryIndex == 2, scroll: _scrolls[_selectedCategoryIndex]),
                ),
              // Swappable Body based on bottom nav
              _selectedBottomNavIndex == 1
                  ? const StepsScreen()
                  : _selectedBottomNavIndex == 2
                  ? const TrainersPage()
                  : _selectedBottomNavIndex == 3
                  ? const CommunityPage()
                  : _selectedBottomNavIndex == 4
                  ? const ProfileScreen()
                  : _homeScroll(context, activeCategory),

              // Draggable side island (snaps left/right, opens Today slider)
              if (_selectedBottomNavIndex == 0)
                const Positioned.fill(child: RepaintBoundary(child: SideIsland())),

              // Bottom Floating Navigation Bar
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: _buildFloatingBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER WITH BLUR STAGGERED GREETING & ANIMATED ICON
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // FIRST-TIME REGISTRATION INTERACTIVE TABS TOUR OVERLAY
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // "SEE DEMO" INTERACTIVE BANNER / BUTTON BELOW MAIN TABS
  // -------------------------------------------------------------

  void _startDemoStepTimer() {
    _demoCountdownTimer?.cancel();
    _demoCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_demoSecondsRemaining > 1) {
        setState(() {
          _demoSecondsRemaining--;
        });
      } else {
        // 5 seconds elapsed -> advance to next tab
        _nextDemoStep();
      }
    });
  }

  void _nextDemoStep() {
    HapticFeedback.mediumImpact();
    _demoCountdownTimer?.cancel();

    if (_demoStep < _tourSteps.length - 1) {
      setState(() {
        _demoStep++;
        _selectedCategoryIndex = _tourSteps[_demoStep]['categoryIndex'] as int;
        _demoSecondsRemaining = 5;
      });
      _startDemoStepTimer();
    } else {
      // Demo completed
      _stopAppDemo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: Color(0xFF22C55E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Complete 🎉 You\'re ready to crush your goals!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _stopAppDemo() {
    HapticFeedback.lightImpact();
    _demoCountdownTimer?.cancel();
    setState(() {
      _isDemoActive = false;
      _selectedCategoryIndex = 0;
    });
  }

  // -------------------------------------------------------------
  // 2. TOP CATEGORY TABS (SHADOW ON ACTIVE + SLIDING UNDERLINE)
  // -------------------------------------------------------------
  static const List<String> _tabIcons = [
    'assets/images/top tabs/icons/overview.png',
    'assets/images/top tabs/icons/workout.png',
    'assets/images/top tabs/icons/nutrition.png',
    'assets/images/top tabs/icons/wellness.png',
    'assets/images/top tabs/icons/shop.png',
  ];
  static const List<String> _tabLabels = [
    'Overview',
    'Workouts',
    'Nutrition',
    'Wellness',
    'Shop',
  ];

  Widget _buildTopCategoryTabs(_CategoryItem activeCategory) {
    return RepaintBoundary(child: CategoryTabBar(
      tabs: [
        for (var i = 0; i < _categories.length; i++)
          CategoryTabData(
            label: _tabLabels[i],
            iconPath: _tabIcons[i],
            color: _categories[i].activeColor,
            badge: i == 4 ? '40% OFF' : null,
          ),
      ],
      selectedIndex: _selectedCategoryIndex,
      highlightIndex: _isDemoActive ? _demoStep : null,
      onSelected: (index) {
        if (_isDemoActive) {
          _nextDemoStep();
        } else {
          setState(() => _selectedCategoryIndex = index);
        }
      },
    ));
  }

  // -------------------------------------------------------------
  // 7. BOTTOM FLOATING NAVIGATION BAR (MATCHING REFERENCE UI)
  // -------------------------------------------------------------
  Widget _buildFloatingBottomNav() {
    return RepaintBoundary(child: CustomFloatingBottomBar(
      selectedIndex: _selectedBottomNavIndex,
      onItemSelected: (index) {
        setState(() {
          _selectedBottomNavIndex = index;
        });
      },
      onAddPressed: () {
        _showQuickAddActionSheet();
      },
    ));
  }

  void _showQuickAddActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Section: Menu
                  Text(
                    'Menu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu 4-Column Grid (Row 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionItem(
                        icon: Icons.bar_chart_rounded,
                        title: 'Progress',
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFE6F7F0),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedBottomNavIndex = 0;
                            _selectedCategoryIndex = 0;
                          });
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.card_giftcard_rounded,
                        title: 'Rewards',
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFE6F7F0),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RewardsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI Coach',
                        iconColor: const Color(0xFF8B5CF6),
                        bgColor: const Color(0xFFF3E8FF),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AiCoachScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.person_rounded,
                        title: 'Profile',
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFE0F2FE),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Menu 4-Column Grid (Row 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionItem(
                        icon: Icons.directions_walk_rounded,
                        title: 'Steps',
                        iconColor: const Color(0xFFF97316),
                        bgColor: const Color(0xFFFFF7ED),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedBottomNavIndex = 1);
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.school_rounded,
                        title: 'Trainers',
                        iconColor: const Color(0xFFEC4899),
                        bgColor: const Color(0xFFFCE7F3),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedBottomNavIndex = 2);
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.forum_rounded,
                        title: 'Community',
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFEFF6FF),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedBottomNavIndex = 3);
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.emoji_events_rounded,
                        title: 'Challenges',
                        iconColor: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFEF3C7),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChallengesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Section: Shop
                  Text(
                    'Shop',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shop 4-Column Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionItem(
                        icon: Icons.shopping_bag_rounded,
                        title: 'Shop',
                        iconColor: const Color(0xFFE11D48),
                        bgColor: const Color(0xFFFFE4E6),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedBottomNavIndex = 0;
                            _selectedCategoryIndex = 4;
                          });
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.assignment_rounded,
                        title: 'Orders',
                        iconColor: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrdersPage(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.favorite_rounded,
                        title: 'Wishlist',
                        iconColor: const Color(0xFF8B5CF6),
                        bgColor: const Color(0xFFF3E8FF),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WishlistPage(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.local_offer_rounded,
                        title: 'Offers',
                        iconColor: const Color(0xFFEAB308),
                        bgColor: const Color(0xFFFEF9C3),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OffersPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. Section: Vendor & Trainer Side-by-Side Panels
                  Row(
                    children: [
                      // Vendor Panel
                      Expanded(
                        child: _buildBannerPanel(
                          title: 'Vendor Panel',
                          subtitle: 'Manage your store,\nproducts and orders',
                          titleColor: const Color(0xFF1E40AF),
                          subColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFDBEAFE),
                          borderColor: const Color(0xFFBFDBFE),
                          imageAsset: 'assets/images/vendor_store_3d.jpg',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VendorRegistrationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Trainer Panel
                      Expanded(
                        child: _buildBannerPanel(
                          title: 'Trainer Panel',
                          subtitle: 'Manage clients,\nplans and sessions',
                          titleColor: const Color(0xFF6B21A8),
                          subColor: const Color(0xFF8B5CF6),
                          bgColor: const Color(0xFFF3E8FF),
                          borderColor: const Color(0xFFE9D5FF),
                          imageAsset: 'assets/images/trainer_panel_3d.jpg',
                          onTap: () {
                            Navigator.pop(context);
                            openTrainerPanel(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPanel({
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color subColor,
    required Color bgColor,
    required Color borderColor,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Circular Arrow Button
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: subColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: subColor,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 3D Graphic on the Right
            Positioned(
              right: -4,
              bottom: -4,
              child: Image.asset(
                imageAsset,
                width: 68,
                height: 68,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final String imagePath;
  final Color bgColor;
  final Color subBgColor;
  final Color activeColor;

  _CategoryItem({
    required this.title,
    required this.imagePath,
    required this.bgColor,
    required this.subBgColor,
    required this.activeColor,
  });
}
