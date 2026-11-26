import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// -------------------------------------------------------------
// 1. TODAY'S PLAN HERO SECTION (RICH PHOTOGRAPHY & GLOWING RING)
// -------------------------------------------------------------
class TodaysPlanSection extends StatelessWidget {
  const TodaysPlanSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Plan",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
                  children: [
                    Text(
                      'View Plan',
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
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Hero Workout Card with Real Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Top Subtle Ambient Gradient
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDCFCE7).withValues(alpha: 0.45),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Workout Photo with Rounded Border & Flame Badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=400&auto=format&fit=crop',
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 84,
                                height: 84,
                                color: const Color(0xFFF0FDF4),
                                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF16A34A)),
                              ),
                            ),
                          ),
                          // Subtle Dark Gradient on photo bottom
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.35),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Mini Play / Resume icon overlay
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Workout Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "INTERMEDIATE • 45 MIN",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF15803D),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Upper Body Strength",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFEF4444)),
                                const SizedBox(width: 2),
                                Text(
                                  "320 kcal • 4 sets",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right Progress Ring
                      Container(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: 0.75,
                                    strokeWidth: 5,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                                  ),
                                  Center(
                                    child: Text(
                                      "75%",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "3 of 4 Done",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
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
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. NUTRITION SUMMARY CAROUSEL (RICH FOOD IMAGERY & MACRO CARDS)
// -------------------------------------------------------------
class NutritionSummarySection extends StatelessWidget {
  const NutritionSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final macros = [
      _MacroCardData(
        label: "Protein",
        current: "120g",
        target: "160g",
        progress: 120 / 160,
        color: const Color(0xFF16A34A),
        tintColor: const Color(0xFFDCFCE7),
        calorieShare: "480 kcal",
        imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=300&auto=format&fit=crop",
      ),
      _MacroCardData(
        label: "Carbs",
        current: "180g",
        target: "200g",
        progress: 180 / 200,
        color: const Color(0xFF3B82F6),
        tintColor: const Color(0xFFDBEAFE),
        calorieShare: "720 kcal",
        imageUrl: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=300&auto=format&fit=crop",
      ),
      _MacroCardData(
        label: "Fats",
        current: "60g",
        target: "70g",
        progress: 60 / 70,
        color: const Color(0xFFF59E0B),
        tintColor: const Color(0xFFFEF3C7),
        calorieShare: "540 kcal",
        imageUrl: "https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=300&auto=format&fit=crop",
      ),
      _MacroCardData(
        label: "Calories",
        current: "1,680",
        target: "2,000",
        progress: 1680 / 2000,
        color: const Color(0xFFEC4899),
        tintColor: const Color(0xFFFCE7F3),
        calorieShare: "Daily Total",
        imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=300&auto=format&fit=crop",
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Nutrition Summary",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
                  children: [
                    Text(
                      'View Details',
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Carousel of Rich Macro Cards with Food Imagery
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: macros.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final macro = macros[index];

              return Container(
                width: 148,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: DecorationImage(
                    image: NetworkImage(macro.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.42),
                      BlendMode.lighten,
                    ),
                  ),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: macro.color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Seamless White Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            stops: const [0.0, 0.65, 1.0],
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Macro Details
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Row: Macro Pill + Percent
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: macro.tintColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  macro.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: macro.color,
                                  ),
                                ),
                              ),
                              Text(
                                "${(macro.progress * 100).toInt()}%",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: macro.color,
                                ),
                              ),
                            ],
                          ),

                          // Bottom Values & Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    macro.current,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "/${macro.target}",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                macro.calorieShare,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: macro.progress.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor: AlwaysStoppedAnimation<Color>(macro.color),
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
}

class _MacroCardData {
  final String label;
  final String current;
  final String target;
  final double progress;
  final Color color;
  final Color tintColor;
  final String calorieShare;
  final String imageUrl;

  _MacroCardData({
    required this.label,
    required this.current,
    required this.target,
    required this.progress,
    required this.color,
    required this.tintColor,
    required this.calorieShare,
    required this.imageUrl,
  });
}

// -------------------------------------------------------------
// 3. WATER INTAKE SECTION (DYNAMIC INTERACTIVE GLASSES & GLOW)
// -------------------------------------------------------------
class WaterIntakeSection extends StatefulWidget {
  const WaterIntakeSection({super.key});

  @override
  State<WaterIntakeSection> createState() => _WaterIntakeSectionState();
}

class _WaterIntakeSectionState extends State<WaterIntakeSection> {
  int _glassesDrunk = 6;
  static const int _targetGlasses = 8;

  void _addGlass() {
    if (_glassesDrunk < _targetGlasses) {
      HapticFeedback.selectionClick();
      setState(() => _glassesDrunk++);
    }
  }

  void _toggleGlass(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (index < _glassesDrunk) {
        _glassesDrunk = index;
      } else {
        _glassesDrunk = index + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _glassesDrunk / _targetGlasses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF2563EB),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Water Intake",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _addGlass,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 2),
                      Text(
                        'Add 250ml',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Water Container Card with Water Droplets Background
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: const NetworkImage(
                  'https://images.unsplash.com/photo-1559839914-17aae19cec71?q=80&w=600&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.88),
                  BlendMode.lighten,
                ),
              ),
              border: Border.all(color: const Color(0xFFBFDBFE).withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular Progress Ring with Glowing Aqua Center
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6.0,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Interactive Glasses Tracker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: "$_glassesDrunk",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                              children: [
                                TextSpan(
                                  text: " / $_targetGlasses Glasses",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${(_glassesDrunk * 0.25).toStringAsFixed(1)}L / 2.0L",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row of 8 clickable Glasses
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_targetGlasses, (index) {
                          final isFilled = index < _glassesDrunk;

                          return GestureDetector(
                            onTap: () => _toggleGlass(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isFilled ? const Color(0xFF2563EB) : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isFilled ? const Color(0xFF1D4ED8) : const Color(0xFF93C5FD),
                                  width: 1.2,
                                ),
                                boxShadow: isFilled
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.water_drop_rounded,
                                  size: 13,
                                  color: isFilled ? Colors.white : const Color(0xFF93C5FD),
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
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. MIND & MOOD CAROUSEL (ANIMATED WELLNESS & BREATHING CARDS)
// -------------------------------------------------------------
class MindMoodSection extends StatefulWidget {
  const MindMoodSection({super.key});

  @override
  State<MindMoodSection> createState() => _MindMoodSectionState();
}

class _MindMoodSectionState extends State<MindMoodSection> {
  int _selectedMoodIndex = 0; // 0: Good, 1: Energized, 2: Calm, 3: Tired

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '🙂', 'title': 'Good', 'subtitle': "Keep going! You're doing great.", 'color': Color(0xFF7C3AED), 'bg': Color(0xFFF5F3FF)},
    {'emoji': '🤩', 'title': 'Energized', 'subtitle': 'Crush your workout today!', 'color': Color(0xFF16A34A), 'bg': Color(0xFFF0FDF4)},
    {'emoji': '😌', 'title': 'Calm & Zen', 'subtitle': 'Mind is clear and focused.', 'color': Color(0xFF0284C7), 'bg': Color(0xFFF0F9FF)},
    {'emoji': '😴', 'title': 'Low Energy', 'subtitle': 'Take a gentle breath & rest.', 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
  ];

  @override
  Widget build(BuildContext context) {
    final currentMood = _moods[_selectedMoodIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Mind & Mood",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
                  children: [
                    Text(
                      'View Details',
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Mind & Mood Horizontal Carousel
        SizedBox(
          height: 154,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Card 1: Interactive Daily Mood Selector
              Container(
                width: 250,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      currentMood['bg'] as Color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: (currentMood['color'] as Color).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          currentMood['emoji'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentMood['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: currentMood['color'] as Color,
                                ),
                              ),
                              Text(
                                currentMood['subtitle'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Emoji Bar Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_moods.length, (i) {
                        final isSel = _selectedMoodIndex == i;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMoodIndex = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? (currentMood['color'] as Color) : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                        color: (currentMood['color'] as Color).withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _moods[i]['emoji'] as String,
                              style: TextStyle(fontSize: isSel ? 18 : 16),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Card 2: Stress Level & Recovery Index
              Container(
                width: 210,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Stress Score",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "OPTIMAL",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "24",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          " / 100 • Low",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(8, (index) {
                            final active = index < 2;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 2.5),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Recovery Readiness 92%",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Card 3: 3-Min Breathwork Card
              Container(
                width: 190,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEFF6FF),
                      Color(0xFFDBEAFE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.air_rounded, color: Color(0xFF2563EB), size: 16),
                        ),
                        Text(
                          "3 min",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Box Breathing\nRelaxation",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            "Start Zen",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
      ],
    );
  }
}

// -------------------------------------------------------------
// 5. ACHIEVEMENTS CAROUSEL (GLOWING 3D TROPHY CARDS & XP)
// -------------------------------------------------------------
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = [
      _BadgeData(
        title: "7 Day Streak",
        subtitle: "7 of 7 Days",
        xp: "+100 XP",
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFF16A34A),
        tintColor: const Color(0xFFDCFCE7),
        progress: 1.0,
        unlocked: true,
      ),
      _BadgeData(
        title: "Iron Master",
        subtitle: "12 Workouts Done",
        xp: "+150 XP",
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFF8B5CF6),
        tintColor: const Color(0xFFF3E8FF),
        progress: 1.0,
        unlocked: true,
      ),
      _BadgeData(
        title: "500 Calories",
        subtitle: "461 / 500 kcal",
        xp: "+75 XP",
        icon: Icons.bolt_rounded,
        color: const Color(0xFFEF4444),
        tintColor: const Color(0xFFFEE2E2),
        progress: 461 / 500,
        unlocked: false,
      ),
      _BadgeData(
        title: "Hydration Hero",
        subtitle: "6 of 8 Glasses",
        xp: "+40 XP",
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF3B82F6),
        tintColor: const Color(0xFFDBEAFE),
        progress: 6 / 8,
        unlocked: false,
      ),
      _BadgeData(
        title: "Consistency God",
        subtitle: "Level 3 Ready",
        xp: "+300 XP",
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFD97706),
        tintColor: const Color(0xFFFEF3C7),
        progress: 0.85,
        unlocked: false,
      ),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Achievements",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 168,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: badges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = badges[index];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Achievement: ${badge.title} (${badge.subtitle})'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 138,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: badge.unlocked
                          ? [Colors.white, badge.tintColor.withValues(alpha: 0.4)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: badge.unlocked ? badge.color.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                      width: badge.unlocked ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: badge.color.withValues(alpha: badge.unlocked ? 0.14 : 0.04),
                        blurRadius: badge.unlocked ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Icon with Glowing Aura & XP Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: badge.tintColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: badge.color.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: badge.color.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(badge.icon, color: badge.color, size: 22),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: badge.unlocked ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: badge.unlocked ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              badge.xp,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: badge.unlocked ? const Color(0xFFB45309) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Status Indicator & Mini Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                badge.unlocked ? 'UNLOCKED ✓' : '${(badge.progress * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: badge.unlocked ? const Color(0xFF16A34A) : badge.color,
                                ),
                              ),
                              if (badge.unlocked)
                                const Icon(Icons.star_rounded, size: 11, color: Color(0xFFEAB308)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: badge.progress.clamp(0.0, 1.0),
                              minHeight: 4.5,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                            ),
                          ),
                        ],
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
}

class _BadgeData {
  final String title;
  final String subtitle;
  final String xp;
  final IconData icon;
  final Color color;
  final Color tintColor;
  final double progress;
  final bool unlocked;

  _BadgeData({
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.icon,
    required this.color,
    required this.tintColor,
    required this.progress,
    required this.unlocked,
  });
}

// -------------------------------------------------------------
// 6. ARTICLES & TIPS MAGAZINE CAROUSEL (INTERACTIVE BOOKMARK)
// -------------------------------------------------------------
class ArticlesTipsSection extends StatefulWidget {
  const ArticlesTipsSection({super.key});

  @override
  State<ArticlesTipsSection> createState() => _ArticlesTipsSectionState();
}

class _ArticlesTipsSectionState extends State<ArticlesTipsSection> {
  final Set<int> _bookmarkedIndices = {0};

  void _toggleBookmark(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_bookmarkedIndices.contains(index)) {
        _bookmarkedIndices.remove(index);
      } else {
        _bookmarkedIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final articles = [
      {
        'title': '5 Best Exercises for Explosive Muscle Growth',
        'readTime': '5 min read',
        'views': '2.4k views',
        'category': 'FITNESS',
        'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=400&auto=format&fit=crop',
      },
      {
        'title': 'High Protein Meals Under 500 Calories',
        'readTime': '4 min read',
        'views': '3.8k views',
        'category': 'NUTRITION',
        'image': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=400&auto=format&fit=crop',
      },
      {
        'title': 'How to Reduce Stress & Cortisol Naturally',
        'readTime': '6 min read',
        'views': '1.9k views',
        'category': 'MINDSET',
        'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=400&auto=format&fit=crop',
      },
      {
        'title': 'Optimizing Deep Sleep for Athletic Recovery',
        'readTime': '5 min read',
        'views': '4.1k views',
        'category': 'RECOVERY',
        'image': 'https://images.unsplash.com/photo-1511295742362-92c96b124e52?q=80&w=400&auto=format&fit=crop',
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Articles & Tips",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Row(
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 205,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final article = articles[index];
              final isBookmarked = _bookmarkedIndices.contains(index);

              return Container(
                width: 220,
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
                    // Image with Category Pill & Bookmark Button
                    Stack(
                      children: [
                        Image.network(
                          article['image']!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 110,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.image_not_supported_rounded, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        // Dark Gradient Mask
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.4, 1.0],
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Category Chip
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article['category']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        // Interactive Bookmark Toggle
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _toggleBookmark(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isBookmarked ? const Color(0xFF16A34A) : Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Title & Metadata
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article['title']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 3),
                                  Text(
                                    article['readTime']!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                article['views']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
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
}
