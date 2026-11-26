import '../services/products_backend_service.dart';
import '../services/banners_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/marketplace_home_layout_service.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../widgets/neuro_island_dock.dart';
import '../widgets/dashboard_motion.dart';
import '../widgets/category_tab_bar.dart';
import '../widgets/kemo.dart';
import '../widgets/tabs_v3/kit3.dart';
import '../widgets/tabs_v3/nutrition_tab.dart';
import '../widgets/tabs_v3/overview_tab.dart';
import '../widgets/tabs_v3/shop_tab.dart';
import '../widgets/tabs_v3/wellness_tab.dart';
import '../widgets/tabs_v3/workouts_tab.dart';
import 'kemo_ai_screen.dart';
import '../widgets/dashboard_3d_icons.dart';
import '../widgets/custom_floating_bottom_bar.dart';
import 'steps_screen.dart';
import 'trainers_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'ai_coach_screen.dart';
import 'shop_screen.dart';
import 'challenges_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';
import 'offers_screen.dart';
import 'transform_screen.dart';
import 'vendor_registration_screen.dart';
import 'streak_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
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
      bgColor: kTint,
      subBgColor: kTint,
      activeColor: kBrand,
      heroColor: kTintTop,
    ),
    _CategoryItem(
      title: 'Workouts',
      imagePath: 'assets/images/top tabs/workout.png',
      bgColor: kTint,
      subBgColor: kTint,
      activeColor: kBrand,
      heroColor: kTintTop,
    ),
    _CategoryItem(
      title: 'Nutrition',
      imagePath: 'assets/images/top tabs/nutrition.png',
      bgColor: kTint,
      subBgColor: kTint,
      activeColor: kBrand,
      heroColor: kTintTop,
    ),
    _CategoryItem(
      title: 'Mental Health',
      imagePath: 'assets/images/top tabs/mental health.png',
      bgColor: kTint,
      subBgColor: kTint,
      activeColor: kBrand,
      heroColor: kTintTop,
    ),
    _CategoryItem(
      title: 'Shop',
      imagePath: 'assets/images/top tabs/shop.png',
      bgColor: kTint,
      subBgColor: kTint,
      activeColor: kBrand,
      heroColor: kTintTop,
    ),
  ];

  static const List<String> _tabLabels = [
    'Overview',
    'Workouts',
    'Nutrition',
    'Wellness',
    'Shop',
  ];

  final ValueNotifier<bool> _pageScrolling = ValueNotifier<bool>(false);
  static const List<String> _tabIcons = [
    'assets/images/top tabs/icons/overview.png',
    'assets/images/top tabs/icons/workout.png',
    'assets/images/top tabs/icons/nutrition.png',
    'assets/images/top tabs/icons/wellness.png',
    'assets/images/top tabs/icons/shop.png',
  ];

  bool _isOverviewLoading = true;
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

  @override
  void initState() {
    super.initState();
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
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isOverviewLoading = false;
        });
        _shimmerController.stop();
        _entranceController.forward(from: 0.0);

        // Eagerly preload all Shop Products, Banners, and Images in the background
        _preloadShopDataAndImages();
      }
    });
  }

  @override
  void dispose() {
    _demoCountdownTimer?.cancel();
    _demoPulseController.dispose();
    _shimmerController.dispose();
    _entranceController.dispose();
    _pageScrolling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCategory = _categories[_selectedCategoryIndex];

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by AnimatedContainer
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.2, 0.42, 0.7],
            colors: [
              activeCategory.heroColor, // Vivid tab colour at the top
              activeCategory.bgColor, // Softening
              activeCategory.subBgColor, // Pastel
              // Overview keeps one solid neon colour; its white sheet
              // starts below the stat cards.
              activeCategory.subBgColor, // Every tab ends on its tint;
              // the curved sheet inside the tab supplies the light surface.
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Swappable Body based on bottom nav
              _selectedBottomNavIndex == 1
                  ? const StepsScreen()
                  : _selectedBottomNavIndex == 2
                  ? const TrainersScreen()
                  : _selectedBottomNavIndex == 3
                  ? const SocialScreen()
                  : _selectedBottomNavIndex == 4
                  ? const ProfileScreen()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.axis != Axis.vertical) return false;
                        if (n is ScrollStartNotification ||
                            n is ScrollUpdateNotification) {
                          _pageScrolling.value = true;
                        } else if (n is ScrollEndNotification) {
                          _pageScrolling.value = false;
                        }
                        return false;
                      },
                      child: RevealScope(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            // Overview's white sheet carries its own space
                            // for the floating bottom nav.
                            bottom: 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),

                              // 1. Top Header (Blur Staggered Greeting, Animated Badge, Streak Pill)
                              _buildAnimatedHeader(),

                              const SizedBox(height: 16),

                              // 2. Fixed Top Category Tabs
                              _buildTopCategoryTabs(activeCategory),

                              // 3. Smooth Animated Switcher for Tab Content
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.04, 0.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_selectedCategoryIndex),
                                  child: _selectedCategoryIndex == 1
                                      ? const WorkoutsTabV3()
                                      : _selectedCategoryIndex == 2
                                      ? const NutritionTabV3()
                                      : _selectedCategoryIndex == 3
                                      ? const WellnessTabV3()
                                      : _selectedCategoryIndex == 4
                                      ? const ShopTabV3()
                                      : const OverviewTabV7(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

              // Docked island on the right edge (home only). Tap to open
              // the full panel with today's stats and quick actions.
              if (_selectedBottomNavIndex == 0)
                Positioned.fill(
                  child: NeuroIslandDock(
                    accent: activeCategory.activeColor,
                    scrolling: _pageScrolling,
                    onSelectTab: (i) {
                      if (i >= 0 && i < _categories.length) {
                        setState(() => _selectedCategoryIndex = i);
                      }
                    },
                  ),
                ),

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning, Rohit!';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon, Rohit!';
    } else {
      return 'Good Evening, Rohit!';
    }
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

  // -------------------------------------------------------------
  // EAGER SHOP DATA & IMAGES PRELOADER (LOADED ON OVERVIEW TAB)
  // -------------------------------------------------------------
  void _preloadShopDataAndImages() async {
    try {
      debugPrint(
        'Eagerly preloading all Shop products, banners, and categories on Overview...',
      );
      await Future.wait([
        ProductsBackendService.instance.fetchProducts(),
        BannersBackendService.instance.fetchBanners(),
        CategoryBackendService.instance.fetchCategories(),
        MarketplaceHomeLayoutService.instance.fetchLayout(),
      ]);

      if (!mounted) return;

      // Pre-cache banner images
      for (final banner in BannersBackendService.instance.banners) {
        if (banner.imageUrl.isNotEmpty) {
          precacheImage(
            NetworkImage(banner.imageUrl),
            context,
          ).catchError((_) {});
        }
      }

      // Pre-cache top product images
      for (final product in ProductsBackendService.instance.products.take(10)) {
        if (product.images.isNotEmpty && product.images.first.isNotEmpty) {
          precacheImage(
            NetworkImage(product.images.first),
            context,
          ).catchError((_) {});
        }
      }
      debugPrint(
        'Shop data & images preloaded successfully! Ready for instant display on Shop tab.',
      );
    } catch (e) {
      debugPrint('Background shop preloading notice: $e');
    }
  }

  Widget _buildSeeDemoBanner(_CategoryItem activeCategory) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: _startAppDemo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'See App Demo',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'INTERACTIVE',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF22C55E),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Highlights each tab & auto-cycles every 5 seconds',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DEMO CONTROLLER LOGIC (5-SECOND COUNTDOWN & ADVANCE)
  // -------------------------------------------------------------
  void _startAppDemo() {
    HapticFeedback.heavyImpact();
    _demoCountdownTimer?.cancel();

    setState(() {
      _isDemoActive = true;
      _demoStep = 0;
      _selectedCategoryIndex = 0;
      _demoSecondsRemaining = 5;
    });

    _startDemoStepTimer();
  }

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

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final anim = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
        ).value;
        final slideY = 24.0 * (1 - anim);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              // Blur-Slide Staggered Dynamic Greeting (No Location Pin)
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, slideY),
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: anim.clamp(0.0, 1.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _getGreeting(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Animated cycling category icon badge
                              const _AnimatedHeaderIconBadge(),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                'Ready to crush your goals today?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Streak Pill
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StreakDetailScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFEF3C7),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '12',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFD97706),
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Streak',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Kemo, the AI buddy: tap to chat
              _KemoHeaderButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, KemoAiScreen.route());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 2. TOP CATEGORY TABS (SHADOW ON ACTIVE + SLIDING UNDERLINE)
  // -------------------------------------------------------------
  Widget _buildTopCategoryTabs(_CategoryItem activeCategory) {
    if (_isOverviewLoading) return _buildTopCategoryTabsSkeleton();

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final anim = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.05, 0.45, curve: Curves.easeOutCubic),
        ).value;
        return Transform.translate(
          offset: Offset(0, (1.0 - anim) * 16.0),
          child: Opacity(opacity: anim.clamp(0.0, 1.0), child: child),
        );
      },
      child: CategoryTabBar(
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
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE SKELETON SHIMMER BOX COMPONENT
  // -------------------------------------------------------------
  Widget _buildSkeletonShimmerBox({
    double? width,
    double? height,
    double borderRadius = 16,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (shimmerValue * 3.0), -0.2),
              end: Alignment(1.5 + (shimmerValue * 3.0), 0.2),
              colors: const [
                Color(0xFFE8ECEF),
                Color(0xFFF8FAFC),
                Color(0xFFE8ECEF),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            ),
          ),
        );
      },
    );
  }

  // Skeleton — matches the wider, pod-less layout
  Widget _buildTopCategoryTabsSkeleton() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = CategoryTabBar.tabWidthFor(c.maxWidth, 5);
        final h = CategoryTabBar.heightFor(w);
        return SizedBox(
          height: h + 4,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, __) => SizedBox(
              width: w,
              height: h,
              child: _buildSkeletonShimmerBox(
                width: w,
                height: h,
                borderRadius: 20,
              ),
            ),
          ),
        );
      },
    );
  }


  // -------------------------------------------------------------
  // 3. SEARCH & TRANSFORM YOURSELF ROW (STAGGERED SLIDE WITH SKELETON)
  // -------------------------------------------------------------
  Widget _buildAnimatedSearchAndTransformRow() {
    if (_isOverviewLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Expanded(
              child: _buildSkeletonShimmerBox(height: 50, borderRadius: 16),
            ),
            const SizedBox(width: 12),
            _buildSkeletonShimmerBox(height: 50, width: 140, borderRadius: 16),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final anim = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
        ).value;
        final slideY = 24.0 * (1 - anim);

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Search Input Container
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF1F5F9),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search for workouts, meals, plans...',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // "Transform Yourself" Mini Banner with Neon Green styling
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransformScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF22C55E), // Vivid Neon Green
                            Color(0xFF16A34A), // Deep Neon Green
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.38),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transform',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Yourself',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Athlete Cutout Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/athlete_transform.jpg',
                              width: 32,
                              height: 38,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // White Circular Forward Arrow Badge
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Color(0xFF16A34A),
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
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 4. HERO BANNER CARD ("Stay Consistent, See Results!")
  // -------------------------------------------------------------
  Widget _buildAnimatedHeroBanner() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final anim = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.52, 0.85, curve: Curves.easeOutCubic),
        ).value;
        final slideY = 30.0 * (1 - anim);

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // Soft Mint Green
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFDCFCE7),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Banner Content
                    SizedBox(
                      height: 168,
                      child: Stack(
                        children: [
                          // 1. Right Image (0 padding from top, right, bottom)
                          Positioned(
                            top: 0,
                            right: 0,
                            bottom: 0,
                            width: 175,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/hero_fitness_gear.jpg',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                ),
                                // Linear gradient blend from left
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      stops: const [0.0, 0.45, 1.0],
                                      colors: [
                                        const Color(0xFFF0FDF4),
                                        const Color(
                                          0xFFF0FDF4,
                                        ).withValues(alpha: 0.5),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Left Content (Heading, Subtitle, Explore Button)
                          Positioned(
                            top: 14,
                            left: 18,
                            bottom: 12,
                            right: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Stay Consistent,\n',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.6,
                                      height: 1.15,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'See Results!',
                                        style: TextStyle(
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track, Train & Transform with Personalized Plans.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Green Explore Plans Button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF16A34A,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                          'Explore Plans',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // OVERVIEW IMAGE CAROUSEL CARDS (BEAUTIFUL 3D CAROUSEL WITH LABELS)
  // -------------------------------------------------------------
  Widget _buildOverviewCategoryCardsCarousel() {
    final List<Map<String, String>> overviewCards = [
      {'icon': 'assets/images/top tabs/overview/all.png', 'label': 'All'},
      {
        'icon': 'assets/images/top tabs/overview/strenth.png',
        'label': 'Strength',
      },
      {'icon': 'assets/images/top tabs/overview/cardio.png', 'label': 'Cardio'},
      {'icon': 'assets/images/top tabs/overview/yoga.png', 'label': 'Yoga'},
      {'icon': 'assets/images/top tabs/overview/hit.png', 'label': 'HIIT'},
      {
        'icon': 'assets/images/top tabs/overview/mobility.png',
        'label': 'Mobility',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate width so exactly 5 cards fit in one screen view with 8px gaps
        const double horizontalPadding = 40.0; // 20px left + 20px right
        const double gap = 8.0;
        final double cardWidth =
            (constraints.maxWidth - horizontalPadding - (4 * gap)) / 5;
        final double cardHeight = cardWidth + 22.0;

        if (_isOverviewLoading) {
          return SizedBox(
            height: cardHeight,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(width: gap),
              itemBuilder: (context, index) {
                return _buildSkeletonShimmerBox(
                  width: cardWidth,
                  height: cardHeight,
                  borderRadius: 18,
                );
              },
            ),
          );
        }

        return AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) {
            return SizedBox(
              height: cardHeight,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: overviewCards.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  final card = overviewCards[index];
                  final iconPath = card['icon']!;
                  final label = card['label']!;
                  final isSelected = _selectedOverviewCardIndex == index;

                  // Sequential staggered entrance for each carousel card
                  final startInterval = (0.35 + (index * 0.05)).clamp(
                    0.0,
                    0.85,
                  );
                  final endInterval = (startInterval + 0.30).clamp(0.0, 1.0);
                  final anim = CurvedAnimation(
                    parent: _entranceController,
                    curve: Interval(
                      startInterval,
                      endInterval,
                      curve: Curves.easeOutCubic,
                    ),
                  ).value;
                  final slideX = (1.0 - anim) * 24.0;

                  return Transform.translate(
                    offset: Offset(slideX, 0),
                    child: Opacity(
                      opacity: anim.clamp(0.0, 1.0),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedOverviewCardIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: cardWidth,
                          height: cardHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isSelected
                                  ? [const Color(0xFFF0FDF4), Colors.white]
                                  : [Colors.white, const Color(0xFFF8FAFC)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(
                                        0xFF16A34A,
                                      ).withValues(alpha: 0.18)
                                    : const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.03),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 6.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.asset(
                                  iconPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: SubCategory3DIcon(
                                          index: index,
                                          themeColor: const Color(0xFF16A34A),
                                          isSelected: isSelected,
                                          size: 24,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF64748B),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 5. OVERVIEW BENTO GRID (LEFT DOUBLE HEIGHT VIDEO + RIGHT 2 IMAGES)
  // -------------------------------------------------------------
  Widget _buildAnimatedOverviewBentoGrid() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final anim = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.62, 0.95, curve: Curves.easeOutCubic),
        ).value;
        final slideY = 24.0 * (1 - anim);

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: 1 Card with Double Height (Pure Video Player, No Text/Overlay)
                  Expanded(
                    flex: 11,
                    child: Container(
                      height: 290,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const _OverviewBentoVideoPlayer(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right: 2 Cards Stacked Vertically
                  Expanded(
                    flex: 10,
                    child: Column(
                      children: [
                        // Top Image Card ("Change How You Train")
                        Container(
                          height: 139,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/overview_bento_train.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1E293B),
                                child: const Center(
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    color: Color(0xFF22C55E),
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bottom Image Card ("Saúde Mental" Brain Lifting Barbell)
                        Container(
                          height: 139,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/overview_bento_mental.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1E293B),
                                child: const Center(
                                  child: Icon(
                                    Icons.psychology_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 6. TODAY'S PROGRESS CAROUSEL (REPLACES OVERVIEW)
  // -------------------------------------------------------------
  Widget _buildAnimatedProgressCarousel() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final anim = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
        ).value;
        final slideY = 30.0 * (1 - anim);

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Progress",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Horizontal Carousel of Animated Progress Cards
                SizedBox(
                  height: 148,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: const [
                      _AnimatedProgressCard(
                        emoji: '🔥',
                        value: '461 kcal',
                        label: 'Calories',
                        percentage: '12%',
                        goalLabel: 'Goal: 600',
                        progressRatio: 461 / 600,
                        isUp: true,
                        lineColor: Color(0xFF16A34A),
                        tintColor: Color(0xFFDCFCE7),
                      ),
                      _AnimatedProgressCard(
                        emoji: '🏋️',
                        value: '12/20',
                        label: 'Workouts',
                        percentage: '8%',
                        goalLabel: 'Monthly Plan',
                        progressRatio: 12 / 20,
                        isUp: true,
                        lineColor: Color(0xFF16A34A),
                        tintColor: Color(0xFFE8F8EE),
                      ),
                      _AnimatedProgressCard(
                        emoji: '✅',
                        value: '8 of 10',
                        label: 'Daily Goals',
                        percentage: '15%',
                        goalLabel: 'Target: 10',
                        progressRatio: 8 / 10,
                        isUp: true,
                        lineColor: Color(0xFF16A34A),
                        tintColor: Color(0xFFDCFCE7),
                      ),
                      _AnimatedProgressCard(
                        emoji: '🌙',
                        value: '7h 32m',
                        label: 'Sleep Rest',
                        percentage: '9%',
                        goalLabel: 'Goal: 8h 00m',
                        progressRatio: 7.53 / 8.0,
                        isUp: true,
                        lineColor: Color(0xFF8B5CF6),
                        tintColor: Color(0xFFF3E8FF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 7. BOTTOM FLOATING NAVIGATION BAR (MATCHING REFERENCE UI)
  // -------------------------------------------------------------
  Widget _buildFloatingBottomNav() {
    return CustomFloatingBottomBar(
      selectedIndex: _selectedBottomNavIndex,
      onItemSelected: (index) {
        setState(() {
          _selectedBottomNavIndex = index;
        });
      },
      onAddPressed: () {
        _showQuickAddActionSheet();
      },
    );
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShopScreen(),
                            ),
                          );
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
                              builder: (context) => const OrdersScreen(),
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
                              builder: (context) => const WishlistScreen(),
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
                              builder: (context) => const OffersScreen(),
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
                          onTap: () {},
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

// -------------------------------------------------------------
// Helper Classes
// -------------------------------------------------------------
// -------------------------------------------------------------
// Animated Header Icon Badge (Cycles through Top Tab Icons)
// -------------------------------------------------------------
class _AnimatedHeaderIconBadge extends StatefulWidget {
  const _AnimatedHeaderIconBadge();

  @override
  State<_AnimatedHeaderIconBadge> createState() =>
      _AnimatedHeaderIconBadgeState();
}

class _AnimatedHeaderIconBadgeState extends State<_AnimatedHeaderIconBadge> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<String> _icons = [
    'assets/images/top tabs/overview.png',
    'assets/images/top tabs/workout.png',
    'assets/images/top tabs/nutrition.png',
    'assets/images/top tabs/mental health.png',
    'assets/images/top tabs/shop.png',
  ];

  final List<Color> _bgColors = [
    const Color(0xFFDCFCE7), // Mint Green
    const Color(0xFFF3E8FF), // Lavender Purple
    const Color(0xFFFEF3C7), // Warm Yellow
    const Color(0xFFFFE4E6), // Soft Pink
    const Color(0xFFE0F2FE), // Sky Blue
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _icons.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[_currentIndex];
    final iconPath = _icons[_currentIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) {
          return ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        child: Image.asset(
          iconPath,
          key: ValueKey<String>(iconPath),
          fit: BoxFit.contain,
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

  /// Vivid colour at the very top of the page, fading into [bgColor].
  final Color heroColor;

  _CategoryItem({
    required this.title,
    required this.imagePath,
    required this.bgColor,
    required this.subBgColor,
    required this.activeColor,
    required this.heroColor,
  });
}

// -------------------------------------------------------------
// Interactive Animated Progress Card (Clean Line-Free UI)
// -------------------------------------------------------------
class _AnimatedProgressCard extends StatefulWidget {
  final String emoji;
  final String value;
  final String label;
  final String percentage;
  final String goalLabel;
  final double progressRatio;
  final bool isUp;
  final Color lineColor;
  final Color tintColor;

  const _AnimatedProgressCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.percentage,
    required this.goalLabel,
    required this.progressRatio,
    required this.isUp,
    required this.lineColor,
    required this.tintColor,
  });

  @override
  State<_AnimatedProgressCard> createState() => _AnimatedProgressCardState();
}

class _AnimatedProgressCardState extends State<_AnimatedProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _barProgress;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _barProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        _animController.forward(from: 0.0);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 148,
          margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.7, 1.0],
              colors: [
                Colors.white,
                Colors.white,
                widget.tintColor.withValues(alpha: 0.40),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.lineColor.withValues(alpha: 0.06),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Emoji Icon + Percentage Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Emoji Badge in Squircle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.tintColor.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: widget.tintColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // Percentage Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isUp
                          ? const Color(0xFFDCFCE7) // Soft mint green
                          : const Color(0xFFFEE2E2), // Soft red
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isUp
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          color: widget.isUp
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444),
                          size: 14,
                        ),
                        Text(
                          widget.percentage,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: widget.isUp
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Middle: Value & Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // Bottom: Clean Animated Progress Line Indicator (No Sparkline Graph)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.goalLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        "${(widget.progressRatio * 100).toInt()}%",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: widget.lineColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  AnimatedBuilder(
                    animation: _barProgress,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (widget.progressRatio * _barProgress.value)
                              .clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.lineColor,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// OVERVIEW BENTO AUTOPLAY LOOPING VIDEO (NO TEXT / NO OVERLAY)
// -------------------------------------------------------------
class _OverviewBentoVideoPlayer extends StatefulWidget {
  const _OverviewBentoVideoPlayer();

  @override
  State<_OverviewBentoVideoPlayer> createState() =>
      _OverviewBentoVideoPlayerState();
}

class _OverviewBentoVideoPlayerState extends State<_OverviewBentoVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller =
        VideoPlayerController.asset('assets/videos/overview_fitness_loop.mp4')
          ..initialize()
              .then((_) {
                if (mounted) {
                  _controller?.setVolume(0.0);
                  _controller?.setLooping(true);
                  _controller?.play();
                  setState(() {
                    _isInitialized = true;
                  });
                }
              })
              .catchError((e) {
                debugPrint('Error loading overview video asset: $e');
              });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_isInitialized) {
      return Container(
        color: const Color(0xFF0F172A),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width > 0
              ? _controller!.value.size.width
              : 300,
          height: _controller!.value.size.height > 0
              ? _controller!.value.size.height
              : 400,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}

/// Round Kemo avatar in the header with an "Ask me" bubble that pops in now
/// and then.
class _KemoHeaderButton extends StatefulWidget {
  final VoidCallback onTap;
  const _KemoHeaderButton({required this.onTap});

  @override
  State<_KemoHeaderButton> createState() => _KemoHeaderButtonState();
}

class _KemoHeaderButtonState extends State<_KemoHeaderButton> {
  bool _showHint = false;
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted) return;
      _tick++;
      setState(() => _showHint = _tick % 3 == 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: widget.onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Hero(tag: 'kemo-face', child: KemoFace(size: 46)),
            // online dot
            Positioned(
              right: 1,
              bottom: 2,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: -20,
              child: IgnorePointer(
                child: AnimatedScale(
                  scale: _showHint ? 1 : 0,
                  alignment: Alignment.topRight,
                  duration: const Duration(milliseconds: 380),
                  curve: _showHint ? Curves.elasticOut : Curves.easeIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14210C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ask Kemo',
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB8FF3D),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
