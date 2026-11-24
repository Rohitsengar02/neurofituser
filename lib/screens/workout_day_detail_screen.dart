import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../widgets/staggered_slide_fade.dart';
import '../services/category_backend_service.dart';
import '../services/user_workout_service.dart';
import 'active_workout_screen.dart';

class WorkoutDayDetailScreen extends StatefulWidget {
  final String workoutId;
  final int dayNumber;
  final int weekNumber;
  final String title;
  final String focus;
  final String duration;
  final String calories;
  final String image;
  final List<Map<String, dynamic>>? exercises;
  final String? coachName;
  final String? coachAvatar;

  const WorkoutDayDetailScreen({
    super.key,
    this.workoutId = 'workout_1',
    required this.dayNumber,
    this.weekNumber = 1,
    required this.title,
    required this.focus,
    required this.duration,
    required this.calories,
    required this.image,
    this.exercises,
    this.coachName,
    this.coachAvatar,
  });

  @override
  State<WorkoutDayDetailScreen> createState() => _WorkoutDayDetailScreenState();
}

class _WorkoutDayDetailScreenState extends State<WorkoutDayDetailScreen> {
  final Set<String> _completedExerciseKeys = {};
  UserWorkoutProgress? _userProgress;
  bool _isBookmarked = false;

  late final List<Map<String, dynamic>> _exerciseList;

  @override
  void initState() {
    super.initState();
    _exerciseList = widget.exercises != null && widget.exercises!.isNotEmpty
        ? widget.exercises!
        : [
      {
        'id': 1,
        'name': 'Incline Dumbbell Bench Press',
        'phase': 'Main Compound',
        'target': 'Upper Pectorals',
        'sets': '4 Sets',
        'reps': '10-12 Reps',
        'rest': '60 sec',
        'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=300&auto=format&fit=crop',
        'tip': 'Keep elbows at a 45-degree angle to protect shoulder joints.',
      },
      {
        'id': 2,
        'name': 'Flat Barbell Bench Press',
        'phase': 'Main Compound',
        'target': 'Mid Chest & Front Delts',
        'sets': '4 Sets',
        'reps': '8-10 Reps',
        'rest': '90 sec',
        'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=300&auto=format&fit=crop',
        'tip': 'Drive feet firmly into the floor and maintain a natural arch in your lower back.',
      },
      {
        'id': 3,
        'name': 'Standing Cable Chest Flyes',
        'phase': 'Isolation',
        'target': 'Inner Squeeze & Stretch',
        'sets': '3 Sets',
        'reps': '15 Reps',
        'rest': '45 sec',
        'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=300&auto=format&fit=crop',
        'tip': 'Pause for 1 second at full contraction for peak muscle fiber activation.',
      },
      {
        'id': 4,
        'name': 'Overhead Rope Tricep Extension',
        'phase': 'Tricep Focus',
        'target': 'Long Head Triceps',
        'sets': '4 Sets',
        'reps': '12-15 Reps',
        'rest': '45 sec',
        'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=300&auto=format&fit=crop',
        'tip': 'Keep your upper arms locked beside your ears without flaring outward.',
      },
      {
        'id': 5,
        'name': 'Barbell Skull Crushers',
        'phase': 'Tricep Focus',
        'target': 'Lateral & Medial Head',
        'sets': '3 Sets',
        'reps': '10-12 Reps',
        'rest': '60 sec',
        'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=300&auto=format&fit=crop',
        'tip': 'Lower the bar slowly to your hairline with controlled 3-second negatives.',
      },
      {
        'id': 6,
        'name': 'Parallel Bar Dips',
        'phase': 'Finisher',
        'target': 'Lower Chest & Triceps',
        'sets': '3 Sets',
        'reps': 'To Failure',
        'rest': '60 sec',
        'image': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=300&auto=format&fit=crop',
        'tip': 'Lean forward 30 degrees to shift maximum load onto chest fibers.',
      },
      {
        'id': 7,
        'name': 'Explosive Push-Up Burnout',
        'phase': 'Burnout',
        'target': 'Full Pectoral Fatigue',
        'sets': '2 Sets',
        'reps': '25 Reps',
        'rest': '30 sec',
        'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=300&auto=format&fit=crop',
        'tip': 'Keep core rigid in a straight line from neck to heels.',
      },
    ];

    UserWorkoutService.instance.addListener(_onServiceUpdate);
    _loadUserProgress();
  }

