import 'package:flutter/material.dart';

import '../../screens/active_workout_screen.dart';
import '../../screens/trainer_detail_screen.dart';
import '../../screens/trainers_screen.dart';
import '../../screens/workout_category_detail_screen.dart';
import '../dashboard_motion.dart';
import '../tabs_v2/kit.dart' show IconArt;
import 'kit3.dart';

const _img = 'assets/images';

class WorkoutsTabV3 extends StatelessWidget {
  const WorkoutsTabV3({super.key});

  @override
  Widget build(BuildContext context) {
    return NTabPage(
      top: [
        const NDateStrip(),
        NHeroCard(
          tag: 'DAY 3 OF 30',
          title: 'Upper Body',
          highlight: 'Strength',
          cta: 'Start workout',
          image: '$_img/illustrations/workout.png',
          pills: const ['45 min', '8 moves', '320 kcal'],
          onTap: () => nPush(
              context,
              const ActiveWorkoutScreen(
                  dayTitle: 'Upper Body Strength', dayNumber: 3)),
        ),
      ],
      sheet: const [
        _ThisWeek(),
        _Categories(),
        _Programs(),
        _QuickSessions(),
        _Trainers(),
      ],
    );
  }
}

class _ThisWeek extends StatelessWidget {
  const _ThisWeek();

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData i, String v, String l, Color c) => Expanded(
          child: Row(
            children: [
              NIconTile(i, size: 34, color: c),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(v, style: tDisplay(14, w: FontWeight.w700)),
                    ),
                    Text(l, maxLines: 1, style: tText(11)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('This Week'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: nCardDeco(r: 24),
          child: Column(
            children: [
              Row(
                children: [
                  NRing(
                    value: 0.6,
                    size: 70,
                    stroke: 8,
                    center: Text('3/5',
                        style: tDisplay(17, w: FontWeight.w700)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workouts done',
                            style: tDisplay(17, w: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('2 more to hit your goal', style: tText(12.5)),
                        const SizedBox(height: 10),
                        const NBar(0.6, height: 6),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: kLine3),
              const SizedBox(height: 14),
              Row(
                children: [
                  stat(Icons.timer_rounded, '1h 52m', 'Active', kBrand),
                  stat(Icons.local_fire_department_rounded, '960', 'kcal',
                      kAccent),
                  stat(Icons.bolt_rounded, '12', 'Day streak', kSuccess),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories();

  static const _items = [
    ('Strength', 'strenth', 0.7, '24 workouts'),
    ('Cardio', 'cardio', 0.45, '18 workouts'),
    ('Yoga', 'yoga', 0.3, '15 workouts'),
    ('HIIT', 'hit', 0.55, '12 workouts'),
    ('Mobility', 'mobility', 0.2, '10 workouts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Categories',
            action: 'View all',
            onAction: () => nPush(context,
                const WorkoutCategoryDetailScreen(initialCategory: 'All'))),
        NCarousel(
          height: 168,
          count: _items.length,
          builder: (context, i) {
            final c = _items[i];
            return NPopIn(
              delay: 50 * i,
              child: PressScale(
                onTap: () => nPush(context,
                    WorkoutCategoryDetailScreen(initialCategory: c.$1)),
                child: Container(
                  width: 132,
                  padding: const EdgeInsets.all(14),
                  decoration: nCardDeco(r: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: kBrandSoft,
                          shape: BoxShape.circle,
                        ),
                        child: IconArt(
                            'assets/images/top tabs/overview/${c.$2}.png',
                            size: 40),
                      ),
                      const Spacer(),
                      Text(c.$1,
                          style: tText(14.5, w: FontWeight.w600, c: kInk3)),
                      const SizedBox(height: 2),
                      Text(c.$4, style: tText(11.5)),
                      const SizedBox(height: 10),
                      NBar(c.$3, height: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Programs extends StatelessWidget {
  const _Programs();

  static const _items = [
    ('$_img/athlete_transform.jpg', 'Muscle Builder', '8 weeks', 'Strength'),
    ('$_img/workout_exercise_cutout.jpg', '30-Day Shred', '30 days', 'HIIT'),
    ('$_img/category_yoga_model.png', 'Yoga Reset', '2 weeks', 'Yoga'),
    ('$_img/transform_hero.jpg', 'Couple Fit', '6 weeks', 'Cardio'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Programs for You',
            action: 'See all',
            onAction: () => nPush(context,
                const WorkoutCategoryDetailScreen(initialCategory: 'All'))),
        NCarousel(
          height: 170,
          count: _items.length,
          builder: (context, i) {
            final p = _items[i];
            return SizedBox(
              width: 170,
              child: NPhotoCard(
                image: p.$1,
                title: p.$2,
                tag: p.$3,
                focus: Alignment.topCenter,
                onTap: () => nPush(
                    context, WorkoutCategoryDetailScreen(initialCategory: p.$4)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickSessions extends StatelessWidget {
  const _QuickSessions();

  static const _items = [
    (Icons.local_fire_department_rounded, kAccent, '7-min Abs Blast', '7 min · 90 kcal'),
    (Icons.bolt_rounded, kBrand, '10-min HIIT Burn', '10 min · 140 kcal'),
    (Icons.self_improvement_rounded, kSuccess, '15-min Mobility Flow', '15 min · 70 kcal'),
    (Icons.fitness_center_rounded, Color(0xFF3B82F6), '20-min Full Body', '20 min · 210 kcal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Quick Sessions'),
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          PressScale(
            onTap: () => nPush(context,
                ActiveWorkoutScreen(dayTitle: _items[i].$3, dayNumber: i + 1)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: nCardDeco(r: 18),
              child: Row(
                children: [
                  NIconTile(_items[i].$1, size: 44, color: _items[i].$2),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_items[i].$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tText(14.5, w: FontWeight.w600, c: kInk3)),
                        const SizedBox(height: 2),
                        Text(_items[i].$4, style: tText(12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: kBrand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Trainers extends StatelessWidget {
  const _Trainers();

  static const _items = [
    ('$_img/ai_coach_avatar_3d.jpg', 'Arjun Mehta', 'Strength Coach', 4.5),
    ('$_img/category_yoga_model.png', 'Priya Nair', 'Yoga Expert', 4.9),
    ('$_img/athlete_transform.jpg', 'Rahul Verma', 'Body Transformation', 4.7),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Top Trainers',
            action: 'View all',
            onAction: () => nPush(context, const TrainersScreen())),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: nCardDeco(r: 22),
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: kLine3),
                InkWell(
                  onTap: () => nPush(
                    context,
                    TrainerDetailScreen(
                      trainerName: _items[i].$2,
                      specialty: _items[i].$3,
                      rating: '${_items[i].$4}',
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(_items[i].$1,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              cacheWidth: 200),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_items[i].$2,
                                  style: tText(15,
                                      w: FontWeight.w600, c: kInk3)),
                              const SizedBox(height: 2),
                              Text(_items[i].$3, style: tText(12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  for (var s = 1; s <= 5; s++)
                                    Icon(
                                      s <= _items[i].$4.floor()
                                          ? Icons.star_rounded
                                          : (s - _items[i].$4 < 1
                                              ? Icons.star_half_rounded
                                              : Icons.star_outline_rounded),
                                      size: 15,
                                      color: kAccent,
                                    ),
                                  const SizedBox(width: 4),
                                  Text('${_items[i].$4}',
                                      style: tText(11.5,
                                          w: FontWeight.w600, c: kInk3)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: kBrandSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_rounded,
                              size: 18, color: kBrand),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
