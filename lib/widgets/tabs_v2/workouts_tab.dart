import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/active_workout_screen.dart';
import '../../screens/workout_category_detail_screen.dart';
import '../dashboard_motion.dart';
import 'kit.dart';

const _accent = Color(0xFF7C3AED);
const _soft = Color(0xFFEDE9FE);

class WorkoutsTabV2 extends StatelessWidget {
  const WorkoutsTabV2({super.key});

  void _push(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...revealSections([
          HeroIllustrationCard(
            eyebrow: 'DAY 3 OF 30',
            title: 'Upper Body',
            highlight: 'Strength',
            illustration: 'assets/images/illustrations/workout.png',
            accent: _accent,
            soft: _soft,
            pills: const ['⏱ 45 min', '💪 8 moves', '🔥 320 kcal'],
            cta: 'Start workout',
            onCta: () => _push(
              context,
              const ActiveWorkoutScreen(
                dayTitle: 'Upper Body Strength',
                dayNumber: 3,
              ),
            ),
          ),
          const _WeekStrip(),
          _Categories(
            onOpen: (c) =>
                _push(context, WorkoutCategoryDetailScreen(initialCategory: c)),
          ),
          _Programs(
            onOpen: (c) =>
                _push(context, WorkoutCategoryDetailScreen(initialCategory: c)),
          ),
          _QuickSessions(
            onStart: (title, day) => _push(
              context,
              ActiveWorkoutScreen(dayTitle: title, dayNumber: day),
            ),
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const done = [true, true, false, true, false, false, false];
    final today = DateTime.now().weekday - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: softCard(tint: _accent),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This week',
                        style: jakarta(16, FontWeight.w900, kInk),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '3 of 5 workouts · 1h 52m active',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(11.5, FontWeight.w600, kMuted),
                      ),
                    ],
                  ),
                ),
                GrowRing(
                  value: 0.6,
                  color: _accent,
                  size: 46,
                  stroke: 5,
                  center: Text(
                    '60%',
                    style: jakarta(11, FontWeight.w900, _accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isToday = i == today;
                return Column(
                  children: [
                    Text(
                      days[i],
                      style: jakarta(
                        11,
                        FontWeight.w800,
                        isToday ? _accent : kMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done[i]
                            ? _accent
                            : isToday
                            ? _soft
                            : const Color(0xFFF8FAFC),
                        border: isToday && !done[i]
                            ? Border.all(color: _accent, width: 1.6)
                            : null,
                      ),
                      child: done[i]
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const _Categories({required this.onOpen});

  static const _items = [
    ('All', 'all', Color(0xFFF1F5F9)),
    ('Strength', 'strenth', Color(0xFFEDE9FE)),
    ('Cardio', 'cardio', Color(0xFFFFE4E6)),
    ('Yoga', 'yoga', Color(0xFFDCFCE7)),
    ('HIIT', 'hit', Color(0xFFFEF3C7)),
    ('Mobility', 'mobility', Color(0xFFE0F2FE)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Categories'),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = _items[i];
              return PressScale(
                onTap: () => onOpen(c.$1),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.$3,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconArt(
                        'assets/images/top tabs/overview/${c.$2}.png',
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(c.$1, style: jakarta(11.5, FontWeight.w700, kInk)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Programs extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const _Programs({required this.onOpen});

  static const _items = [
    (
      'assets/images/workout_category_1.png',
      'Core Crusher',
      '4 weeks · Beginner',
      'Strength',
    ),
    (
      'assets/images/workout_category_3.png',
      '30-Day Shred',
      '30 days · Intermediate',
      'HIIT',
    ),
    (
      'assets/images/workout_category_4.png',
      'Transformation',
      '8 weeks · Advanced',
      'Strength',
    ),
    (
      'assets/images/workout_category_2.jpg',
      'Yoga Reset',
      '2 weeks · All levels',
      'Yoga',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'Programs for you',
          action: 'See all',
          accent: _accent,
        ),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = _items[i];
              return PressScale(
                onTap: () => onOpen(p.$4),
                child: SizedBox(
                  width: 148,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          p.$1,
                          width: 148,
                          height: 180,
                          fit: BoxFit.cover,
                          cacheWidth: 444,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(13.5, FontWeight.w800, kInk),
                      ),
                      Text(
                        p.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(11, FontWeight.w600, kMuted),
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

class _QuickSessions extends StatelessWidget {
  final void Function(String title, int day) onStart;
  const _QuickSessions({required this.onStart});

  static const _items = [
    (
      '🔥',
      '7-min Abs Blast',
      '7 min · 90 kcal',
      Color(0xFFFFEDD5),
      Color(0xFFFDBA74),
    ),
    (
      '⚡',
      '10-min HIIT Burn',
      '10 min · 140 kcal',
      Color(0xFFFEF9C3),
      Color(0xFFFDE047),
    ),
    (
      '🤸',
      '15-min Mobility Flow',
      '15 min · 70 kcal',
      Color(0xFFE0F2FE),
      Color(0xFF7DD3FC),
    ),
    (
      '🏋️',
      '20-min Full Body',
      '20 min · 210 kcal',
      Color(0xFFEDE9FE),
      Color(0xFFC4B5FD),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Quick sessions'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: softCard(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 76,
                      endIndent: 16,
                      color: kLine,
                    ),
                  InkWell(
                    onTap: () => onStart(_items[i].$2, i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          EmojiBadge(_items[i].$1, _items[i].$4, _items[i].$5),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _items[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(14, FontWeight.w800, kInk),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _items[i].$3,
                                  style: jakarta(11.5, FontWeight.w600, kMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
