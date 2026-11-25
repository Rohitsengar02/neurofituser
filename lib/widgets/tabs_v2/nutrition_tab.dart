import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/date_nutrition_detail_screen.dart';
import '../../screens/log_meal_screen.dart';
import '../dashboard_motion.dart';
import '../neuro_island_dock.dart';
import 'kit.dart';

const _accent = Color(0xFFD97706);
const _soft = Color(0xFFFEF3C7);

class NutritionTabV2 extends StatelessWidget {
  const NutritionTabV2({super.key});

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
            eyebrow: '1,380 OF 2,000 KCAL',
            title: '620 kcal left',
            highlight: 'for today',
            illustration: 'assets/images/illustrations/nutrition.png',
            accent: _accent,
            soft: _soft,
            cta: 'Log a meal',
            onCta: () => _push(context, const LogMealScreen()),
            footer: const _Macros(),
          ),
          _Meals(
            onOpen: (type) =>
                _push(context, LogMealScreen(initialMealType: type)),
            onDetails: () => _push(
              context,
              DateNutritionDetailScreen(initialDate: DateTime.now()),
            ),
          ),
          const _Hydration(),
          const _HealthyPicks(),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Macros extends StatelessWidget {
  const _Macros();

  @override
  Widget build(BuildContext context) {
    Widget macro(String name, int now, int goal, Color c) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: jakarta(11, FontWeight.w700, kMuted)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$now',
                    style: jakarta(14, FontWeight.w900, kInk),
                  ),
                  TextSpan(
                    text: ' / ${goal}g',
                    style: jakarta(11, FontWeight.w700, kMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          GrowBar(value: now / goal, color: c, height: 5),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          macro('Protein', 82, 120, const Color(0xFFEF4444)),
          const SizedBox(width: 14),
          macro('Carbs', 160, 220, _accent),
          const SizedBox(width: 14),
          macro('Fat', 38, 60, const Color(0xFF0EA5E9)),
        ],
      ),
    );
  }
}

class _Meals extends StatelessWidget {
  final ValueChanged<String> onOpen;
  final VoidCallback onDetails;
  const _Meals({required this.onOpen, required this.onDetails});

  static const _items = [
    (
      'Breakfast',
      '🥣',
      'Oats, berries & almonds',
      420,
      true,
      Color(0xFFFFEDD5),
      Color(0xFFFED7AA),
    ),
    (
      'Lunch',
      '🥗',
      'Paneer bowl & brown rice',
      640,
      true,
      Color(0xFFDCFCE7),
      Color(0xFFBBF7D0),
    ),
    (
      'Snack',
      '🍌',
      'Suggested: banana + whey',
      220,
      false,
      Color(0xFFFEF9C3),
      Color(0xFFFDE68A),
    ),
    (
      'Dinner',
      '🍲',
      'Not logged yet',
      0,
      false,
      Color(0xFFE0F2FE),
      Color(0xFFBAE6FD),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Today\'s meals',
          action: 'Details',
          onAction: onDetails,
          accent: _accent,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final m in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PressScale(
                    onTap: () => onOpen(m.$1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: softCard(tint: _accent, radius: 20),
                      child: Row(
                        children: [
                          EmojiBadge(m.$2, m.$6, m.$7, size: 50),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.$1,
                                  style: jakarta(14, FontWeight.w800, kInk),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(11.5, FontWeight.w600, kMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (m.$5)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${m.$4}',
                                  style: jakarta(15, FontWeight.w900, kInk),
                                ),
                                Text(
                                  'kcal',
                                  style: jakarta(10.5, FontWeight.w700, kMuted),
                                ),
                              ],
                            )
                          else
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _soft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: _accent,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
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

class _Hydration extends StatelessWidget {
  const _Hydration();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    const blue = Color(0xFF0EA5E9);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<int>(
        valueListenable: m.waterMl,
        builder: (context, ml, _) {
          final glasses = (ml / 250).floor();
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hydration',
                            style: jakarta(16, FontWeight.w900, kInk),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(ml / 1000).toStringAsFixed(2)} L of ${(m.waterGoalMl / 1000).toStringAsFixed(1)} L · tap a glass',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(11.5, FontWeight.w600, kMuted),
                          ),
                        ],
                      ),
                    ),
                    PressScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        m.waterMl.value = (ml + 250).clamp(0, 5000);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: blue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '+250 ml',
                          style: jakarta(12, FontWeight.w800, Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (i) {
                    final full = i < glasses;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        m.waterMl.value = (i + 1) * 250;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        width: 22,
                        height: full ? 34 : 30,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                            bottom: Radius.circular(8),
                          ),
                          color: full ? blue : Colors.white,
                          border: Border.all(
                            color: blue.withValues(alpha: full ? 1 : 0.35),
                            width: 1.4,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HealthyPicks extends StatelessWidget {
  const _HealthyPicks();

  static const _items = [
    (
      '🥑',
      'Avocado toast',
      '320 kcal · 10 min',
      Color(0xFFDCFCE7),
      Color(0xFF86EFAC),
    ),
    (
      '🍳',
      'Veggie omelette',
      '280 kcal · 12 min',
      Color(0xFFFEF3C7),
      Color(0xFFFCD34D),
    ),
    (
      '🍓',
      'Berry smoothie',
      '210 kcal · 5 min',
      Color(0xFFFFE4E6),
      Color(0xFFFDA4AF),
    ),
    (
      '🍛',
      'Dal & quinoa',
      '450 kcal · 25 min',
      Color(0xFFFFEDD5),
      Color(0xFFFDBA74),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Healthy picks'),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final r = _items[i];
              return Container(
                width: 136,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [r.$4, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: r.$4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: r.$5.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(r.$1, style: const TextStyle(fontSize: 28)),
                    ),
                    const Spacer(),
                    Text(
                      r.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(13.5, FontWeight.w800, kInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(11, FontWeight.w600, kMuted),
                    ),
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
