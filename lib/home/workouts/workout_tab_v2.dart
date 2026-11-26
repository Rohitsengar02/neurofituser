import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/liquid_glass.dart';
import '../overview/overview_home_cards.dart' show DottedLineChart;

part 'sections/welcome.dart';
part 'sections/dot_matrix_stats.dart';
part 'sections/week_chart.dart';
part 'sections/programs.dart';
part 'sections/todays_exercises.dart';
part 'sections/browse_by_type.dart';
part 'sections/muscle_recovery.dart';
part 'sections/quick_workouts.dart';
part 'sections/personal_records.dart';
part 'sections/challenges.dart';

// Workouts tab in the Overview's Apple style: a welcome reveal, today's
// session, dot-matrix stats, animated charts and image-led liquid glass
// cards. Exercise art comes from the bundled exercise dataset.

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _faint = Color(0xFF6E7681);
const _green = Color(0xFF16A34A);
const _mint = Color(0xFF22C55E);
const _orange = Color(0xFFFF7A3D);
const _blue = Color(0xFF3B82F6);
const _purple = Color(0xFF8B5CF6);
const _pink = Color(0xFFEC4899);
const _amber = Color(0xFFF59E0B);
const Curve _spring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle _t(double s, {FontWeight w = FontWeight.w600, Color c = _ink, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

String _ex(String file) => 'assets/exercises/images/$file';

class _Exercise {
  final String name, image, sets, muscle, tip;
  const _Exercise(this.name, this.image, this.sets, this.muscle, this.tip);
}

const _today = [
  _Exercise('Barbell Bench Press', '0025-EIeI8Vf.jpg', '4 × 10', 'Chest',
      'Lie flat, grip slightly wider than shoulders, lower to mid-chest and press up in a straight line.'),
  _Exercise('Incline Dumbbell Press', '0314-ns0SIbU.jpg', '3 × 12', 'Upper chest',
      'Bench at 45°, dumbbells at shoulder height, press up and together without locking elbows.'),
  _Exercise('Seated Shoulder Press', '0405-znQUdHY.jpg', '3 × 10', 'Shoulders',
      'Sit tall, press the dumbbells overhead until arms are straight, lower slowly to ear level.'),
  _Exercise('Lateral Raise', '0334-DsgkuIt.jpg', '3 × 15', 'Side delts',
      'Soft elbows, raise to shoulder height leading with the elbows, pause, lower for 3 seconds.'),
  _Exercise('Triceps Dip', '0814-X6C6i5Y.jpg', '3 × 12', 'Triceps',
      'Hands on the bench edge, lower until elbows reach 90°, push back up through the palms.'),
  _Exercise('Push-up Finisher', '0662-I4hDWkc.jpg', '2 × max', 'Chest',
      'High plank, body in one line, chest to fist height, push the floor away.'),
];

// =====================================================================

class WorkoutTabV2 extends StatelessWidget {
  const WorkoutTabV2({super.key});

  /// The tab's sections, built lazily by the home scroll view.
  static const List<Widget> sections = [
        SizedBox(height: 18),
        _Welcome(),
        SizedBox(height: 16),
        ScrollReveal(child: _StatsRow()),
        _Head('This week', action: 'History'),
        ScrollReveal(child: _WeekCard()),
        _Head('Programs for you', action: 'See all'),
        _Programs(),
        _Head("Today's exercises", action: '6 · 45 min'),
        _TodayList(),
        _Head('Browse by type'),
        _TypeGrid(),
        _Head('Muscle recovery'),
        ScrollReveal(child: _RecoveryCard()),
        _Head('Quick workouts'),
        _QuickRow(),
        _Head('Personal records'),
        ScrollReveal(child: _Records()),
        _Head('Challenges'),
        ScrollReveal(child: _Challenges()),
        SizedBox(height: 20),
      ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

class _Head extends StatelessWidget {
  final String title;
  final String? action;
  const _Head(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(children: [
          Expanded(child: Text(title, style: _t(20, w: FontWeight.w800, ls: -0.5))),
          if (action != null) Text(action!, style: _t(13, w: FontWeight.w700, c: _green)),
        ]),
      ),
    );
  }
}

/// Runs [builder] with a 0→1 value that starts when the widget scrolls into view.
class _Seen extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  final Duration duration;
  final Curve curve;
  const _Seen({
    required this.builder,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<_Seen> createState() => _SeenState();
}

class _SeenState extends State<_Seen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  ScrollPosition? _pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.value = 1;
      return;
    }
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _pos) {
      _pos?.removeListener(_check);
      _pos = pos?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _c.value > 0 || _c.isAnimating) return;
    final box = context.findRenderObject() as RenderBox?;
    final view = Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = view == null ? 0.0 : box.localToGlobal(Offset.zero, ancestor: view).dy;
    if (view == null || top < view.size.height - 40) {
      _pos?.removeListener(_check);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => widget.builder(context, widget.curve.transform(_c.value)),
      );
}

