import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_nutrition_service.dart';
import 'log_meal_screen.dart';

class DateNutritionDetailScreen extends StatefulWidget {
  final DateTime initialDate;

  const DateNutritionDetailScreen({
    super.key,
    required this.initialDate,
  });

  @override
  State<DateNutritionDetailScreen> createState() => _DateNutritionDetailScreenState();
}

class _DateNutritionDetailScreenState extends State<DateNutritionDetailScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  bool _isLoading = false;
  UserDailyNutritionModel? _dateNutrition;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    UserNutritionService.instance.addListener(_onServiceUpdated);
    _loadDataForSelectedDate();
  }

  @override
  void dispose() {
    UserNutritionService.instance.removeListener(_onServiceUpdated);
    _ringController.dispose();
    super.dispose();
  }

  void _onServiceUpdated() {
    if (!mounted) return;
    final dateKey = _formatDateKey(_selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    if (isToday) {
      setState(() {
        _dateNutrition = UserNutritionService.instance.currentNutrition;
      });
    } else {
      final cached = UserNutritionService.instance.fetchNutritionForDate(dateKey);
      cached.then((model) {
        if (mounted && _formatDateKey(_selectedDate) == dateKey) {
          setState(() {
            _dateNutrition = model;
          });
        }
      });
    }
  }

  String _formatDateKey(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadDataForSelectedDate() async {
    setState(() => _isLoading = true);
    final dateKey = _formatDateKey(_selectedDate);

    try {
      final model = await UserNutritionService.instance.fetchNutritionForDate(dateKey);
      if (mounted) {
        setState(() {
          _dateNutrition = model;
          _isLoading = false;
        });
        _ringController.reset();
        _ringController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeDateByDays(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadDataForSelectedDate();
  }

  Future<void> _pickDate() async {
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

    if (picked != null && !_isSameDay(picked, _selectedDate)) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDataForSelectedDate();
    }
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
    if (n.contains('oat') || n.contains('bread') || c.contains('grain')) return const Color(0xFFEAB308);
    if (n.contains('shake') || n.contains('protein')) return const Color(0xFF8B5CF6);
    return const Color(0xFF10B981);
  }

  String _formatFriendlyDate(DateTime dt) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isPast = _selectedDate.isBefore(DateTime.now()) && !isToday;
    final dateKey = _formatDateKey(_selectedDate);

    final nutrition = _dateNutrition ??
        (isToday
            ? UserNutritionService.instance.currentNutrition
            : UserDailyNutritionModel.empty());

    final consumedCal = nutrition.consumedCalories;
    final targetCal = nutrition.targetCalories > 0 ? nutrition.targetCalories : 2400;
    final calFraction = (consumedCal / targetCal).clamp(0.0, 1.0);
    final remainingCal = (targetCal - consumedCal).clamp(0, 99999);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Summary',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Text(
              _formatDateKey(_selectedDate),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF10B981)),
            ),
            onPressed: _pickDate,
            tooltip: 'Pick Date',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : RefreshIndicator(
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF1E293B),
              onRefresh: _loadDataForSelectedDate,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: [
                  // 1. Interactive Date Navigator Banner
                  _buildDateNavigatorBanner(isToday, isPast),

                  const SizedBox(height: 18),

                  // 2. Hero Calorie Ring & Metric Card
                  _buildCalorieHeroCard(nutrition, calFraction, remainingCal, targetCal),

                  const SizedBox(height: 20),

                  // 3. Macronutrient Targets & Distribution
                  _buildMacroCards(nutrition),

                  const SizedBox(height: 20),

                  // 4. Hydration & Water Intake Card
                  _buildHydrationCard(nutrition, dateKey),

                  const SizedBox(height: 24),

                  // 5. Meals Logged on This Date
                  _buildMealsSection(nutrition, dateKey),

                  const SizedBox(height: 36),
                ],
              ),
            ),
            ),
    );
  }

  // --------------------------------------------------------------------------
  // 1. DATE NAVIGATOR BANNER
  // --------------------------------------------------------------------------
  Widget _buildDateNavigatorBanner(bool isToday, bool isPast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _changeDateByDays(-1),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatFriendlyDate(_selectedDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF94A3B8), size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : (isPast
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFF6366F1).withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isToday
                          ? 'TODAY'
                          : (isPast ? 'PAST LOG' : 'UPCOMING'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isToday
                            ? const Color(0xFF10B981)
                            : (isPast ? const Color(0xFF94A3B8) : const Color(0xFF818CF8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _changeDateByDays(1),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. HERO CALORIE RING & METRICS
  // --------------------------------------------------------------------------
  Widget _buildCalorieHeroCard(
    UserDailyNutritionModel nutrition,
    double calFraction,
    int remainingCal,
    int targetCal,
  ) {
    final isGoalReached = nutrition.consumedCalories >= targetCal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF161F36),
            const Color(0xFF111827),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Energy & Calories',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGoalReached
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGoalReached
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  isGoalReached ? 'GOAL MET 🔥' : '$remainingCal KCAL LEFT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isGoalReached ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ring + Big Numbers
          Row(
            children: [
              // Animated Circular Ring
              AnimatedBuilder(
                animation: _ringController,
                builder: (context, _) {
                  final animatedFraction = calFraction * _ringController.value;
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background track
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 11,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        // Active Progress
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: animatedFraction,
                            strokeWidth: 11,
                            strokeCap: StrokeCap.round,
                            color: isGoalReached
                                ? const Color(0xFF10B981)
                                : const Color(0xFF06B6D4),
                          ),
                        ),
                        // Inner Text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(animatedFraction * 100).toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'of daily goal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 24),

              // Breakdown Numbers Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${nutrition.consumedCalories}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kcal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSmallStat('Target', '$targetCal kcal'),
                        _buildSmallStat('Meals', '${nutrition.meals.length} logged'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 3. MACRONUTRIENT BARS
  // --------------------------------------------------------------------------
  Widget _buildMacroCards(UserDailyNutritionModel nutrition) {
    final pConsumed = nutrition.consumedProtein;
    final pTarget = nutrition.targetProtein > 0 ? nutrition.targetProtein : 140;
    final cConsumed = nutrition.consumedCarbs;
    final cTarget = nutrition.targetCarbs > 0 ? nutrition.targetCarbs : 220;
    final fConsumed = nutrition.consumedFat;
    final fTarget = nutrition.targetFat > 0 ? nutrition.targetFat : 60;
    final fibConsumed = nutrition.consumedFiber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Macronutrients',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Daily Targets',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildMacroProgressBar(
            label: 'Protein',
            consumed: pConsumed,
            target: pTarget.toDouble(),
            unit: 'g',
            color: const Color(0xFF10B981),
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 14),

          _buildMacroProgressBar(
            label: 'Carbohydrates',
            consumed: cConsumed,
            target: cTarget.toDouble(),
            unit: 'g',
            color: const Color(0xFFF59E0B),
            icon: Icons.bakery_dining_rounded,
          ),
          const SizedBox(height: 14),

          _buildMacroProgressBar(
            label: 'Fats',
            consumed: fConsumed,
            target: fTarget.toDouble(),
            unit: 'g',
            color: const Color(0xFF3B82F6),
            icon: Icons.opacity_rounded,
          ),
          const SizedBox(height: 14),

          _buildMacroProgressBar(
            label: 'Dietary Fiber',
            consumed: fibConsumed,
            target: 30.0,
            unit: 'g',
            color: const Color(0xFF8B5CF6),
            icon: Icons.grass_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressBar({
    required String label,
    required double consumed,
    required double target,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    final frac = (target > 0 ? consumed / target : 0.0).clamp(0.0, 1.0);
    final pct = (frac * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
            Text(
              '${consumed.toStringAsFixed(1)} / ${target.toInt()} $unit ($pct%)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                color: Colors.white.withOpacity(0.06),
              ),
              FractionallySizedBox(
                widthFactor: frac,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 4. HYDRATION CARD
  // --------------------------------------------------------------------------
  Widget _buildHydrationCard(UserDailyNutritionModel nutrition, String dateKey) {
    final glasses = nutrition.waterGlasses;
    final targetGlasses = nutrition.waterTargetGlasses > 0 ? nutrition.waterTargetGlasses : 8;
    final ml = glasses * 250;
    final targetMl = targetGlasses * 250;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: Color(0xFF38BDF8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration Tracker',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$ml / $targetMl ml ($glasses of $targetGlasses glasses)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF94A3B8), size: 24),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final newG = (glasses - 1).clamp(0, 16);
                      UserNutritionService.instance.updateWater(glasses: newG, date: dateKey);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF38BDF8), size: 26),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final newG = (glasses + 1).clamp(0, 16);
                      UserNutritionService.instance.updateWater(glasses: newG, date: dateKey);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual glass icons row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(targetGlasses, (i) {
              final isFilled = i < glasses;
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final newG = (glasses == i + 1) ? i : (i + 1);
                  UserNutritionService.instance.updateWater(glasses: newG, date: dateKey);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? const Color(0xFF0284C7).withOpacity(0.25)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFilled
                          ? const Color(0xFF38BDF8).withOpacity(0.6)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.local_drink_rounded,
                    size: 20,
                    color: isFilled ? const Color(0xFF38BDF8) : const Color(0xFF475569),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5. MEALS LOGGED SECTION
  // --------------------------------------------------------------------------
  Widget _buildMealsSection(UserDailyNutritionModel nutrition, String dateKey) {
    final meals = nutrition.meals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Logged Meals (${meals.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogMealScreen(targetDate: dateKey),
                  ),
                );
                if (res == true) {
                  _loadDataForSelectedDate();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Log Meal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (meals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, size: 36, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Text(
                  'No meals logged on this day',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "+ Log Meal" above to record what was consumed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final meal = meals[index];
              final catColor = _getMealCategoryColor(meal.category, meal.foodName);
              final iconData = _getMealCategoryIcon(meal.category, meal.foodName);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    // Category Food Icon (Strictly icon, NO network images!)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: catColor.withOpacity(0.3)),
                      ),
                      child: Icon(iconData, color: catColor, size: 24),
                    ),
                    const SizedBox(width: 14),

                    // Meal Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  meal.mealType.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              if (meal.time.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  meal.time,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meal.foodName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Macro Pills
                          Row(
                            children: [
                              _buildMacroPill('${meal.calories} kcal', Colors.white),
                              const SizedBox(width: 6),
                              _buildMacroPill('${meal.protein.toInt()}g P', const Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              _buildMacroPill('${meal.carbs.toInt()}g C', const Color(0xFFF59E0B)),
                              const SizedBox(width: 6),
                              _buildMacroPill('${meal.fat.toInt()}g F', const Color(0xFF38BDF8)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        UserNutritionService.instance.deleteMeal(meal.mealId, date: dateKey);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMacroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
