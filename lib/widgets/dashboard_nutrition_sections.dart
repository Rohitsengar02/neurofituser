import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/user_nutrition_service.dart';
import '../screens/log_meal_screen.dart';
import '../screens/date_nutrition_detail_screen.dart';

class DashboardNutritionTabContent extends StatefulWidget {
  const DashboardNutritionTabContent({super.key});

  @override
  State<DashboardNutritionTabContent> createState() => _DashboardNutritionTabContentState();
}

class _DashboardNutritionTabContentState extends State<DashboardNutritionTabContent>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _staggerController;
  late AnimationController _shimmerController;
  late AnimationController _calorieRingController;
  late ScrollController _calendarScrollController;
  late List<DateTime> _carouselDates;

  // Interactive states
  int _selectedRecipeCategory = 0;
  DateTime _selectedDate = DateTime.now();
  UserDailyNutritionModel? _selectedDateNutrition;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  UserDailyNutritionModel get _activeNutrition {
    if (_isSameDay(_selectedDate, DateTime.now())) {
      return UserNutritionService.instance.currentNutrition;
    }
    return _selectedDateNutrition ?? UserDailyNutritionModel.empty();
  }

  Future<void> _selectDate(DateTime date) async {
    final newDate = DateTime(date.year, date.month, date.day);
    final isToday = _isSameDay(newDate, DateTime.now());

    setState(() {
      _selectedDate = newDate;
    });

    if (!isToday) {
      final dateKey = _formatDateKey(newDate);
      final model = await UserNutritionService.instance.fetchNutritionForDate(dateKey);
      if (mounted && _formatDateKey(_selectedDate) == dateKey) {
        setState(() {
          _selectedDateNutrition = model;
        });
      }
    } else {
      setState(() {
        _selectedDateNutrition = null;
      });
    }

    if (_calorieRingController.status == AnimationStatus.completed) {
      _calorieRingController.reset();
      _calorieRingController.forward();
    }
  }

  String _formatFriendlyDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    _carouselDates = List.generate(28, (index) {
      return DateTime(today.year, today.month, today.day).subtract(Duration(days: 20 - index));
    });
    _calendarScrollController = ScrollController();

    // 1. Shimmer Controller for Skeleton
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // 2. Stagger Animation Controller
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // 3. Calorie Ring Animation Controller
    _calorieRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Connect to UserNutritionService
    UserNutritionService.instance.addListener(_onNutritionUpdate);
    UserNutritionService.instance.fetchTodayNutrition();
    UserNutritionService.instance.fetchNutritionHistory();
    UserNutritionService.instance.fetchDailyFeaturedRecipes();
    UserNutritionService.instance.fetchMealSuggestions();

    // Center calendar on today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_calendarScrollController.hasClients) {
        final screenW = MediaQuery.of(context).size.width;
        final targetOffset = (20 * 74.0) - (screenW / 2) + 32.0;
        _calendarScrollController.jumpTo(
          targetOffset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
        );
      }
    });

    // Simulate skeleton loading -> Stagger Blur Reveal
    Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _staggerController.forward();
        _calorieRingController.forward();
      }
    });
  }

  void _onNutritionUpdate() {
    if (mounted) {
      setState(() {});
      if (_calorieRingController.status == AnimationStatus.completed) {
        _calorieRingController.reset();
        _calorieRingController.forward();
      }
    }
  }

  @override
  void dispose() {
    UserNutritionService.instance.removeListener(_onNutritionUpdate);
    _calendarScrollController.dispose();
    _shimmerController.dispose();
    _staggerController.dispose();
    _calorieRingController.dispose();
    super.dispose();
  }

  String _formatDateKey(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _toggleWaterGlass(int index) {
    HapticFeedback.lightImpact();
    final current = UserNutritionService.instance.currentNutrition.waterGlasses;
    final newGlasses = (current == index + 1) ? index : index + 1;
    UserNutritionService.instance.updateWater(glasses: newGlasses);
  }

  String _getTodayFormattedDate() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}";
  }

  IconData _getMealCategoryIcon(String category, String name) {
    final c = category.toLowerCase();
    final n = name.toLowerCase();
    if (n.contains('egg') || c.contains('egg')) return Icons.egg_alt_rounded;
    if (n.contains('chicken') || n.contains('turkey') || c.contains('poultry')) return Icons.lunch_dining_rounded;
    if (n.contains('beef') || n.contains('steak') || n.contains('meat')) return Icons.restaurant_rounded;
    if (n.contains('fish') || n.contains('salmon') || n.contains('tuna') || c.contains('seafood')) return Icons.set_meal_rounded;
    if (n.contains('milk') || n.contains('yogurt') || n.contains('paneer') || n.contains('cheese') || c.contains('dairy')) return Icons.local_drink_rounded;
    if (n.contains('oat') || n.contains('bread') || n.contains('rice') || c.contains('grain')) return Icons.bakery_dining_rounded;
    if (n.contains('apple') || n.contains('banana') || n.contains('berry') || c.contains('fruit')) return Icons.apple_rounded;
    if (n.contains('salad') || n.contains('spinach') || n.contains('broccoli') || c.contains('veg')) return Icons.eco_rounded;
    if (n.contains('shake') || n.contains('protein') || n.contains('whey')) return Icons.fitness_center_rounded;
    if (n.contains('coffee') || n.contains('tea') || c.contains('beverage')) return Icons.local_cafe_rounded;
    return Icons.restaurant_menu_rounded;
  }

  Color _getMealCategoryColor(String category, String name) {
    final c = category.toLowerCase();
    final n = name.toLowerCase();
    if (n.contains('fish') || n.contains('salmon') || c.contains('seafood')) return const Color(0xFF0284C7);
    if (n.contains('chicken') || n.contains('turkey') || c.contains('poultry') || n.contains('beef')) return const Color(0xFFEA580C);
    if (n.contains('salad') || n.contains('spinach') || c.contains('veg')) return const Color(0xFF16A34A);
    if (n.contains('egg') || c.contains('egg') || c.contains('dairy')) return const Color(0xFFD97706);
    if (n.contains('oat') || c.contains('grain')) return const Color(0xFFB45309);
    if (n.contains('apple') || n.contains('berry') || c.contains('fruit')) return const Color(0xFFE11D48);
    return const Color(0xFF6366F1);
  }

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

        final blurVal = ((1 - anim) * 12.0).clamp(0.0, 12.0);
        final slideY = (24.0 * (1 - anim));

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoadingView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),

        // 00. Top Carousel Calendar (Stagger 0.0 -> 0.16)
        _buildStaggeredSection(
          startInterval: 0.0,
          endInterval: 0.16,
          child: _buildCalendarCarouselSection(),
        ),

        const SizedBox(height: 18),

        // 01. Today's Nutrition — Hero Section (Stagger 0.06 -> 0.22)
        _buildStaggeredSection(
          startInterval: 0.06,
          endInterval: 0.22,
          child: _buildTodayNutritionHeroSection(),
        ),

        const SizedBox(height: 24),

        // 02. Today's Macro Balance (Stagger 0.10 -> 0.28)
        _buildStaggeredSection(
          startInterval: 0.10,
          endInterval: 0.28,
          child: _buildMacroBalanceSection(),
        ),

        const SizedBox(height: 24),

        // 03. Water Intake 💧 (Stagger 0.18 -> 0.36)
        _buildStaggeredSection(
          startInterval: 0.18,
          endInterval: 0.36,
          child: _buildWaterIntakeSection(),
        ),

        const SizedBox(height: 26),

        // 04. Today's Meals (Stagger 0.26 -> 0.44)
        _buildStaggeredSection(
          startInterval: 0.26,
          endInterval: 0.44,
          child: _buildTodaysMealsSection(),
        ),

        const SizedBox(height: 26),

        // 05. Nutrition Insights & AI Coach 🧠 (Stagger 0.34 -> 0.52)
        _buildStaggeredSection(
          startInterval: 0.34,
          endInterval: 0.52,
          child: _buildNutritionInsightsSection(),
        ),

        const SizedBox(height: 26),

        // 06. Nutrient Breakdown (Stagger 0.42 -> 0.60)
        _buildStaggeredSection(
          startInterval: 0.42,
          endInterval: 0.60,
          child: _buildNutrientBreakdownSection(),
        ),

        const SizedBox(height: 26),

        // 07. Healthy Picks For You 🥑 (Stagger 0.50 -> 0.70)
        _buildStaggeredSection(
          startInterval: 0.50,
          endInterval: 0.70,
          child: _buildHealthyPicksCarouselSection(),
        ),

        const SizedBox(height: 26),

        // 08. Recipes & Food Discovery 🍽️ (Stagger 0.60 -> 0.80)
        _buildStaggeredSection(
          startInterval: 0.60,
          endInterval: 0.80,
          child: _buildRecipesDiscoverySection(),
        ),

        const SizedBox(height: 26),

        // 10. Nutrition Progress & 7-Day Graph 📈 (Stagger 0.74 -> 0.90)
        _buildStaggeredSection(
          startInterval: 0.74,
          endInterval: 0.90,
          child: _buildNutritionProgressGraphSection(),
        ),

        const SizedBox(height: 24),

        // 11. Nutrition Streak 🔥 (Stagger 0.82 -> 0.96)
        _buildStaggeredSection(
          startInterval: 0.82,
          endInterval: 0.96,
          child: _buildNutritionStreakSection(),
        ),

        const SizedBox(height: 24),

        // 12. Bottom CTA 🚀 (Stagger 0.90 -> 1.0)
        _buildStaggeredSection(
          startInterval: 0.90,
          endInterval: 1.0,
          child: _buildBottomCTASection(),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // -------------------------------------------------------------
  // SHIMMER SKELETON LOADING VIEW (NUTRITION TAB)
  // -------------------------------------------------------------
  Widget _buildSkeletonLoadingView() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // Skeleton Calendar Carousel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (i) => _buildShimmerBox(width: 62, height: 88, borderRadius: 18),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Skeleton Hero Calorie Ring Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 250, borderRadius: 26),
            ),

            const SizedBox(height: 24),

            // Skeleton Macro Balance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 110, borderRadius: 22),
            ),

            const SizedBox(height: 24),

            // Skeleton Water Tracker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 130, borderRadius: 22),
            ),

            const SizedBox(height: 26),

            // Skeleton Meals Carousel
            SizedBox(
              height: 200,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildShimmerBox(width: 170, height: 200, borderRadius: 22),
                  const SizedBox(width: 14),
                  _buildShimmerBox(width: 170, height: 200, borderRadius: 22),
                ],
              ),
            ),
            const SizedBox(height: 26),
          ],
        );
      },
    );
  }

  Widget _buildShimmerBox({double? width, required double height, double borderRadius = 12}) {
    final double shimmerPos = _shimmerController.value;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + (3.0 * shimmerPos), -0.3),
          end: Alignment(1.5 + (3.0 * shimmerPos), 0.3),
          colors: const [
            Color(0xFFF1F5F9),
            Color(0xFFFFFFFF),
            Color(0xFFF1F5F9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 00. CAROUSEL CALENDAR SECTION (TOP OF NUTRITION TAB)
  // -------------------------------------------------------------
  Widget _buildCalendarCarouselSection() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final isViewingToday = _isSameDay(_selectedDate, now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Month & Year + Jump to Date Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${months[_selectedDate.month - 1]} ${_selectedDate.year}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isViewingToday ? 'Real-time Daily Log' : 'Viewing Log for ${_formatFriendlyDate(_selectedDate)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isViewingToday ? const Color(0xFF64748B) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF10B981),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1E293B),
                            onSurface: Colors.white,
                          ),
                          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0F172A)),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && mounted) {
                    _selectDate(picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF475569)),
                      const SizedBox(width: 4),
                      Text(
                        'All Dates',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Horizontal Carousel List of Days
          SizedBox(
            height: 88,
            child: ListView.separated(
              controller: _calendarScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _carouselDates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = _carouselDates[index];
                final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                final isSelected = _isSameDay(date, _selectedDate);
                final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
                final dateKey = _formatDateKey(date);

                final history = UserNutritionService.instance.historyMap[dateKey];
                final hasLogged = isToday
                    ? (UserNutritionService.instance.currentNutrition.consumedCalories > 0 ||
                        UserNutritionService.instance.currentNutrition.meals.isNotEmpty)
                    : (history != null && history['hasLogged'] == true);

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _selectDate(date);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 62,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0F172A),
                                Color(0xFF1E293B),
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : (hasLogged
                                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : (hasLogged
                                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.03)),
                          blurRadius: isSelected ? 12 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isToday ? 'TODAY' : weekdays[date.weekday - 1].toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Logged status indicator dot
                        if (hasLogged)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF16A34A),
                            ),
                          )
                        else
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPast
                                  ? Colors.transparent
                                  : (isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.transparent),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Date indicator banner if viewing non-today date
          if (!isViewingToday) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Viewing ${_formatFriendlyDate(_selectedDate)} Data',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _selectDate(DateTime.now()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Reset to Today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
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
  // 01. TODAY'S NUTRITION — HERO SECTION (ZERO OVERFLOW)
  // -------------------------------------------------------------
  Widget _buildTodayNutritionHeroSection() {
    final nutrition = _activeNutrition;
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dateKey = _formatDateKey(_selectedDate);

    final consumed = nutrition.consumedCalories;
    final target = nutrition.targetCalories > 0 ? nutrition.targetCalories : 2400;
    final remaining = (target - consumed).clamp(0, 99999);
    final targetProtein = nutrition.targetProtein > 0 ? nutrition.targetProtein : 160.0;
    final targetCarbs = nutrition.targetCarbs > 0 ? nutrition.targetCarbs : 220.0;
    final targetFat = nutrition.targetFat > 0 ? nutrition.targetFat : 70.0;

    final proteinRatio = (nutrition.consumedProtein / targetProtein).clamp(0.0, 1.0);
    final carbsRatio = (nutrition.consumedCarbs / targetCarbs).clamp(0.0, 1.0);
    final fatRatio = (nutrition.consumedFat / targetFat).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Date & + Log Meal Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isToday ? "Today's Nutrition" : "${_formatFriendlyDate(_selectedDate)} Nutrition",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text("🌱", style: TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isToday ? _getTodayFormattedDate() : "Selected Date Log",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // + Log Meal Button
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LogMealScreen(targetDate: dateKey)),
                    );
                    _selectDate(_selectedDate);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          "+ Log Meal",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
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
            const SizedBox(height: 16),

            // Middle: Circular Calorie Gauge + Intake / Burn Stats
            Row(
              children: [
                // Animated Circular Ring
                SizedBox(
                  width: 108,
                  height: 108,
                  child: AnimatedBuilder(
                    animation: _calorieRingController,
                    builder: (context, child) {
                      final rawProgress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
                      final progress = rawProgress * CurvedAnimation(
                        parent: _calorieRingController,
                        curve: Curves.easeOutCubic,
                      ).value;

                      return CustomPaint(
                        painter: _CalorieRingPainter(progress: progress),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$consumed",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "kcal eaten",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Intake & Goal Side Cards
                Expanded(
                  child: Column(
                    children: [
                      _buildHeroStatPill(
                        icon: Icons.restaurant_rounded,
                        label: "Food Intake",
                        value: "$consumed kcal",
                        color: const Color(0xFF16A34A),
                        bg: const Color(0xFFDCFCE7),
                      ),
                      const SizedBox(height: 8),
                      _buildHeroStatPill(
                        icon: Icons.track_changes_rounded,
                        label: "Daily Target",
                        value: "$target kcal",
                        color: const Color(0xFFEA580C),
                        bg: const Color(0xFFFFF7ED),
                      ),
                      const SizedBox(height: 8),
                      _buildHeroStatPill(
                        icon: Icons.hourglass_bottom_rounded,
                        label: "Remaining",
                        value: "$remaining kcal",
                        color: const Color(0xFF2563EB),
                        bg: const Color(0xFFDBEAFE),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom: Macro Progress Bars (Protein, Carbs, Fats) starting from 0
            Row(
              children: [
                Expanded(
                  child: _buildMacroProgressItem(
                    name: "Protein",
                    amount: "${nutrition.consumedProtein.toStringAsFixed(0)} / ${targetProtein.toStringAsFixed(0)}g",
                    percent: proteinRatio,
                    color: const Color(0xFF16A34A),
                    icon: "🟢",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroProgressItem(
                    name: "Carbs",
                    amount: "${nutrition.consumedCarbs.toStringAsFixed(0)} / ${targetCarbs.toStringAsFixed(0)}g",
                    percent: carbsRatio,
                    color: const Color(0xFF8B5CF6),
                    icon: "🟣",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroProgressItem(
                    name: "Fats",
                    amount: "${nutrition.consumedFat.toStringAsFixed(0)} / ${targetFat.toStringAsFixed(0)}g",
                    percent: fatRatio,
                    color: const Color(0xFFF59E0B),
                    icon: "🟠",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4.5),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressItem({
    required String name,
    required String amount,
    required double percent,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 9)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
  // -------------------------------------------------------------
  // 02. TODAY'S MACRO BALANCE
  // -------------------------------------------------------------
  Widget _buildMacroBalanceSection() {
    final nutrition = _activeNutrition;
    final dateKey = _formatDateKey(_selectedDate);
    final pGrams = "${nutrition.consumedProtein.toStringAsFixed(0)}g";
    final cGrams = "${nutrition.consumedCarbs.toStringAsFixed(0)}g";
    final fGrams = "${nutrition.consumedFat.toStringAsFixed(0)}g";
    final calStr = "${nutrition.consumedCalories}";

    final targetP = nutrition.targetProtein > 0 ? nutrition.targetProtein : 160.0;
    final targetC = nutrition.targetCarbs > 0 ? nutrition.targetCarbs : 220.0;
    final targetF = nutrition.targetFat > 0 ? nutrition.targetFat : 70.0;

    final pPct = "${((nutrition.consumedProtein / targetP) * 100).clamp(0, 999).toStringAsFixed(0)}%";
    final cPct = "${((nutrition.consumedCarbs / targetC) * 100).clamp(0, 999).toStringAsFixed(0)}%";
    final fPct = "${((nutrition.consumedFat / targetF) * 100).clamp(0, 999).toStringAsFixed(0)}%";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/nutrition_bg.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85), // White overlay for text readability
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Macro Balance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LogMealScreen(targetDate: dateKey)),
                      );
                      _selectDate(_selectedDate);
                    },
                    child: Text(
                      '+ Log Meal →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4 Cards Grid
              Row(
                children: [
                  Expanded(child: _buildMacroCardWidget("Protein", pGrams, pPct, const Color(0xFF16A34A))),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMacroCardWidget("Carbs", cGrams, cPct, const Color(0xFF8B5CF6))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildMacroCardWidget("Fats", fGrams, fPct, const Color(0xFFF59E0B))),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMacroCardWidget("Calories", calStr, "Kcal", const Color(0xFFEC4899))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCardWidget(String label, String amount, String percent, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            percent == "Kcal" ? "Daily Total" : "$percent of daily limit",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 03. WATER INTAKE 💧 (TILTING NATURAL WATER CARD)
  // -------------------------------------------------------------
  Widget _buildWaterIntakeSection() {
    final nutrition = _activeNutrition;
    final dateKey = _formatDateKey(_selectedDate);

    return TiltingNaturalWaterCard(
      glasses: nutrition.waterGlasses,
      targetGlasses: nutrition.waterTargetGlasses > 0 ? nutrition.waterTargetGlasses : 8,
      onGlassesChanged: (newGlasses) {
        UserNutritionService.instance.updateWater(glasses: newGlasses, date: dateKey);
        _selectDate(_selectedDate);
      },
    );
  }

  // -------------------------------------------------------------
  // 04. TODAY'S MEALS CAROUSEL
  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // 04. TODAY'S MEALS CAROUSEL (NO IMAGES - FOOD ICONS ONLY + USDA SUGGESTIONS)
  // -------------------------------------------------------------
  Widget _buildTodaysMealsSection() {
    final nutrition = _activeNutrition;
    final loggedMeals = nutrition.loggedMeals;
    final dateKey = _formatDateKey(_selectedDate);

    // Standard daily slots to always present to the user
    final mealSlots = [
      {
        'slot': 'breakfast',
        'label': 'Breakfast',
        'time': '8:30 AM',
        'defaultName': 'Rolled Oats & Berry Whey Bowl',
        'defaultSource': 'USDA FoodData',
        'defaultCal': 380,
        'defaultP': 26.0,
        'defaultC': 52.0,
        'defaultF': 6.0,
        'category': 'Grains & Oats',
      },
      {
        'slot': 'lunch',
        'label': 'Lunch',
        'time': '1:00 PM',
        'defaultName': 'Grilled Chicken Breast & Brown Rice',
        'defaultSource': 'USDA FoodData',
        'defaultCal': 520,
        'defaultP': 44.0,
        'defaultC': 58.0,
        'defaultF': 9.0,
        'category': 'Poultry & Meat',
      },
      {
        'slot': 'snack',
        'label': 'Snack',
        'time': '4:30 PM',
        'defaultName': 'Greek Yogurt with Mixed Almonds',
        'defaultSource': 'USDA FoodData',
        'defaultCal': 210,
        'defaultP': 18.0,
        'defaultC': 12.0,
        'defaultF': 10.0,
        'category': 'Dairy & Eggs',
      },
      {
        'slot': 'dinner',
        'label': 'Dinner',
        'time': '8:00 PM',
        'defaultName': 'Steamed Salmon Fillet & Steamed Broccoli',
        'defaultSource': 'USDA FoodData',
        'defaultCal': 480,
        'defaultP': 42.0,
        'defaultC': 14.0,
        'defaultF': 18.0,
        'category': 'Seafood',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSameDay(_selectedDate, DateTime.now()) ? "Today's Meals" : "Meals Logged",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${loggedMeals.length} logged",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),

              // + Log Meal Button
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LogMealScreen(targetDate: dateKey)),
                  );
                  _selectDate(_selectedDate);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Log Meal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
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
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: mealSlots.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final slot = mealSlots[index];
              final slotKey = slot['slot'] as String;
              final slotLabel = slot['label'] as String;
              final slotTime = slot['time'] as String;

              // Check if user already logged meal(s) for this slot
              final matchingLogged = loggedMeals
                  .where((m) => m.mealType.toLowerCase() == slotKey)
                  .toList();
              final isLogged = matchingLogged.isNotEmpty;
              final activeLogged = isLogged ? matchingLogged.last : null;

              final foodName = isLogged
                  ? activeLogged!.name
                  : (slot['defaultName'] as String);
              final calories = isLogged
                  ? activeLogged!.calories
                  : (slot['defaultCal'] as int);
              final protein = isLogged
                  ? activeLogged!.protein
                  : (slot['defaultP'] as double);
              final category = isLogged
                  ? activeLogged!.category
                  : (slot['category'] as String);

              final iconData = _getMealCategoryIcon(category, foodName);
              final iconColor = _getMealCategoryColor(category, foodName);

              return Container(
                width: 195,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isLogged ? const Color(0xFF86EFAC) : const Color(0xFFF1F5F9),
                    width: isLogged ? 1.8 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLogged
                          ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                          : const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Slot Label & Icon Badge (STRICTLY NO IMAGES - FOOD ICON ONLY)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Thematic Food Icon Container
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(iconData, color: iconColor, size: 22),
                          ),
                        ),
                        // Slot Pill & Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              slotLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              slotTime,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Middle: Food Name & Calories / Source Pill
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$calories kcal",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${protein.toStringAsFixed(0)}g P",
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

                    // Bottom Action: Quick Log / Logged State with Delete Option
                    if (isLogged)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '✓ Logged',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await UserNutritionService.instance.deleteMeal(
                                activeLogged!.id,
                                date: dateKey,
                              );
                              _selectDate(_selectedDate);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          // 1-tap quick add of USDA suggestion
                          await UserNutritionService.instance.logMeal(
                            mealType: slotKey,
                            name: foodName,
                            category: category,
                            calories: calories,
                            protein: protein,
                            carbs: (slot['defaultC'] as num).toDouble(),
                            fat: (slot['defaultF'] as num).toDouble(),
                            quantity: 1.0,
                            servingSize: '1 serving',
                            source: slot['defaultSource'] as String,
                            date: dateKey,
                          );
                          _selectDate(_selectedDate);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logged $foodName (+ $calories kcal)!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '+ Quick Add',
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
  // 05. NUTRITION INSIGHTS & AI COACH 🧠
  // -------------------------------------------------------------
  Widget _buildNutritionInsightsSection() {
    final insights = [
      {'title': 'World Protein Day', 'subtitle': 'Choose wisely', 'image': 'assets/images/insight_1.png'},
      {'title': 'Choose Wisely', 'subtitle': 'Nutritious choices', 'image': 'assets/images/insight_2.png'},
      {'title': 'Eat Right', 'subtitle': 'Feel Bright', 'image': 'assets/images/insight_3.png'},
      {'title': 'Daily Balance', 'subtitle': 'Find your rhythm', 'image': 'assets/images/insight_4.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Your Nutrition Insights 🧠',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2x2 Grid of 3:4 Image Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 3 / 4,
            ),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final insight = insights[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(insight['image']!),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.4, 0.65, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        insight['subtitle']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Glowing AI Coach Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0FDF4),
                  Color(0xFFDCFCE7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("💡", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      "AI Coach Recommendation",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "“Your protein intake is slightly low today. Add a high-protein snack after your evening workout.”",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Improve My Nutrition →",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 06. NUTRIENT BREAKDOWN
  // -------------------------------------------------------------
  Widget _buildNutrientBreakdownSection() {
    final nutrients = [
      {'name': 'Fiber', 'val': '25 / 30g', 'percent': 0.83, 'color': const Color(0xFF16A34A)},
      {'name': 'Vitamin C', 'val': '80 / 90mg', 'percent': 0.89, 'color': const Color(0xFFF59E0B)},
      {'name': 'Calcium', 'val': '600 / 1000mg', 'percent': 0.60, 'color': const Color(0xFF3B82F6)},
      {'name': 'Iron', 'val': '12 / 18mg', 'percent': 0.67, 'color': const Color(0xFFEF4444)},
      {'name': 'Sugar', 'val': '24 / 40g', 'percent': 0.60, 'color': const Color(0xFF8B5CF6)},
      {'name': 'Sodium', 'val': '1200 / 2300mg', 'percent': 0.52, 'color': const Color(0xFF06B6D4)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Micro Nutrients Breakdown',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nutrients.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                final nut = nutrients[index];
                final percent = nut['percent'] as double;
                final color = nut['color'] as Color;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nut['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "${(percent * 100).toInt()}%",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 3.5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 07. HEALTHY PICKS FOR YOU 🥑
  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // 07. HEALTHY PICKS FOR YOU 🥑 (LIVE FREE API RECIPES)
  // -------------------------------------------------------------
  Widget _buildHealthyPicksCarouselSection() {
    final liveRecipes = UserNutritionService.instance.dailyFeaturedRecipes;

    // Fallback if still fetching
    final defaultPicks = [
      {
        'title': 'Avocado Toast & Boiled Egg',
        'calories': 320,
        'protein': 16.0,
        'carbs': 24.0,
        'fat': 18.0,
        'imageUrl': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=400&auto=format&fit=crop',
      },
      {
        'title': 'Berry Acai & Protein Shake',
        'calories': 260,
        'protein': 24.0,
        'carbs': 28.0,
        'fat': 4.0,
        'imageUrl': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=400&auto=format&fit=crop',
      },
      {
        'title': 'Quinoa & Grilled Paneer Bowl',
        'calories': 380,
        'protein': 22.0,
        'carbs': 42.0,
        'fat': 12.0,
        'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
      },
      {
        'title': 'Greek Yogurt & Roasted Walnuts',
        'calories': 280,
        'protein': 20.0,
        'carbs': 14.0,
        'fat': 16.0,
        'imageUrl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=400&auto=format&fit=crop',
      },
    ];

    final displayList = liveRecipes.isNotEmpty
        ? liveRecipes.take(6).map((r) => {
            'title': r['title'] ?? 'Healthy Dish',
            'calories': int.tryParse(r['calories']?.toString() ?? '300') ?? 300,
            'protein': double.tryParse(r['protein']?.toString() ?? '20') ?? 20.0,
            'carbs': double.tryParse(r['carbs']?.toString() ?? '30') ?? 30.0,
            'fat': double.tryParse(r['fat']?.toString() ?? '10') ?? 10.0,
            'imageUrl': (r['imageUrl'] ?? '').toString().isNotEmpty
                ? r['imageUrl']
                : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop',
          }).toList()
        : defaultPicks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Healthy Picks For You 🥑',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogMealScreen()),
                  );
                },
                child: Text(
                  'Explore All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 185,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final pick = displayList[index];
              final title = pick['title'] as String;
              final cal = pick['calories'] as int;
              final p = pick['protein'] as double;
              final c = pick['carbs'] as double;
              final f = pick['fat'] as double;
              final img = pick['imageUrl'] as String;

              return Container(
                width: 165,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      img,
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 95,
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(Icons.restaurant_rounded, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$cal kcal",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  UserNutritionService.instance.logMeal(
                                    mealType: 'lunch',
                                    name: title,
                                    category: 'Healthy Picks',
                                    calories: cal,
                                    protein: p,
                                    carbs: c,
                                    fat: f,
                                    quantity: 1.0,
                                    servingSize: '1 serving',
                                    source: 'Healthy Picks',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Logged $title (+ $cal kcal)!'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: const Color(0xFF16A34A),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDCFCE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF16A34A)),
                                ),
                              ),
                            ],
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
      ],
    );
  }

  // -------------------------------------------------------------
  // 08. RECIPES & FOOD DISCOVERY 🍽️ (CACHED 24H FROM 100% FREE APIS)
  // -------------------------------------------------------------
  Widget _buildRecipesDiscoverySection() {
    final categories = ['All', 'High Protein', 'Low Carb', 'Quick Meals', 'Post Workout'];
    final liveRecipes = UserNutritionService.instance.dailyFeaturedRecipes;

    // Filter based on active category tab
    List<Map<String, dynamic>> filteredList = List<Map<String, dynamic>>.from(liveRecipes);
    if (_selectedRecipeCategory == 1) {
      // High Protein >= 25g
      filteredList = liveRecipes.where((r) {
        final p = num.tryParse(r['protein']?.toString() ?? '0') ?? 0;
        return p >= 25;
      }).toList();
    } else if (_selectedRecipeCategory == 2) {
      // Low Carb <= 30g
      filteredList = liveRecipes.where((r) {
        final c = num.tryParse(r['carbs']?.toString() ?? '0') ?? 0;
        return c <= 30;
      }).toList();
    } else if (_selectedRecipeCategory == 3) {
      // Quick Meals
      filteredList = liveRecipes.where((r) {
        final time = (r['time'] ?? '').toString();
        return time.contains('10') || time.contains('15') || time.contains('20');
      }).toList();
    } else if (_selectedRecipeCategory == 4) {
      // Post Workout >= 20g protein
      filteredList = liveRecipes.where((r) {
        final p = num.tryParse(r['protein']?.toString() ?? '0') ?? 0;
        return p >= 20;
      }).toList();
    }

    if (filteredList.isEmpty && liveRecipes.isNotEmpty) {
      filteredList = liveRecipes;
    }

    // Default fallback if loading
    final displayRecipes = filteredList.isNotEmpty
        ? filteredList
        : [
            {
              'title': 'High Protein Paneer Bowl',
              'meta': '32g Protein • 420 kcal',
              'calories': 420,
              'protein': 32.0,
              'carbs': 28.0,
              'fat': 18.0,
              'time': '15 min',
              'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop',
            },
            {
              'title': 'Salmon & Quinoa Power Bowl',
              'meta': '38g Protein • 480 kcal',
              'calories': 480,
              'protein': 38.0,
              'carbs': 35.0,
              'fat': 16.0,
              'time': '20 min',
              'imageUrl': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=400&auto=format&fit=crop',
            },
            {
              'title': 'Tofu & Edamame Veggie Stir Fry',
              'meta': '26g Protein • 340 kcal',
              'calories': 340,
              'protein': 26.0,
              'carbs': 30.0,
              'fat': 10.0,
              'time': '12 min',
              'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore Healthy Recipes 🍽️',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Daily Pick",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogMealScreen()),
                  );
                },
                child: Text(
                  'All Recipes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Category Filter Chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSel = _selectedRecipeCategory == index;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRecipeCategory = index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF16A34A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    categories[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isSel ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Daily Recipe Carousel (Cached 24h in MongoDB)
        SizedBox(
          height: 205,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayRecipes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final rec = displayRecipes[index];
              final title = (rec['title'] ?? 'Healthy Dish').toString();
              final cal = int.tryParse(rec['calories']?.toString() ?? '350') ?? 350;
              final p = double.tryParse(rec['protein']?.toString() ?? '25') ?? 25.0;
              final c = double.tryParse(rec['carbs']?.toString() ?? '30') ?? 30.0;
              final f = double.tryParse(rec['fat']?.toString() ?? '10') ?? 10.0;
              final time = (rec['time'] ?? '15 min').toString();
              final img = (rec['imageUrl'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop').toString();

              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Show bottom sheet with details and log button
                  _showRecipeDetailSheet(title, cal, p, c, f, time, img);
                },
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            img,
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 110,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(Icons.restaurant_rounded, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded, color: Colors.white, size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    time,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${p.toStringAsFixed(0)}g P • $cal kcal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "+ Log",
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

  void _showRecipeDetailSheet(
    String title,
    int cal,
    double p,
    double c,
    double f,
    String time,
    String img,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(22),
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
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  img,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.restaurant_rounded, size: 36, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Ready in $time • 100% Free Recipe API",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              // Macro Pills
              Row(
                children: [
                  Expanded(
                    child: _buildRecipeMacroBadge("Calories", "$cal", "kcal", const Color(0xFFEC4899)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRecipeMacroBadge("Protein", "${p.toStringAsFixed(0)}g", "muscle", const Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRecipeMacroBadge("Carbs", "${c.toStringAsFixed(0)}g", "energy", const Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRecipeMacroBadge("Fats", "${f.toStringAsFixed(0)}g", "healthy", const Color(0xFFF59E0B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  UserNutritionService.instance.logMeal(
                    mealType: 'dinner',
                    name: title,
                    category: 'Explore Recipes',
                    calories: cal,
                    protein: p,
                    carbs: c,
                    fat: f,
                    quantity: 1.0,
                    servingSize: '1 serving',
                    source: 'Free Recipe API',
                  );
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Logged $title (+ $cal kcal)!'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "+ Log This Recipe to Today's Meals",
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
      },
    );
  }

  Widget _buildRecipeMacroBadge(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 10. NUTRITION PROGRESS & 7-DAY GRAPH 📈
  // -------------------------------------------------------------
  Widget _buildNutritionProgressGraphSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 14,
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
                  '7-Day Nutrition Score',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Avg 92 / 100",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7-Day Animated Curve
            SizedBox(
              height: 90,
              width: double.infinity,
              child: CustomPaint(
                painter: _NutritionProgressChartPainter(),
              ),
            ),
            const SizedBox(height: 10),

            // Days Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("M", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("T", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("W", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("T", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("F", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("S", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("S", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom 3 Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressMetricColumn("Avg Calories", "1,940 kcal"),
                _buildProgressMetricColumn("Avg Protein", "112g"),
                _buildProgressMetricColumn("Consistency", "86%"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 11. NUTRITION STREAK 🔥
  // -------------------------------------------------------------
  Widget _buildNutritionStreakSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: const Text("🔥", style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "7-Day Nutrition Streak! 🔥",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Keep logging your meals to reach your 10-day streak reward.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
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

  // -------------------------------------------------------------
  // 12. BOTTOM CTA 🚀
  // -------------------------------------------------------------
  Widget _buildBottomCTASection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF16A34A),
              Color(0xFF15803D),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ready to eat better?",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Build a personalized meal plan tailored to your body goal.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Create Plan →",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Custom Ring Painter for Calorie Gauge
// -------------------------------------------------------------
class _CalorieRingPainter extends CustomPainter {
  final double progress;
  _CalorieRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track Paint
    final trackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active Progress Paint
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// -------------------------------------------------------------
// Custom 7-Day Curve Chart Painter
// -------------------------------------------------------------
class _NutritionProgressChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.16, size.height * 0.65),
      Offset(size.width * 0.33, size.height * 0.5),
      Offset(size.width * 0.50, size.height * 0.3),
      Offset(size.width * 0.66, size.height * 0.25),
      Offset(size.width * 0.83, size.height * 0.1),
      Offset(size.width, size.height * 0.2),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset((p0.dx + p1.dx) / 2, p0.dy);
      final ctrl2 = Offset((p0.dx + p1.dx) / 2, p1.dy);
      path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Draw End Circle
    final endPoint = points.last;
    final dotPaint = Paint()..color = const Color(0xFF16A34A);
    final innerDot = Paint()..color = Colors.white;
    canvas.drawCircle(endPoint, 6, dotPaint);
    canvas.drawCircle(endPoint, 3, innerDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// TILTING NATURAL WATER CARD (PHYSICS & ACCELEROMETER SENSOR RESPONSIVE)
// ----------------------------------------------------------------------------
class TiltingNaturalWaterCard extends StatefulWidget {
  final int glasses;
  final int targetGlasses;
  final Function(int) onGlassesChanged;

  const TiltingNaturalWaterCard({
    super.key,
    required this.glasses,
    this.targetGlasses = 8,
    required this.onGlassesChanged,
  });

  @override
  State<TiltingNaturalWaterCard> createState() => _TiltingNaturalWaterCardState();
}

class _TiltingNaturalWaterCardState extends State<TiltingNaturalWaterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _tiltX = 0.0;
  double _manualTiltX = 0.0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _listenToAccelerometer();
  }

  void _listenToAccelerometer() {
    try {
      _accelSub = accelerometerEventStream().listen((event) {
        if (!mounted) return;
        setState(() {
          final targetX = (-event.x / 9.8).clamp(-1.0, 1.0);
          _tiltX += (targetX - _tiltX) * 0.15;
        });
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTiltX = (_tiltX.abs() > 0.01) ? _tiltX : _manualTiltX;
    final totalMl = widget.glasses * 250;
    final targetMl = widget.targetGlasses * 250;
    final liters = (totalMl / 1000.0).toStringAsFixed(2);
    final targetLiters = (targetMl / 1000.0).toStringAsFixed(1);
    final fillFraction = (widget.glasses / widget.targetGlasses).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _manualTiltX = (_manualTiltX + details.delta.dx * 0.01).clamp(-1.0, 1.0);
          });
        },
        onPanEnd: (_) {
          Timer.periodic(const Duration(milliseconds: 16), (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            if (_manualTiltX.abs() < 0.02) {
              setState(() => _manualTiltX = 0);
              timer.cancel();
            } else {
              setState(() => _manualTiltX *= 0.85);
            }
          });
        },
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Liquid Custom Paint Layer
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: NaturalWaterLiquidPainter(
                      fillFraction: fillFraction,
                      wavePhase: _waveController.value * 2 * math.pi,
                      tiltAngle: effectiveTiltX * 0.35,
                    ),
                  );
                },
              ),

              // Foreground Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.water_drop_rounded, color: Color(0xFF38BDF8), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hydration Tracker',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Natural Liquid • Tilt Phone 📱',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '$liters L / $targetLiters L',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Middle: Glasses count & controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${widget.glasses}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  ' / ${widget.targetGlasses} glasses',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${(fillFraction * 100).toInt()}% Daily Hydration Goal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFBAE6FD),
                              ),
                            ),
                          ],
                        ),

                        // - / + Buttons
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                final newG = (widget.glasses - 1).clamp(0, 16);
                                widget.onGlassesChanged(newG);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.remove_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                final newG = (widget.glasses + 1).clamp(0, 16);
                                widget.onGlassesChanged(newG);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom: Glass Chips Bar
                    Row(
                      children: List.generate(widget.targetGlasses, (index) {
                        final isFilled = index < widget.glasses;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                final newG = (widget.glasses == index + 1) ? index : index + 1;
                                widget.onGlassesChanged(newG);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isFilled
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isFilled
                                        ? const Color(0xFF7DD3FC)
                                        : Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.water_drop_rounded,
                                    size: 14,
                                    color: isFilled ? Colors.white : Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
}

class NaturalWaterLiquidPainter extends CustomPainter {
  final double fillFraction;
  final double wavePhase;
  final double tiltAngle;

  NaturalWaterLiquidPainter({
    required this.fillFraction,
    required this.wavePhase,
    required this.tiltAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillFraction <= 0.001) return;

    final width = size.width;
    final height = size.height;
    final targetY = height * (1.0 - (fillFraction * 0.85));

    final paintBack = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final paintFront = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.85),
          const Color(0xFF0284C7).withValues(alpha: 0.95),
          const Color(0xFF075985),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    final paintFoam = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pathBack = Path();
    final pathFront = Path();
    final cx = width / 2;
    final cy = targetY;

    pathBack.moveTo(0, height);
    pathFront.moveTo(0, height);

    for (double x = 0; x <= width; x += 3) {
      final relX = x - cx;
      final wave1 = math.sin((x / width * 4 * math.pi) + wavePhase) * 6;
      final wave2 = math.cos((x / width * 3 * math.pi) + wavePhase * 1.3) * 5;
      final tiltOffsetY = relX * math.tan(tiltAngle);

      final yBack = (cy + wave1 + tiltOffsetY).clamp(0.0, height);
      final yFront = (cy + wave2 + tiltOffsetY).clamp(0.0, height);

      if (x == 0) {
        pathBack.lineTo(0, yBack);
        pathFront.lineTo(0, yFront);
      } else {
        pathBack.lineTo(x, yBack);
        pathFront.lineTo(x, yFront);
      }
    }

    pathBack.lineTo(width, height);
    pathBack.lineTo(0, height);
    pathBack.close();

    pathFront.lineTo(width, height);
    pathFront.lineTo(0, height);
    pathFront.close();

    canvas.drawPath(pathBack, paintBack);
    canvas.drawPath(pathFront, paintFront);
    canvas.drawPath(pathFront, paintFoam);

    final rand = math.Random(42);
    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (int i = 0; i < 8; i++) {
      final bx = (rand.nextDouble() * width);
      final speed = 0.5 + rand.nextDouble() * 0.5;
      final offset = (wavePhase * 20 * speed + i * 35) % (height - targetY);
      final by = height - offset;

      if (by > targetY + 10 && by < height - 10) {
        final radius = 2.0 + rand.nextDouble() * 3.0;
        canvas.drawCircle(Offset(bx, by), radius, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NaturalWaterLiquidPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.tiltAngle != tiltAngle;
  }
}

