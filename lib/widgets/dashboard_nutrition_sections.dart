import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Interactive states
  int _waterGlasses = 6;
  final Set<int> _loggedMeals = {0, 1}; // Breakfast & Lunch logged
  int _selectedRecipeCategory = 0;

  @override
  void initState() {
    super.initState();

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

    // Simulate skeleton loading -> Stagger Blur Reveal
    Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _staggerController.forward();
        _calorieRingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _staggerController.dispose();
    _calorieRingController.dispose();
    super.dispose();
  }

  void _toggleWaterGlass(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_waterGlasses == index + 1) {
        _waterGlasses = index;
      } else {
        _waterGlasses = index + 1;
      }
    });
  }

  void _toggleMeal(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_loggedMeals.contains(index)) {
        _loggedMeals.remove(index);
      } else {
        _loggedMeals.add(index);
      }
    });
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
        const SizedBox(height: 16),

        // 01. Today's Nutrition — Hero Section (Stagger 0.0 -> 0.20)
        _buildStaggeredSection(
          startInterval: 0.0,
          endInterval: 0.20,
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

        // 07. Healthy Picks For You 🥑 (Stagger 0.50 -> 0.68)
        _buildStaggeredSection(
          startInterval: 0.50,
          endInterval: 0.68,
          child: _buildHealthyPicksCarouselSection(),
        ),

        const SizedBox(height: 26),

        // 08. Smart Meal Plans (Stagger 0.58 -> 0.76)
        _buildStaggeredSection(
          startInterval: 0.58,
          endInterval: 0.76,
          child: _buildSmartMealPlansSection(),
        ),

        const SizedBox(height: 26),

        // 09. Recipes & Food Discovery 🍽️ (Stagger 0.66 -> 0.84)
        _buildStaggeredSection(
          startInterval: 0.66,
          endInterval: 0.84,
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
            const SizedBox(height: 16),

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
  // 01. TODAY'S NUTRITION — HERO SECTION (ZERO OVERFLOW)
  // -------------------------------------------------------------
  Widget _buildTodayNutritionHeroSection() {
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
            // Top Header: Date & Edit Goal Pill
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
                              "Today's Nutrition",
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
                        "Wednesday, 27 Aug",
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
                GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 12, color: Color(0xFF475569)),
                        const SizedBox(width: 4),
                        Text(
                          "Goal: 2,200",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
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
                      final progress = (1680 / 2200) * CurvedAnimation(
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
                                "1,680",
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

                // Intake & Burn Side Cards
                Expanded(
                  child: Column(
                    children: [
                      _buildHeroStatPill(
                        icon: Icons.restaurant_rounded,
                        label: "Food Intake",
                        value: "1,680 kcal",
                        color: const Color(0xFF16A34A),
                        bg: const Color(0xFFDCFCE7),
                      ),
                      const SizedBox(height: 8),
                      _buildHeroStatPill(
                        icon: Icons.local_fire_department_rounded,
                        label: "Exercise Burn",
                        value: "420 kcal",
                        color: const Color(0xFFEA580C),
                        bg: const Color(0xFFFFF7ED),
                      ),
                      const SizedBox(height: 8),
                      _buildHeroStatPill(
                        icon: Icons.hourglass_bottom_rounded,
                        label: "Remaining",
                        value: "520 kcal",
                        color: const Color(0xFF2563EB),
                        bg: const Color(0xFFDBEAFE),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom: Macro Progress Bars (Protein, Carbs, Fats)
            Row(
              children: [
                Expanded(
                  child: _buildMacroProgressItem(
                    name: "Protein",
                    amount: "120 / 160g",
                    percent: 0.75,
                    color: const Color(0xFF16A34A),
                    icon: "🟢",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroProgressItem(
                    name: "Carbs",
                    amount: "180 / 220g",
                    percent: 0.81,
                    color: const Color(0xFF8B5CF6),
                    icon: "🟣",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroProgressItem(
                    name: "Fats",
                    amount: "60 / 70g",
                    percent: 0.85,
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
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Text(
                      'View Details →',
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
                  Expanded(child: _buildMacroCardWidget("Protein", "120g", "29%", const Color(0xFF16A34A))),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMacroCardWidget("Carbs", "180g", "43%", const Color(0xFF8B5CF6))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildMacroCardWidget("Fats", "60g", "14%", const Color(0xFFF59E0B))),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMacroCardWidget("Calories", "1,680", "Kcal", const Color(0xFFEC4899))),
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
  // 03. WATER INTAKE 💧 (ZERO OVERFLOW, AUTO SCALING)
  // -------------------------------------------------------------
  Widget _buildWaterIntakeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/images/hydration_bg.png'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                blurRadius: 16,
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
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("💧", style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Hydration',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$_waterGlasses / 8 glasses • ${(_waterGlasses * 0.25).toStringAsFixed(1)}L",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 8 Animated Interactive Water Glasses
                Row(
                  children: List.generate(8, (index) {
                    final isFilled = index < _waterGlasses;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: GestureDetector(
                          onTap: () => _toggleWaterGlass(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isFilled ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.15),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(10),
                                top: Radius.circular(4),
                              ),
                              border: Border.all(
                                color: isFilled ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: isFilled
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                isFilled ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                                color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                size: 16,
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
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 04. TODAY'S MEALS CAROUSEL
  // -------------------------------------------------------------
  Widget _buildTodaysMealsSection() {
    final meals = [
      {
        'type': 'Breakfast',
        'calories': '420 kcal',
        'food': 'Oats + berries & whey',
        'time': '8:30 AM',
        'image': 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?q=80&w=400&auto=format&fit=crop',
      },
      {
        'type': 'Lunch',
        'calories': '540 kcal',
        'food': 'Brown rice + chicken & veg',
        'time': '1:00 PM',
        'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop',
      },
      {
        'type': 'Snack',
        'calories': '180 kcal',
        'food': 'Mixed almonds & walnuts',
        'time': '4:30 PM',
        'image': 'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?q=80&w=400&auto=format&fit=crop',
      },
      {
        'type': 'Dinner',
        'calories': '540 kcal',
        'food': 'Grilled salmon & quinoa',
        'time': '8:00 PM',
        'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=400&auto=format&fit=crop',
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
              Text(
                "Today's Meals",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Customize',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 215,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: meals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final meal = meals[index];
              final isLogged = _loggedMeals.contains(index);

              return Container(
                width: 185,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal Image with Time Badge
                    Stack(
                      children: [
                        Image.network(
                          meal['image']!,
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 105,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.restaurant_rounded, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        // Time Pill
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              meal['time']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Meal Details & Log Action
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                meal['type']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                meal['calories']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meal['food']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Log Button
                          GestureDetector(
                            onTap: () => _toggleMeal(index),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isLogged ? const Color(0xFFDCFCE7) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  isLogged ? '✓ Logged' : '+ Add',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isLogged ? const Color(0xFF15803D) : Colors.white,
                                  ),
                                ),
                              ),
                            ),
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
  Widget _buildHealthyPicksCarouselSection() {
    final picks = [
      {
        'name': 'Avocado Toast & Egg',
        'cal': '320 kcal',
        'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=400&auto=format&fit=crop',
      },
      {
        'name': 'Berry Acai Smoothie',
        'cal': '250 kcal',
        'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=400&auto=format&fit=crop',
      },
      {
        'name': 'Quinoa Power Salad',
        'cal': '350 kcal',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
      },
      {
        'name': 'Greek Yogurt Bowl',
        'cal': '280 kcal',
        'image': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=400&auto=format&fit=crop',
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
              Text(
                'Healthy Picks For You 🥑',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Explore All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 175,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: picks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final pick = picks[index];

              return Container(
                width: 155,
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
                      pick['image']!,
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pick['name']!,
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
                                pick['cal']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 12, color: Color(0xFF16A34A)),
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
  // 08. SMART MEAL PLANS
  // -------------------------------------------------------------
  Widget _buildSmartMealPlansSection() {
    final plans = [
      {'title': 'High Protein Muscle', 'calories': '2,200 kcal/day', 'tag': 'Popular', 'color': const Color(0xFF16A34A), 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Weight Loss Shred', 'calories': '1,800 kcal/day', 'tag': 'Deficit', 'color': const Color(0xFFEA580C), 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Clean Bulking Power', 'calories': '2,500 kcal/day', 'tag': 'Surplus', 'color': const Color(0xFF2563EB), 'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Balanced Longevity', 'calories': '2,100 kcal/day', 'tag': 'Maintenance', 'color': const Color(0xFF8B5CF6), 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=400&auto=format&fit=crop'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Meal Plans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),

          Column(
            children: List.generate(plans.length, (index) {
              final plan = plans[index];
              final color = plan['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        plan['image'] as String,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plan['tag'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            plan['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            plan['calories'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 09. RECIPES & FOOD DISCOVERY 🍽️
  // -------------------------------------------------------------
  Widget _buildRecipesDiscoverySection() {
    final categories = ['All', 'High Protein', 'Low Carb', 'Quick Meals', 'Post Workout'];
    final recipes = [
      {'title': 'Paneer Power Bowl', 'meta': '32g Protein • 420 kcal', 'time': '15 min', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Salmon Quinoa Crunch', 'meta': '38g Protein • 480 kcal', 'time': '20 min', 'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Tofu Veggie Stir Fry', 'meta': '26g Protein • 340 kcal', 'time': '12 min', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop'},
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
                'Explore Healthy Recipes 🍽️',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'All Recipes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
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

        SizedBox(
          height: 195,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recipes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final rec = recipes[index];

              return Container(
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
                    Image.network(
                      rec['image']!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rec['meta']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
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
