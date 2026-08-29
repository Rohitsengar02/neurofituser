import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum WorkoutSessionState { active, resting, paused }

class ActiveWorkoutScreen extends StatefulWidget {
  final String dayTitle;
  final int dayNumber;
  final List<Map<String, dynamic>>? exercises;

  const ActiveWorkoutScreen({
    super.key,
    required this.dayTitle,
    required this.dayNumber,
    this.exercises,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with TickerProviderStateMixin {
  late final List<Map<String, dynamic>> _exercises;
  int _currentExerciseIndex = 0;
  WorkoutSessionState _sessionState = WorkoutSessionState.active;

  // Timers
  Timer? _sessionTimer;
  Timer? _exerciseTimer;
  Timer? _restTimer;

  int _totalSessionSeconds = 25; // starts at 00:25
  int _currentExerciseSecondsRemaining = 45;
  int _totalExerciseDuration = 45;
  int _restSecondsRemaining = 30; // 30s rest

  late AnimationController _staggerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _exercises = widget.exercises ?? [
      {
        'title': 'WARM-UP REFLECTION',
        'subtitle': 'Workout at home • Dynamic High Knees',
        'duration': 45,
        'image': 'assets/images/workout_exercise_cutout.jpg',
        'target': 'Full Body Mobility',
      },
      {
        'title': 'INCLINE DUMBBELL BENCH PRESS',
        'subtitle': 'Upper Body Push • 4 Sets x 12 Reps',
        'duration': 60,
        'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=600&auto=format&fit=crop',
        'target': 'Upper Pectorals',
      },
      {
        'title': 'FLAT BARBELL BENCH PRESS',
        'subtitle': 'Compound Strength • 4 Sets x 10 Reps',
        'duration': 60,
        'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=600&auto=format&fit=crop',
        'target': 'Mid Chest & Deltoids',
      },
      {
        'title': 'STANDING CABLE CHEST FLYES',
        'subtitle': 'Isolation Contraction • 3 Sets x 15 Reps',
        'duration': 45,
        'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=600&auto=format&fit=crop',
        'target': 'Inner Chest Squeeze',
      },
      {
        'title': 'OVERHEAD ROPE TRICEP EXTENSION',
        'subtitle': 'Tricep Peak • 4 Sets x 15 Reps',
        'duration': 45,
        'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=600&auto=format&fit=crop',
        'target': 'Long Head Triceps',
      },
      {
        'title': 'EXPLOSIVE PUSH-UP BURNOUT',
        'subtitle': 'Finisher • 2 Sets x 25 Reps',
        'duration': 50,
        'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=600&auto=format&fit=crop',
        'target': 'Pectorals & Core',
      },
    ];

    _totalExerciseDuration = _exercises[0]['duration'] as int? ?? 45;
    _currentExerciseSecondsRemaining = _totalExerciseDuration;

    // 1. Initial Stagger Reveal Controller (Blur + Slide + Fade)
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 2. Pulse / Breathing Controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Start reveal animation
    _staggerController.forward();

    _startAllTimers();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _exerciseTimer?.cancel();
    _restTimer?.cancel();
    _staggerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAllTimers() {
    // Session overall timer (counting up)
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState != WorkoutSessionState.paused && mounted) {
        setState(() => _totalSessionSeconds++);
      }
    });

    _startActiveExerciseTimer();
  }

