import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/active_workout_screen.dart';
import '../../screens/kemo_ai_screen.dart';
import '../../screens/log_meal_screen.dart';
import '../../screens/rewards_screen.dart';
import '../../screens/shop_screen.dart';
import '../../screens/steps_screen.dart';
import '../../screens/streak_detail_screen.dart';
import '../../screens/trainers_screen.dart';
import '../../screens/transform_screen.dart';
import '../dashboard_motion.dart';
import '../kemo.dart';
import '../neuro_island_dock.dart';
import '../shop_home_sections.dart';
import 'kit3.dart';

const _v4 = 'assets/images/overview_v4';
const _img = 'assets/images';

class OverviewTabV7 extends StatelessWidget {
  const OverviewTabV7({super.key});

  @override
  Widget build(BuildContext context) {
    return const NTabPage(
      top: [NDateStrip(), _StatGrid()],
      sheet: [
        _TodayPlan(),
        _GoalChart(),
        _KemoCard(),
        _QuickActions(),
        _BodyMetrics(),
        _Routine(),
        _Products(),
        _Achievements(),
        _Streak(),
        _TrainToday(),
        _Explore(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    return ValueListenableBuilder<int>(
      valueListenable: m.waterMl,
      builder: (context, ml, _) {
        final tiles = [
          NStatTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Calories',
            value: m.calories.toDouble(),
            suffix: ' kcal',
            progress: m.calorieProgress,
            filled: true,
            onTap: () => nPush(context, const LogMealScreen()),
          ),
          NStatTile(
            icon: Icons.fitness_center_rounded,
            label: 'Workout',
            value: m.activeMinutes.toDouble(),
            suffix: ' min',
            progress: m.activeProgress,
            onTap: () => nPush(
                context,
                const ActiveWorkoutScreen(
                    dayTitle: 'Upper Body Strength', dayNumber: 3)),
          ),
          NStatTile(
            icon: Icons.flag_rounded,
            label: 'Goal',
            value: 65,
            suffix: '%',
            progress: 0.65,
            onTap: () => nPush(context, const TransformScreen()),
          ),
          NStatTile(
            icon: Icons.directions_walk_rounded,
            label: 'Steps',
            value: m.steps.toDouble(),
            grouping: true,
            progress: m.stepProgress,
            onTap: () => nPush(context, const StepsScreen()),
          ),
          NStatTile(
            icon: Icons.water_drop_rounded,
            label: 'Water',
            value: ml / 1000,
            decimals: 2,
            suffix: ' L',
            progress: (ml / m.waterGoalMl).clamp(0.0, 1.0),
            onTap: () {
              HapticFeedback.selectionClick();
              m.waterMl.value = (ml + 250).clamp(0, 5000);
            },
          ),
          const NStatTile(
            icon: Icons.bedtime_rounded,
            label: 'Sleep',
            value: 7.5,
            decimals: 1,
            suffix: ' h',
            progress: 7.5 / 8,
          ),
        ];
        return NSquareGrid(
          cols: 3,
          gap: 10,
          children: [
            for (var i = 0; i < tiles.length; i++)
              NPopIn(delay: 50 * i, child: tiles[i]),
          ],
        );
      },
    );
  }
}

class _TodayPlan extends StatelessWidget {
  const _TodayPlan();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead("Today's Plan"),
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
    );
  }
}

class _GoalChart extends StatefulWidget {
  const _GoalChart();

  @override
  State<_GoalChart> createState() => _GoalChartState();
}

