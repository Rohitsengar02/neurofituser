import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';
import '../services/workouts_backend_service.dart';
import '../services/category_backend_service.dart';
import 'workout_day_detail_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String? workoutId;
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
    this.workoutId,
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
  final Set<int> _completedDays = {1};

  final List<String> _weeks = ['All Days', 'Week 1', 'Week 2', 'Week 3', 'Week 4'];
  final WorkoutsBackendService _workoutsService = WorkoutsBackendService();

  @override
  void initState() {
    super.initState();
    _workoutsService.addListener(_onServiceUpdate);
    if (_workoutsService.workouts.isEmpty) {
      _workoutsService.fetchWorkouts();
    }
  }

  @override
  void dispose() {
    _workoutsService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  WorkoutModel? get _liveWorkout {
    final workouts = _workoutsService.workouts;
    if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
      final found = workouts.firstWhere(
        (w) => w.id == widget.workoutId,
        orElse: () => WorkoutModel(id: '', title: '', category: '', imageUrl: ''),
      );
      if (found.id.isNotEmpty) return found;
    }
    if (widget.title != null && widget.title!.isNotEmpty) {
      final found = workouts.firstWhere(
        (w) => w.title.toLowerCase().contains(widget.title!.toLowerCase()),
        orElse: () => WorkoutModel(id: '', title: '', category: '', imageUrl: ''),
      );
      if (found.id.isNotEmpty) return found;
    }
    return null;
  }

  List<WorkoutDayModel> get _daysList {
    final workout = _liveWorkout;
    if (workout != null && workout.days.isNotEmpty) {
      return workout.days;
    }

    // Default 4 Days structure fallback
    final fallbackExercises = workout?.exercises ?? [];
    return [
      WorkoutDayModel(
        dayNumber: 1,
        weekNumber: 1,
        title: '${workout?.title ?? widget.title ?? "Upper Body"} Hypertrophy',
        focus: 'Upper Body Focus',
        durationMinutes: workout?.durationMinutes ?? 45,
        caloriesBurn: workout?.caloriesBurn ?? 420,
        isRestDay: false,
        exercises: fallbackExercises,
      ),
      WorkoutDayModel(
        dayNumber: 2,
        weekNumber: 1,
        title: 'Lower Body & Core Shred',
        focus: 'Lower Body & Core',
        durationMinutes: 40,
        caloriesBurn: 380,
        isRestDay: false,
        exercises: fallbackExercises,
      ),
      WorkoutDayModel(
        dayNumber: 3,
        weekNumber: 1,
        title: 'Active Mobility & Recovery Flow',
        focus: 'Mobility & Joints',
        durationMinutes: 25,
        caloriesBurn: 160,
        isRestDay: true,
        exercises: fallbackExercises,
      ),
      WorkoutDayModel(
        dayNumber: 4,
        weekNumber: 1,
        title: 'Full Body HIIT Conditioning',
        focus: 'Metabolic Burn',
        durationMinutes: 35,
        caloriesBurn: 450,
        isRestDay: false,
        exercises: fallbackExercises,
      ),
    ];
  }

  List<WorkoutDayModel> get _filteredDays {
    final allDays = _daysList;
    if (_selectedWeekIndex == 0) return allDays;
    return allDays.where((d) => d.weekNumber == _selectedWeekIndex).toList();
  }

  @override
  Widget build(BuildContext context) {
    final workout = _liveWorkout;

    final title = workout?.title ?? widget.title ?? 'Workout Plan';
    final subtitle = workout?.subtitle ?? widget.subtitle ?? 'High Intensity & Strength Training';
    final image = workout?.imageUrl ?? widget.image ?? 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=800&auto=format&fit=crop';
    final trainer = workout?.coach ?? widget.trainer ?? 'Coach Vikram';
    final duration = workout != null ? '${workout.durationMinutes} min' : (widget.duration ?? '45 min');
    final level = workout?.level ?? widget.level ?? 'Intermediate';
    final rating = workout != null ? '${workout.rating}' : (widget.rating ?? '4.9');
    final calories = workout != null ? '${workout.caloriesBurn} kcal' : (widget.calories ?? '480 kcal');
    final description = (workout != null && workout.description.isNotEmpty)
        ? workout.description
        : 'A progressive overload program designed to build muscular endurance, strength, and caloric burn with real-time tracking.';

    final filteredDays = _filteredDays;

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
                    duration: duration,
                    level: level,
                    rating: rating,
                    calories: calories,
                    mediaType: workout?.mediaType ?? 'image',
                  ),
                ),
              ),

              // 2. Program Details & Metrics Badges
              SliverToBoxAdapter(
                child: StaggeredSlideFade(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildProgramDetailsCard(
                      duration: duration,
                      calories: calories,
                      level: level,
                      trainer: trainer,
                      description: description,
                    ),
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

              // 4. Workout Days Stack Cards List
              if (filteredDays.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No routine days added yet for this week.',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final day = filteredDays[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: StaggeredSlideFade(
                            index: 3 + (index % 4),
                            child: _buildDayStackCard(day, image),
                          ),
                        );
                      },
                      childCount: filteredDays.length,
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
            child: _buildFixedBottomBar(title),
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
    required String duration,
    required String level,
    required String rating,
    required String calories,
    required String mediaType,
  }) {
    final isVid = mediaType == 'video' || image.toLowerCase().endsWith('.mp4') || image.toLowerCase().endsWith('.mov');

    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          isVid
              ? Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Icon(Icons.play_arrow_rounded, color: Color(0xFF38BDF8), size: 50),
                  ),
                )
              : Image.network(
                  CategoryBackendService.getDisplayableImageUrl(image),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
                ),

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
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isBookmarked = !_isBookmarked);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: _isBookmarked ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
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

                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
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
  Widget _buildProgramDetailsCard({
    required String duration,
    required String calories,
    required String level,
    required String trainer,
    required String description,
  }) {
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
          Row(
            children: [
              Expanded(child: _buildDetailMetric(Icons.timer_rounded, 'Duration', duration, const Color(0xFF0284C7))),
              const SizedBox(width: 8),
              Expanded(child: _buildDetailMetric(Icons.local_fire_department_rounded, 'Burn', calories, const Color(0xFFEA580C))),
              const SizedBox(width: 8),
              Expanded(child: _buildDetailMetric(Icons.speed_rounded, 'Level', level, const Color(0xFF8B5CF6))),
              const SizedBox(width: 8),
              Expanded(child: _buildDetailMetric(Icons.person_rounded, 'Coach', trainer, const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Text(
              _isDescriptionExpanded || description.length <= 120
                  ? description
                  : '${description.substring(0, 115)}...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SCHEDULE SECTION HEADER & WEEK SWITCHER
  // -------------------------------------------------------------
  Widget _buildScheduleSectionHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Program Routine Days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${_daysList.length} Total Days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _weeks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final weekName = _weeks[index];
              final isSelected = _selectedWeekIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedWeekIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    weekName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
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
  // 4. DAY STACK CARD
  // -------------------------------------------------------------
  Widget _buildDayStackCard(WorkoutDayModel day, String defaultImage) {
    final dayNum = day.dayNumber < 10 ? '0${day.dayNumber}' : '${day.dayNumber}';
    final isCompleted = _completedDays.contains(day.dayNumber);
    final dayExercises = day.exercises.isNotEmpty
        ? day.exercises
        : (_liveWorkout?.exercises ?? []);
    final exList = dayExercises.map((e) => e.toJson()).toList();

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDayDetailScreen(
              workoutId: _liveWorkout?.id ?? widget.workoutId ?? 'workout_1',
              dayNumber: day.dayNumber,
              weekNumber: day.weekNumber,
              title: day.title,
              focus: day.focus,
              duration: '${day.durationMinutes} min',
              calories: '${day.caloriesBurn} kcal',
              image: defaultImage,
              exercises: exList,
              coachName: _liveWorkout?.coach ?? widget.trainer,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
            width: isCompleted ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Strip
              Container(
                width: 6,
                color: day.isRestDay
                    ? const Color(0xFF8B5CF6)
                    : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF0284C7)),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'DAY $dayNum • WEEK ${day.weekNumber}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: day.isRestDay ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  day.focus,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: day.isRestDay ? const Color(0xFF7C3AED) : const Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            isCompleted ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        day.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          _buildMiniBadge(Icons.timer_outlined, '${day.durationMinutes} min'),
                          const SizedBox(width: 8),
                          _buildMiniBadge(Icons.local_fire_department_rounded, '${day.caloriesBurn} kcal', isHot: true),
                          const SizedBox(width: 8),
                          _buildMiniBadge(Icons.fitness_center_rounded, '${day.exercises.length} Movements'),
                        ],
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
  }

  Widget _buildMiniBadge(IconData icon, String label, {bool isHot = false}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: isHot ? const Color(0xFFEA580C) : const Color(0xFF64748B)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. FIXED BOTTOM BAR
  // -------------------------------------------------------------
  Widget _buildFixedBottomBar(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          final firstDay = _daysList.isNotEmpty ? _daysList[0] : null;
          if (firstDay != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDayDetailScreen(
                  workoutId: _liveWorkout?.id ?? widget.workoutId ?? 'workout_1',
                  dayNumber: firstDay.dayNumber,
                  weekNumber: firstDay.weekNumber,
                  title: firstDay.title,
                  focus: firstDay.focus,
                  duration: '${firstDay.durationMinutes} min',
                  calories: '${firstDay.caloriesBurn} kcal',
                  image: widget.image ?? '',
                  exercises: firstDay.exercises.map((e) => e.toJson()).toList(),
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          'Start Program Routine 🔥',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
