import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/log_meal_screen.dart';
import '../screens/steps_screen.dart';
import 'apple_kit.dart';
import 'liquid_glass.dart';
import 'side_island.dart' show IslandStats;
import 'wellness_tab_v3.dart' show WellnessState;

// White liquid-glass panels that grow out of the side island, one per menu
// option: Stats, Water, Steps, Breathe, Sleep, Mood and Log meal.

enum IslandPanel { stats, water, steps, breathe, sleep, mood, meal }

class IslandOptionInfo {
  final String title, sub;
  final IconData icon;
  final Color color;
  const IslandOptionInfo(this.title, this.sub, this.icon, this.color);
}

const islandPanelInfo = {
  IslandPanel.stats: IslandOptionInfo('Stats', 'Today at a glance', Icons.bar_chart_rounded, Color(0xFF16A34A)),
  IslandPanel.water: IslandOptionInfo('Water', 'Log a glass', Icons.water_drop_rounded, Color(0xFF38BDF8)),
  IslandPanel.steps: IslandOptionInfo('Steps', 'Walk & distance', Icons.directions_walk_rounded, Color(0xFFF97316)),
  IslandPanel.breathe: IslandOptionInfo('Breathe', 'One-minute calm', Icons.air_rounded, Color(0xFF14B8A6)),
  IslandPanel.sleep: IslandOptionInfo('Sleep', 'Last night', Icons.bedtime_rounded, Color(0xFF6366F1)),
  IslandPanel.mood: IslandOptionInfo('Mood', 'Quick check-in', Icons.emoji_emotions_rounded, Color(0xFFF59E0B)),
  IslandPanel.meal: IslandOptionInfo('Log meal', 'Add food fast', Icons.restaurant_rounded, Color(0xFFEC4899)),
};

const Curve _iosSpring = Cubic(0.18, 1.12, 0.32, 1);

Future<void> showIslandPanel(BuildContext context, IslandPanel p, {Alignment origin = Alignment.center}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 560),
    pageBuilder: (context, a, b) => _PanelShell(p),
    transitionBuilder: (context, a, b, child) => AnimatedBuilder(
      animation: a,
      child: child,
      builder: (_, c) {
        final fwd = a.status != AnimationStatus.reverse;
        final t = (fwd ? _iosSpring : Curves.easeInCubic).transform(a.value);
        return Opacity(
          opacity: Curves.easeOut.transform((a.value * 2.2).clamp(0.0, 1.0)),
          child: Transform.scale(scale: 0.2 + 0.8 * t, alignment: origin, child: c),
        );
      },
    ),
  );
}

class _PanelShell extends StatelessWidget {
  final IslandPanel p;
  const _PanelShell(this.p);

  @override
  Widget build(BuildContext context) {
    final info = islandPanelInfo[p]!;
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480, maxHeight: size.height * 0.82),
            child: Material(
              color: Colors.transparent,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(34),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(colors: [info.color.withValues(alpha: 0.7), info.color]),
                      ),
                      child: Icon(info.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(info.title, style: akT(18, w: FontWeight.w800)),
                        Text(info.sub, style: akT(12, c: akMuted)),
                      ]),
                    ),
                    AkPress(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.06), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 18, color: akMuted),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: switch (p) {
                        IslandPanel.stats => const _Stats(),
                        IslandPanel.water => const _Water(),
                        IslandPanel.steps => const _Steps(),
                        IslandPanel.breathe => const _Breathe(),
                        IslandPanel.sleep => const _Sleep(),
                        IslandPanel.mood => const _Mood(),
                        IslandPanel.meal => const _Meal(),
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _ring(double v, Color c, double size, double stroke, Widget child) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, x, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: x,
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              color: c,
              backgroundColor: c.withValues(alpha: 0.14),
            ),
          ),
          child,
        ]),
      ),
    );

Widget _tile(String label, String value, Color c, {IconData? icon}) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (icon != null) Icon(icon, size: 18, color: c),
          if (icon != null) const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: akN(18))),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11, c: akMuted)),
        ]),
      ),
    );

Widget _button(String t, Color c, VoidCallback onTap) => AkPress(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16)),
        child: Text(t, style: akT(14.5, w: FontWeight.w800, c: Colors.white)),
      ),
    );