  void _startActiveExerciseTimer() {
    _exerciseTimer?.cancel();
    _restTimer?.cancel();
    _sessionState = WorkoutSessionState.active;

    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState == WorkoutSessionState.active && mounted) {
        if (_currentExerciseSecondsRemaining > 0) {
          setState(() => _currentExerciseSecondsRemaining--);
        } else {
          // Exercise completed -> start 30 sec rest automatically!
          _triggerRestPeriod();
        }
      }
    });
  }

  void _triggerRestPeriod() {
    _exerciseTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionState = WorkoutSessionState.resting;
      _restSecondsRemaining = 30; // 30 sec rest
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState == WorkoutSessionState.resting && mounted) {
        if (_restSecondsRemaining > 0) {
          setState(() => _restSecondsRemaining--);
        } else {
          // Rest finished -> move to next exercise
          _goToNextExercise(skipRest: true);
        }
      }
    });
  }

  void _togglePlayPause() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sessionState == WorkoutSessionState.paused) {
        _sessionState = WorkoutSessionState.active;
      } else {
        _sessionState = WorkoutSessionState.paused;
      }
    });
  }

  void _goToNextExercise({bool skipRest = false}) {
    HapticFeedback.heavyImpact();
    if (_currentExerciseIndex < _exercises.length - 1) {
      if (!skipRest && _sessionState == WorkoutSessionState.active) {
        // Show rest time for 30s before starting next exercise
        _triggerRestPeriod();
      } else {
        _exerciseTimer?.cancel();
        _restTimer?.cancel();
        setState(() {
          _currentExerciseIndex++;
          _sessionState = WorkoutSessionState.active;
          _totalExerciseDuration = _exercises[_currentExerciseIndex]['duration'] as int? ?? 45;
          _currentExerciseSecondsRemaining = _totalExerciseDuration;
        });
        _startActiveExerciseTimer();
      }
    } else {
      _showWorkoutCompleteDialog();
    }
  }

  void _goToPreviousExercise() {
    HapticFeedback.lightImpact();
    if (_currentExerciseIndex > 0) {
      _exerciseTimer?.cancel();
      _restTimer?.cancel();
      setState(() {
        _currentExerciseIndex--;
        _sessionState = WorkoutSessionState.active;
        _totalExerciseDuration = _exercises[_currentExerciseIndex]['duration'] as int? ?? 45;
        _currentExerciseSecondsRemaining = _totalExerciseDuration;
      });
      _startActiveExerciseTimer();
    }
  }

  void _addRestTime(int seconds) {
    HapticFeedback.lightImpact();
    setState(() {
      _restSecondsRemaining += seconds;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Staggered Blur Reveal Section Builder
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
        final slideY = (28.0 * (1 - anim));

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
    final currentExercise = _exercises[_currentExerciseIndex];
    final progressPercentage = ((_currentExerciseIndex + 1) / _exercises.length * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Header Bar (Stagger 0.0 -> 0.35)
            _buildStaggeredBlurSection(
              startInterval: 0.0,
              endInterval: 0.35,
              child: _buildTopHeaderBar(),
            ),

            // 2. Middle Visual Model Section (Stagger 0.20 -> 0.65)
            Expanded(
              child: _buildStaggeredBlurSection(
                startInterval: 0.20,
                endInterval: 0.65,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    final slideIn = Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slideIn,
                        child: child,
                      ),
                    );
                  },
                  child: _sessionState == WorkoutSessionState.resting
                      ? _buildRestView(key: ValueKey('rest_view_$_currentExerciseIndex'))
                      : _buildExerciseModelView(
                          currentExercise,
                          key: ValueKey('exercise_model_$_currentExerciseIndex'),
                        ),
                ),
              ),
            ),

            // 3. Bottom Dark Player Card (Stagger 0.40 -> 1.0)
            _buildStaggeredBlurSection(
              startInterval: 0.40,
              endInterval: 1.0,
              child: _buildBottomControlCard(currentExercise, progressPercentage),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER BAR
  // -------------------------------------------------------------
  Widget _buildTopHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button in light rounded container
          GestureDetector(
            onTap: _showExitConfirmation,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),

          // Live Elapsed Session Timer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_totalSessionSeconds),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
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
  // 2. ACTIVE EXERCISE MODEL VIEW (IMAGE CUTOUT & SMOOTH PULSE)
  // -------------------------------------------------------------
  Widget _buildExerciseModelView(Map<String, dynamic> currentExercise, {Key? key}) {
    final imagePath = currentExercise['image'] as String;

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final translateY = 5.0 * (_pulseController.value - 0.5);
                  final scale = 1.0 + (0.02 * _pulseController.value);

                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(
                      scale: scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Subtle Ambient Radial Glow
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFF59E0B).withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // Model Exercise Image
                          imagePath.startsWith('assets')
                              ? Image.asset(
                                  imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.fitness_center_rounded,
                                    size: 100,
                                    color: Color(0xFF94A3B8),
                                  ),
                                )
                              : Image.network(
                                  imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.fitness_center_rounded,
                                    size: 100,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Soft Ground Drop Shadow
            Container(
              width: 170,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(170, 14)),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. REST TIME VIEW (30 SECONDS COUNTDOWN & NEXT UP PREVIEW)
  // -------------------------------------------------------------
  Widget _buildRestView({Key? key}) {
    final nextIndex = _currentExerciseIndex < _exercises.length - 1 ? _currentExerciseIndex + 1 : _currentExerciseIndex;
    final nextExercise = _exercises[nextIndex];

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rest Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                size: 40,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'REST & RECOVER',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFD97706),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),

            // Big 30s Countdown Display
            Text(
              '00:${_restSecondsRemaining.toString().padLeft(2, '0')}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),

            // Add Rest Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _addRestTime(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '+20s Rest',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _goToNextExercise(skipRest: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip Rest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Next Up Preview Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: nextExercise['image'].toString().startsWith('assets')
                        ? Image.asset(
                            nextExercise['image'] as String,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            nextExercise['image'] as String,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF94A3B8)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXT UP • STEP ${nextIndex + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextExercise['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  // -------------------------------------------------------------
  // 4. BOTTOM CONTROL CARD (WITH DYNAMIC STEP TRANSITIONS)
  // -------------------------------------------------------------
  Widget _buildBottomControlCard(Map<String, dynamic> currentExercise, int progressPercentage) {
    final stepNumber = _currentExerciseIndex + 1;
    final exerciseTitle = currentExercise['title'] as String;
    final exerciseSubtitle = currentExercise['subtitle'] as String;

    final isResting = _sessionState == WorkoutSessionState.resting;
    final isPaused = _sessionState == WorkoutSessionState.paused;

    final progressRatio = _totalExerciseDuration > 0
        ? (_totalExerciseDuration - _currentExerciseSecondsRemaining) / _totalExerciseDuration
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF141518), // Sleek Dark Black Charcoal
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Indicator Top Center
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Animated Step Title & Subtitle on Next/Prev clicks
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey('step_info_${_currentExerciseIndex}_$isResting'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isResting ? 'REST TIME (30 SECONDS)' : 'STEP $stepNumber. $exerciseTitle',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isResting ? 'Prepare for next movement' : exerciseSubtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Timestamp & Percentage Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isResting ? '00:${_restSecondsRemaining.toString().padLeft(2, '0')}' : _formatTime(_currentExerciseSecondsRemaining),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '$progressPercentage%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Orange Progress Bar Line
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (isResting ? (30 - _restSecondsRemaining) / 30 : progressRatio).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Vibrant Orange / Amber line
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Audio / Exercise Controls Row (Prev, Large Amber Play/Pause, Next)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Button
              GestureDetector(
                onTap: _goToPreviousExercise,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFF23242A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.skip_previous_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 26,
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Large Vibrant Play/Pause Amber Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: const Color(0xFF141518),
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Next Button
              GestureDetector(
                onTap: () => _goToNextExercise(skipRest: false),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFF23242A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.skip_next_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. EXIT CONFIRMATION DIALOG
  // -------------------------------------------------------------
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Quit Workout?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Are you sure you want to end this workout session? Your active progress will be saved.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Resume',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // exit session screen
              },
              child: Text(
                'Quit',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE11D48),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 6. WORKOUT COMPLETE CELEBRATION MODAL
  // -------------------------------------------------------------
  void _showWorkoutCompleteDialog() {
    _sessionTimer?.cancel();
    _exerciseTimer?.cancel();
    _restTimer?.cancel();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF16A34A),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Workout Completed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Awesome effort! You finished all ${_exercises.length} exercises in Day ${widget.dayNumber}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompleteStat('Duration', _formatTime(_totalSessionSeconds), Icons.timer_outlined),
                  _buildCompleteStat('Burned', '340 kcal', Icons.local_fire_department_rounded),
                  _buildCompleteStat('Completed', '${_exercises.length} Moves', Icons.check_circle_rounded),
                ],
              ),
              const SizedBox(height: 24),

              // Back to Dashboard CTA
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // close modal
                  Navigator.pop(context); // close active session
                },
                child: Container(
                  height: 52,
                  width: double.infinity,
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
                  child: Text(
                    'Finish & Save Workout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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

  Widget _buildCompleteStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF16A34A)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
