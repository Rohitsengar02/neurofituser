import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../services/category_backend_service.dart';
import '../services/user_workout_service.dart';

enum WorkoutSessionState { active, resting, paused }

class ActiveWorkoutScreen extends StatefulWidget {
  final String workoutId;
  final String dayTitle;
  final int dayNumber;
  final int initialExerciseIndex;
  final List<Map<String, dynamic>>? exercises;

  const ActiveWorkoutScreen({
    super.key,
    this.workoutId = 'workout_1',
    required this.dayTitle,
    required this.dayNumber,
    this.initialExerciseIndex = 0,
    this.exercises,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin {
  late final List<Map<String, dynamic>> _exercises;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  WorkoutSessionState _sessionState = WorkoutSessionState.active;

  Timer? _sessionTimer;
  Timer? _restTimer;

  int _totalSessionSeconds = 0;
  int _restSecondsRemaining = 0;

  late AnimationController _staggerController;
  late AnimationController _pulseController;

  // Safe field readers with complete null safety
  String _exTitle(Map<String, dynamic> ex) {
    final val = ex['title'] ?? ex['name'];
    if (val == null || val.toString().isEmpty) return 'Exercise';
    return val.toString();
  }

  String _exImage(Map<String, dynamic> ex) {
    final val = ex['mediaUrl'] ?? ex['gifUrl'] ?? ex['imageUrl'] ?? ex['image'] ?? ex['videoUrl'];
    if (val == null) return '';
    return val.toString();
  }

  String _exMediaType(Map<String, dynamic> ex) {
    final val = ex['mediaType'];
    if (val != null && val.toString().isNotEmpty) return val.toString();
    final url = _exImage(ex).toLowerCase();
    if (url.endsWith('.gif')) return 'gif';
    if (url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm')) return 'video';
    return 'image';
  }

  String _exMuscle(Map<String, dynamic> ex) {
    final val = ex['muscleGroup'] ?? ex['target'] ?? ex['bodyPart'] ?? ex['phase'];
    if (val == null) return '';
    return val.toString();
  }

  String _exInstructions(Map<String, dynamic> ex) {
    final val = ex['instructions'] ?? ex['instructionText'] ?? ex['tip'] ?? ex['tips'];
    if (val == null) return '';
    if (val is List) return val.join('\n');
    return val.toString();
  }

  int _exSets(Map<String, dynamic> ex) {
    final v = ex['sets'];
    if (v is int) return v;
    if (v == null) return 3;
    final parsed = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    return parsed ?? 3;
  }

  int _exReps(Map<String, dynamic> ex) {
    final v = ex['reps'];
    if (v is int) return v;
    if (v == null) return 12;
    final parsed = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    return parsed ?? 12;
  }

  int _exRest(Map<String, dynamic> ex) {
    final v = ex['restSeconds'] ?? ex['rest'];
    if (v is int) return v;
    if (v == null) return 45;
    final parsed = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    return parsed ?? 45;
  }

  @override
  void initState() {
    super.initState();
    _exercises = (widget.exercises != null && widget.exercises!.isNotEmpty)
        ? widget.exercises!
        : [
          {
            'title': 'Dumbbell Bench Press',
            'mediaUrl': '',
            'mediaType': 'image',
            'muscleGroup': 'Chest & Pecs',
            'sets': 4,
            'reps': 12,
            'restSeconds': 60,
            'instructions':
                '1. Lie on bench with dumbbells\n2. Press upward in arc\n3. Squeeze chest at top\n4. Lower with 3 sec negative',
          },
          {
            'title': 'Barbell Deadlift',
            'mediaUrl': '',
            'mediaType': 'video',
            'muscleGroup': 'Back & Hamstrings',
            'sets': 4,
            'reps': 10,
            'restSeconds': 90,
            'instructions':
                '1. Feet under bar\n2. Grip just outside knees\n3. Drive through heels\n4. Lock out hips',
          },
          {
            'title': 'Cable Chest Flyes',
            'mediaUrl': '',
            'mediaType': 'image',
            'muscleGroup': 'Inner Chest',
            'sets': 3,
            'reps': 15,
            'restSeconds': 45,
            'instructions':
                '1. Set handles at chest height\n2. Hug a big tree\n3. Peak contraction 1s',
          },
        ];

    _currentExerciseIndex =
        widget.initialExerciseIndex.clamp(0, _exercises.length - 1);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _staggerController.forward();
    _startSessionTimer();

    // Register/resume workout session in database
    UserWorkoutService.instance.startWorkout(
      workoutId: widget.workoutId,
      workoutTitle: widget.dayTitle,
      dayNumber: widget.dayNumber,
      exercises: _exercises,
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _staggerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState != WorkoutSessionState.paused && mounted) {
        setState(() => _totalSessionSeconds++);
      }
    });
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
    return '${index + 1}';
  }

  void _completeCurrentSet() {
    HapticFeedback.mediumImpact();
    final currentEx = _exercises[_currentExerciseIndex];
    final totalSets = _exSets(currentEx);
    final restSec = _exRest(currentEx);
    final exId = _getExerciseKey(currentEx, _currentExerciseIndex);
    final altKey = '${_currentExerciseIndex + 1}';
    final title = _exTitle(currentEx);

    if (_currentSetIndex < totalSets - 1) {
      setState(() {
        _currentSetIndex++;
        _sessionState = WorkoutSessionState.resting;
        _restSecondsRemaining = restSec;
      });
      _startRestTimer();

      // Sync partial set progress
      UserWorkoutService.instance.updateProgress(
        workoutId: widget.workoutId,
        dayNumber: widget.dayNumber,
        currentExerciseIndex: _currentExerciseIndex,
        currentSetIndex: _currentSetIndex,
        totalDurationSeconds: _totalSessionSeconds,
      );
    } else {
      // Completed all sets for this exercise -> mark exercise done in DB & Socket
      UserWorkoutService.instance.updateProgress(
        workoutId: widget.workoutId,
        dayNumber: widget.dayNumber,
        currentExerciseIndex: _currentExerciseIndex,
        currentSetIndex: _currentSetIndex,
        completedExerciseId: exId,
        isExerciseCompleted: true,
        totalDurationSeconds: _totalSessionSeconds,
      );
      if (altKey != exId) {
        UserWorkoutService.instance.updateProgress(
          workoutId: widget.workoutId,
          dayNumber: widget.dayNumber,
          completedExerciseId: altKey,
          isExerciseCompleted: true,
        );
      }
      if (title.isNotEmpty && title != 'Exercise' && title != exId && title != altKey) {
        UserWorkoutService.instance.updateProgress(
          workoutId: widget.workoutId,
          dayNumber: widget.dayNumber,
          completedExerciseId: title,
          isExerciseCompleted: true,
        );
      }
      _goToNextExercise();
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState == WorkoutSessionState.resting && mounted) {
        if (_restSecondsRemaining > 0) {
          setState(() => _restSecondsRemaining--);
        } else {
          _restTimer?.cancel();
          setState(() => _sessionState = WorkoutSessionState.active);
        }
      }
    });
  }

