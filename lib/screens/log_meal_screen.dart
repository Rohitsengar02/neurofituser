import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_nutrition_service.dart';

class LogMealScreen extends StatefulWidget {
  final String? initialMealType;
  final String? targetDate;

  const LogMealScreen({super.key, this.initialMealType, this.targetDate});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  String _selectedCategory = 'All';
  String _activeMealSlot = 'breakfast';

  final List<String> _categories = [
    'All',
    'USDA Only',
    'High Protein',
    'Poultry & Meat',
    'Seafood',
    'Dairy & Eggs',
    'Grains & Oats',
    'Fruits',
    'Vegetables & Greens',
    'Healthy Snacks',
  ];

  @override
  void initState() {
    super.initState();
    _activeMealSlot = widget.initialMealType ?? 'breakfast';
    _performSearch('healthy');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    String searchCategory = _selectedCategory;
    if (_selectedCategory == 'All' || _selectedCategory == 'USDA Only') {
      searchCategory = 'All';
    }

    final results = await UserNutritionService.instance.searchFoods(
      query,
      category: searchCategory,
    );

    List<Map<String, dynamic>> filtered = results;
    if (_selectedCategory == 'USDA Only') {
      filtered = results
          .where((f) => (f['source'] ?? '').toString().toUpperCase().contains('USDA'))
          .toList();
    } else if (_selectedCategory == 'High Protein') {
      filtered = results.where((f) {
        final p = num.tryParse((f['protein'] ?? 0).toString()) ?? 0;
        return p >= 15;
      }).toList();
    }

    // Strictly ensure USDA meals are placed first in the list
    filtered.sort((a, b) {
      final isUsdaA = (a['source'] ?? '').toString().toUpperCase().contains('USDA');
      final isUsdaB = (b['source'] ?? '').toString().toUpperCase().contains('USDA');
      if (isUsdaA && !isUsdaB) return -1;
      if (!isUsdaA && isUsdaB) return 1;
      return 0;
    });

    if (mounted) {
      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });
    }
  }

  // Returns food icon only (strictly NO image thumbnails as requested)
  IconData _getFoodIcon(Map<String, dynamic> food) {
    final cat = (food['category'] ?? '').toString().toLowerCase();
    final name = (food['name'] ?? food['title'] ?? '').toString().toLowerCase();

    if (name.contains('egg') || cat.contains('egg')) return Icons.egg_alt_rounded;
    if (name.contains('chicken') || name.contains('turkey') || cat.contains('poultry')) return Icons.lunch_dining_rounded;
    if (name.contains('beef') || name.contains('steak') || name.contains('meat')) return Icons.restaurant_rounded;
    if (name.contains('fish') || name.contains('salmon') || name.contains('tuna') || cat.contains('seafood')) return Icons.set_meal_rounded;
    if (name.contains('milk') || name.contains('yogurt') || name.contains('paneer') || name.contains('cheese') || cat.contains('dairy')) return Icons.local_drink_rounded;
    if (name.contains('oat') || name.contains('bread') || name.contains('rice') || cat.contains('grain')) return Icons.bakery_dining_rounded;
    if (name.contains('apple') || name.contains('banana') || name.contains('berry') || cat.contains('fruit')) return Icons.apple_rounded;
    if (name.contains('salad') || name.contains('spinach') || name.contains('broccoli') || cat.contains('veg')) return Icons.eco_rounded;
    if (name.contains('shake') || name.contains('protein') || name.contains('whey')) return Icons.fitness_center_rounded;
    if (name.contains('coffee') || name.contains('tea') || cat.contains('beverage')) return Icons.local_cafe_rounded;

    return Icons.restaurant_menu_rounded;
  }

  Color _getFoodIconColor(Map<String, dynamic> food) {
    final cat = (food['category'] ?? '').toString().toLowerCase();
    final name = (food['name'] ?? food['title'] ?? '').toString().toLowerCase();

    if (name.contains('fish') || name.contains('salmon') || cat.contains('seafood')) return const Color(0xFF0284C7);
    if (name.contains('chicken') || name.contains('turkey') || cat.contains('poultry') || name.contains('beef')) return const Color(0xFFEA580C);
    if (name.contains('salad') || name.contains('spinach') || cat.contains('veg')) return const Color(0xFF16A34A);
    if (name.contains('egg') || cat.contains('egg') || cat.contains('dairy')) return const Color(0xFFD97706);
    if (name.contains('oat') || cat.contains('grain')) return const Color(0xFFB45309);
    if (name.contains('apple') || name.contains('berry') || cat.contains('fruit')) return const Color(0xFFE11D48);

    return const Color(0xFF6366F1);
  }

  void _openLogMealBottomSheet(Map<String, dynamic> food) {
    HapticFeedback.mediumImpact();
    double quantity = 1.0;
    String selectedSlot = _activeMealSlot;
    final name = (food['name'] ?? food['title'] ?? 'Food Item').toString();
    final source = (food['source'] ?? 'USDA').toString();
    final isUsda = source.toUpperCase().contains('USDA');
    final category = (food['category'] ?? 'General').toString();
    final baseCalories = int.tryParse(food['calories']?.toString() ?? '0') ?? 0;
    final baseProtein = double.tryParse(food['protein']?.toString() ?? '0') ?? 0.0;
    final baseCarbs = double.tryParse(food['carbs']?.toString() ?? '0') ?? 0.0;
    final baseFat = double.tryParse(food['fat']?.toString() ?? '0') ?? 0.0;
    final servingSize = (food['servingSize'] ?? '100g').toString();
    final iconData = _getFoodIcon(food);
    final iconColor = _getFoodIconColor(food);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final calcCal = (baseCalories * quantity).round();
            final calcP = (baseProtein * quantity).toStringAsFixed(1);
            final calcC = (baseCarbs * quantity).toStringAsFixed(1);
            final calcF = (baseFat * quantity).toStringAsFixed(1);

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
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
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header with Icon (NO image)
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                        ),
                        child: Icon(iconData, color: iconColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isUsda) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'USDA VERIFIED',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    category,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Meal Slot Picker
                  Text(
                    'Meal Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSlotChip('Breakfast', 'breakfast', selectedSlot, (s) {
                        setSheetState(() => selectedSlot = s);
                      }),
                      const SizedBox(width: 6),
                      _buildSlotChip('Lunch', 'lunch', selectedSlot, (s) {
                        setSheetState(() => selectedSlot = s);
                      }),
                      const SizedBox(width: 6),
                      _buildSlotChip('Dinner', 'dinner', selectedSlot, (s) {
                        setSheetState(() => selectedSlot = s);
                      }),
                      const SizedBox(width: 6),
                      _buildSlotChip('Snack', 'snack', selectedSlot, (s) {
                        setSheetState(() => selectedSlot = s);
                      }),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Servings / Quantity Slider & Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Serving Size ($servingSize)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      Text(
                        '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)}x Servings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF16A34A),
                      inactiveTrackColor: const Color(0xFFE2E8F0),
                      thumbColor: const Color(0xFF16A34A),
                      overlayColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: quantity,
                      min: 0.5,
                      max: 4.0,
                      divisions: 7,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setSheetState(() => quantity = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Calculated Dynamic Macro Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroPill('Calories', '$calcCal', 'kcal', const Color(0xFF10B981)),
                        _buildMacroPill('Protein', '${calcP}g', 'P', const Color(0xFF6366F1)),
                        _buildMacroPill('Carbs', '${calcC}g', 'C', const Color(0xFFF59E0B)),
                        _buildMacroPill('Fats', '${calcF}g', 'F', const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm & Log Button
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(ctx);

                      await UserNutritionService.instance.logMeal(
                        mealType: selectedSlot,
                        foodName: name,
                        date: widget.targetDate,
                        source: source,
                        category: category,
                        calories: baseCalories,
                        protein: baseProtein,
                        carbs: baseCarbs,
                        fat: baseFat,
                        servingSize: servingSize,
                        quantity: quantity,
                        iconType: _iconNameFromData(iconData),
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Logged $name ($calcCal kcal) to ${selectedSlot.toUpperCase()}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: const Color(0xFF0F172A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Confirm & Log Meal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlotChip(String label, String value, String selected, ValueChanged<String> onSelected) {
    final isSel = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String title, String val, String sub, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  String _iconNameFromData(IconData icon) {
    if (icon == Icons.egg_alt_rounded) return 'egg_alt';
    if (icon == Icons.lunch_dining_rounded) return 'lunch_dining';
    if (icon == Icons.set_meal_rounded) return 'set_meal';
    if (icon == Icons.bakery_dining_rounded) return 'bakery_dining';
    if (icon == Icons.apple_rounded) return 'apple';
    if (icon == Icons.eco_rounded) return 'eco';
    if (icon == Icons.fitness_center_rounded) return 'fitness_center';
    if (icon == Icons.local_cafe_rounded) return 'local_cafe';
    return 'restaurant';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
          ),
        ),
        title: Text(
          'Log Meal & Nutrition',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Search Bar Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search foods (USDA meals shown first)...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _performSearch('healthy');
                              },
                              child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSel = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                          _performSearch(_searchController.text);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF16A34A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Meal Slot Quick Switch Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOGGING FOR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    _buildActiveSlotButton('Breakfast', 'breakfast'),
                    const SizedBox(width: 6),
                    _buildActiveSlotButton('Lunch', 'lunch'),
                    const SizedBox(width: 6),
                    _buildActiveSlotButton('Dinner', 'dinner'),
                    const SizedBox(width: 6),
                    _buildActiveSlotButton('Snack', 'snack'),
                  ],
                ),
              ],
            ),
          ),

          // Search Results Grid List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF16A34A), strokeWidth: 2.5),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            Text(
                              'No meals found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for oats, chicken, eggs, or salmon',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          return _buildFoodItemGridCard(food);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSlotButton(String label, String slot) {
    final isCurrent = _activeMealSlot == slot;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeMealSlot = slot);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF16A34A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: isCurrent ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // Card showing ICON ONLY (NO IMAGES as explicitly requested)
  Widget _buildFoodItemGridCard(Map<String, dynamic> food) {
    final name = (food['name'] ?? food['title'] ?? 'Food').toString();
    final source = (food['source'] ?? '').toString();
    final isUsda = source.toUpperCase().contains('USDA');
    final category = (food['category'] ?? 'General').toString();
    final calories = int.tryParse(food['calories']?.toString() ?? '0') ?? 0;
    final protein = (num.tryParse(food['protein']?.toString() ?? '0') ?? 0).toDouble();
    final iconData = _getFoodIcon(food);
    final iconColor = _getFoodIconColor(food);

    return GestureDetector(
      onTap: () => _openLogMealBottomSheet(food),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUsda ? const Color(0xFFBBF7D0) : const Color(0xFFF1F5F9),
            width: isUsda ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Food Category Icon (NO IMAGE) + USDA Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                if (isUsda)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'USDA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Food Title
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Calorie & Protein metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$calories kcal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${protein.toStringAsFixed(0)}g Protein',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