  @override
  void dispose() {
    UserWorkoutService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    final cached = UserWorkoutService.instance.getCachedProgress(widget.workoutId, widget.dayNumber);
    if (cached != null && mounted) {
      setState(() {
        _userProgress = cached;
        _completedExerciseKeys.clear();
        _completedExerciseKeys.addAll(cached.completedExercises);
      });
    }
  }

  Future<void> _loadUserProgress() async {
    final cached = UserWorkoutService.instance.getCachedProgress(widget.workoutId, widget.dayNumber);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _userProgress = cached;
          _completedExerciseKeys.clear();
          _completedExerciseKeys.addAll(cached.completedExercises);
        });
      }
    }
    final progress = await UserWorkoutService.instance.fetchProgress(widget.workoutId, widget.dayNumber);
    if (mounted) {
      setState(() {
        _userProgress = progress;
        _completedExerciseKeys.clear();
        _completedExerciseKeys.addAll(progress.completedExercises);
      });
    }
  }

  String _getExerciseKey(Map<String, dynamic> ex, int index) {
    final rawExId = ex['exerciseId']?.toString();
    final rawId = ex['id']?.toString();
    final rawMongoId = ex['_id']?.toString();
    if (rawExId != null && rawExId.trim().isNotEmpty) {
      return rawExId.trim();
    }
    if (rawId != null && rawId.trim().isNotEmpty) {
      return rawId.trim();
    }
    if (rawMongoId != null && rawMongoId.trim().isNotEmpty) {
      return rawMongoId.trim();
    }
    return '$index';
  }

  bool _isExerciseDone(Map<String, dynamic> ex, int index) {
    if (_userProgress?.isCompleted == true) return true;
    final key = _getExerciseKey(ex, index);
    final altKey = '$index';
    final title = (ex['title'] ?? ex['name'] ?? '').toString().trim();
    return _completedExerciseKeys.contains(key) ||
        _completedExerciseKeys.contains(altKey) ||
        (title.isNotEmpty && _completedExerciseKeys.contains(title));
  }

  void _toggleExerciseComplete(Map<String, dynamic> ex, int index) {
    HapticFeedback.lightImpact();
    final key = _getExerciseKey(ex, index);
    final altKey = '$index';
    final title = (ex['title'] ?? ex['name'] ?? '').toString().trim();
    final isDoneNow = !_isExerciseDone(ex, index);

    setState(() {
      if (isDoneNow) {
        _completedExerciseKeys.add(key);
        _completedExerciseKeys.add(altKey);
        if (title.isNotEmpty) _completedExerciseKeys.add(title);
      } else {
        _completedExerciseKeys.remove(key);
        _completedExerciseKeys.remove(altKey);
        if (title.isNotEmpty) _completedExerciseKeys.remove(title);
      }
    });

    UserWorkoutService.instance.toggleExerciseCompletion(
      workoutId: widget.workoutId,
      dayNumber: widget.dayNumber,
      exerciseId: key,
      isDone: isDoneNow,
    );
    if (altKey != key) {
      UserWorkoutService.instance.toggleExerciseCompletion(
        workoutId: widget.workoutId,
        dayNumber: widget.dayNumber,
        exerciseId: altKey,
        isDone: isDoneNow,
      );
    }
  }

  Future<void> _confirmResetWorkout() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Workout Day?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'This will clear your completed exercises and restart this session from Step 1.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      setState(() {
        _completedExerciseKeys.clear();
      });
      await UserWorkoutService.instance.resetWorkout(
        widget.workoutId,
        widget.dayNumber,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout progress reset to Step 1',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = 0;
    for (int i = 0; i < _exerciseList.length; i++) {
      if (_isExerciseDone(_exerciseList[i], i + 1)) {
        completedCount++;
      }
    }
    final totalCount = _exerciseList.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Hero Workout Cover Image & Day Header
              SliverToBoxAdapter(
                child: _buildHeroTopSection(),
              ),

              // 2. Overview Info & Coach Tip Card
              SliverToBoxAdapter(
                child: StaggeredSlideFade(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildCoachTipAndTargetCard(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3. Exercise Stack Header & Live Progress
              SliverToBoxAdapter(
                child: StaggeredSlideFade(
                  index: 2,
                  child: _buildExercisesHeader(completedCount, totalCount, progress),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // 4. All Exercises Stack List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exercise = _exerciseList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: StaggeredSlideFade(
                          index: 3 + (index % 4),
                          child: _buildExerciseCard(exercise, index + 1),
                        ),
                      );
                    },
                    childCount: _exerciseList.length,
                  ),
                ),
              ),
            ],
          ),

          // Fixed Bottom Action Bar with Start Workout CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStartExerciseBottomBar(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. HERO TOP SECTION
  // -------------------------------------------------------------
  Widget _buildHeroTopSection() {
    final dayStr = widget.dayNumber < 10 ? '0${widget.dayNumber}' : '${widget.dayNumber}';

    return SizedBox(
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top Workout Image
          Image.network(
            CategoryBackendService.getDisplayableImageUrl(widget.image),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF0F172A),
              child: const Icon(Icons.fitness_center_rounded, color: Colors.white54, size: 48),
            ),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                  const Color(0xFFF8FAFC).withValues(alpha: 0.95),
                  const Color(0xFFF8FAFC),
                ],
                stops: const [0.0, 0.35, 0.65, 0.92, 1.0],
              ),
            ),
          ),

          // Top App Bar Icons
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

          // Bottom Day Details Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Badge & Focus Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'DAY $dayStr • WEEK ${widget.weekNumber}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
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
                        child: Text(
                          widget.focus,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Main Title
                Text(
                  widget.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),

                // Metrics Row (Wrap prevents right overflow)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildTopMetricBadge(Icons.timer_outlined, widget.duration),
                    _buildTopMetricBadge(Icons.local_fire_department_rounded, widget.calories, isHot: true),
                    _buildTopMetricBadge(Icons.fitness_center_rounded, '${_exerciseList.length} Moves'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetricBadge(IconData icon, String label, {bool isHot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isHot ? const Color(0xFFEA580C) : const Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. COACH TIP & TARGET MUSCLES CARD
  // -------------------------------------------------------------
  Widget _buildCoachTipAndTargetCard() {
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
          // Target Muscles Tags
          Row(
            children: [
              const Icon(Icons.accessibility_new_rounded, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Text(
                'Target Muscles: ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ['Pectorals', 'Triceps', 'Anterior Delts', 'Core'].map((m) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Coach Pro Tip Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    widget.coachAvatar ?? 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=200&auto=format&fit=crop',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.coachName ?? 'Coach Marcus',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF16A34A)),
                          const Spacer(),
                          Text(
                            'PRO TIP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF16A34A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Focus on a 3-second slow eccentric (lowering) phase on all compound presses to maximize muscle hypertrophy.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF166534),
                          height: 1.35,
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
  // 3. EXERCISE STACK HEADER & PROGRESS
  // -------------------------------------------------------------
  Widget _buildExercisesHeader(int completed, int total, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises Stack ($total)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '$completed / $total Done',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
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
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. EXERCISE CARD IN STACK
  // -------------------------------------------------------------
  Widget _buildExerciseCard(Map<String, dynamic> ex, int index) {
    // Support both backend format (exerciseId, title, sets as int) and legacy demo format (id as int, name, sets as String)
    final isDone = _isExerciseDone(ex, index);

    // Exercise name: backend uses 'title', demo uses 'name'
    final name = (ex['title'] ?? ex['name'] ?? 'Exercise ${index + 1}').toString();
    // Image / GIF: backend uses 'mediaUrl' or 'gifUrl' or 'imageUrl', demo uses 'image'
    final imageUrl = (ex['mediaUrl'] ?? ex['gifUrl'] ?? ex['imageUrl'] ?? ex['image'] ?? ex['videoUrl'] ?? '').toString();
    // Phase/category label: backend uses 'muscleGroup', demo uses 'phase'
    final phase = (ex['phase'] ?? ex['muscleGroup'] ?? ex['bodyPart'] ?? 'Movement').toString();
    // Target: demo uses 'target', backend uses 'muscleGroup'
    final target = (ex['target'] ?? ex['muscleGroup'] ?? '').toString();
    // Sets & reps: backend sends int, demo sends String
    final setsVal = ex['sets'];
    final repsVal = ex['reps'];
    final setsStr = setsVal is int ? '$setsVal Sets' : (setsVal?.toString() ?? '3 Sets');
    final repsStr = repsVal is int ? '$repsVal Reps' : (repsVal?.toString() ?? '12 Reps');
    // Rest: backend sends 'restSeconds' as int, demo sends 'rest' as String
    final restVal = ex['restSeconds'] ?? ex['rest'];
    final restStr = restVal is int ? '${restVal}s Rest' : (restVal?.toString() ?? '45s Rest');
    // Tip / Instructions
    final tip = (ex['instructions'] ?? ex['instructionText'] ?? ex['tip'] ?? ex['tips'] ?? 'Focus on controlled form and full range of motion.').toString();

    return GestureDetector(
      onTap: () => _showExerciseDetailSheet(ex, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9),
            width: isDone ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDone
                  ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                  : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Exercise Thumbnail (Video, GIF, or Image)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 75,
                          height: 75,
                          child: _LoopingExerciseMedia(
                            mediaUrl: imageUrl,
                            mediaType: (ex['mediaType'] ?? '').toString(),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF16A34A)
                                  : Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isDone) ...[
                                  const Icon(Icons.check_rounded, size: 9, color: Colors.white),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  '#$index',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
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
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  phase,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isDone ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (target.isNotEmpty && target != phase) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  target,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF16A34A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildSetPill(Icons.repeat_rounded, '$setsStr x $repsStr'),
                            _buildSetPill(Icons.timer_outlined, restStr),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Checkbox / Mark Done Button
                  GestureDetector(
                    onTap: () => _toggleExerciseComplete(ex, index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF16A34A) : const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                        boxShadow: isDone
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: isDone ? Colors.white : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pro Form Tip footer on card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 13, color: Color(0xFFEAB308)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4.5 EXERCISE DETAIL BOTTOM SLIDER SHEET (Dynamic Info & GIF)
  // -------------------------------------------------------------
  void _showExerciseDetailSheet(Map<String, dynamic> ex, int index) {
    HapticFeedback.mediumImpact();
    final name = (ex['title'] ?? ex['name'] ?? 'Exercise ${index + 1}').toString();
    final imageUrl = (ex['mediaUrl'] ?? ex['gifUrl'] ?? ex['imageUrl'] ?? ex['image'] ?? ex['videoUrl'] ?? '').toString();
    final mediaType = (ex['mediaType'] ?? '').toString();
    final muscle = (ex['muscleGroup'] ?? ex['target'] ?? ex['bodyPart'] ?? ex['phase'] ?? '').toString();

    final setsVal = ex['sets'];
    final repsVal = ex['reps'];
    final setsStr = setsVal is int ? '$setsVal Sets' : (setsVal?.toString() ?? '3 Sets');
    final repsStr = repsVal is int ? '$repsVal Reps' : (repsVal?.toString() ?? '12 Reps');
    final restVal = ex['restSeconds'] ?? ex['rest'];
    final restStr = restVal is int ? '${restVal}s Rest' : (restVal?.toString() ?? '45s Rest');

    final rawInstructions = (ex['instructions'] ?? ex['instructionText'] ?? ex['tip'] ?? ex['tips'] ?? '').toString();
    final List<Map<String, String>> steps = [];

    final rawLines = rawInstructions
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (rawLines.isNotEmpty) {
      for (int i = 0; i < rawLines.length; i++) {
        final line = rawLines[i].trim();
        final cleanDesc = line
            .replaceFirst(
              RegExp(
                r'^(step\s*\d*[\.\:]?\s*|\d+[\.\)]\s*)',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
        steps.add({
          'step': '${i + 1}',
          'title': 'Step ${i + 1}',
          'desc': cleanDesc.isNotEmpty ? cleanDesc : line,
        });
      }
    } else {
      steps.add({
        'step': '1',
        'title': 'Starting Position',
        'desc':
            'Set up your stance and grip. Engage your core, retract shoulder blades, and establish a stable base before lifting.',
      });
      steps.add({
        'step': '2',
        'title': 'Execution Phase',
        'desc':
            'Perform the movement with controlled tempo. Focus on mind-muscle connection and full range of motion.',
      });
      steps.add({
        'step': '3',
        'title': 'Peak Contraction',
        'desc':
            'Squeeze the target muscle at the top of the movement for 1-2 seconds. Maintain proper form throughout.',
      });
      steps.add({
        'step': '4',
        'title': 'Eccentric (Lowering)',
        'desc':
            'Lower the weight slowly with a 3-second negative. Control the descent to maximize muscle fiber recruitment.',
      });
    }

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
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Media (Video/GIF) - Covering edge to edge inside card
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _LoopingExerciseMedia(
                              mediaUrl: imageUrl,
                              mediaType: mediaType,
                              fit: BoxFit.cover,
                            ),
                            if (muscle.isNotEmpty)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    muscle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _buildDetailStatPill(Icons.repeat_rounded, setsStr),
                          const SizedBox(width: 8),
                          _buildDetailStatPill(Icons.fitness_center_rounded, repsStr),
                          const SizedBox(width: 8),
                          _buildDetailStatPill(Icons.timer_outlined, restStr),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // How To Perform Steps from Admin
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'How To Perform',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...steps.map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  step['step']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step['title']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      step['desc']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Got It, Let\'s Go! 💪',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
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

  Widget _buildDetailStatPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. START / CONTINUE / RESET EXERCISE BOTTOM BAR
  // -------------------------------------------------------------
  Widget _buildStartExerciseBottomBar() {
    final bool isCompleted = _userProgress?.isCompleted ?? false;
    final bool isInProgress = _userProgress?.isInProgress ?? false;
    final int currentStep = (_userProgress?.currentExerciseIndex ?? 0);
    final int totalSteps = _exerciseList.length;
    final int stepDisplay = (currentStep + 1).clamp(1, totalSteps > 0 ? totalSteps : 1);

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
          // If in progress or completed, show Reset button
          if (isInProgress || isCompleted) ...[
            GestureDetector(
              onTap: _confirmResetWorkout,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reset',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Session Time',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  widget.duration,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],

          // Action CTA Button
          Expanded(
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.heavyImpact();
                final startIdx = isInProgress ? currentStep : 0;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveWorkoutScreen(
                      workoutId: widget.workoutId,
                      dayTitle: widget.title,
                      dayNumber: widget.dayNumber,
                      initialExerciseIndex: startIdx,
                      exercises: _exerciseList,
                    ),
                  ),
                );
                if (mounted) {
                  _loadUserProgress();
                }
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [const Color(0xFF059669), const Color(0xFF047857)]
                        : isInProgress
                            ? [const Color(0xFF22C55E), const Color(0xFF15803D)]
                            : [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted
                              ? const Color(0xFF047857)
                              : const Color(0xFF16A34A))
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : isInProgress
                              ? Icons.play_circle_filled_rounded
                              : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isCompleted
                            ? 'Day Completed! 🔥'
                            : isInProgress
                                ? 'Continue ($stepDisplay/$totalSteps)'
                                : 'Start Exercise',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

// -------------------------------------------------------------
// LOOPING EXERCISE MEDIA PLAYER (SUPPORT MP4, MOV, WEBM, GIF, IMAGE)
// -------------------------------------------------------------
class _LoopingExerciseMedia extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;
  final BoxFit fit;

  const _LoopingExerciseMedia({
    required this.mediaUrl,
    required this.mediaType,
    this.fit = BoxFit.contain,
  });

  @override
  State<_LoopingExerciseMedia> createState() => _LoopingExerciseMediaState();
}

class _LoopingExerciseMediaState extends State<_LoopingExerciseMedia> {
  VideoPlayerController? _videoController;
  bool _isInit = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  @override
  void didUpdateWidget(covariant _LoopingExerciseMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _disposeVideo();
      _initMedia();
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isInit = false;
    _hasError = false;
  }

  bool get _isVideo {
    final lower = widget.mediaUrl.toLowerCase();
    return widget.mediaType == 'video' ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.m3u8');
  }

  Future<void> _initMedia() async {
    if (widget.mediaUrl.isEmpty || !_isVideo) return;
    try {
      final displayUrl = CategoryBackendService.getDisplayableImageUrl(
        widget.mediaUrl,
      );
      final uri = Uri.parse(displayUrl);
      final controller = VideoPlayerController.networkUrl(uri);
      _videoController = controller;

      await controller.initialize();
      await controller.setVolume(0.0); // Muted
      await controller.setLooping(true); // Loop
      await controller.play();

      if (mounted) {
        setState(() => _isInit = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrl.isEmpty) {
      return _buildFallbackIcon();
    }

    final displayUrl = CategoryBackendService.getDisplayableImageUrl(
      widget.mediaUrl,
    );

    if (_isVideo) {
      if (_isInit &&
          _videoController != null &&
          _videoController!.value.isInitialized) {
        return FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        );
      }
      if (_hasError) {
        return _buildFallbackIcon();
      }
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
          strokeWidth: 2.5,
        ),
      );
    }

    // Standard GIF or Image (Flutter natively plays looping GIFs in Image.network)
    return Image.network(
      displayUrl,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 32,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