  void _skipRest() {
    HapticFeedback.lightImpact();
    _restTimer?.cancel();
    setState(() {
      _sessionState = WorkoutSessionState.active;
      _restSecondsRemaining = 0;
    });
  }

  void _addRestTime(int seconds) {
    HapticFeedback.lightImpact();
    setState(() => _restSecondsRemaining += seconds);
  }

  void _togglePlayPause() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sessionState == WorkoutSessionState.paused) {
        _sessionState = WorkoutSessionState.active;
      } else if (_sessionState == WorkoutSessionState.active) {
        _sessionState = WorkoutSessionState.paused;
      }
    });
  }

  void _goToNextExercise() {
    HapticFeedback.heavyImpact();
    _restTimer?.cancel();
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSetIndex = 0;
        _sessionState = WorkoutSessionState.active;
      });

      UserWorkoutService.instance.updateProgress(
        workoutId: widget.workoutId,
        dayNumber: widget.dayNumber,
        currentExerciseIndex: _currentExerciseIndex,
        currentSetIndex: 0,
        totalDurationSeconds: _totalSessionSeconds,
      );
    } else {
      _showWorkoutCompleteDialog();
    }
  }

  void _goToPreviousExercise() {
    HapticFeedback.lightImpact();
    _restTimer?.cancel();
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _currentSetIndex = 0;
        _sessionState = WorkoutSessionState.active;
      });

      UserWorkoutService.instance.updateProgress(
        workoutId: widget.workoutId,
        dayNumber: widget.dayNumber,
        currentExerciseIndex: _currentExerciseIndex,
        currentSetIndex: 0,
        totalDurationSeconds: _totalSessionSeconds,
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

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
          curve: Interval(
            startInterval,
            endInterval,
            curve: Curves.easeOutCubic,
          ),
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
    final totalSets = _exSets(currentExercise);
    final progressPercentage =
        ((_currentExerciseIndex + 1) / _exercises.length * 100).toInt();
    final isPaused = _sessionState == WorkoutSessionState.paused;
    final isResting = _sessionState == WorkoutSessionState.resting;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Header Bar (Active Exercise Title + Timer)
            _buildStaggeredBlurSection(
              startInterval: 0.0,
              endInterval: 0.35,
              child: _buildTopHeaderBar(currentExercise),
            ),

            // 2. Middle - Centered 1:1 Exercise Animation GIF / Rest View
            Expanded(
              child: _buildStaggeredBlurSection(
                startInterval: 0.20,
                endInterval: 0.65,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    final slideIn =
                        Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slideIn, child: child),
                    );
                  },
                  child: isResting
                      ? _buildRestView(
                          key: ValueKey(
                            'rest_${_currentExerciseIndex}_$_currentSetIndex',
                          ),
                        )
                      : _buildExerciseMediaView(
                          currentExercise,
                          key: ValueKey('media_$_currentExerciseIndex'),
                        ),
                ),
              ),
            ),

            // 3. Bottom Dark Card with controls + set tracker + tick complete
            _buildStaggeredBlurSection(
              startInterval: 0.40,
              endInterval: 1.0,
              child: _buildBottomControlCard(
                currentExercise,
                totalSets,
                progressPercentage,
                isPaused,
                isResting,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER BAR (active exercise title + timer + list modal)
  // -------------------------------------------------------------
  Widget _buildTopHeaderBar(Map<String, dynamic> currentExercise) {
    final activeTitle = _exTitle(currentExercise);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showExitConfirmation,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeTitle.isNotEmpty ? activeTitle : widget.dayTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      widget.dayTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Step ${_currentExerciseIndex + 1}/${_exercises.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatTime(_totalSessionSeconds),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // All exercises quick sheet button
          GestureDetector(
            onTap: _showAllExercisesSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.format_list_bulleted_rounded,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_exercises.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ALL EXERCISES BOTTOM SHEET MODAL
  // -------------------------------------------------------------
  void _showAllExercisesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${widget.dayNumber} Exercises',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${_exercises.length} Movements selected by Admin',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Step ${_currentExerciseIndex + 1}/${_exercises.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ex = _exercises[index];
                        final isCurrent = index == _currentExerciseIndex;
                        final isDone = index < _currentExerciseIndex;
                        final title = _exTitle(ex);
                        final img = _exImage(ex);
                        final mType = _exMediaType(ex);
                        final muscle = _exMuscle(ex);
                        final sets = _exSets(ex);
                        final reps = _exReps(ex);
                        final rest = _exRest(ex);

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _restTimer?.cancel();
                            setState(() {
                              _currentExerciseIndex = index;
                              _currentSetIndex = 0;
                              _sessionState = WorkoutSessionState.active;
                              _restSecondsRemaining = 0;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFFF0FDF4)
                                  : (isDone
                                        ? const Color(0xFFF8FAFC)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF10B981)
                                    : (isDone
                                          ? const Color(0xFFBBF7D0)
                                          : const Color(0xFFE2E8F0)),
                                width: isCurrent ? 1.8 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Stack(
                                      children: [
                                        _LoopingExerciseMedia(
                                          mediaUrl: img,
                                          mediaType: mType,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 3,
                                          left: 3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '#${index + 1}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
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
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (muscle.isNotEmpty)
                                        Text(
                                          muscle.toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$sets Sets • $reps Reps • ${rest}s Rest',
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? const Color(0xFF16A34A)
                                        : (isCurrent
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFF1F5F9)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDone
                                        ? Icons.check_rounded
                                        : (isCurrent
                                              ? Icons.play_arrow_rounded
                                              : Icons.chevron_right_rounded),
                                    color: (isDone || isCurrent)
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                    size: 16,
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
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // EXERCISE INFO SLIDER SHEET (Dynamic Admin Instructions)
  // -------------------------------------------------------------
  void _showExerciseInfoSheet(Map<String, dynamic> ex) {
    final title = _exTitle(ex);
    final imageUrl = _exImage(ex);
    final mediaType = _exMediaType(ex);
    final muscle = _exMuscle(ex);
    final sets = _exSets(ex);
    final reps = _exReps(ex);
    final rest = _exRest(ex);

    final rawInstructions = _exInstructions(ex);
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
                      // Exercise Media (Video/GIF)
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
                        title,
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
                          _buildInfoStatPill(
                            Icons.repeat_rounded,
                            '$sets Sets',
                          ),
                          const SizedBox(width: 8),
                          _buildInfoStatPill(
                            Icons.fitness_center_rounded,
                            '$reps Reps',
                          ),
                          const SizedBox(width: 8),
                          _buildInfoStatPill(
                            Icons.timer_outlined,
                            '${rest}s Rest',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // How To Perform Steps from Admin
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.1),
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
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.25),
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

  Widget _buildInfoStatPill(IconData icon, String label) {
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

  // -------------------------------------------------------------
  // 2. EXERCISE MEDIA VIEW (Centered 1:1 AspectRatio Card)
  // -------------------------------------------------------------
  Widget _buildExerciseMediaView(Map<String, dynamic> ex, {Key? key}) {
    final imageUrl = _exImage(ex);
    final mediaType = _exMediaType(ex);
    final muscle = _exMuscle(ex);

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1:1 Edge-to-edge covering Animation GIF / Video (no internal padding)
                _LoopingExerciseMedia(
                  mediaUrl: imageUrl,
                  mediaType: mediaType,
                  fit: BoxFit.cover,
                ),

                // Target Muscle Badge on top-left overlay
                if (muscle.isNotEmpty)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        muscle.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF34D399),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                // Info Icon with NO background at right-bottom corner
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showExerciseInfoSheet(ex),
                      borderRadius: BorderRadius.circular(20),
                      splashColor:
                          const Color(0xFF6366F1).withValues(alpha: 0.15),
                      highlightColor:
                          const Color(0xFF6366F1).withValues(alpha: 0.08),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 24,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. REST VIEW
  // -------------------------------------------------------------
  Widget _buildRestView({Key? key}) {
    final nextIndex = _currentExerciseIndex < _exercises.length - 1
        ? _currentExerciseIndex + 1
        : _currentExerciseIndex;
    final nextExercise = _exercises[nextIndex];
    final nextImage = _exImage(nextExercise);

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                size: 44,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _addRestTime(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '+20s',
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
                  onTap: _skipRest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.35),
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
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                    child: nextImage.isNotEmpty
                        ? Image.network(
                            CategoryBackendService.getDisplayableImageUrl(
                              nextImage,
                            ),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: Color(0xFF94A3B8),
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
                          _exTitle(nextExercise),
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
  // 4. BOTTOM DARK CONTROL CARD
  // -------------------------------------------------------------
  Widget _buildBottomControlCard(
    Map<String, dynamic> currentExercise,
    int totalSets,
    int progressPercentage,
    bool isPaused,
    bool isResting,
  ) {
    final stepNumber = _currentExerciseIndex + 1;
    final exerciseTitle = _exTitle(currentExercise);
    final exerciseReps = _exReps(currentExercise);
    final exerciseSets = _exSets(currentExercise);
    final totalExerciseSets = _exercises.fold<int>(
      0,
      (sum, e) => sum + _exSets(e),
    );
    final completedSets =
        _exercises
            .sublist(0, _currentExerciseIndex)
            .fold<int>(0, (sum, e) => sum + _exSets(e)) +
        _currentSetIndex;
    final overallProgress = totalExerciseSets > 0
        ? completedSets / totalExerciseSets
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF141518),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(
                'info_${_currentExerciseIndex}_${_currentSetIndex}_$isResting',
              ),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isResting
                      ? 'REST (${_restSecondsRemaining}s)'
                      : 'STEP $stepNumber. ${exerciseTitle.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isResting
                      ? 'Breathe & prepare for next set'
                      : '$exerciseSets Sets × $exerciseReps Reps • ${_exMuscle(currentExercise)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(totalSets, (i) {
                    final isCompleted = i < _currentSetIndex;
                    final isCurrent = i == _currentSetIndex;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: i < totalSets - 1 ? 4 : 0,
                        ),
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (isCurrent
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF334155)),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Set ${_currentSetIndex + 1}/$totalSets',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isResting
                    ? '00:${_restSecondsRemaining.toString().padLeft(2, '0')}'
                    : _formatTime(_totalSessionSeconds),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '$progressPercentage%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: overallProgress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _goToPreviousExercise,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFF23242A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.skip_previous_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              GestureDetector(
                onTap: isResting ? _skipRest : _completeCurrentSet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: isResting
                        ? const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isResting
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                            : const Color(0xFF10B981).withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isResting
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: const Color(0xFF141518),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              GestureDetector(
                onTap: _goToNextExercise,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFF23242A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.skip_next_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 24,
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
  // 5. EXIT CONFIRMATION
  // -------------------------------------------------------------
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          'Are you sure you want to end this workout session?',
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
              Navigator.pop(context);
              Navigator.pop(context);
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
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. WORKOUT COMPLETE CELEBRATION
  // -------------------------------------------------------------
  void _showWorkoutCompleteDialog() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();

    // Mark every exercise in this workout day as completed
    for (int i = 0; i < _exercises.length; i++) {
      final key = _getExerciseKey(_exercises[i], i);
      final altKey = '${i + 1}';
      final title = _exTitle(_exercises[i]);
      UserWorkoutService.instance.updateProgress(
        workoutId: widget.workoutId,
        dayNumber: widget.dayNumber,
        completedExerciseId: key,
        isExerciseCompleted: true,
      );
      if (altKey != key) {
        UserWorkoutService.instance.updateProgress(
          workoutId: widget.workoutId,
          dayNumber: widget.dayNumber,
          completedExerciseId: altKey,
          isExerciseCompleted: true,
        );
      }
      if (title.isNotEmpty && title != 'Exercise' && title != key && title != altKey) {
        UserWorkoutService.instance.updateProgress(
          workoutId: widget.workoutId,
          dayNumber: widget.dayNumber,
          completedExerciseId: title,
          isExerciseCompleted: true,
        );
      }
    }

    // Mark workout day completed in DB and Socket
    UserWorkoutService.instance.updateProgress(
      workoutId: widget.workoutId,
      dayNumber: widget.dayNumber,
      dayCompleted: true,
      totalDurationSeconds: _totalSessionSeconds,
    );

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
                'Workout Completed! 🔥',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompleteStat(
                    'Duration',
                    _formatTime(_totalSessionSeconds),
                    Icons.timer_outlined,
                  ),
                  _buildCompleteStat(
                    'Exercises',
                    '${_exercises.length} Done',
                    Icons.fitness_center_rounded,
                  ),
                  _buildCompleteStat(
                    'Total Sets',
                    '${_exercises.fold<int>(0, (sum, e) => sum + _exSets(e))}',
                    Icons.check_circle_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
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

// -------------------------------------------------------------
// LOOPING EXERCISE MEDIA WIDGET (VIDEO PLAYER FOR MP4/MOV / IMAGE.NETWORK FOR GIF/IMAGE)
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
