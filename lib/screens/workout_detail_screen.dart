import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';
import 'workout_day_detail_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String? image;
  final String? trainer;
  final String? trainerAvatar;
  final String? duration;
  final String? level;
  final String? rating;
  final String? calories;

  const WorkoutDetailScreen({
    super.key,
    this.title,
    this.subtitle,
    this.image,
    this.trainer,
    this.trainerAvatar,
    this.duration,
    this.level,
    this.rating,
    this.calories,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  int _selectedWeekIndex = 0;
  bool _isBookmarked = false;
  bool _isDescriptionExpanded = false;
  final Set<int> _completedDays = {1, 2};

  final List<String> _weeks = ['All Days', 'Week 1', 'Week 2', 'Week 3', 'Week 4'];

  final List<Map<String, dynamic>> _programDays = [
    {
      'day': 1,
      'week': 1,
      'title': 'Chest & Tricep Hypertrophy',
      'focus': 'Upper Push',
      'duration': '45 min',
      'calories': '420 kcal',
      'exercisesCount': 7,
      'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=400&auto=format&fit=crop',
      'isCompleted': true,
      'isRestDay': false,
      'exercises': [
        {'name': 'Incline Dumbbell Press', 'detail': '4 Sets x 10-12 Reps'},
        {'name': 'Barbell Flat Bench Press', 'detail': '4 Sets x 8-10 Reps'},
        {'name': 'Cable Chest Flyes', 'detail': '3 Sets x 15 Reps'},
        {'name': 'Overhead Rope Tricep Extension', 'detail': '4 Sets x 12 Reps'},
        {'name': 'Skull Crushers', 'detail': '3 Sets x 12 Reps'},
        {'name': 'Dips to Failure', 'detail': '3 Sets to Failure'},
        {'name': 'Push-Up Burnout', 'detail': '2 Sets x 25 Reps'},
      ],
    },
    {
      'day': 2,
      'week': 1,
      'title': 'Back & Bicep Power Pull',
      'focus': 'Upper Pull',
      'duration': '50 min',
      'calories': '480 kcal',
      'exercisesCount': 8,
      'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=400&auto=format&fit=crop',
      'isCompleted': true,
      'isRestDay': false,
      'exercises': [
        {'name': 'Weighted Pull-Ups', 'detail': '4 Sets x 8 Reps'},
        {'name': 'Barbell Bent Over Row', 'detail': '4 Sets x 10 Reps'},
        {'name': 'Lat Pulldown (Wide Grip)', 'detail': '3 Sets x 12 Reps'},
        {'name': 'Seated Cable Row', 'detail': '3 Sets x 12 Reps'},
        {'name': 'Incline Dumbbell Curl', 'detail': '4 Sets x 12 Reps'},
        {'name': 'Hammer Curls', 'detail': '3 Sets x 15 Reps'},
        {'name': 'Face Pulls', 'detail': '4 Sets x 20 Reps'},
        {'name': 'Hanging Knee Tucks', 'detail': '3 Sets x 15 Reps'},
      ],
    },
    {
      'day': 3,
      'week': 1,
      'title': 'Active Recovery & Mobility Flow',
      'focus': 'Mobility & Joints',
      'duration': '25 min',
      'calories': '160 kcal',
      'exercisesCount': 5,
      'image': 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?q=80&w=400&auto=format&fit=crop',
      'isCompleted': false,
      'isRestDay': true,
      'exercises': [
        {'name': 'World’s Greatest Stretch', 'detail': '3 Sets x 6 Reps/side'},
        {'name': 'Cat-Cow Thoracic Waves', 'detail': '3 Sets x 12 Reps'},
        {'name': '90/90 Hip Switches', 'detail': '3 Sets x 10 Reps/side'},
        {'name': 'Deep Squat Hold with Reach', 'detail': '3 Sets x 45s'},
        {'name': 'Full Body Foam Rolling', 'detail': '10 min Routine'},
      ],
    },
    {
      'day': 4,
      'week': 1,
      'title': 'Quad Dominant Leg Blitz',
      'focus': 'Lower Push',
      'duration': '55 min',
      'calories': '540 kcal',
      'exercisesCount': 7,
      'image': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=400&auto=format&fit=crop',
      'isCompleted': false,
      'isRestDay': false,
      'exercises': [
        {'name': 'Barbell Back Squats', 'detail': '5 Sets x 8 Reps'},
        {'name': 'Bulgarian Split Squats', 'detail': '3 Sets x 10 Reps/leg'},
        {'name': 'Leg Press Heavy', 'detail': '4 Sets x 12 Reps'},
        {'name': 'Leg Extensions Drop Set', 'detail': '3 Sets x 15 Reps'},
        {'name': 'Standing Calf Raises', 'detail': '4 Sets x 20 Reps'},
        {'name': 'Walking Lunges w/ DBs', 'detail': '3 Sets x 20 Steps'},
        {'name': 'Plank Hold Finisher', 'detail': '3 Sets x 60s'},
      ],
    },
    {
      'day': 5,
      'week': 1,
      'title': 'Deltoid Sculpt & Core Shred',
      'focus': 'Shoulders & Abs',
      'duration': '40 min',
      'calories': '390 kcal',
      'exercisesCount': 6,
      'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=400&auto=format&fit=crop',
      'isCompleted': false,
      'isRestDay': false,
      'exercises': [
        {'name': 'Overhead Military Press', 'detail': '4 Sets x 8-10 Reps'},
        {'name': 'Dumbbell Lateral Raises', 'detail': '5 Sets x 15 Reps'},
        {'name': 'Rear Delt Cable Cross', 'detail': '4 Sets x 15 Reps'},
        {'name': 'Arnold Press', 'detail': '3 Sets x 12 Reps'},
        {'name': 'Hanging Leg Raises', 'detail': '4 Sets x 15 Reps'},
        {'name': 'Ab Wheel Rollouts', 'detail': '3 Sets x 12 Reps'},
      ],
    },
    {
      'day': 6,
      'week': 1,
      'title': 'Posterior Chain & Hamstring Power',
      'focus': 'Lower Pull',
      'duration': '45 min',
      'calories': '460 kcal',
      'exercisesCount': 6,
      'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=400&auto=format&fit=crop',
      'isCompleted': false,
      'isRestDay': false,
      'exercises': [
        {'name': 'Romanian Deadlifts', 'detail': '4 Sets x 10 Reps'},
        {'name': 'Lying Leg Curls', 'detail': '4 Sets x 12 Reps'},
        {'name': 'Hip Thrusts with Barbell', 'detail': '4 Sets x 12 Reps'},
        {'name': 'Glute Ham Raises', 'detail': '3 Sets x 10 Reps'},
        {'name': 'Farmer Carries', 'detail': '4 Sets x 50m'},
        {'name': 'Reverse Hyperextensions', 'detail': '3 Sets x 15 Reps'},
      ],
    },
    {
      'day': 7,
      'week': 1,
      'title': 'Complete Muscle Restoration',
      'focus': 'Rest & Recovery',
      'duration': '20 min',
      'calories': '110 kcal',
      'exercisesCount': 4,
      'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=400&auto=format&fit=crop',
      'isCompleted': false,
      'isRestDay': true,
      'exercises': [
        {'name': 'Diaphragmatic Breathing', 'detail': '5 min'},
        {'name': 'Hamstring & Glute Yoga Stretch', 'detail': '5 min per leg'},
        {'name': 'Spinal Twist & Chest Opener', 'detail': '5 min'},
        {'name': 'Hydration & Nutrition Check', 'detail': 'Recovery Prep'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredDays {
    if (_selectedWeekIndex == 0) return _programDays;
    return _programDays.where((d) => d['week'] == _selectedWeekIndex).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? '28-Day Hypertrophy Blast';
    final subtitle = widget.subtitle ?? 'Full body athletic conditioning & hypertrophy';
    final image = widget.image ?? 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=800&auto=format&fit=crop';
    final trainer = widget.trainer ?? 'Coach Marcus Vance';
    final trainerAvatar = widget.trainerAvatar ?? 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=200&auto=format&fit=crop';
    final duration = widget.duration ?? '4 Weeks';
    final level = widget.level ?? 'Intermediate';
    final rating = widget.rating ?? '4.9';
    final calories = widget.calories ?? '480 kcal/day';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Top Hero Section with Media & Overlays
              SliverToBoxAdapter(
                child: StaggeredSlideFade(
                  index: 0,
                  child: _buildHeroHeader(
                    title: title,
                    subtitle: subtitle,
                    image: image,
                    trainer: trainer,
                    trainerAvatar: trainerAvatar,
                    duration: duration,
                    level: level,
                    rating: rating,
                    calories: calories,
                  ),
                ),
              ),

              // 2. Program Details & Metrics Badges
              SliverToBoxAdapter(
                child: StaggeredSlideFade(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildProgramDetailsCard(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3. Program Schedule Header & Week Switcher
              SliverToBoxAdapter(
                child: StaggeredSlideFade(
                  index: 2,
                  child: _buildScheduleSectionHeader(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // 4. Workout Days Stack Cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dayData = _filteredDays[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: StaggeredSlideFade(
                          index: 3 + (index % 4),
                          child: _buildDayStackCard(dayData),
                        ),
                      );
                    },
                    childCount: _filteredDays.length,
                  ),
                ),
              ),
            ],
          ),

          // Fixed Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFixedBottomBar(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HERO HEADER
  // -------------------------------------------------------------
  Widget _buildHeroHeader({
    required String title,
    required String subtitle,
    required String image,
    required String trainer,
    required String trainerAvatar,
    required String duration,
    required String level,
    required String rating,
    required String calories,
  }) {
    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF0F172A),
            ),
          ),

          // Dark Gradient Vignette
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                  const Color(0xFFF8FAFC).withValues(alpha: 0.95),
                  const Color(0xFFF8FAFC),
                ],
                stops: const [0.0, 0.35, 0.65, 0.92, 1.0],
              ),
            ),
          ),

          // Top Nav Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isBookmarked = !_isBookmarked);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: _isBookmarked ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: Color(0xFF0F172A),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Hero Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Rating Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FEATURED PROGRAM',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            rating,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Main Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. PROGRAM DETAILS CARD
  // -------------------------------------------------------------
  Widget _buildProgramDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Metric Capsules
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailMetric(Icons.calendar_today_rounded, 'Duration', '28 Days', const Color(0xFF16A34A)),
              _buildDetailMetric(Icons.local_fire_department_rounded, 'Avg. Burn', '450 kcal', const Color(0xFFEA580C)),
              _buildDetailMetric(Icons.speed_rounded, 'Level', 'Advanced', const Color(0xFF8B5CF6)),
              _buildDetailMetric(Icons.fitness_center_rounded, 'Equipment', 'Gym / DB', const Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Coach Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  widget.trainerAvatar ?? 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=200&auto=format&fit=crop',
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trainer ?? 'Coach Marcus Vance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'IFBB Pro & Master Athletic Coach',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Verified',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overview paragraph with Read More
          GestureDetector(
            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Text(
              _isDescriptionExpanded
                  ? 'A scientifically sequenced 28-day progressive overload program designed to trigger maximum myofibrillar hypertrophy while optimizing central nervous system recovery. Includes high-intensity supersets, compound lifts, and joint mobility routines.'
                  : 'A scientifically sequenced 28-day progressive overload program designed to trigger maximum myofibrillar hypertrophy...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. SCHEDULE SECTION HEADER & WEEK SWITCHER
  // -------------------------------------------------------------
  Widget _buildScheduleSectionHeader() {
    final completedCount = _completedDays.length;
    final totalDays = _programDays.length;
    final progressFactor = completedCount / totalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Program Days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '$completedCount of $totalDays Completed',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Progress Line
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressFactor,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Week Filter Tabs
        SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _weeks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final week = _weeks[index];
              final isSelected = _selectedWeekIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedWeekIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    week,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
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
  // 4. DAY STACK CARD WITH PLAY BUTTON ON RIGHT
  // -------------------------------------------------------------
  Widget _buildDayStackCard(Map<String, dynamic> day) {
    final dayNum = day['day'] as int;
    final isCompleted = _completedDays.contains(dayNum);
    final isRest = day['isRestDay'] as bool;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDayDetailScreen(
              dayNumber: day['day'] as int,
              weekNumber: day['week'] as int,
              title: day['title'] as String,
              focus: day['focus'] as String,
              duration: day['duration'] as String,
              calories: day['calories'] as String,
              image: day['image'] as String,
              coachName: widget.trainer,
              coachAvatar: widget.trainerAvatar,
            ),
          ),
        );
      },
      child: Container(
        height: 102,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFF1F5F9),
            width: isCompleted ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left Day Image Thumbnail
            Stack(
              children: [
                SizedBox(
                  width: 95,
                  height: double.infinity,
                  child: Image.network(
                    day['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                Container(
                  width: 95,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                // Day Pill on Image
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF16A34A) : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Text(
                      'DAY ${dayNum < 10 ? '0$dayNum' : dayNum}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Completed Checkmark or Focus Pill
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: isCompleted
                      ? Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            day['focus'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                ),
              ],
            ),

            // Middle Content Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 3),
                        Text(
                          day['duration'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.local_fire_department_rounded, size: 12, color: Color(0xFFEA580C)),
                        const SizedBox(width: 2),
                        Text(
                          day['calories'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRest ? 'Active Recovery Routine' : '${day['exercisesCount']} Exercises Planned',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isRest ? const Color(0xFF0D9488) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right PLAY Button
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDayDetailScreen(
                        dayNumber: day['day'] as int,
                        weekNumber: day['week'] as int,
                        title: day['title'] as String,
                        focus: day['focus'] as String,
                        duration: day['duration'] as String,
                        calories: day['calories'] as String,
                        image: day['image'] as String,
                        coachName: widget.trainer,
                        coachAvatar: widget.trainerAvatar,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF334155)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted ? const Color(0xFF0F172A) : const Color(0xFF16A34A)).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
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
  // 5. EXERCISE BREAKDOWN MODAL SHEET
  // -------------------------------------------------------------
  void _showDayExercisePreviewModal(Map<String, dynamic> day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
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

              // Title & Day Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAY ${day['day']} WORKOUT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          day['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        day['duration'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Exercise List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: (day['exercises'] as List).length,
                  itemBuilder: (context, index) {
                    final ex = (day['exercises'] as List)[index] as Map<String, String>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
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
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ex['detail']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Play Button CTA in Modal
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _startWorkoutSession(day);
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
                          'Start Day ${day['day']} Session',
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
        );
      },
    );
  }

  void _startWorkoutSession(Map<String, dynamic> day) {
    HapticFeedback.heavyImpact();
    final dayNum = day['day'] as int;
    setState(() {
      _completedDays.add(dayNum);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Starting Day $dayNum: ${day['title']}!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. FIXED BOTTOM ACTION BAR
  // -------------------------------------------------------------
  Widget _buildFixedBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next Up: Day 03',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
              Text(
                'Mobility & Core',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_programDays.length > 2) {
                  final day = _programDays[2];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDayDetailScreen(
                        dayNumber: day['day'] as int,
                        weekNumber: day['week'] as int,
                        title: day['title'] as String,
                        focus: day['focus'] as String,
                        duration: day['duration'] as String,
                        calories: day['calories'] as String,
                        image: day['image'] as String,
                        coachName: widget.trainer,
                        coachAvatar: widget.trainerAvatar,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
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
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'Continue Workout',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
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
    );
  }
}