class _GoalChartState extends State<_GoalChart>
    with SingleTickerProviderStateMixin {
  static const _w = [71.0, 70.2, 69.6, 69.1, 68.2, 67.8, 67.1, 66.5];
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    whenRevealed(context, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _fig(String v, String label, {bool strong = false}) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: v,
                    style: tDisplay(20,
                        w: FontWeight.w700, c: strong ? kBrand : kInk3)),
                TextSpan(
                    text: ' kg',
                    style: tDisplay(12, w: FontWeight.w600, c: kMuted3)),
              ])),
            ),
            const SizedBox(height: 2),
            Text(label, style: tText(12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Goal Progress',
            action: 'Details',
            onAction: () => nPush(context, const TransformScreen())),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: nCardDeco(r: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _fig('71', 'Start'),
                  _fig('66.5', 'Now', strong: true),
                  _fig('62', 'Target'),
                  NRing(
                    value: 0.65,
                    size: 54,
                    stroke: 6,
                    center: Text('65%',
                        style: tDisplay(13, w: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _Chart(_w, 62,
                        Curves.easeOutCubic.transform(_c.value)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 1; i <= _w.length; i++)
                    Text('W$i',
                        style: tText(10.5,
                            w: i == _w.length
                                ? FontWeight.w700
                                : FontWeight.w500,
                            c: i == _w.length ? kBrand : kMuted3)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chart extends CustomPainter {
  final List<double> v;
  final double target;
  final double t;
  const _Chart(this.v, this.target, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final hi = v.reduce(math.max) + 0.8;
    final lo = target - 0.8;
    Offset pt(int i) => Offset(
        size.width * i / (v.length - 1), size.height * (hi - v[i]) / (hi - lo));
    final grid = Paint()
      ..color = kLine3
      ..strokeWidth = 1;
    for (var k = 0; k <= 3; k++) {
      final y = size.height * k / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final ty = size.height * (hi - target) / (hi - lo);
    final dash = Paint()
      ..color = kAccent
      ..strokeWidth = 1.4;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(
          Offset(x, ty), Offset(math.min(x + 4, size.width), ty), dash);
    }
    final tp = TextPainter(
      text: TextSpan(
          text: 'Target', style: tText(10, w: FontWeight.w700, c: kAccent)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, ty - tp.height - 3));

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      final a = pt(i - 1), b = pt(i);
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    canvas.save();
    canvas.clipRect(
        Rect.fromLTWH(0, -10, size.width * t + 2, size.height + 20));
    canvas.drawPath(
      Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBrand.withValues(alpha: 0.22), kBrand.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = kBrand,
    );
    canvas.restore();
    if (t > 0.98) {
      final last = pt(v.length - 1);
      canvas.drawCircle(last, 9, Paint()..color = kBrand.withValues(alpha: 0.18));
      canvas.drawCircle(last, 5, Paint()..color = kBrand);
      canvas.drawCircle(last, 2.2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_Chart o) => o.t != t;
}

class _KemoCard extends StatelessWidget {
  const _KemoCard();

  @override
  Widget build(BuildContext context) {
    void open() {
      HapticFeedback.lightImpact();
      Navigator.push(context, KemoAiScreen.route());
    }

    const chips = ['Plan my day', 'Meal idea', 'Sleep tips'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Kemo AI'),
        PressScale(
          onTap: open,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6E72F5), kBrandDeep],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: kBrand.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const KemoFace(size: 60),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ask Kemo',
                              style: tDisplay(20,
                                  w: FontWeight.w700, c: Colors.white)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF6EE7B7),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text('AI Coach · Online',
                                  style: tText(12,
                                      c: Colors.white
                                          .withValues(alpha: 0.8))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_outward_rounded,
                          color: kBrand, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < chips.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: open,
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(chips[i],
                                  style: tText(12,
                                      w: FontWeight.w600, c: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    final actions = <(IconData, String, Color, VoidCallback)>[
      (
        Icons.play_arrow_rounded,
        'Workout',
        kBrand,
        () => nPush(
            context,
            const ActiveWorkoutScreen(
                dayTitle: 'Upper Body Strength', dayNumber: 3)),
      ),
      (
        Icons.restaurant_rounded,
        'Log Meal',
        kAccent,
        () => nPush(context, const LogMealScreen()),
      ),
      (
        Icons.water_drop_rounded,
        'Water',
        const Color(0xFF3B82F6),
        () {
          HapticFeedback.selectionClick();
          m.waterMl.value = (m.waterMl.value + 250).clamp(0, 5000);
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('+250 ml water added'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(milliseconds: 1400),
            ));
        },
      ),
      (
        Icons.monitor_weight_rounded,
        'Weight',
        kSuccess,
        () => nPush(context, const TransformScreen()),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Quick Actions'),
        NSquareGrid(
          cols: 4,
          gap: 10,
          children: [
            for (var i = 0; i < actions.length; i++)
              NPopIn(
                delay: 50 * i,
                child: PressScale(
                  onTap: actions[i].$4,
                  child: LayoutBuilder(builder: (context, c) {
                    final side = c.maxWidth;
                    return Container(
                      decoration: nCardDeco(r: side * 0.24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NIconTile(actions[i].$1,
                              size: side * 0.44, color: actions[i].$3),
                          SizedBox(height: side * 0.08),
                          Text(actions[i].$2,
                              maxLines: 1,
                              style: tText(side * 0.13,
                                  w: FontWeight.w600, c: kInk3)),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BodyMetrics extends StatelessWidget {
  const _BodyMetrics();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.monitor_weight_rounded, 'Weight', 66.5, ' kg', '−2.4 kg', 0.65, 'Goal 62 kg'),
      (Icons.speed_rounded, 'BMI', 22.9, '', 'Normal', 0.55, 'Healthy range'),
      (Icons.opacity_rounded, 'Body Fat', 15.8, '%', '−1.9%', 0.62, 'Goal 14%'),
      (Icons.fitness_center_rounded, 'Muscle', 72.4, ' kg', '+1.2 kg', 0.8, 'Goal 74 kg'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Body Metrics',
            action: 'Track',
            onAction: () => nPush(context, const TransformScreen())),
        NSquareGrid(
          cols: 2,
          aspect: 1.1,
          children: [
            for (final it in items)
              PressScale(
                onTap: () => nPush(context, const TransformScreen()),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: nCardDeco(r: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NIconTile(it.$1, size: 36),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kSuccess.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(it.$5,
                                style: tText(10.5,
                                    w: FontWeight.w700, c: kSuccess)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: NCountUp(
                          it.$3,
                          decimals: 1,
                          suffix: it.$4,
                          style: tDisplay(23, w: FontWeight.w700, height: 1.1),
                          suffixStyle: tDisplay(13,
                              w: FontWeight.w600, c: kMuted3, height: 1.1),
                        ),
                      ),
                      Text(it.$2, style: tText(12, height: 1.3)),
                      const SizedBox(height: 8),
                      NBar(it.$6, height: 4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Routine extends StatefulWidget {
  const _Routine();

  @override
  State<_Routine> createState() => _RoutineState();
}

class _RoutineState extends State<_Routine> {
  final _done = [true, true, false, false];
  static const _items = [
    (Icons.local_drink_rounded, Color(0xFF3B82F6), 'Drink a glass of water', 'Streak 3 days', '1 min'),
    (Icons.self_improvement_rounded, kBrand, 'Meditate to relax', 'Streak 6 days', '10 min'),
    (Icons.accessibility_new_rounded, kAccent, 'Stretch your body', 'Streak 5 days', '10 min'),
    (Icons.directions_walk_rounded, kSuccess, 'Go for a short walk', 'Streak 3 days', '20 min'),
  ];

  @override
  Widget build(BuildContext context) {
    final n = _done.where((d) => d).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Daily Routine', action: '$n/${_items.length} done'),
        for (var i = 0; i < _items.length; i++)
          NRoutineRow(
            icon: _items[i].$1,
            color: _items[i].$2,
            title: _items[i].$3,
            sub: _items[i].$4,
            trailing: _items[i].$5,
            done: _done[i],
            last: i == _items.length - 1,
            onToggle: () {
              HapticFeedback.selectionClick();
              setState(() => _done[i] = !_done[i]);
            },
          ),
      ],
    );
  }
}

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) {
    final picks = [
      shopDemoProducts[0],
      shopDemoProducts[3],
      shopDemoProducts[4],
      shopDemoProducts[6],
      shopDemoProducts[5],
      shopDemoProducts[2],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Recommended for You',
            action: 'See all',
            onAction: () => nPush(context, const ShopScreen())),
        NCarousel(
          height: 262,
          count: picks.length,
          builder: (context, i) => NProductCard(picks[i]),
        ),
      ],
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('b_streak', '12 Days', 'Streak'),
      ('b_workouts', '25', 'Workouts'),
      ('b_steps', '10K', 'Steps'),
      ('b_water', '7 Days', 'Hydrated'),
      ('b_clean', '5 Days', 'Clean eating'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Achievements',
            action: 'View all',
            onAction: () => nPush(context, const RewardsScreen())),
        NCarousel(
          height: 150,
          count: items.length,
          builder: (context, i) => NPopIn(
            delay: 60 * i,
            child: PressScale(
              onTap: () => nPush(context, const RewardsScreen()),
              child: Container(
                width: 124,
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                decoration: nCardDeco(r: 22),
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset('$_v4/${items[i].$1}.png',
                          cacheWidth: 200),
                    ),
                    const SizedBox(height: 6),
                    Text(items[i].$2,
                        style: tDisplay(15, w: FontWeight.w700)),
                    Text(items[i].$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tText(11)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Streak extends StatelessWidget {
  const _Streak();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Streak'),
        PressScale(
          onTap: () => nPush(context, const StreakDetailScreen()),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kAccentSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset('$_v4/fire.png',
                        width: 54, height: 54, cacheWidth: 160),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NCountUp(
                            m.streak.toDouble(),
                            suffix: ' days',
                            style: tDisplay(28, w: FontWeight.w800),
                            suffixStyle: tDisplay(15,
                                w: FontWeight.w600, c: kMuted3),
                          ),
                          Text('Best 21 days', style: tText(12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B2E12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Text('Keep it',
                              style: tText(12,
                                  w: FontWeight.w700, c: Colors.white)),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          children: [
                            Text(days[i],
                                style: tText(11,
                                    w: i == today
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    c: i == today ? kInk3 : kMuted3)),
                            const SizedBox(height: 6),
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i <= today ? kAccent : Colors.white,
                                ),
                                child: i <= today
                                    ? const FittedBox(
                                        child: Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(Icons.check_rounded,
                                              color: Colors.white),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrainToday extends StatelessWidget {
  const _TrainToday();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Train Today'),
        NSquareGrid(
          cols: 2,
          children: [
            NPhotoCard(
              image: '$_img/workout_exercise_cutout.jpg',
              title: 'Full Body HIIT',
              tag: '25 min',
              play: true,
              onTap: () => nPush(
                  context,
                  const ActiveWorkoutScreen(
                      dayTitle: 'Full Body HIIT', dayNumber: 3)),
            ),
            NPhotoCard(
              image: '$_img/category_yoga_model.png',
              title: 'Yoga Flow',
              tag: '20 min',
              play: true,
              focus: Alignment.topCenter,
              onTap: () => nPush(
                  context,
                  const ActiveWorkoutScreen(
                      dayTitle: 'Yoga Flow', dayNumber: 3)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Explore extends StatelessWidget {
  const _Explore();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Explore'),
        NSquareGrid(
          cols: 2,
          children: [
            NPhotoCard(
              image: '$_img/transform_hero.jpg',
              title: 'Transformation',
              tag: 'Before · After',
              focus: Alignment.topCenter,
              onTap: () => nPush(context, const TransformScreen()),
            ),
            NPhotoCard(
              image: '$_img/trainers_hero_banner.jpg',
              title: 'Personal Trainers',
              tag: '500+ coaches',
              onTap: () => nPush(context, const TrainersScreen()),
            ),
            NPhotoCard(
              image: '$_img/steps_walking_person.jpg',
              title: 'Live Walk',
              tag: 'Steps',
              onTap: () => nPush(context, const StepsScreen()),
            ),
            NPhotoCard(
              image: '$_img/rewards_gold_trophy_3d.jpg',
              title: 'Rewards',
              tag: '1,250 pts',
              onTap: () => nPush(context, const RewardsScreen()),
            ),
          ],
        ),
      ],
    );
  }
}