String _k(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';

// --------------------------------------------------------------------

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    const g = Color(0xFF16A34A);
    return Column(children: [
      _ring(
        IslandStats.eaten / IslandStats.budget,
        g,
        170,
        14,
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${IslandStats.left}', style: akN(38)),
          Text('kcal left', style: akT(12.5, c: akMuted)),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        _tile('Eaten', '${IslandStats.eaten}', const Color(0xFFF97316), icon: Icons.restaurant_rounded),
        const SizedBox(width: 8),
        _tile('Burned', '${IslandStats.burned}', const Color(0xFFEF4444), icon: Icons.local_fire_department_rounded),
        const SizedBox(width: 8),
        _tile('Goal', '${IslandStats.budget}', g, icon: Icons.flag_rounded),
      ]),
      const SizedBox(height: 14),
      for (final (n, v, goal, c) in [
        ('Protein', 98, 140, const Color(0xFF8B5CF6)),
        ('Carbs', 168, 220, const Color(0xFFF59E0B)),
        ('Fat', 41, 60, const Color(0xFFEC4899)),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 62, child: Text(n, style: akT(13, w: FontWeight.w700))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: v / goal),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (_, x, _) => LinearProgressIndicator(value: x, minHeight: 8, color: c, backgroundColor: c.withValues(alpha: 0.14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 72, child: Text('$v / ${goal}g', textAlign: TextAlign.right, style: akT(11.5, c: akMuted))),
          ]),
        ),
      const SizedBox(height: 4),
      ValueListenableBuilder<int>(
        valueListenable: IslandStats.waterMl,
        builder: (_, ml, _) => Row(children: [
          _tile('Steps', _k(IslandStats.steps), const Color(0xFFF97316), icon: Icons.directions_walk_rounded),
          const SizedBox(width: 8),
          _tile('Water', '${(ml / 1000).toStringAsFixed(2)} L', const Color(0xFF38BDF8), icon: Icons.water_drop_rounded),
          const SizedBox(width: 8),
          _tile('Sleep', '7h 12m', const Color(0xFF6366F1), icon: Icons.bedtime_rounded),
        ]),
      ),
    ]);
  }
}

class _Water extends StatelessWidget {
  const _Water();

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFF38BDF8);
    return ValueListenableBuilder<int>(
      valueListenable: IslandStats.waterMl,
      builder: (_, ml, _) {
        final f = (ml / IslandStats.waterGoal).clamp(0.0, 1.0);
        return Column(children: [
          SizedBox(
            height: 190,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 96,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: c.withValues(alpha: 0.4), width: 2),
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: akSpring,
                  height: 176 * f,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)]),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((ml / 1000).toStringAsFixed(2), style: akN(40)),
                Text('of ${(IslandStats.waterGoal / 1000).toStringAsFixed(1)} L', style: akT(13, c: akMuted)),
                const SizedBox(height: 8),
                Text('${(f * 100).round()}% of goal', style: akT(13, w: FontWeight.w800, c: c)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            for (final add in [150, 250, 500]) ...[
              Expanded(
                child: _button('+$add ml', c, () {
                  HapticFeedback.mediumImpact();
                  IslandStats.waterMl.value = (ml + add).clamp(0, IslandStats.waterGoal);
                }),
              ),
              if (add != 500) const SizedBox(width: 8),
            ],
          ]),
        ]);
      },
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFF97316);
    const hours = [0.1, 0.05, 0.4, 0.8, 0.3, 0.5, 0.9, 0.6, 0.2, 0.7, 1.0, 0.45];
    return Column(children: [
      _ring(
        IslandStats.steps / IslandStats.stepGoal,
        c,
        160,
        14,
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${IslandStats.steps}', style: akN(32)),
          Text('of ${IslandStats.stepGoal}', style: akT(12, c: akMuted)),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        _tile('Distance', '6.1 km', c, icon: Icons.route_rounded),
        const SizedBox(width: 8),
        _tile('Active', '74 min', const Color(0xFF16A34A), icon: Icons.timer_rounded),
        const SizedBox(width: 8),
        _tile('Burned', '342 kcal', const Color(0xFFEF4444), icon: Icons.local_fire_department_rounded),
      ]),
      const SizedBox(height: 16),
      SizedBox(
        height: 70,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < hours.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: hours[i]),
                  duration: Duration(milliseconds: 600 + i * 60),
                  curve: akSpring,
                  builder: (_, v, _) => Container(
                    height: 70 * v.clamp(0.04, 1.2),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.35 + 0.6 * hours[i]), borderRadius: BorderRadius.circular(5)),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      _button('Open steps', c, () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StepsScreen()));
      }),
    ]);
  }
}

