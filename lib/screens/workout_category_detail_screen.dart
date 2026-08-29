import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';
import 'workout_detail_screen.dart';

class WorkoutCategoryDetailScreen extends StatefulWidget {
  final String? initialCategory;

  const WorkoutCategoryDetailScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<WorkoutCategoryDetailScreen> createState() => _WorkoutCategoryDetailScreenState();
}

class _WorkoutCategoryDetailScreenState extends State<WorkoutCategoryDetailScreen> {
  late int _selectedCategoryIndex;
  String _selectedFilter = 'All';
  String _selectedSort = 'Popular';
  String _searchQuery = '';
  final Set<int> _savedWorkouts = {0, 3};

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All Workouts',
      'icon': Icons.fitness_center_rounded,
      'color': Color(0xFF16A34A),
      'bannerColor': [Color(0xFF15803D), Color(0xFF16A34A)],
      'count': '120+ Workouts',
      'tagline': 'Explore full spectrum strength, cardio, and mobility programs.',
      'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Strength & Hypertrophy',
      'icon': Icons.fitness_center_rounded,
      'color': Color(0xFF8B5CF6),
      'bannerColor': [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
      'count': '38 Workouts',
      'tagline': 'Build raw power, dense muscle mass, and progressive overload.',
      'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'HIIT & Fat Burn',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEA580C),
      'bannerColor': [Color(0xFFC2410C), Color(0xFFEA580C)],
      'count': '26 Workouts',
      'tagline': 'High intensity metabolic burn for maximum caloric output.',
      'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Yoga & Mobility',
      'icon': Icons.self_improvement_rounded,
      'color': Color(0xFF0D9488),
      'bannerColor': [Color(0xFF0F766E), Color(0xFF0D9488)],
      'count': '22 Workouts',
      'tagline': 'Decompress joints, improve flexibility, and balance nervous system.',
      'image': 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Core & Abs Sculpt',
      'icon': Icons.accessibility_new_rounded,
      'color': Color(0xFFE11D48),
      'bannerColor': [Color(0xFFBE123C), Color(0xFFE11D48)],
      'count': '18 Workouts',
      'tagline': 'Targeted transverse abdominal, oblique, and lower back stability.',
      'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Cardio & Endurance',
      'icon': Icons.directions_run_rounded,
      'color': Color(0xFF2563EB),
      'bannerColor': [Color(0xFF1D4ED8), Color(0xFF2563EB)],
      'count': '19 Workouts',
      'tagline': 'Aerobic capacity, VO2 max stamina, and sustained athletic output.',
      'image': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?q=80&w=800&auto=format&fit=crop',
    },
  ];

  final List<Map<String, dynamic>> _workouts = [
    {
      'id': 0,
      'title': 'Full Body Hypertrophy Blitz',
      'category': 'Strength & Hypertrophy',
      'categoryIndex': 1,
      'duration': '45 min',
      'calories': '480 kcal',
      'level': 'Intermediate',
      'exercisesCount': 8,
      'rating': 4.9,
      'reviews': '1.4k',
      'trainer': 'Coach Marcus Vance',
      'trainerAvatar': 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=200&auto=format&fit=crop',
      'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=600&auto=format&fit=crop',
      'equipment': 'Dumbbells & Bench',
      'tags': ['Chest', 'Quads', 'Shoulders', 'Hypertrophy'],
      'exercises': [
        {'name': 'Barbell Incline Press', 'sets': '4 Sets x 10 Reps', 'rest': '60s'},
        {'name': 'Goblet Squats', 'sets': '4 Sets x 12 Reps', 'rest': '60s'},
        {'name': 'Romanian Deadlifts', 'sets': '3 Sets x 10 Reps', 'rest': '90s'},
        {'name': 'Dumbbell Lateral Raises', 'sets': '4 Sets x 15 Reps', 'rest': '45s'},
        {'name': 'Incline Bicep Curls', 'sets': '3 Sets x 12 Reps', 'rest': '45s'},
        {'name': 'Overhead Tricep Extension', 'sets': '3 Sets x 12 Reps', 'rest': '45s'},
        {'name': 'Hanging Leg Raises', 'sets': '3 Sets x 15 Reps', 'rest': '30s'},
        {'name': 'Farmer’s Walk', 'sets': '3 Sets x 40m', 'rest': '60s'},
      ],
    },
    {
      'id': 1,
      'title': 'High Octane Tabata Inferno',
      'category': 'HIIT & Fat Burn',
      'categoryIndex': 2,
      'duration': '30 min',
      'calories': '420 kcal',
      'level': 'Advanced',
      'exercisesCount': 6,
      'rating': 5.0,
      'reviews': '2.1k',
      'trainer': 'Sarah Jenkins',
      'trainerAvatar': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop',
      'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=600&auto=format&fit=crop',
      'equipment': 'Bodyweight Only',
      'tags': ['Cardio', 'Full Body', 'Fat Loss', 'No Gear'],
      'exercises': [
        {'name': 'Burpee Broad Jumps', 'sets': '4 Rounds x 40s on', 'rest': '20s'},
        {'name': 'High Knee Sprints', 'sets': '4 Rounds x 40s on', 'rest': '20s'},
        {'name': 'Mountain Climbers Turbo', 'sets': '4 Rounds x 40s on', 'rest': '20s'},
        {'name': 'Jumping Lunges', 'sets': '4 Rounds x 40s on', 'rest': '20s'},
        {'name': 'Plank Jack to Tuck', 'sets': '4 Rounds x 40s on', 'rest': '20s'},
        {'name': 'Speed Skaters', 'sets': '4 Rounds x 40s on', 'rest': '20s'},
      ],
    },
    {
      'id': 2,
      'title': 'Spine Align & Vinyasa Flow',
      'category': 'Yoga & Mobility',
      'categoryIndex': 3,
      'duration': '35 min',
      'calories': '190 kcal',
      'level': 'All Levels',
      'exercisesCount': 7,
      'rating': 4.9,
      'reviews': '980',
      'trainer': 'Maya Lin',
      'trainerAvatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200&auto=format&fit=crop',
      'image': 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?q=80&w=600&auto=format&fit=crop',
      'equipment': 'Yoga Mat',
      'tags': ['Flexibility', 'Spine', 'Breathing', 'Recovery'],
      'exercises': [
        {'name': 'Sun Salutation A Flow', 'sets': '5 Rounds', 'rest': 'None'},
        {'name': 'Warrior II into Triangle', 'sets': '3 min per side', 'rest': '15s'},
        {'name': 'Downward Dog to Cobra', 'sets': '10 Fluid Reps', 'rest': '20s'},
        {'name': 'Pigeon Pose Hip Opener', 'sets': '2 min per side', 'rest': 'None'},
        {'name': 'Bridge Pose Spine Articulation', 'sets': '3 Sets x 45s', 'rest': '30s'},
        {'name': 'Seated Spinal Twist', 'sets': '90s per side', 'rest': 'None'},
        {'name': 'Savasana Mindfulness', 'sets': '5 min hold', 'rest': 'Complete'},
      ],
    },
    {
      'id': 3,
      'title': 'Defined 6-Pack Core Sculpt',
      'category': 'Core & Abs Sculpt',
      'categoryIndex': 4,
      'duration': '25 min',
      'calories': '280 kcal',
      'level': 'Intermediate',
      'exercisesCount': 6,
      'rating': 4.8,
      'reviews': '1.8k',
      'trainer': 'Coach Alex Carter',
      'trainerAvatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
      'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=600&auto=format&fit=crop',
      'equipment': 'Mat & Small Weight',
      'tags': ['Six Pack', 'Obliques', 'Lower Abs', 'Core'],
      'exercises': [
        {'name': 'Hanging Knee Raises', 'sets': '4 Sets x 15 Reps', 'rest': '30s'},
        {'name': 'Russian Twists w/ Plate', 'sets': '4 Sets x 20 Reps', 'rest': '30s'},
        {'name': 'Hollow Body Rock Hold', 'sets': '3 Sets x 45s Hold', 'rest': '45s'},
        {'name': 'Cable / Band Woodchoppers', 'sets': '3 Sets x 12 Reps/side', 'rest': '30s'},
        {'name': 'Deadbug Core Stability', 'sets': '3 Sets x 16 Reps', 'rest': '30s'},
        {'name': 'Side Plank with Dip', 'sets': '3 Sets x 12 Reps/side', 'rest': '30s'},
      ],
    },
    {
      'id': 4,
      'title': 'Upper Body Power & Pump',
      'category': 'Strength & Hypertrophy',
      'categoryIndex': 1,
      'duration': '50 min',
      'calories': '510 kcal',
      'level': 'Advanced',
      'exercisesCount': 7,
      'rating': 4.9,
      'reviews': '1.6k',
      'trainer': 'Coach Marcus Vance',
      'trainerAvatar': 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=200&auto=format&fit=crop',
      'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=600&auto=format&fit=crop',
      'equipment': 'Barbell & Cable',
      'tags': ['Chest', 'Lats', 'Deltoids', 'Arms'],
      'exercises': [
        {'name': 'Flat Barbell Bench Press', 'sets': '4 Sets x 8 Reps', 'rest': '90s'},
        {'name': 'Weighted Pull-Ups', 'sets': '4 Sets x 8 Reps', 'rest': '90s'},
        {'name': 'Seated Dumbbell Shoulder Press', 'sets': '3 Sets x 10 Reps', 'rest': '60s'},
        {'name': 'Chest-Supported Row', 'sets': '3 Sets x 12 Reps', 'rest': '60s'},
        {'name': 'Cable Lateral Raise', 'sets': '4 Sets x 15 Reps', 'rest': '45s'},
        {'name': 'Cable Rope Tricep Pushdown', 'sets': '3 Sets x 12 Reps', 'rest': '45s'},
        {'name': 'EZ-Bar Bicep Curl', 'sets': '3 Sets x 10 Reps', 'rest': '45s'},
      ],
    },
    {
      'id': 5,
      'title': 'VO2 Max Cardio Sprint Circuit',
      'category': 'Cardio & Endurance',
      'categoryIndex': 5,
      'duration': '40 min',
      'calories': '550 kcal',
      'level': 'Advanced',
      'exercisesCount': 5,
      'rating': 4.9,
      'reviews': '820',
      'trainer': 'Liam Gallagher',
      'trainerAvatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
      'image': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?q=80&w=600&auto=format&fit=crop',
      'equipment': 'Treadmill / Track',
      'tags': ['Sprints', 'Stamina', 'VO2 Max', 'Heart Rate'],
      'exercises': [
        {'name': 'Progressive Incline Jog', 'sets': '8 min Warmup', 'rest': '1 min'},
        {'name': '30s Max Sprint / 30s Rest', 'sets': '10 Rounds', 'rest': '30s'},
        {'name': 'Tempo Pace Threshold Run', 'sets': '12 min Continuous', 'rest': '2 min'},
        {'name': 'Hill Sprints at 8% Incline', 'sets': '6 Rounds x 45s', 'rest': '45s'},
        {'name': 'Recovery Walk & Stretches', 'sets': '5 min Cool Down', 'rest': 'Done'},
      ],
    },
    {
      'id': 6,
      'title': 'Functional Mobility & Joint Rehab',
      'category': 'Yoga & Mobility',
      'categoryIndex': 3,
      'duration': '28 min',
      'calories': '160 kcal',
      'level': 'Beginner',
      'exercisesCount': 6,
      'rating': 4.9,
      'reviews': '1.1k',
      'trainer': 'Maya Lin',
      'trainerAvatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200&auto=format&fit=crop',
      'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600&auto=format&fit=crop',
      'equipment': 'Resistance Band',
      'tags': ['Shoulders', 'Hips', 'Ankles', 'Posture'],
      'exercises': [
        {'name': 'Shoulder Dislocates w/ Band', 'sets': '3 Sets x 15 Reps', 'rest': '20s'},
        {'name': 'World’s Greatest Stretch', 'sets': '5 Reps per side', 'rest': '20s'},
        {'name': '90/90 Hip Mobility Switches', 'sets': '10 Reps per side', 'rest': '30s'},
        {'name': 'Cat-Cow Thoracic Waves', 'sets': '15 Controlled Reps', 'rest': '15s'},
        {'name': 'Ankle Dorsiflexion Wall Rocks', 'sets': '12 Reps per side', 'rest': '15s'},
        {'name': 'Deep Squat Pry & Hold', 'sets': '3 Sets x 45s Hold', 'rest': '30s'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = 0;
    if (widget.initialCategory != null) {
      final found = _categories.indexWhere(
        (c) => (c['name'] as String).toLowerCase().contains(widget.initialCategory!.toLowerCase()),
      );
      if (found != -1) {
        _selectedCategoryIndex = found;
      }
    }
  }

  void _toggleBookmark(int id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_savedWorkouts.contains(id)) {
        _savedWorkouts.remove(id);
      } else {
        _savedWorkouts.add(id);
      }
    });
  }

  List<Map<String, dynamic>> get _filteredWorkouts {
    return _workouts.where((w) {
      // 1. Category Filter
      if (_selectedCategoryIndex != 0) {
        if (w['categoryIndex'] != _selectedCategoryIndex) return false;
      }

      // 2. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (w['title'] as String).toLowerCase();
        final trainer = (w['trainer'] as String).toLowerCase();
        final tags = (w['tags'] as List).map((e) => e.toString().toLowerCase()).join(' ');
        if (!title.contains(q) && !trainer.contains(q) && !tags.contains(q)) {
          return false;
        }
      }

      // 3. Filter Pills
      if (_selectedFilter == 'Under 30 Min') {
        final durStr = w['duration'] as String;
        final mins = int.tryParse(durStr.split(' ')[0]) ?? 40;
        if (mins > 30) return false;
      } else if (_selectedFilter == 'Bodyweight') {
        final eq = (w['equipment'] as String).toLowerCase();
        if (!eq.contains('bodyweight') && !eq.contains('no gear')) return false;
      } else if (_selectedFilter == 'Advanced') {
        if (w['level'] != 'Advanced') return false;
      } else if (_selectedFilter == 'Saved') {
        if (!_savedWorkouts.contains(w['id'])) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _categories[_selectedCategoryIndex];
    final filteredList = _filteredWorkouts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 1. Top Header Bar
            StaggeredSlideFade(index: 0, child: _buildTopHeader()),

            const SizedBox(height: 12),

            // Main Content Area
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 2. Search Bar
                  SliverToBoxAdapter(
                    child: StaggeredSlideFade(
                      index: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSearchBar(),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // 3. Category Horizontal Pills
                  SliverToBoxAdapter(
                    child: StaggeredSlideFade(
                      index: 2,
                      child: _buildCategoryPills(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 4. Hero Banner of Selected Category
                  SliverToBoxAdapter(
                    child: StaggeredSlideFade(
                      index: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildCategoryHeroCard(currentCategory),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // 5. Filter Chips & Results Count Bar
                  SliverToBoxAdapter(
                    child: StaggeredSlideFade(
                      index: 4,
                      child: _buildFilterChipsBar(filteredList.length),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 6. Workout Cards List
                  if (filteredList.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
                        child: _buildEmptyState(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final workout = filteredList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: StaggeredSlideFade(
                                index: 5 + (index % 4),
                                child: _buildWorkoutDetailCard(workout),
                              ),
                            );
                          },
                          childCount: filteredList.length,
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

  // -------------------------------------------------------------
  // 1. TOP HEADER BAR
  // -------------------------------------------------------------
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                'Workout Categories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Browse & Stream Guided Routines',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF0F172A),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. SEARCH BAR
  // -------------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search workouts, muscle group, coach...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _searchQuery = ''),
              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. CATEGORY PILLS
  // -------------------------------------------------------------
  Widget _buildCategoryPills() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;
          final color = cat['color'] as Color;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategoryIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. HERO BANNER OF CURRENT CATEGORY
  // -------------------------------------------------------------
  Widget _buildCategoryHeroCard(Map<String, dynamic> cat) {
    final gradientColors = cat['bannerColor'] as List<Color>;

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(cat['image'] as String),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  gradientColors[0].withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        cat['count'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 220,
                  child: Text(
                    cat['tagline'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
  // 5. FILTER CHIPS & RESULTS COUNT BAR
  // -------------------------------------------------------------
  Widget _buildFilterChipsBar(int count) {
    final filters = ['All', 'Under 30 Min', 'Bodyweight', 'Advanced', 'Saved'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workouts ($count)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    _selectedSort,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilter = filter);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
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
  // 6. WORKOUT DETAIL CARD
  // -------------------------------------------------------------
  Widget _buildWorkoutDetailCard(Map<String, dynamic> w) {
    final isSaved = _savedWorkouts.contains(w['id']);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailScreen(
              title: w['title'] as String,
              subtitle: '${w['category']} • ${w['level']}',
              image: w['image'] as String,
              trainer: w['trainer'] as String,
              trainerAvatar: w['trainerAvatar'] as String,
              duration: w['duration'] as String,
              level: w['level'] as String,
              rating: '${w['rating']}',
              calories: w['calories'] as String,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9)),
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
            // Top Image with badges
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    w['image'] as String,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),

                  // Top Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        w['category'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Bookmark Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleBookmark(w['id'] as int),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isSaved ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Info Badges over Image
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildImageBadge(Icons.timer_outlined, w['duration'] as String),
                            const SizedBox(width: 6),
                            _buildImageBadge(Icons.local_fire_department_rounded, w['calories'] as String, isHot: true),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.white, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                '${w['rating']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
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

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Coach info & Gear
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: NetworkImage(w['trainerAvatar'] as String),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        w['trainer'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.fitness_center_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        w['equipment'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Tag Pills & Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 4,
                        children: (w['tags'] as List).take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                          ],
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
  }

  Widget _buildImageBadge(IconData icon, String text, {bool isHot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isHot ? const Color(0xFFFB923C) : Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 48),
          const SizedBox(height: 12),
          Text(
            'No Workouts Found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try clearing your search query or switching category filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. WORKOUT DETAIL MODAL SHEET (EXERCISE BREAKDOWN)
  // -------------------------------------------------------------
  void _showWorkoutDetailModal(Map<String, dynamic> w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Modal Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Hero Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        w['image'] as String,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      w['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Metrics Strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildModalMetric(Icons.timer_outlined, 'Duration', w['duration'] as String),
                        _buildModalMetric(Icons.local_fire_department_rounded, 'Burn', w['calories'] as String),
                        _buildModalMetric(Icons.speed_rounded, 'Intensity', w['level'] as String),
                        _buildModalMetric(Icons.format_list_numbered_rounded, 'Moves', '${w['exercisesCount']} Sets'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Trainer Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(w['trainerAvatar'] as String),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w['trainer'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Certified Master Coach',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF0F172A)),
                                const SizedBox(width: 4),
                                Text(
                                  'Ask Coach',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Exercise Sequence Breakdown
                    Text(
                      'Workout Routine Breakdown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...((w['exercises'] as List).asMap().entries.map((entry) {
                      final i = entry.key;
                      final ex = entry.value as Map<String, String>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex['name']!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ex['sets']!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Rest: ${ex['rest']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Bottom Start Session Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF16A34A),
                              content: Text(
                                'Starting "${w['title']}" session!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Start Workout Now',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF16A34A), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
