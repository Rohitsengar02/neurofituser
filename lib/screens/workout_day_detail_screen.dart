import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';
import 'active_workout_screen.dart';

class WorkoutDayDetailScreen extends StatefulWidget {
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
  final Set<int> _completedExercises = {};
  bool _isBookmarked = false;

  late final List<Map<String, dynamic>> _exerciseList;

  @override
  void initState() {
    super.initState();
    _exerciseList = widget.exercises ?? [
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
  }

  void _toggleExerciseComplete(int id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_completedExercises.contains(id)) {
        _completedExercises.remove(id);
      } else {
        _completedExercises.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedExercises.length;
    final totalCount = _exerciseList.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Hero Image & Day Details Top Section
              SliverToBoxAdapter(
                child: StaggeredSlideFade(
                  index: 0,
                  child: _buildHeroTopSection(),
                ),
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
          // Top Image
          Image.network(
            widget.image,
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
                      child: Text(
                        widget.focus,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),

                // Metrics Row
                Row(
                  children: [
                    _buildTopMetricBadge(Icons.timer_outlined, widget.duration),
                    const SizedBox(width: 8),
                    _buildTopMetricBadge(Icons.local_fire_department_rounded, widget.calories, isHot: true),
                    const SizedBox(width: 8),
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
    final id = ex['id'] as int;
    final isDone = _completedExercises.contains(id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFF1F5F9),
          width: isDone ? 1.5 : 1.0,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Exercise Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.network(
                        ex['image'] as String,
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 75,
                          height: 75,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$index',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ex['phase'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ex['target'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ex['name'] as String,
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
                      Row(
                        children: [
                          _buildSetPill(Icons.repeat_rounded, '${ex['sets']} x ${ex['reps']}'),
                          const SizedBox(width: 6),
                          _buildSetPill(Icons.timer_outlined, ex['rest'] as String),
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkbox / Mark Done Button
                GestureDetector(
                  onTap: () => _toggleExerciseComplete(id),
                  child: Container(
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
                                color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: isDone ? Colors.white : const Color(0xFF94A3B8),
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
                    ex['tip'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
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
  // 5. START EXERCISE BOTTOM BAR
  // -------------------------------------------------------------
  Widget _buildStartExerciseBottomBar() {
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
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveWorkoutScreen(
                      dayTitle: widget.title,
                      dayNumber: widget.dayNumber,
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
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      'Start Exercise',
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
  }
}
