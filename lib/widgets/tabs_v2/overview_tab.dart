import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/active_workout_screen.dart';
import '../../screens/kemo_ai_screen.dart';
import '../../screens/steps_screen.dart';
import '../../screens/workout_category_detail_screen.dart';
import '../dashboard_highlights.dart';
import '../dashboard_motion.dart';
import '../kemo.dart';
import '../neuro_island_dock.dart';
import 'kit.dart';

const _accent = Color(0xFF16A34A);
const _soft = Color(0xFFDCFCE7);

class OverviewTabV2 extends StatelessWidget {
  const OverviewTabV2({super.key});

  void _push(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...revealSections([
          HeroIllustrationCard(
            eyebrow: 'TODAY · ${(m.dayProgress * 100).round()}% DONE',
            title: 'Keep the streak',
            highlight: 'going strong!',
            illustration: 'assets/images/illustrations/overview.png',
            accent: _accent,
            soft: _soft,
            pills: [
              '🔥 ${m.streak} days',
              '⏱ ${m.activeMinutes} min',
              '❤️ ${m.heartRate} bpm',
            ],
            cta: 'Continue',
            onCta: () => _push(
              context,
              const ActiveWorkoutScreen(
                dayTitle: 'Upper Body Strength',
                dayNumber: 3,
              ),
            ),
          ),
          _KemoTip(onTap: () => Navigator.push(context, KemoAiScreen.route())),
          _AtAGlance(onSteps: () => _push(context, const StepsScreen())),
          const _TodayPlan(),
          const WeeklyActivityCard(),
          _Explore(
            onOpen: (c) =>
                _push(context, WorkoutCategoryDetailScreen(initialCategory: c)),
          ),
          const _Badges(),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _KemoTip extends StatelessWidget {
  final VoidCallback onTap;
  const _KemoTip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF14210C), Color(0xFF233B12)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const KemoFace(size: 46, glow: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kemo says',
                      style: jakarta(
                        11,
                        FontWeight.w800,
                        const Color(0xFFB8FF3D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'A glass of water before your workout will help. You are 1.25 L from your goal.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(
                        12.5,
                        FontWeight.w600,
                        Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8FF3D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtAGlance extends StatelessWidget {
  final VoidCallback onSteps;
  const _AtAGlance({required this.onSteps});

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Today at a glance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Pair(
                StatTile(
                  emoji: '👟',
                  value: '8,542',
                  label: 'of ${m.stepGoal ~/ 1000}k steps',
                  progress: m.stepProgress,
                  color: _accent,
                  onTap: onSteps,
                ),
                StatTile(
                  emoji: '🔥',
                  value: '${m.calories}',
                  unit: 'kcal',
                  label: 'burned of ${m.calorieGoal}',
                  progress: m.calorieProgress,
                  color: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: m.waterMl,
                builder: (context, ml, _) => Pair(
                  StatTile(
                    emoji: '💧',
                    value: (ml / 1000).toStringAsFixed(2),
                    unit: 'L',
                    label: 'water · tap to add',
                    progress: m.waterProgress,
                    color: const Color(0xFF0EA5E9),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      m.waterMl.value = (ml + 250).clamp(0, m.waterGoalMl * 2);
                    },
                  ),
                  StatTile(
                    emoji: '😴',
                    value: m.sleep,
                    label: 'sleep last night',
                    progress: 0.94,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanItem {
  final String time;
  final String title;
  final String sub;
  final String emoji;
  final Color color;
  final bool done;
  const _PlanItem(
    this.time,
    this.title,
    this.sub,
    this.emoji,
    this.color,
    this.done,
  );
}

class _TodayPlan extends StatelessWidget {
  const _TodayPlan();

  static const _items = [
    _PlanItem(
      '7:00',
      'Morning stretch',
      '10 min · done',
      '🧘',
      Color(0xFF8B5CF6),
      true,
    ),
    _PlanItem(
      '9:00',
      'Protein breakfast',
      '420 kcal · done',
      '🥣',
      Color(0xFFF59E0B),
      true,
    ),
    _PlanItem(
      '18:00',
      'Upper body strength',
      '45 min · 8 moves',
      '💪',
      Color(0xFF16A34A),
      false,
    ),
    _PlanItem(
      '22:30',
      'Wind down',
      'Breathing + sleep story',
      '🌙',
      Color(0xFFE11D48),
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Your plan today'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
            decoration: softCard(),
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++)
                  _row(_items[i], last: i == _items.length - 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(_PlanItem it, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Text(it.time, style: jakarta(11.5, FontWeight.w800, kMuted)),
          ),
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: it.done ? it.color : Colors.white,
                  border: Border.all(color: it.color, width: 2),
                ),
                child: it.done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: kLine,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            14,
                            FontWeight.w800,
                            it.done ? kMuted : kInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          it.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(11.5, FontWeight.w600, kMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(it.emoji, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Explore extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const _Explore({required this.onOpen});

  static const _items = [
    (
      'Strength',
      'strenth',
      Color(0xFFEDE9FE),
      Color(0xFF7C3AED),
      '24 workouts',
    ),
    ('Cardio', 'cardio', Color(0xFFFFE4E6), Color(0xFFE11D48), '18 workouts'),
    ('Yoga', 'yoga', Color(0xFFDCFCE7), Color(0xFF16A34A), '15 flows'),
    ('HIIT', 'hit', Color(0xFFFEF3C7), Color(0xFFD97706), '12 workouts'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget tile((String, String, Color, Color, String) t) => PressScale(
      onTap: () => onOpen(t.$1),
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: t.$3,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 4,
              bottom: 6,
              child: IconArt(
                'assets/images/top tabs/overview/${t.$2}.png',
                size: 84,
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              right: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.$1,
                    maxLines: 1,
                    style: jakarta(15, FontWeight.w900, kInk),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.$5,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(11, FontWeight.w700, t.$4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Explore workouts'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Pair(tile(_items[0]), tile(_items[1])),
              const SizedBox(height: 12),
              Pair(tile(_items[2]), tile(_items[3])),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges();

  static const _items = [
    ('🏅', 'Early bird', '5 morning workouts', Color(0xFFFEF3C7), true),
    ('🔥', '12-day streak', 'Keep it going', Color(0xFFFFE4E6), true),
    ('💧', 'Hydro hero', '7 days at goal', Color(0xFFE0F2FE), true),
    ('🏃', '100 km club', '68 km so far', Color(0xFFF1F5F9), false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Badges', action: '3 of 4'),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final b = _items[i];
              return Opacity(
                opacity: b.$5 ? 1 : 0.55,
                child: Container(
                  width: 116,
                  padding: const EdgeInsets.all(12),
                  decoration: softCard(radius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: b.$4,
                          shape: BoxShape.circle,
                        ),
                        child: Text(b.$1, style: const TextStyle(fontSize: 20)),
                      ),
                      const Spacer(),
                      Text(
                        b.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(12.5, FontWeight.w800, kInk),
                      ),
                      Text(
                        b.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(10.5, FontWeight.w600, kMuted),
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
}
