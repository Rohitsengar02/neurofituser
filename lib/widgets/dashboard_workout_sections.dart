import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../screens/workout_category_detail_screen.dart';
import '../screens/workout_detail_screen.dart';

class DashboardWorkoutTabContent extends StatefulWidget {
  const DashboardWorkoutTabContent({super.key});

  @override
  State<DashboardWorkoutTabContent> createState() => _DashboardWorkoutTabContentState();
}

class _DashboardWorkoutTabContentState extends State<DashboardWorkoutTabContent>
    with TickerProviderStateMixin {
  int _selectedCategoryFilter = 0;
  final Set<int> _bookmarkedPrograms = {0};
  final Set<int> _followedCoaches = {0};
  bool _isLoading = true;

  late AnimationController _staggerController;
  late AnimationController _shimmerController;

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
      duration: const Duration(milliseconds: 1200),
    );

    // Simulate clean, fast skeleton loading -> Stagger Blur Reveal
    Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _toggleBookmark(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_bookmarkedPrograms.contains(index)) {
        _bookmarkedPrograms.remove(index);
      } else {
        _bookmarkedPrograms.add(index);
      }
    });
  }

  void _toggleFollowCoach(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_followedCoaches.contains(index)) {
        _followedCoaches.remove(index);
      } else {
        _followedCoaches.add(index);
      }
    });
  }

  // Helper to apply staggered blur reveal to each section
  Widget _buildStaggeredBlurSection({
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

        // 1. Search Bar (Stagger 0.0 -> 0.25)
        _buildStaggeredBlurSection(
          startInterval: 0.0,
          endInterval: 0.25,
          child: _buildWorkoutSearchBar(),
        ),

        const SizedBox(height: 18),

        // 2. Featured Programs Hero Banners Carousel (Stagger 0.08 -> 0.35)
        _buildStaggeredBlurSection(
          startInterval: 0.08,
          endInterval: 0.35,
          child: _buildFeaturedProgramsBannerCarousel(),
        ),

        const SizedBox(height: 24),

        // 3. Workout Categories in 1:1 Aspect Ratio (Stagger 0.16 -> 0.45)
        _buildStaggeredBlurSection(
          startInterval: 0.16,
          endInterval: 0.45,
          child: _buildWorkoutCategoriesSection(),
        ),

        const SizedBox(height: 26),

        // 4. Popular Programs Section (Carousel) (Stagger 0.24 -> 0.55)
        _buildStaggeredBlurSection(
          startInterval: 0.24,
          endInterval: 0.55,
          child: _buildPopularProgramsCarouselSection(),
        ),

        const SizedBox(height: 26),

        // 5. Bento Grid Spotlight (Stagger 0.32 -> 0.65)
        _buildStaggeredBlurSection(
          startInterval: 0.32,
          endInterval: 0.65,
          child: _buildBentoGridSpotlightSection(),
        ),

        const SizedBox(height: 26),

        // 6. Train by Muscle Group Grid Carousel (Stagger 0.40 -> 0.72)
        _buildStaggeredBlurSection(
          startInterval: 0.40,
          endInterval: 0.72,
          child: _buildTargetMuscleGroupsSection(),
        ),

        const SizedBox(height: 26),

        // 7. Top Celebrity Coaches Carousel (Stagger 0.48 -> 0.80)
        _buildStaggeredBlurSection(
          startInterval: 0.48,
          endInterval: 0.80,
          child: _buildCelebrityCoachesCarouselSection(),
        ),

        const SizedBox(height: 26),

        // 8. Equipment-Based Training Carousel (Stagger 0.55 -> 0.88)
        _buildStaggeredBlurSection(
          startInterval: 0.55,
          endInterval: 0.88,
          child: _buildEquipmentBasedTrainingSection(),
        ),

        const SizedBox(height: 26),

        // 9. Trending Transformation Challenges (Stagger 0.62 -> 0.94)
        _buildStaggeredBlurSection(
          startInterval: 0.62,
          endInterval: 0.94,
          child: _buildTrendingChallengesSection(),
        ),

        const SizedBox(height: 26),

        // 10. Beat-Synced Audio & Video Workouts (Stagger 0.70 -> 1.0)
        _buildStaggeredBlurSection(
          startInterval: 0.70,
          endInterval: 1.0,
          child: _buildAudioBeatsWorkoutsSection(),
        ),

        const SizedBox(height: 28),
      ],
    );
  }

  // -------------------------------------------------------------
  // SHIMMER SKELETON LOADING VIEW (WHITE THEME)
  // -------------------------------------------------------------
  Widget _buildSkeletonLoadingView() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Skeleton Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 50, borderRadius: 16),
            ),

            const SizedBox(height: 18),

            // Skeleton Featured Banner
            SizedBox(
              height: 180,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildShimmerBox(width: 295, height: 180, borderRadius: 24),
                  const SizedBox(width: 14),
                  _buildShimmerBox(width: 295, height: 180, borderRadius: 24),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Skeleton Categories Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(width: 120, height: 20, borderRadius: 6),
                  _buildShimmerBox(width: 50, height: 16, borderRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Skeleton 1:1 Square Categories (125x125)
            SizedBox(
              height: 125,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildShimmerBox(width: 125, height: 125, borderRadius: 20),
                  );
                }),
              ),
            ),

            const SizedBox(height: 26),

            // Skeleton Popular Programs Carousel Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(width: 150, height: 20, borderRadius: 6),
                  _buildShimmerBox(width: 50, height: 16, borderRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Skeleton Popular Carousel Cards
            SizedBox(
              height: 220,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildShimmerBox(width: 240, height: 220, borderRadius: 22),
                  const SizedBox(width: 14),
                  _buildShimmerBox(width: 240, height: 220, borderRadius: 22),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Skeleton Bento Grid Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildShimmerBox(height: 200, borderRadius: 22),
            ),
            const SizedBox(height: 24),
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
  // 1. Search Bar
  // -------------------------------------------------------------
  Widget _buildWorkoutSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search workouts, coaches, body part...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. Featured Programs Hero Banners Carousel (WHITE THEME + VIDEO)
  // -------------------------------------------------------------
  Widget _buildFeaturedProgramsBannerCarousel() {
    final banners = [
      'assets/images/workout_banner_1.png',
      'assets/images/workout_banner_2.png',
      'assets/images/workout_banner_3.png',
      'assets/images/workout_banner_4.png',
    ];
    return _AutoScrollingBannersWidget(images: banners);
  }

  // -------------------------------------------------------------
  // 3. Workout Categories (1:1 Square Cards: 125x125 - Full Cover Image)
  // -------------------------------------------------------------
  Widget _buildWorkoutCategoriesSection() {
    final categories = [
      'assets/images/workout_category_1.png',
      'assets/images/workout_category_2.jpg',
      'assets/images/workout_category_3.png',
      'assets/images/workout_category_4.png',
      'assets/images/workout_category_5.png',
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
              Text(
                'Categories',
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
                    MaterialPageRoute(
                      builder: (context) => const WorkoutCategoryDetailScreen(),
                    ),
                  );
                },
                child: Text(
                  'See All',
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

        // Categories Carousel with 1:1 Aspect Ratio (Square 125x125) - Full Cover Image Only
        SizedBox(
          height: 125,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final imagePath = categories[index];
              final isSelected = _selectedCategoryFilter == index;

              final categoryNames = [
                'Strength',
                'HIIT',
                'Yoga',
                'Core',
                'Cardio',
              ];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategoryFilter = index);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutCategoryDetailScreen(
                        initialCategory: index < categoryNames.length ? categoryNames[index] : null,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 125,
                  height: 125,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. Popular Programs Carousel (WHITE THEME GRADIENT)
  // -------------------------------------------------------------
  Widget _buildPopularProgramsCarouselSection() {
    final programs = [
      {
        'title': 'Body Wellness & Core',
        'subtitle': 'Full body toning & condition',
        'duration': '35 min',
        'episodes': '18 episodes',
        'level': 'Intermediate',
        'rating': '4.9',
        'coach': 'Coach Emma',
        'image': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'Lean Muscle Hypertrophy',
        'subtitle': 'Dumbbell & compound mastery',
        'duration': '45 min',
        'episodes': '24 episodes',
        'level': 'Advanced',
        'rating': '5.0',
        'coach': 'Coach David',
        'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'Morning Sun Vinyasa',
        'subtitle': 'Flexibility & spine alignment',
        'duration': '25 min',
        'episodes': '14 episodes',
        'level': 'All Levels',
        'rating': '4.8',
        'coach': 'Coach Maya',
        'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'HIIT Metabolic Burn',
        'subtitle': 'Explosive cardio & endurance',
        'duration': '30 min',
        'episodes': '16 episodes',
        'level': 'Intermediate',
        'rating': '4.9',
        'coach': 'Coach Alex',
        'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600&auto=format&fit=crop',
      },
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
              Text(
                'Popular Programs',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Text(
                  'See All',
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

        // Programs Horizontal Carousel Cards with White Theme
        SizedBox(
          height: 225,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: programs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final prog = programs[index];
              final isBookmarked = _bookmarkedPrograms.contains(index);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(
                        title: prog['title'],
                        subtitle: prog['subtitle'],
                        image: prog['image'],
                        trainer: prog['coach'],
                        duration: prog['duration'],
                        level: prog['level'],
                        rating: prog['rating'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 235,
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
                    // Banner Image with White Bottom Gradient
                    Stack(
                      children: [
                        Image.network(
                          prog['image']!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        // White Linear Gradient on Image Bottom
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: const [0.0, 0.45],
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Rating Pill
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  prog['rating']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bookmark Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _toggleBookmark(index),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isBookmarked ? const Color(0xFF16A34A) : Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: isBookmarked ? Colors.white : const Color(0xFF0F172A),
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        // Bottom duration badge
                        Positioned(
                          right: 8,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prog['duration']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Details with Dark Text
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prog['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${prog['coach']!} • ${prog['episodes']!}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
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

  // -------------------------------------------------------------
  // 5. Bento Grid Workout Spotlight (WHITE THEME GRADIENT)
  // -------------------------------------------------------------
  Widget _buildBentoGridSpotlightSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workout Spotlight',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Featured',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bento Grid Layout with 5px gap
          SizedBox(
            height: 215,
            child: Row(
              children: [
                // Left Big Bento Card
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/spotlight_1.png'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Right 2 Stacked Bento Cards
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Top Right Card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/spotlight_2.png'),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Bottom Right Card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/spotlight_3.png'),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
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
    );
  }

  // -------------------------------------------------------------
  // 6. Train by Muscle Group Grid Carousel (WHITE THEME GRADIENT)
  // -------------------------------------------------------------
  Widget _buildTargetMuscleGroupsSection() {
    final muscles = [
      {'name': 'Chest & Triceps', 'exercises': '14 exercises', 'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=400&auto=format&fit=crop'},
      {'name': 'Back & Biceps', 'exercises': '16 exercises', 'image': 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?q=80&w=400&auto=format&fit=crop'},
      {'name': 'Legs & Glutes', 'exercises': '20 exercises', 'image': 'https://images.unsplash.com/photo-1434682881908-b43d0467b798?q=80&w=400&auto=format&fit=crop'},
      {'name': 'Shoulders & Abs', 'exercises': '12 exercises', 'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=400&auto=format&fit=crop'},
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
                'Target Muscle Groups',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Explore',
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
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: muscles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final muscle = muscles[index];

              return Container(
                width: 165,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(muscle['image']!),
                    fit: BoxFit.cover,
                  ),
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
                child: Stack(
                  children: [
                    // White Linear Gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            stops: const [0.0, 0.65],
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            muscle['name']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            muscle['exercises']!,
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
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 7. Top Celebrity Coaches Carousel
  // -------------------------------------------------------------
  Widget _buildCelebrityCoachesCarouselSection() {
    final coaches = [
      {
        'name': 'Elena Rostova',
        'specialty': 'Olympic Lifting & HIIT',
        'rating': '4.9',
        'avatar': 'https://images.unsplash.com/photo-1548690312-e3b507d8c110?q=80&w=300&auto=format&fit=crop',
      },
      {
        'name': 'Marcus Vance',
        'specialty': 'CrossFit & Conditioning',
        'rating': '5.0',
        'avatar': 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=300&auto=format&fit=crop',
      },
      {
        'name': 'Sarah Jenkins',
        'specialty': 'Mindful Yoga & Pilates',
        'rating': '4.9',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
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
                'Elite Coaches',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'View All',
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
          height: 155,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: coaches.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final coach = coaches[index];
              final isFollowed = _followedCoaches.contains(index);

              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar + Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(coach['avatar']!),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 12),
                              const SizedBox(width: 2),
                              Text(
                                coach['rating']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Name & Specialty
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach['name']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          coach['specialty']!,
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

                    // Follow Button
                    GestureDetector(
                      onTap: () => _toggleFollowCoach(index),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isFollowed ? const Color(0xFFDCFCE7) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            isFollowed ? 'Following' : '+ Follow',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isFollowed ? const Color(0xFF15803D) : Colors.white,
                            ),
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
  // 8. Equipment-Based Training Carousel
  // -------------------------------------------------------------
  Widget _buildEquipmentBasedTrainingSection() {
    final gear = [
      {'name': 'Dumbbells Only', 'count': '28 workouts', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
      {'name': 'Resistance Bands', 'count': '16 workouts', 'icon': Icons.album_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF3E8FF)},
      {'name': 'Kettlebell Mastery', 'count': '14 workouts', 'icon': Icons.sports_gymnastics_rounded, 'color': const Color(0xFFEA580C), 'bg': const Color(0xFFFFF7ED)},
      {'name': 'Bodyweight (Zero)', 'count': '35 workouts', 'icon': Icons.directions_run_rounded, 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFF0F9FF)},
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
                'Workout by Equipment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Filter',
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
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: gear.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = gear[index];

              return Container(
                width: 145,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          item['count'] as String,
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
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 9. Trending Transformation Challenges (WHITE THEME GRADIENT)
  // -------------------------------------------------------------
  Widget _buildTrendingChallengesSection() {
    final challenges = [
      {
        'title': '30-Day Summer Shred Challenge',
        'joined': '14.2k joined',
        'progress': 'Week 2 of 4',
        'badge': '+500 XP',
        'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': '21-Day Core & Abs Ignite',
        'joined': '8.6k joined',
        'progress': 'Week 1 of 3',
        'badge': '+350 XP',
        'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=600&auto=format&fit=crop',
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
                'Trending Challenges',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Join All',
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
          height: 165,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: challenges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final challenge = challenges[index];

              return Container(
                width: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: DecorationImage(
                    image: NetworkImage(challenge['image']!),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // White Linear Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            stops: const [0.0, 0.70],
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  challenge['badge']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                              Text(
                                challenge['joined']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge['title']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                challenge['progress']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
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
  // 10. Beat-Synced Audio & Video Workouts
  // -------------------------------------------------------------
  Widget _buildAudioBeatsWorkoutsSection() {
    final tracks = [
      {'title': 'High BPM HIIT Cardio Beat', 'bpm': '145 BPM', 'duration': '30 min', 'color': const Color(0xFF16A34A), 'image': 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Deep House Strength Lift', 'bpm': '128 BPM', 'duration': '45 min', 'color': const Color(0xFF8B5CF6), 'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=400&auto=format&fit=crop'},
      {'title': 'Lo-Fi Chill Sunset Yoga', 'bpm': '90 BPM', 'duration': '20 min', 'color': const Color(0xFF3B82F6), 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=400&auto=format&fit=crop'},
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
                'Music-Synced Workouts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Playlists',
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
          height: 145,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tracks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final color = track['color'] as Color;

              return Container(
                width: 175,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 12,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            track['bpm'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                        const Icon(Icons.graphic_eq_rounded, color: Color(0xFF16A34A), size: 18),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track['title'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track['duration'] as String,
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
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Auto-playing Muted Loop Video Widget for Workout Banner
// -------------------------------------------------------------
class _WorkoutBannerVideoWidget extends StatefulWidget {
  final String assetPath;
  const _WorkoutBannerVideoWidget({required this.assetPath});

  @override
  State<_WorkoutBannerVideoWidget> createState() => _WorkoutBannerVideoWidgetState();
}

class _WorkoutBannerVideoWidgetState extends State<_WorkoutBannerVideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (mounted) {
          _controller.setVolume(0.0);
          _controller.setLooping(true);
          _controller.play();
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(color: const Color(0xFFF1F5F9));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

class _AutoScrollingBannersWidget extends StatefulWidget {
  final List<String> images;
  const _AutoScrollingBannersWidget({super.key, required this.images});

  @override
  State<_AutoScrollingBannersWidget> createState() => _AutoScrollingBannersWidgetState();
}

class _AutoScrollingBannersWidgetState extends State<_AutoScrollingBannersWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < widget.images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _currentPage = index;
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: AssetImage(widget.images[index]),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
            ),
          );
        },
      ),
    );
  }
}
