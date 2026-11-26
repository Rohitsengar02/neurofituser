import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardMentalHealthTabContent extends StatefulWidget {
  const DashboardMentalHealthTabContent({super.key});

  @override
  State<DashboardMentalHealthTabContent> createState() => _DashboardMentalHealthTabContentState();
}

class _DashboardMentalHealthTabContentState extends State<DashboardMentalHealthTabContent>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _staggerController;
  late AnimationController _shimmerController;
  late AnimationController _mindScoreController;

  // Interactive States
  int _selectedMoodIndex = 0; // 0: Great, 1: Good, 2: Okay, 3: Low, 4: Stressed
  final Set<String> _selectedMoodFactors = {'Exercise', 'Sleep'};
  int _selectedLibraryCategory = 0;
  int _reflectionMoodIndex = 0;

  final List<Map<String, dynamic>> _moodList = [
    {'emoji': '😄', 'label': 'Great', 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
    {'emoji': '🙂', 'label': 'Good', 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFE0F2FE)},
    {'emoji': '😐', 'label': 'Okay', 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7)},
    {'emoji': '😔', 'label': 'Low', 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF3E8FF)},
    {'emoji': '😣', 'label': 'Stressed', 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEE2E2)},
  ];

  final List<String> _moodFactors = [
    'Work', 'Sleep', 'Exercise', 'Relationships', 'Family', 'Money', 'Health', 'Nothing specific'
  ];

  @override
  void initState() {
    super.initState();

    // 1. Shimmer Controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // 2. Stagger Entrance Controller
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // 3. Mind Score Progress Controller
    _mindScoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Simulate skeleton loading
    Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _staggerController.forward();
        _mindScoreController.forward();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _staggerController.dispose();
    _mindScoreController.dispose();
    super.dispose();
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

        // 01. Today's Mind 🌿 — Hero Section (Stagger 0.0 -> 0.16)
        _buildStaggeredSection(
          startInterval: 0.0,
          endInterval: 0.16,
          child: _buildTodayMindHeroSection(),
        ),

        const SizedBox(height: 24),

        // 02. How Are You Feeling? Check-In (Stagger 0.08 -> 0.24)
        _buildStaggeredSection(
          startInterval: 0.08,
          endInterval: 0.24,
          child: _buildMoodCheckInSection(),
        ),

        const SizedBox(height: 24),

        // 03. Stress & Energy Wellbeing Meters (Stagger 0.16 -> 0.32)
        _buildStaggeredSection(
          startInterval: 0.16,
          endInterval: 0.32,
          child: _buildStressEnergySection(),
        ),

        const SizedBox(height: 24),

        // 04. AI Mind Coach 🤖 (Stagger 0.24 -> 0.40)
        _buildStaggeredSection(
          startInterval: 0.24,
          endInterval: 0.40,
          child: _buildAIMindCoachSection(),
        ),

        const SizedBox(height: 26),

        // 05. Quick Mind Exercises (Stagger 0.32 -> 0.48)
        _buildStaggeredSection(
          startInterval: 0.32,
          endInterval: 0.48,
          child: _buildQuickExercisesCarousel(),
        ),

        const SizedBox(height: 26),

        // 06. Interactive Breathing Exercise (Stagger 0.40 -> 0.56)
        _buildStaggeredSection(
          startInterval: 0.40,
          endInterval: 0.56,
          child: _buildBreathingExerciseSection(),
        ),

        const SizedBox(height: 26),

        // 07. Meditation & Mindfulness Audio Cards (Stagger 0.48 -> 0.64)
        _buildStaggeredSection(
          startInterval: 0.48,
          endInterval: 0.64,
          child: _buildMeditationCardsSection(),
        ),

        const SizedBox(height: 26),

        // 08. Sleep & Recovery 😴 (Stagger 0.56 -> 0.72)
        _buildStaggeredSection(
          startInterval: 0.56,
          endInterval: 0.72,
          child: _buildSleepRecoverySection(),
        ),

        const SizedBox(height: 24),

        // 09. Mood Journal 📖 (Stagger 0.64 -> 0.78)
        _buildStaggeredSection(
          startInterval: 0.64,
          endInterval: 0.78,
          child: _buildMoodJournalSection(),
        ),

        const SizedBox(height: 24),

        // 10. Your Mood Trends 📈 (Stagger 0.70 -> 0.84)
        _buildStaggeredSection(
          startInterval: 0.70,
          endInterval: 0.84,
          child: _buildMoodTrendsSection(),
        ),

        const SizedBox(height: 24),

        // 11. Mental Wellness Streak 🔥 (Stagger 0.76 -> 0.88)
        _buildStaggeredSection(
          startInterval: 0.76,
          endInterval: 0.88,
          child: _buildWellnessStreakSection(),
        ),

        const SizedBox(height: 26),

        // 12. Recommended For You (Stagger 0.82 -> 0.92)
        _buildStaggeredSection(
          startInterval: 0.82,
          endInterval: 0.92,
          child: _buildRecommendedSection(),
        ),

        const SizedBox(height: 26),

        // 13. Mental Wellness Library (Stagger 0.86 -> 0.95)
        _buildStaggeredSection(
          startInterval: 0.86,
          endInterval: 0.95,
          child: _buildWellnessLibrarySection(),
        ),

        const SizedBox(height: 24),

        // 14. Daily Reflection 🌙 (Stagger 0.90 -> 0.98)
        _buildStaggeredSection(
          startInterval: 0.90,
          endInterval: 0.98,
          child: _buildDailyReflectionSection(),
        ),

        const SizedBox(height: 24),

        // 15. Final Motivational Card 🌿 (Stagger 0.94 -> 1.0)
        _buildStaggeredSection(
          startInterval: 0.94,
          endInterval: 1.0,
          child: _buildFinalMotivationCard(),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // -------------------------------------------------------------
  // SHIMMER SKELETON LOADING VIEW (CALMING PASTEL)
  // -------------------------------------------------------------
  Widget _buildSkeletonLoadingView() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 230, borderRadius: 28),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 120, borderRadius: 24),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 150, borderRadius: 24),
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
            Color(0xFFF8FAFC),
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 01. TODAY'S MIND 🌿 — HERO SECTION
  // -------------------------------------------------------------
  Widget _buildTodayMindHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Greeting + Calming Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good evening, Rohit 👋",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "How are you feeling today?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text("🌿", style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        "Mind Recovery",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mood Selector Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moodList.length, (index) {
                final mood = _moodList[index];
                final isSelected = _selectedMoodIndex == index;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMoodIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? (mood['bg'] as Color) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (mood['color'] as Color).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(mood['emoji'] as String, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 3),
                        Text(
                          mood['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? (mood['color'] as Color) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Middle: Circular Mind Score Gauge + Stat Badges
            Row(
              children: [
                // Mind Score Gauge
                SizedBox(
                  width: 108,
                  height: 108,
                  child: AnimatedBuilder(
                    animation: _mindScoreController,
                    builder: (context, child) {
                      final progress = (82 / 100) * CurvedAnimation(
                        parent: _mindScoreController,
                        curve: Curves.easeOutCubic,
                      ).value;

                      return CustomPaint(
                        painter: _MindScoreRingPainter(progress: progress),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "82",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "Mind Score",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Stress, Energy, Recovery Badges
                Expanded(
                  child: Column(
                    children: [
                      _buildMindPill(
                        icon: "🧘",
                        label: "Stress",
                        value: "Low",
                        color: const Color(0xFF16A34A),
                        bg: const Color(0xFFDCFCE7),
                      ),
                      const SizedBox(height: 8),
                      _buildMindPill(
                        icon: "⚡",
                        label: "Energy",
                        value: "Good",
                        color: const Color(0xFF0284C7),
                        bg: const Color(0xFFE0F2FE),
                      ),
                      const SizedBox(height: 8),
                      _buildMindPill(
                        icon: "😴",
                        label: "Recovery",
                        value: "82%",
                        color: const Color(0xFF7C3AED),
                        bg: const Color(0xFFF3E8FF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMindPill({
    required String icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 02. HOW ARE YOU FEELING? (CHECK IN WITH YOURSELF)
  // -------------------------------------------------------------
  Widget _buildMoodCheckInSection() {
    final moodBanners = [
      'assets/images/mood_banner_1.jpg',
      'assets/images/mood_banner_2.jpg',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

    
    // Beautiful section carousel with linear gradient
    SizedBox(
      height: 220, // Taller for these beautiful posters
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: moodBanners.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return Container(
            width: 310,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: AssetImage(moodBanners[index]),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomLeft,
              child: index == 0 ? Text(
                "Strong Body,\nCalm Mind",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ) : Text(
                "Wellness,\nEvery Day",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          );
        },
      ),
    ),
  ],
);
}

  // -------------------------------------------------------------
  // 03. STRESS & ENERGY WELLBEING METERS
  // -------------------------------------------------------------
  Widget _buildStressEnergySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Wellbeing State",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildWellbeingImageCard("Stress Level", "LOW", 0.28, const Color(0xFF22C55E), 'assets/images/stress_level.png'),
              const SizedBox(width: 14),
              _buildWellbeingImageCard("Energy Level", "HIGH", 0.78, const Color(0xFF3B82F6), 'assets/images/energy_level.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingImageCard(String title, String status, double progress, Color color, String imagePath) {
    return Expanded(
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.75),
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 04. AI MIND COACH 🤖
  // -------------------------------------------------------------
  Widget _buildAIMindCoachSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/ai_coach_bg.png'),
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                const Color(0xFF3B8E9F), // Deeper teal matching the image
                const Color(0xFF54A8B9).withValues(alpha: 0.85),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Mind Coach",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Personalized daily reset",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(right: 70.0), // Keep text on the left away from the illustration
                child: Text(
                  "“You've been consistent with your workouts this week. Your stress level looks slightly higher today. Take 5 minutes to reset your breath.”",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                children: [
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        "Start 5-min Reset →",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: Text(
                        "Talk to Coach",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
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

  // -------------------------------------------------------------
  // 05. QUICK MIND EXERCISES CAROUSEL
  // -------------------------------------------------------------
  Widget _buildQuickExercisesCarousel() {
    final exercises = [
      {'title': 'Breathing', 'duration': '2 min', 'icon': '🌬️', 'color': const Color(0xFFE0F2FE), 'accent': const Color(0xFF0284C7)},
      {'title': 'Meditation', 'duration': '5 min', 'icon': '🧘', 'color': const Color(0xFFF3E8FF), 'accent': const Color(0xFF7C3AED)},
      {'title': 'Mindfulness', 'duration': '3 min', 'icon': '🌿', 'color': const Color(0xFFDCFCE7), 'accent': const Color(0xFF16A34A)},
      {'title': 'Relax', 'duration': '5 min', 'icon': '😌', 'color': const Color(0xFFFFFBEB), 'accent': const Color(0xFFD97706)},
      {'title': 'Calm Audio', 'duration': '10 min', 'icon': '🎧', 'color': const Color(0xFFFFEEF1), 'accent': const Color(0xFFE11D48)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Take a Moment 🌿",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: exercises.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = exercises[index];
              final bg = item['color'] as Color;
              final accent = item['accent'] as Color;

              return Container(
                width: 105,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                      child: Text(item['icon'] as String, style: const TextStyle(fontSize: 16)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          item['duration'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
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
  // 06. INTERACTIVE BREATHING EXERCISE (BREATHE & RESET - ULTRA LUXE)
  // -------------------------------------------------------------
  Widget _buildBreathingExerciseSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: _InteractiveBreathingCard(),
    );
  }

  // -------------------------------------------------------------
  // 07. MEDITATION & MINDFULNESS AUDIO CAROUSEL
  // -------------------------------------------------------------
  Widget _buildMeditationCardsSection() {
    final meditations = [
      {'title': 'Morning Calm', 'time': '10 min', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Stress Reset', 'time': '5 min', 'image': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Deep Focus', 'time': '15 min', 'image': 'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Sleep Meditation', 'time': '20 min', 'image': 'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?q=80&w=400&auto=format&fit=crop'},
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
                "For Your Mind 🧘",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                "View All",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 165,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: meditations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final med = meditations[index];

              return Container(
                width: 150,
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
                          med['image']!,
                          height: 95,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF7C3AED), size: 16),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            med['time']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C3AED),
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
  // 08. SLEEP & RECOVERY 😴
  // -------------------------------------------------------------
  Widget _buildSleepRecoverySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/sleep_bg.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          // Uniform dark overlay for text readability against white clouds
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("😴", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        "Sleep & Recovery",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "7h 32m",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF38BDF8), // Light blue for dark bg
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSleepStat("Sleep Quality", "88%"),
                  _buildSleepStat("Deep Sleep", "2h 14m"),
                  _buildSleepStat("Recovery Score", "82%"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 09. MOOD JOURNAL 📖
  // -------------------------------------------------------------
  Widget _buildMoodJournalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/journal_bg.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55), // Dark overlay for text readability
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Journal 📖",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Today • 5:42 PM",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "“Feeling productive and focused after the morning stretch, but slightly tired in the late afternoon.”",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Write in Journal +",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 10. MOOD TRENDS 📈
  // -------------------------------------------------------------
  Widget _buildMoodTrendsSection() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mood Trends 📈",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "Avg Mood: 4.2 / 5",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7-Day Curve
            SizedBox(
              height: 80,
              width: double.infinity,
              child: CustomPaint(
                painter: _MoodCurvePainter(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("M", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("T", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("W", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("T", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("F", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("S", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text("S", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 11. MENTAL WELLNESS STREAK 🔥
  // -------------------------------------------------------------
  Widget _buildWellnessStreakSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EEFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
              child: const Text("🌿", style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "7-Day Mindful Streak! 🧘",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF581C87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Badges earned: 🏆 7-Day Calm • 🌿 Stress Master",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7E22CE),
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
  // 12. RECOMMENDED FOR YOU (AI ADAPTIVE)
  // -------------------------------------------------------------
  Widget _buildRecommendedSection() {
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
              "Because you're feeling calm ✨",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _buildRecItem("5-Minute Stress Reset", "Quick soothing audio", const Color(0xFFDCFCE7)),
            const SizedBox(height: 8),
            _buildRecItem("Guided Nature Breath", "Forest soundscape", const Color(0xFFE0F2FE)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecItem(String title, String sub, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF0F172A), size: 24),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 13. MENTAL WELLNESS LIBRARY
  // -------------------------------------------------------------
  Widget _buildWellnessLibrarySection() {
    final categories = ['All', 'Meditation', 'Breathing', 'Sleep', 'Focus', 'Stress Relief'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Explore Wellness Library 📚",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSel = _selectedLibraryCategory == index;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLibraryCategory = index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF7C3AED) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
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
      ],
    );
  }

  // -------------------------------------------------------------
  // 14. DAILY REFLECTION 🌙
  // -------------------------------------------------------------
  Widget _buildDailyReflectionSection() {
    final moods = ['😄', '🙂', '😐', '😔'];

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
              "End Your Day 🌙",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "How was your overall day?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(moods.length, (index) {
                final isSel = _reflectionMoodIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _reflectionMoodIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFF3E8FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                    ),
                    child: Text(moods[index], style: const TextStyle(fontSize: 18)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Save Reflection",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

  // -------------------------------------------------------------
  // 15. FINAL MOTIVATIONAL CARD 🌿
  // -------------------------------------------------------------
  Widget _buildFinalMotivationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFF6D28D9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your mind deserves recovery too. 🌿",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Small moments of mindfulness can become powerful habits for peak performance.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Custom Mind Score Ring Painter
// -------------------------------------------------------------
class _MindScoreRingPainter extends CustomPainter {
  final double progress;
  _MindScoreRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
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
  bool shouldRepaint(covariant _MindScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// -------------------------------------------------------------
// Custom Mood Curve Painter
// -------------------------------------------------------------
class _MoodCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.5),
      Offset(size.width * 0.33, size.height * 0.35),
      Offset(size.width * 0.50, size.height * 0.2),
      Offset(size.width * 0.66, size.height * 0.4),
      Offset(size.width * 0.83, size.height * 0.25),
      Offset(size.width, size.height * 0.15),
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
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    final endPoint = points.last;
    final dotPaint = Paint()..color = const Color(0xFF8B5CF6);
    final innerDot = Paint()..color = Colors.white;
    canvas.drawCircle(endPoint, 6, dotPaint);
    canvas.drawCircle(endPoint, 3, innerDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// ULTRA-LUXE INTERACTIVE BREATHING & RESET CARD
// -------------------------------------------------------------
class _InteractiveBreathingCard extends StatefulWidget {
  const _InteractiveBreathingCard();

  @override
  State<_InteractiveBreathingCard> createState() => _InteractiveBreathingCardState();
}

class _InteractiveBreathingCardState extends State<_InteractiveBreathingCard>
    with TickerProviderStateMixin {
  int _selectedTechniqueIndex = 0; // 0: 4-4-6 Relax, 1: 4-7-8 Sleep, 2: 4-4-4 Box
  bool _isActive = false;
  int _currentPhaseIndex = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Rest
  int _secondsRemaining = 4;
  int _currentCycle = 1;
  final int _totalCycles = 4;

  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late AnimationController _orbScaleController;

  final List<Map<String, dynamic>> _techniques = [
    {
      'title': '4-4-6 Calm',
      'tag': 'Stress Reset',
      'phases': [
        {'name': 'INHALE', 'duration': 4, 'sub': 'Breathe in gently through nose', 'scale': 1.0},
        {'name': 'HOLD', 'duration': 4, 'sub': 'Maintain quiet stillness', 'scale': 1.0},
        {'name': 'EXHALE', 'duration': 6, 'sub': 'Slowly release all tension', 'scale': 0.0},
      ],
      'color': const Color(0xFF16A34A),
      'bg': const Color(0xFFDCFCE7),
    },
    {
      'title': '4-7-8 Sleep',
      'tag': 'Deep Rest',
      'phases': [
        {'name': 'INHALE', 'duration': 4, 'sub': 'Breathe in deep peace', 'scale': 1.0},
        {'name': 'HOLD', 'duration': 7, 'sub': 'Hold the serenity within', 'scale': 1.0},
        {'name': 'EXHALE', 'duration': 8, 'sub': 'Exhale completely & relax', 'scale': 0.0},
      ],
      'color': const Color(0xFF7C3AED),
      'bg': const Color(0xFFF3E8FF),
    },
    {
      'title': '4-4-4 Box',
      'tag': 'Sharp Focus',
      'phases': [
        {'name': 'INHALE', 'duration': 4, 'sub': 'Draw focused energy in', 'scale': 1.0},
        {'name': 'HOLD', 'duration': 4, 'sub': 'Centering your clarity', 'scale': 1.0},
        {'name': 'EXHALE', 'duration': 4, 'sub': 'Release with control', 'scale': 0.0},
        {'name': 'HOLD', 'duration': 4, 'sub': 'Quiet mental stillness', 'scale': 0.0},
      ],
      'color': const Color(0xFF0284C7),
      'bg': const Color(0xFFE0F2FE),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _orbScaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _orbScaleController.dispose();
    super.dispose();
  }

  void _startBreathingSession() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isActive = true;
      _currentPhaseIndex = 0;
      _currentCycle = 1;
      _setPhase(0);
    });
  }

  void _stopBreathingSession() {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    _orbScaleController.stop();
    setState(() {
      _isActive = false;
      _currentPhaseIndex = 0;
      _secondsRemaining = _getCurrentPhase()['duration'] as int;
    });
  }

  Map<String, dynamic> _getCurrentPhase() {
    final phases = _techniques[_selectedTechniqueIndex]['phases'] as List<Map<String, dynamic>>;
    return phases[_currentPhaseIndex];
  }

  void _setPhase(int phaseIndex) {
    final phases = _techniques[_selectedTechniqueIndex]['phases'] as List<Map<String, dynamic>>;
    final phase = phases[phaseIndex];
    final duration = phase['duration'] as int;

    setState(() {
      _currentPhaseIndex = phaseIndex;
      _secondsRemaining = duration;
    });

    // Animate scale matching phase duration
    _orbScaleController.duration = Duration(seconds: duration);
    if (phase['name'] == 'INHALE') {
      _orbScaleController.forward(from: 0.0);
    } else if (phase['name'] == 'EXHALE') {
      _orbScaleController.reverse(from: 1.0);
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _advanceToNextPhase();
      }
    });
  }

  void _advanceToNextPhase() {
    HapticFeedback.lightImpact();
    final phases = _techniques[_selectedTechniqueIndex]['phases'] as List<Map<String, dynamic>>;
    if (_currentPhaseIndex < phases.length - 1) {
      _setPhase(_currentPhaseIndex + 1);
    } else {
      // Completed a full cycle
      if (_currentCycle < _totalCycles) {
        setState(() => _currentCycle++);
        _setPhase(0);
      } else {
        // Finished all cycles
        _stopBreathingSession();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTech = _techniques[_selectedTechniqueIndex];
    final activeColor = currentTech['color'] as Color;
    final activePhase = _getCurrentPhase();
    final phaseName = activePhase['name'] as String;
    final phaseSub = activePhase['sub'] as String;
    final totalPhaseSecs = activePhase['duration'] as int;
    final phaseProgress = _isActive ? (1.0 - (_secondsRemaining / totalPhaseSecs)).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Title, Subtitle, and Cycle Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Breathe & Reset",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text("🌬️", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Calm nervous system in minutes",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _isActive ? "Cycle $_currentCycle / $_totalCycles" : "4 Cycles",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _isActive ? activeColor : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Rhythm Technique Selector Pills
          Row(
            children: List.generate(_techniques.length, (index) {
              final tech = _techniques[index];
              final isSel = _selectedTechniqueIndex == index;
              final color = tech['color'] as Color;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == _techniques.length - 1 ? 0 : 4,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (_isActive) _stopBreathingSession();
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTechniqueIndex = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? color : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? color : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            tech['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            tech['tag'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // 3. Central Concentric Glowing Breathing Orbs with Phase Indicator
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: AnimatedBuilder(
                animation: Listenable.merge([_orbScaleController, _pulseController]),
                builder: (context, child) {
                  final orbScale = _isActive
                      ? (0.75 + (0.28 * _orbScaleController.value))
                      : (0.85 + (0.05 * _pulseController.value));

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulsating Ambient Aura
                      Transform.scale(
                        scale: orbScale * 1.25,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                activeColor.withValues(alpha: _isActive ? 0.25 : 0.12),
                                activeColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Mid Concentric Ring
                      Transform.scale(
                        scale: orbScale * 1.10,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeColor.withValues(alpha: _isActive ? 0.15 : 0.07),
                            border: Border.all(
                              color: activeColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // Arc Progress Painter
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _BreathingArcPainter(
                          progress: phaseProgress,
                          color: activeColor,
                        ),
                      ),

                      // Inner Core Frosted Bubble
                      Transform.scale(
                        scale: orbScale,
                        child: Container(
                          width: 125,
                          height: 125,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.25),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isActive ? phaseName : "BREATHE",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: activeColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isActive ? "${_secondsRemaining}s" : "Ready",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Dynamic Subtitle Guidance
          Center(
            child: Text(
              _isActive ? phaseSub : "Press Start to begin a guided peaceful breathing cycle.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 5. Action Controls Row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isActive ? _stopBreathingSession : _startBreathingSession,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isActive ? const Color(0xFF0F172A) : activeColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isActive ? const Color(0xFF0F172A) : activeColor).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isActive ? "Pause Exercise" : "Start Session",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isActive) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _stopBreathingSession,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Custom Arc Painter for Breathing Phase Track
// -------------------------------------------------------------
class _BreathingArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BreathingArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BreathingArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

