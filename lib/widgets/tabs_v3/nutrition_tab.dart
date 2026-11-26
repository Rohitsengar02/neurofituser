import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/date_nutrition_detail_screen.dart';
import '../../screens/log_meal_screen.dart';
import '../../screens/shop_screen.dart';
import '../dashboard_motion.dart';
import '../neuro_island_dock.dart';
import '../shop_home_sections.dart';
import 'kit3.dart';

const _img = 'assets/images';

class NutritionTabV3 extends StatelessWidget {
  const NutritionTabV3({super.key});

  @override
  Widget build(BuildContext context) {
    return const NTabPage(
      top: [_CalorieCard(), _Macros()],
      sheet: [
        _Meals(),
        _Water(),
        _ScanMeal(),
        _WeekBars(),
        _Supplements(),
      ],
    );
  }
}

class _CalorieCard extends StatelessWidget {
  const _CalorieCard();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData i, Color c, String label, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              NIconTile(i, size: 34, color: c),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: tText(12.5))),
              Text(v, style: tDisplay(15, w: FontWeight.w700)),
            ],
          ),
        );
    return PressScale(
      onTap: () => nPush(
          context, DateNutritionDetailScreen(initialDate: DateTime.now())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: nCardDeco(r: 26),
        child: Row(
          children: [
            NRing(
              value: 1420 / 1800,
              size: 122,
              stroke: 11,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NCountUp(380,
                      style: tDisplay(26, w: FontWeight.w800, height: 1)),
                  const SizedBox(height: 2),
                  Text('kcal left', style: tText(11.5)),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: [
                  row(Icons.restaurant_rounded, kBrand, 'Eaten', '1,420'),
                  row(Icons.local_fire_department_rounded, kAccent, 'Burned',
                      '320'),
                  row(Icons.flag_rounded, kSuccess, 'Goal', '1,800'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Macros extends StatelessWidget {
  const _Macros();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Protein', 92, 120, kBrand),
      ('Carbs', 160, 220, kAccent),
      ('Fat', 48, 60, kSuccess),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: NPopIn(
              delay: 60 * i,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: nCardDeco(r: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(items[i].$1, style: tText(12)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '${items[i].$2}',
                            style: tDisplay(18, w: FontWeight.w700)),
                        TextSpan(
                            text: ' / ${items[i].$3}g',
                            style: tText(11.5, w: FontWeight.w500)),
                      ])),
                    ),
                    const SizedBox(height: 8),
                    NBar(items[i].$2 / items[i].$3,
                        color: items[i].$4, height: 5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Meals extends StatefulWidget {
  const _Meals();

  @override
  State<_Meals> createState() => _MealsState();
}

class _MealsState extends State<_Meals> {
  final _done = [true, true, true, false];
  static const _items = [
    (Icons.free_breakfast_rounded, kAccent, 'Breakfast', 'Oats & berries', '420'),
    (Icons.lunch_dining_rounded, kSuccess, 'Lunch', 'Paneer rice bowl', '610'),
    (Icons.icecream_rounded, Color(0xFF3B82F6), 'Snack', 'Greek yogurt', '180'),
    (Icons.dinner_dining_rounded, kBrand, 'Dinner', 'Tap to add', '—'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Meals Today',
            action: 'Add meal',
            onAction: () => nPush(context, const LogMealScreen())),
        for (var i = 0; i < _items.length; i++)
          NRoutineRow(
            icon: _items[i].$1,
            color: _items[i].$2,
            title: _items[i].$3,
            sub: _items[i].$4,
            trailing: _items[i].$5 == '—' ? 'Add' : '${_items[i].$5} kcal',
            trailingIcon: _items[i].$5 == '—'
                ? Icons.add_circle_rounded
                : Icons.local_fire_department_rounded,
            done: _done[i],
            last: i == _items.length - 1,
            onToggle: () {
              HapticFeedback.selectionClick();
              setState(() => _done[i] = !_done[i]);
            },
            onTap: () => nPush(context, const LogMealScreen()),
          ),
      ],
    );
  }
}

class _Water extends StatelessWidget {
  const _Water();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    const blue = Color(0xFF3B82F6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Water'),
        ValueListenableBuilder<int>(
          valueListenable: m.waterMl,
          builder: (context, ml, _) {
            final glasses = (ml / 250).floor();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: nCardDeco(r: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: (ml / 1000).toStringAsFixed(2),
                              style: tDisplay(26, w: FontWeight.w800)),
                          TextSpan(
                              text: ' / 2.5 L',
                              style: tText(13, w: FontWeight.w500)),
                        ])),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          m.waterMl.value = (ml + 250).clamp(0, 5000);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                          decoration: BoxDecoration(
                            color: blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_rounded,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('250 ml',
                                  style: tText(12.5,
                                      w: FontWeight.w700, c: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < 10; i++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              m.waterMl.value = (i + 1) * 250;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: i < glasses
                                    ? blue
                                    : blue.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                  bottom: Radius.circular(10),
                                ),
                              ),
                              child: Icon(Icons.water_drop_rounded,
                                  size: 14,
                                  color: i < glasses
                                      ? Colors.white
                                      : blue.withValues(alpha: 0.35)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ScanMeal extends StatelessWidget {
  const _ScanMeal();

  @override
  Widget build(BuildContext context) {
    return NHeroCard(
      tag: 'AI MEAL SCAN',
      title: 'Snap your',
      highlight: 'plate',
      cta: 'Log meal',
      image: '$_img/illustrations/nutrition.png',
      onTap: () => nPush(context, const LogMealScreen()),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars();

  @override
  Widget build(BuildContext context) {
    const kcal = [1650, 1820, 1540, 1760, 1900, 1380, 1420];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('This Week',
            action: 'Details',
            onAction: () => nPush(context,
                DateNutritionDetailScreen(initialDate: DateTime.now()))),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: nCardDeco(r: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('1,639', style: tDisplay(24, w: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Text('avg kcal / day', style: tText(12)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: kcal[i] / 2000),
                              duration: Duration(milliseconds: 700 + i * 60),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, _) => Container(
                                width: 22,
                                height: 92 * t,
                                decoration: BoxDecoration(
                                  color: i == today
                                      ? kBrand
                                      : kBrand.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(days[i],
                                style: tText(11,
                                    w: i == today
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    c: i == today ? kBrand : kMuted3)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Supplements extends StatelessWidget {
  const _Supplements();

  @override
  Widget build(BuildContext context) {
    final picks = shopDemoProducts
        .where((p) => p.category == 'Protein' || p.category == 'Bottles')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Fuel Your Goals',
            action: 'See all',
            onAction: () =>
                nPush(context, const ShopScreen(initialCategory: 'Protein'))),
        NCarousel(
          height: 262,
          count: picks.length,
          builder: (context, i) => NProductCard(picks[i]),
        ),
      ],
    );
  }
}
