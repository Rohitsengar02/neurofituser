import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/date_nutrition_detail_screen.dart';
import '../screens/kemo_ai_screen.dart';
import '../screens/log_meal_screen.dart';
import 'kemo_avatar.dart';
import 'side_island.dart' show IslandStats;

const _blue = Color(0xFF3B82F6);
const _blueDeep = Color(0xFF2563EB);
const _blueSoft = Color(0xFFE8F1FF);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _protein = Color(0xFFEF4444);
const _carbs = Color(0xFFF5B301);
const _fat = Color(0xFF22C55E);

TextStyle _f(double size,
        {FontWeight w = FontWeight.w600, Color c = _ink, double? h}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: w, color: c, height: h);

BoxDecoration _card({double r = 24}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      boxShadow: [
        BoxShadow(
          color: _blue.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

/// Nutrition tab: a calm calorie tracker. Day strip with rings, the big
/// "kcal left" number, macro rings, Meals / Activity / Water, AI meal scan,
/// the week's chart, recipes and a tip from Kemo.
class NutritionTabV2 extends StatefulWidget {
  const NutritionTabV2({super.key});

  @override
  State<NutritionTabV2> createState() => _NutritionTabV2State();
}

class _NutritionTabV2State extends State<NutritionTabV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  // Day offsets from today (-3 .. +3) and how full each day was.
  static const _dayFill = [0.92, 1.0, 0.85, 0.71, 0.0, 0.0, 0.0];
  int _day = 3; // today
  int _cat = 0;

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  int get _left =>
      [410, 120, 560, IslandStats.left, 1800, 1800, 1800][_day];

  Widget _reveal(int i, Widget child) {
    final a = CurvedAnimation(
      parent: _in,
      curve: Interval((0.07 * i).clamp(0.0, 0.7),
          (0.07 * i + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, c) => Opacity(
        opacity: a.value,
        child:
            Transform.translate(offset: Offset(0, 22 * (1 - a.value)), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _reveal(0, _dayStrip()),
          const SizedBox(height: 14),
          _reveal(1, _hero()),
          const SizedBox(height: 14),
          _reveal(2, _macros()),
          const SizedBox(height: 24),
          _reveal(3, _categories()),
          const SizedBox(height: 24),
          _reveal(4, _scanCard()),
          const SizedBox(height: 24),
          _reveal(5, _week()),
          const SizedBox(height: 24),
          _reveal(6, _recipes()),
          const SizedBox(height: 24),
          _reveal(7, _kemoTip()),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- days
  Widget _dayStrip() {
    final now = DateTime.now();
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: _card(r: 22),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(builder: (context) {
                final d = now.add(Duration(days: i - 3));
                final sel = i == _day;
                final future = i > 3;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _day = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? _blueSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(names[d.weekday - 1],
                            style: _f(10.5,
                                w: FontWeight.w600,
                                c: sel ? _blueDeep : _muted)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CustomPaint(
                            painter: _Ring(
                              future ? 0 : _dayFill[i],
                              color: _dayFill[i] >= 1 ? _fat : _blue,
                              track: future
                                  ? const Color(0xFFE2E8F0)
                                  : _blue.withValues(alpha: 0.14),
                              stroke: 3,
                              dashed: future,
                            ),
                            child: Center(
                              child: Text('${d.day}',
                                  style: _f(11.5,
                                      w: FontWeight.w700,
                                      c: future ? _muted : _ink)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- hero
  Widget _hero() {
    Widget chip(IconData i, String v, String l) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(i, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(v,
                            style: _f(14,
                                w: FontWeight.w800, c: Colors.white)),
                      ),
                      Text(l,
                          style: _f(10.5,
                              w: FontWeight.w500, c: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return GestureDetector(
      onTap: () => _push(
          context, DateNutritionDetailScreen(initialDate: DateTime.now())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7CB8FF), _blue, _blueDeep],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.3),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14), width: 22),
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    _arrow(Icons.chevron_left_rounded,
                        _day > 0 ? () => setState(() => _day--) : null),
                    Expanded(
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(_day),
                            tween: Tween(begin: 0, end: _left.toDouble()),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _fmt(v.round()),
                                style: _f(64,
                                    w: FontWeight.w800,
                                    c: Colors.white,
                                    h: 1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Kcal left',
                              style: _f(13,
                                  w: FontWeight.w600, c: Colors.white70)),
                        ],
                      ),
                    ),
                    _arrow(Icons.chevron_right_rounded,
                        _day < 6 ? () => setState(() => _day++) : null),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    chip(Icons.restaurant_rounded, _fmt(IslandStats.eaten),
                        'Eaten'),
                    const SizedBox(width: 8),
                    chip(Icons.local_fire_department_rounded,
                        '${IslandStats.burned}', 'Burned'),
                    const SizedBox(width: 8),
                    chip(Icons.flag_rounded, _fmt(IslandStats.budget), 'Goal'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrow(IconData i, VoidCallback? onTap) => GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: onTap == null ? 0.06 : 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(i,
              color: Colors.white.withValues(alpha: onTap == null ? 0.4 : 1)),
        ),
      );

  // -------------------------------------------------------------- macros
  Widget _macros() {
    const items = [
      ('Protein', 100, 140, _protein, Icons.egg_alt_rounded),
      ('Carbs', 245, 350, _carbs, Icons.bakery_dining_rounded),
      ('Fat', 70, 70, _fat, Icons.water_drop_rounded),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              decoration: _card(r: 22),
              child: Column(
                children: [
                  Text(items[i].$1, style: _f(13, w: FontWeight.w700)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: AnimatedBuilder(
                      animation: _in,
                      builder: (context, child) => CustomPaint(
                        painter: _Ring(
                          (items[i].$2 / items[i].$3) *
                              Curves.easeOutCubic.transform(
                                  ((_in.value - 0.2) / 0.6).clamp(0.0, 1.0)),
                          color: items[i].$4,
                          track: items[i].$4.withValues(alpha: 0.14),
                          stroke: 6,
                          gap: true,
                        ),
                        child: child,
                      ),
                      child: Center(
                        child: Icon(items[i].$5,
                            size: 20, color: items[i].$4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '${items[i].$2}',
                          style: _f(13, w: FontWeight.w800)),
                      TextSpan(
                          text: '/${items[i].$3}g',
                          style: _f(12,
                              w: FontWeight.w600, c: items[i].$4)),
                    ])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------- categories
  Widget _head(String t, {String? badge, String? action, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(t, style: _f(18, w: FontWeight.w800)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _blueSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge,
                  style: _f(10.5, w: FontWeight.w700, c: _blueDeep)),
            ),
          ],
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action,
                  style: _f(13, w: FontWeight.w700, c: _blueDeep)),
            ),
        ],
      ),
    );
  }

  Widget _categories() {
    const labels = ['Meals', 'Activity', 'Water'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _head('Categories', badge: 'New'),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: _card(r: 18),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth / labels.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: w * _cat,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6AADFF), _blue]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _cat = i);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: _f(13.5,
                                  w: FontWeight.w700,
                                  c: i == _cat ? Colors.white : _ink),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: KeyedSubtree(
              key: ValueKey(_cat),
              child: switch (_cat) {
                0 => _mealsList(),
                1 => _activityList(),
                _ => _waterCard(),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _mealsList() {
    const meals = [
      ('Breakfast', 'Oats, berries & coffee', 420, 17, 62, 9,
          'assets/images/island/meal_scan.png'),
      ('Lunch', 'Classic creamy paneer bowl', 612, 28, 160, 13,
          'assets/images/island/bowl.png'),
      ('Snack', 'Greek yogurt & almonds', 188, 14, 12, 8, null),
    ];
    return Column(
      children: [
        for (final m in meals) ...[
          GestureDetector(
            onTap: () => _push(context, LogMealScreen(initialMealType: m.$1)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: _card(r: 22),
              child: Row(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: _blueSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: m.$7 == null
                        ? const Icon(Icons.icecream_rounded,
                            color: _blue, size: 32)
                        : Image.asset(m.$7!,
                            fit: BoxFit.cover, cacheWidth: 220),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(m.$1,
                                  style: _f(11.5,
                                      w: FontWeight.w600, c: _muted)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _blueSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${m.$3} kcal',
                                  style: _f(11,
                                      w: FontWeight.w700, c: _blueDeep)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(m.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _f(14, w: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _macroMini(_protein, 'Protein', '${m.$4}g'),
                            _macroMini(_carbs, 'Carbs', '${m.$5}g'),
                            _macroMini(_fat, 'Fat', '${m.$6}g'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        GestureDetector(
          onTap: () =>
              _push(context, const LogMealScreen(initialMealType: 'Dinner')),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_rounded, color: _blue),
                const SizedBox(width: 8),
                Text('Add dinner',
                    style: _f(14, w: FontWeight.w700, c: _blueDeep)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _macroMini(Color c, String l, String v) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(l, style: _f(10.5, w: FontWeight.w500, c: _muted)),
              ],
            ),
            Text(v, style: _f(13.5, w: FontWeight.w700)),
          ],
        ),
      );

  Widget _activityList() {
    const items = [
      (Icons.directions_run_rounded, 'Morning run', '25 min · 3.2 km', 210,
          Color(0xFFFF7A1A)),
      (Icons.fitness_center_rounded, 'Upper body strength', '30 min', 110,
          Color(0xFF8B5CF6)),
      (Icons.directions_walk_rounded, 'Steps', '8,542 steps', 0, _fat),
    ];
    return Column(
      children: [
        for (final a in items)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: _card(r: 22),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: a.$5.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(a.$1, color: a.$5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.$2, style: _f(14, w: FontWeight.w700)),
                      Text(a.$3, style: _f(12, w: FontWeight.w500, c: _muted)),
                    ],
                  ),
                ),
                Text(a.$4 == 0 ? '85%' : '-${a.$4} kcal',
                    style: _f(13.5, w: FontWeight.w800, c: a.$5)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _waterCard() {
    const cyan = Color(0xFF0EA5E9);
    return ValueListenableBuilder<int>(
      valueListenable: IslandStats.waterMl,
      builder: (context, ml, _) {
        final glasses = (ml / 250).floor();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _card(r: 22),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: (ml / 1000).toStringAsFixed(2),
                          style: _f(28, w: FontWeight.w800)),
                      TextSpan(
                          text: ' / 2.5 L',
                          style: _f(13, w: FontWeight.w600, c: _muted)),
                    ])),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      IslandStats.waterMl.value = (ml + 250).clamp(0, 2500);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
                      decoration: BoxDecoration(
                        color: cyan,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 2),
                          Text('250 ml',
                              style: _f(12.5,
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
                          IslandStats.waterMl.value = (i + 1) * 250;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i < glasses
                                ? cyan
                                : cyan.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                              bottom: Radius.circular(10),
                            ),
                          ),
                          child: Icon(Icons.water_drop_rounded,
                              size: 14,
                              color: i < glasses
                                  ? Colors.white
                                  : cyan.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- scan
  Widget _scanCard() {
    return GestureDetector(
      onTap: () => _push(context, const LogMealScreen()),
      child: Container(
        height: 132,
        decoration: _card(r: 26),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: 0,
              bottom: 0,
              width: 170,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                  stops: [0, 0.35],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: Image.asset('assets/images/island/meal_scan.png',
                    fit: BoxFit.cover, cacheWidth: 420),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _blueSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('AI MEAL SCAN',
                        style: _f(10, w: FontWeight.w800, c: _blueDeep)),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Snap your ', style: _f(19, w: FontWeight.w800)),
                    TextSpan(
                        text: 'plate',
                        style: _f(19, w: FontWeight.w800, c: _blue)),
                  ])),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('Scan meal',
                            style: _f(12.5,
                                w: FontWeight.w700, c: Colors.white)),
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

  // ---------------------------------------------------------------- week
  Widget _week() {
    const kcal = [1650, 1820, 1540, 1760, 1900, 1380, 1420];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _head('This Week',
            action: 'Details',
            onTap: () => _push(context,
                DateNutritionDetailScreen(initialDate: DateTime.now()))),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('1,639', style: _f(24, w: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Text('avg kcal / day',
                      style: _f(12, w: FontWeight.w500, c: _muted)),
                ],
              ),
              const SizedBox(height: 14),
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
                              duration: Duration(milliseconds: 700 + i * 70),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, _) => Container(
                                width: 22,
                                height: 92 * t,
                                decoration: BoxDecoration(
                                  gradient: i == today
                                      ? const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Color(0xFF7CB8FF), _blueDeep])
                                      : null,
                                  color: i == today
                                      ? null
                                      : _blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(days[i],
                                style: _f(11,
                                    w: i == today
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    c: i == today ? _blueDeep : _muted)),
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

  // ------------------------------------------------------------- recipes
  Widget _recipes() {
    const items = [
      ('High-protein bowl', '520 kcal · 15 min', 'assets/images/island/bowl.png'),
      ('Green power salad', '340 kcal · 10 min',
          'assets/images/island/meal_scan.png'),
      ('Chocolate whey shake', '220 kcal · 3 min',
          'assets/images/nutrifit_whey_protein.jpg'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _head('Recipes for You', action: 'See all'),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => Container(
              width: 158,
              decoration: _card(r: 22),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(items[i].$3,
                            fit: BoxFit.cover, cacheWidth: 360),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border_rounded,
                                size: 16, color: _protein),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _f(13.5, w: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(items[i].$2,
                            style: _f(11.5, w: FontWeight.w500, c: _muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- tip
  Widget _kemoTip() {
    return GestureDetector(
      onTap: () => _push(context, const KemoAiScreen()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: _blueSoft,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _blue.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const KemoAvatar(size: 58),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kemo tip', style: _f(12, w: FontWeight.w600, c: _muted)),
                  const SizedBox(height: 2),
                  Text('40 g more protein today. Try paneer, eggs or a whey shake.',
                      style: _f(13.5, w: FontWeight.w700, h: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _blueDeep),
          ],
        ),
      ),
    );
  }
}

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _Ring extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double stroke;
  final bool dashed;
  final bool gap;
  _Ring(this.value,
      {required this.color,
      required this.track,
      required this.stroke,
      this.dashed = false,
      this.gap = false});

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Speedometer-style ring with an opening at the bottom when [gap].
    final start = gap ? math.pi * 0.75 : -math.pi / 2;
    final sweep = gap ? math.pi * 1.5 : 2 * math.pi;
    if (dashed) {
      const n = 14;
      for (var i = 0; i < n; i++) {
        canvas.drawArc(r, start + sweep * i / n, sweep / n * 0.5, false,
            p..color = track);
      }
    } else {
      canvas.drawArc(r, start, sweep, false, p..color = track);
    }
    if (value > 0) {
      canvas.drawArc(
          r, start, sweep * value.clamp(0.0, 1.0), false, p..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _Ring old) =>
      old.value != value || old.color != color;
}