class _Breathe extends StatefulWidget {
  const _Breathe();
  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  int cycles = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((_) {});
    _c.addListener(() {
      if (_c.value < 0.01 && mounted) setState(() => cycles++);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFF14B8A6);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final v = _c.value;
        final inhale = v < 0.5;
        final s = 0.45 + 0.55 * Curves.easeInOut.transform(inhale ? v * 2 : 2 - v * 2);
        return Column(children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(alignment: Alignment.center, children: [
              for (var k = 0; k < 3; k++)
                Container(
                  width: 220 * s * (1 - k * 0.18),
                  height: 220 * s * (1 - k * 0.18),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.14 + k * 0.14)),
                ),
              Text(inhale ? 'Breathe in' : 'Breathe out', style: akT(19, w: FontWeight.w800, c: Colors.white)),
            ]),
          ),
          const SizedBox(height: 12),
          Text('4 seconds in, 4 seconds out', style: akT(13.5, c: akMuted)),
          const SizedBox(height: 14),
          _button('Finish', c, () {
            WellnessState.mindfulMin.value += 1;
            Navigator.of(context).pop();
          }),
        ]);
      },
    );
  }
}

class _Sleep extends StatelessWidget {
  const _Sleep();

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFF6366F1);
    const stages = [('Deep', 1.4, Color(0xFF4338CA)), ('Core', 3.6, Color(0xFF6366F1)), ('REM', 1.8, Color(0xFFA78BFA)), ('Awake', 0.4, Color(0xFFFBBF24))];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        _ring(
          0.86,
          c,
          110,
          10,
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('86', style: akN(30)),
            Text('score', style: akT(11, c: akMuted)),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('7h 12m', style: akN(30)),
            const SizedBox(height: 4),
            Text('11:20 PM – 6:42 AM', style: akT(12.5, c: akMuted)),
            const SizedBox(height: 6),
            Text('18 min more than your average', style: akT(12, w: FontWeight.w700, c: const Color(0xFF16A34A))),
          ]),
        ),
      ]),
      const SizedBox(height: 18),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 16,
          child: Row(children: [
            for (final s in stages) Expanded(flex: (s.$2 * 10).round(), child: Container(color: s.$3)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        for (final s in stages)
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.$1, style: akT(11.5, c: akMuted)),
              Text('${s.$2}h', style: akN(15)),
            ]),
          ),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const Icon(Icons.nightlight_round, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text('Wind down at 10:45 PM tonight to keep your streak.', style: akT(13, w: FontWeight.w600, h: 1.35))),
        ]),
      ),
    ]);
  }
}

class _Mood extends StatelessWidget {
  const _Mood();

  @override
  Widget build(BuildContext context) {
    const moods = [('😣', 'Awful'), ('😕', 'Low'), ('😐', 'Okay'), ('😊', 'Good'), ('🤩', 'Great')];
    return ValueListenableBuilder<int>(
      valueListenable: WellnessState.mood,
      builder: (_, m, _) => Column(children: [
        Text(moods[m].$1, style: const TextStyle(fontSize: 70)),
        Text('Feeling ${moods[m].$2.toLowerCase()}', style: akT(17, w: FontWeight.w800)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < moods.length; i++)
            AkPress(
              onTap: () => WellnessState.mood.value = i,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == m ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                ),
                child: Text(moods[i].$1, style: const TextStyle(fontSize: 26)),
              ),
            ),
        ]),
        const SizedBox(height: 18),
        _button('Save check-in', const Color(0xFFF59E0B), () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
        }),
      ]),
    );
  }
}

class _Meal extends StatelessWidget {
  const _Meal();

  @override
  Widget build(BuildContext context) {
    const meals = [
      ('Breakfast', '420 kcal logged', '🍳', Color(0xFFF59E0B)),
      ('Lunch', '610 kcal logged', '🥗', Color(0xFF16A34A)),
      ('Snack', '390 kcal logged', '🍓', Color(0xFFEC4899)),
      ('Dinner', 'Not logged yet', '🍲', Color(0xFF6366F1)),
    ];
    return Column(children: [
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
        children: [
          for (final m in meals)
            AkPress(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => LogMealScreen(initialMealType: m.$1)));
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: m.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.$3, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  Text(m.$1, style: akT(14.5, w: FontWeight.w800)),
                  Text(m.$2, style: akT(11, c: akMuted)),
                ]),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      _button('Scan a meal with Kemo', const Color(0xFFEC4899), () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogMealScreen()));
      }),
      SizedBox(height: math.max(0, 0)),
    ]);
  }
}
