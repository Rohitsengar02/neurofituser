import '../../widgets/ticker_gate.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/apple_kit.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/mindful_games.dart';
import '../overview/overview_home_cards.dart' show DottedLineChart;

part 'sections/stats_grid.dart';
part 'sections/stress.dart';
part 'sections/mood.dart';
part 'sections/breathing_exercises.dart';
part 'sections/journal.dart';
part 'sections/sleep.dart';
part 'sections/mind_games.dart';
part 'sections/mindful_sounds.dart';

// Wellness tab in the shared Apple style: a 3×3 grid of today's stats,
// the stress meter, mood check-in, guided breathing and exercises, today's
// journal, sleep, mindful minutes, soundscapes, affirmations and sixteen
// levelled mind games.

const _violet = Color(0xFF8B5CF6);
const _teal = Color(0xFF14B8A6);
const _indigo = Color(0xFF6366F1);
const _pink = Color(0xFFEC4899);
const _amber = Color(0xFFF59E0B);
const _green = Color(0xFF22C55E);
const _sky = Color(0xFF38BDF8);
const _red = Color(0xFFEF4444);
const _orange = Color(0xFFF97316);

class WellnessState {
  WellnessState._();
  static final mood = ValueNotifier<int>(3);
  static final mindfulMin = ValueNotifier<int>(18);
  static final journal = ValueNotifier<List<JournalEntry>>([
    JournalEntry('7:40 AM', '🌅', 'Morning intention', 'Move slowly, drink more water, and stay kind to myself in the meeting.', 'Intention'),
    JournalEntry('1:15 PM', '🙏', 'Gratitude', 'A quiet lunch walk, Mom\'s call, and finishing the hard task early.', 'Gratitude'),
    JournalEntry('6:05 PM', '💭', 'After workout', 'Felt heavy at first, lighter after the second set. Stress went from 7 to 4.', 'Reflection'),
  ]);
}

class JournalEntry {
  final String time, mood, title, body, tag;
  JournalEntry(this.time, this.mood, this.title, this.body, this.tag);
}

// =====================================================================

class WellnessTabV3 extends StatefulWidget {
  /// The tab's sections, built lazily by the home scroll view.
  static List<Widget> get sections {
    GameProgress.load();
    return _WellnessTabV3State.sections;
  }

  const WellnessTabV3({super.key});

  @override
  State<WellnessTabV3> createState() => _WellnessTabV3State();
}

class _WellnessTabV3State extends State<WellnessTabV3> {
  @override
  void initState() {
    super.initState();
    GameProgress.load();
  }

  /// The tab's sections, built lazily by the home scroll view.
  static const List<Widget> sections = [
        SizedBox(height: 18),
        AkWelcome(
          caption: 'WELLNESS · MIND SCORE 82',
          words: ['Find', 'your', 'calm,', 'Rohit'],
          accent: _violet,
          subtitle: 'Stress is lower than yesterday. A short breath session keeps it there.',
        ),
        AkHead('Today', caption: 'Nine signals from your body and mind'),
        _StatsGrid(),
        AkHead('Stress level'),
        ScrollReveal(child: _StressCard()),
        AkHead('How are you feeling?'),
        ScrollReveal(child: _MoodCard()),
        AkHead('Breathe & unwind', caption: 'Guided sessions, 1 to 6 minutes'),
        _Exercises(),
        AkHead("Today's journal", action: 'Write'),
        _Journal(),
        AkHead('Sleep'),
        ScrollReveal(child: _SleepCard()),
        AkHead('Mind games', caption: 'Play, level up, stay sharp'),
        ScrollReveal(child: _MindLevelCard()),
        SizedBox(height: 12),
        _GamesGrid(),
        AkHead('Mindful minutes'),
        ScrollReveal(child: _MindfulWeek()),
        AkHead('Soundscapes'),
        TickerGate(child: _Sounds()),
        AkHead('Daily affirmation'),
        _Affirmations(),
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

