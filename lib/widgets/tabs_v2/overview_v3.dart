import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/active_workout_screen.dart';
import '../../screens/date_nutrition_detail_screen.dart';
import '../../screens/kemo_ai_screen.dart';
import '../../screens/rewards_screen.dart';
import '../../screens/steps_screen.dart';
import '../../screens/challenges_screen.dart';
import '../dashboard_motion.dart';
import '../kemo.dart';
import '../neuro_island_dock.dart';
import 'kit.dart';

/// Overview tab, laid out like Rohit's mockup: progress banner, quick stats,
/// activity rings, today's workout plan, then one card per health area.

const _green = Color(0xFF16A34A);
const _greenSoft = Color(0xFFDCFCE7);
const _orange = Color(0xFFF97316);
const _violet = Color(0xFF8B5CF6);
const _blue = Color(0xFF0EA5E9);
const _img = 'assets/images/overview_v3';

BoxDecoration _card() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFEFF6EE)),
      boxShadow: [
        BoxShadow(
          color: _green.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

class OverviewTabV3 extends StatelessWidget {
  const OverviewTabV3({super.key});

  void _push(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _HeroBanner(
        onContinue: () => _push(
          context,
          const ActiveWorkoutScreen(
              dayTitle: 'Full Body Strength', dayNumber: 3),
        ),
      ),
      const _QuickStats(),
      const _ActivitySummary(),
      _WorkoutPlan(
        onStart: () => _push(
          context,
          const ActiveWorkoutScreen(
              dayTitle: 'Full Body Strength', dayNumber: 3),
        ),
      ),
      _StepsCard(onTap: () => _push(context, const StepsScreen())),
      _NutritionCard(
        onTap: () => _push(
            context, DateNutritionDetailScreen(initialDate: DateTime.now())),
      ),
      const _HydrationCard(),
      const _SleepCard(),
      const _WellnessCard(),
      _BottomTrio(
        onBadges: () => _push(context, const RewardsScreen()),
        onChallenge: () => _push(context, const ChallengesScreen()),
        onKemo: () => Navigator.push(context, KemoAiScreen.route()),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Reveal(
              delay: Duration(milliseconds: i < 4 ? 60 * i : 0),
              offset: 18,
              child: sections[i],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

/// Left column used by most cards: picture, title and a short line.
class _Lead extends StatelessWidget {
  final String image;
  final String title;
  final String sub;
  final double imageSize;
  const _Lead(this.image, this.title, this.sub, {this.imageSize = 46});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('$_img/$image.png',
            width: imageSize, height: imageSize, fit: BoxFit.contain),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  maxLines: 2,
                  softWrap: true,
                  style: jakarta(14, FontWeight.w900, kInk,
                      height: 1.15, spacing: -0.3)),
              const SizedBox(height: 4),
              Text(sub,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(11, FontWeight.w600, kMuted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card that puts [lead] on the left and [body] on the right when there is
/// room, and stacks them on narrow phones.
class _SplitCard extends StatelessWidget {
  final Widget lead;
  final Widget body;
  final double leadFraction;
  final VoidCallback? onTap;
  const _SplitCard({
    required this.lead,
    required this.body,
    this.leadFraction = 0.44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [lead, const SizedBox(height: 12), body],
          );
        }
        return Row(
          children: [
            SizedBox(width: c.maxWidth * leadFraction, child: lead),
            const SizedBox(width: 10),
            Expanded(child: body),
          ],
        );
      }),
    );
    return onTap == null ? card : PressScale(onTap: onTap, child: card);
  }
}

class _InfoPill extends StatelessWidget {
  final Widget child;
  final Color color;
  const _InfoPill({required this.child, this.color = const Color(0xFFF6FBF4)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Banner
// ---------------------------------------------------------------------------

class _HeroBanner extends StatefulWidget {
  final VoidCallback onContinue;
  const _HeroBanner({required this.onContinue});

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = IslandMetrics.instance.dayProgress;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = (w * 0.66).clamp(214.0, 268.0);
      final narrow = w < 340;
      return Container(
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF1FBEA), Color(0xFFE3F6D7)],
          ),
          border: Border.all(color: const Color(0xFFE2F3DA)),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Runner illustration, bottom right
            Positioned(
              right: 0,
              bottom: 0,
              height: h,
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                      0, -3 * Curves.easeInOut.transform(_float.value)),
                  child: child,
                ),
                child: RepaintBoundary(
                  child: Image.asset(
                    '$_img/hero_runner.png',
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.bottomRight,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            // Progress ring
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GrowRing(
                  value: p,
                  color: const Color(0xFF4ADE80),
                  size: narrow ? 62 : 72,
                  stroke: 5,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(p * 100).round()}%',
                          style: jakarta(narrow ? 15 : 17, FontWeight.w900,
                              Colors.white,
                              height: 1)),
                      Text('Done',
                          style: jakarta(10, FontWeight.w700,
                              const Color(0xFFBBF7D0))),
                    ],
                  ),
                ),
              ),
            ),
            // Copy
            Positioned(
              left: 16,
              top: 16,
              bottom: 16,
              width: w * (narrow ? 0.6 : 0.52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _greenSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("TODAY'S PROGRESS",
                        style: jakarta(10, FontWeight.w900, _green,
                            spacing: 0.3)),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Keep the streak\n'),
                        TextSpan(
                          text: 'going strong! 💪',
                          style: jakarta(20, FontWeight.w900, _green,
                              spacing: -0.5),
                        ),
                      ]),
                      style: jakarta(20, FontWeight.w900, kInk,
                          height: 1.18, spacing: -0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      "You're ${(p * 100).round()}% closer to your daily goal. Let's finish strong!",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(11.5, FontWeight.w600, kMuted,
                          height: 1.35),
                    ),
                  ),
                  const Spacer(),
                  PressScale(
                    onTap: widget.onContinue,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), _green],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _green.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              narrow ? 'Continue' : "Continue Today's Plan",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(
                                  12.5, FontWeight.w800, Colors.white),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// 2. Quick stats strip
// ---------------------------------------------------------------------------

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    Widget cell(String emoji, String value, String label) => Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 7),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value,
                          style: jakarta(15, FontWeight.w900, kInk)),
                    ),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(10, FontWeight.w600, kMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
    Widget divider() =>
        Container(width: 1, height: 30, color: const Color(0xFFE8EFE6));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: _card(),
      child: Row(
        children: [
          cell('🔥', '${m.streak} days', 'Current Streak'),
          divider(),
          cell('⏱️', '${m.activeMinutes} min', 'Workout Time'),
          divider(),
          cell('❤️', '${m.heartRate} bpm', 'Avg. Heart Rate'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Activity rings
// ---------------------------------------------------------------------------

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary();

  @override
  Widget build(BuildContext context) {
    Widget ring(String emoji, String value, String unit, double p,
            String foot, Color c) =>
        Expanded(
          child: LayoutBuilder(builder: (context, cc) {
            final size = math.min(cc.maxWidth, 82.0);
            return Column(
              children: [
                GrowRing(
                  value: p,
                  color: c,
                  size: size,
                  stroke: 6,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: TextStyle(fontSize: size * 0.15)),
                      FittedBox(
                        child: Text(value,
                            style: jakarta(size * 0.19, FontWeight.w900, kInk,
                                height: 1.1)),
                      ),
                      Text(unit,
                          style: jakarta(size * 0.11, FontWeight.w600,
                              kMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '${(p * 100).round()}%',
                          style: TextStyle(color: c)),
                      TextSpan(text: ' of $foot'),
                    ]),
                    style: jakarta(10.5, FontWeight.w800, kMuted),
                  ),
                ),
              ],
            );
          }),
        );
    return _SplitCard(
      leadFraction: 0.34,
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Daily Activity Summary',
              style: jakarta(15, FontWeight.w900, kInk,
                  height: 1.15, spacing: -0.3)),
          const SizedBox(height: 4),
          Text('Your movement, calories and goals at a glance.',
              style: jakarta(11.5, FontWeight.w600, kMuted, height: 1.3)),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ring('👟', '8,520', 'Steps', 0.85, '10,000', _green),
          const SizedBox(width: 6),
          ring('🔥', '360', 'kcal', 0.72, '500', _orange),
          const SizedBox(width: 6),
          ring('🏃', '42 min', 'Movement', 0.84, '50 min', _violet),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Today's workout plan
// ---------------------------------------------------------------------------

class _WorkoutPlan extends StatelessWidget {
  final VoidCallback onStart;
  const _WorkoutPlan({required this.onStart});

  @override
  Widget build(BuildContext context) {
    Widget info(IconData icon, String a, String b) => Expanded(
          child: Row(
            children: [
              Icon(icon, size: 16, color: _green),
              const SizedBox(width: 5),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(a,
                          style: jakarta(11.5, FontWeight.w800, kInk)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(b,
                          style: jakarta(9.5, FontWeight.w600, kMuted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    Widget step(String label, String time, int state) {
      // 0 done, 1 current, 2 next
      final c = state == 2 ? const Color(0xFFCBD5E1) : _green;
      return Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state == 2 ? Colors.white : c,
              border: Border.all(color: c, width: 2),
            ),
            child: Icon(
              state == 0
                  ? Icons.check_rounded
                  : state == 1
                      ? Icons.play_arrow_rounded
                      : Icons.circle,
              size: state == 2 ? 8 : 14,
              color: state == 2 ? c : Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: jakarta(10.5, FontWeight.w700, kInk)),
          Text(time, style: jakarta(9.5, FontWeight.w600, kMuted)),
        ],
      );
    }

    return _SplitCard(
      onTap: onStart,
      leadFraction: 0.36,
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Today's Workout Plan",
              style: jakarta(15, FontWeight.w900, kInk,
                  height: 1.15, spacing: -0.3)),
          const SizedBox(height: 4),
          Text('A focused session to build strength and endurance.',
              style: jakarta(11.5, FontWeight.w600, kMuted, height: 1.3)),
          const SizedBox(height: 6),
          Image.asset('$_img/workout_gear.png', height: 64),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded,
                  size: 16, color: _green),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Full Body Strength',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(13.5, FontWeight.w900, kInk)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _greenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Today',
                    style: jakarta(10.5, FontWeight.w800, _green)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoPill(
            child: Row(
              children: [
                info(Icons.timer_outlined, '42 min', 'Duration'),
                info(Icons.bar_chart_rounded, 'Moderate', 'Intensity'),
                info(Icons.track_changes_rounded, 'Strength', '+ Stamina'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Positioned(
                left: 30,
                right: 30,
                top: 10,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 2, color: _green)),
                    Expanded(
                        child: Container(
                            height: 2, color: const Color(0xFFE2E8F0))),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  step('Warm-up', '5 min', 0),
                  step('Workout', '32 min', 1),
                  step('Cool-down', '5 min', 2),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5-9. Health cards
// ---------------------------------------------------------------------------

class _ProgressHeader extends StatelessWidget {
  final String value;
  final String rest;
  final double p;
  final Color color;
  const _ProgressHeader(this.value, this.rest, this.p, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: value,
                      style: jakarta(17, FontWeight.w900, kInk)),
                  TextSpan(
                      text: ' $rest',
                      style: jakarta(11.5, FontWeight.w600, kMuted)),
                ])),
              ),
            ),
            Text('${(p * 100).round()}%',
                style: jakarta(14, FontWeight.w900, color)),
          ],
        ),
        const SizedBox(height: 8),
        GrowBar(value: p, color: color, height: 8),
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _StepsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _SplitCard(
      onTap: onTap,
      lead: const _Lead('shoe', 'Steps & Movement',
          'Great pace today! Keep moving to hit your goal.'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProgressHeader('8,520', '/ 10,000 steps', 0.85, _green),
          const SizedBox(height: 10),
          _InfoPill(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  const Text('🚶', style: TextStyle(fontSize: 13)),
                  Text(' ~6.8 km walked',
                      style: jakarta(11, FontWeight.w700, kInk)),
                  Container(
                    width: 1,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: kLine,
                  ),
                  const Text('🔥', style: TextStyle(fontSize: 13)),
                  Text(' ~360 kcal burned',
                      style: jakarta(11, FontWeight.w700, kInk)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NutritionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget macro(String emoji, String name, int now, int goal, Color c) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: jakarta(10.5, FontWeight.w700, kInk)),
                  ),
                  Text('$now/${goal}g',
                      style: jakarta(9.5, FontWeight.w700, kMuted)),
                ],
              ),
              const SizedBox(height: 4),
              GrowBar(value: now / goal, color: c, height: 5),
            ],
          ),
        );
    return _SplitCard(
      onTap: onTap,
      leadFraction: 0.42,
      lead: const _Lead('bowl', 'Nutrition Snapshot',
          'Fuel your goals with the right balance.'),
      body: Row(
        children: [
          GrowRing(
            value: 0.71,
            color: _green,
            size: 68,
            stroke: 6,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🍴', style: TextStyle(fontSize: 12)),
                Text('1,420',
                    style: jakarta(15, FontWeight.w900, kInk, height: 1.1)),
                Text('of 2,000',
                    style: jakarta(8.5, FontWeight.w600, kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                macro('🥩', 'Protein', 92, 120, _green),
                macro('🍞', 'Carbs', 176, 250, const Color(0xFFF59E0B)),
                macro('🥑', 'Fats', 38, 67, _violet),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    const goal = 2000;
    return ValueListenableBuilder<int>(
      valueListenable: m.waterMl,
      builder: (context, ml, _) {
        final p = (ml / goal).clamp(0.0, 1.0);
        return _SplitCard(
          lead: const _Lead('bottle', 'Hydration Tracker',
              'Stay hydrated, stay energized.'),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressHeader(
                  '${(ml / 1000).toStringAsFixed(2)} L', '/ 2.0 L', p, _green),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InfoPill(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded,
                                size: 14, color: _green),
                            const SizedBox(width: 5),
                            Text('Drink 250 ml in 30 min',
                                style: jakarta(11, FontWeight.w700, kInk)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PressScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      m.waterMl.value = (ml + 250).clamp(0, 5000);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _green, width: 1.4),
                      ),
                      child: Text('Log Water',
                          style: jakarta(11.5, FontWeight.w800, _green)),
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
}

class _SleepCard extends StatelessWidget {
  const _SleepCard();

  @override
  Widget build(BuildContext context) {
    Widget box(Widget icon, String value, String label, Color bg, Color fg) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(value,
                            style: jakarta(14, FontWeight.w900, fg)),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(label,
                            style: jakarta(9.5, FontWeight.w600, kMuted)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return _SplitCard(
      lead: const _Lead('moon', 'Sleep & Recovery',
          'Better rest = better performance.'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              box(const Text('🛏️', style: TextStyle(fontSize: 16)),
                  '7h 36m', 'Sleep Time', const Color(0xFFF1EEFF), _violet),
              const SizedBox(width: 8),
              box(const Text('🍃', style: TextStyle(fontSize: 16)), '88%',
                  'Recovery Score', const Color(0xFFF0FBEA), kInk),
            ],
          ),
          const SizedBox(height: 8),
          _InfoPill(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.nightlight_round,
                      size: 13, color: _green),
                  const SizedBox(width: 5),
                  Text('Restful Sleep  ·  ',
                      style: jakarta(11, FontWeight.w800, _green)),
                  Text("You're well recovered!",
                      style: jakarta(11, FontWeight.w700, _green)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessCard extends StatelessWidget {
  const _WellnessCard();

  @override
  Widget build(BuildContext context) {
    Widget metric(String emoji, String value, String label, Color c,
            CustomPainter spark) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(value,
                              style: jakarta(13, FontWeight.w900, kInk)),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label,
                              style: jakarta(9, FontWeight.w600, kMuted)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: CustomPaint(painter: spark),
              ),
            ],
          ),
        );
    return _SplitCard(
      leadFraction: 0.42,
      lead: const _Lead('lotus', 'Wellness Insights',
          'A quick look at your overall well-being.'),
      body: Row(
        children: [
          metric('❤️', '76 bpm', 'Heart Rate', const Color(0xFFEF4444),
              _WavePainter(const Color(0xFF22C55E), 2.0)),
          const SizedBox(width: 8),
          metric('🧘', '24', 'Stress (Low)', _blue,
              _WavePainter(_blue, 1.0)),
          const SizedBox(width: 8),
          metric('⚡', '92%', 'Energy Score', const Color(0xFFF59E0B),
              _BarsPainter(_green)),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double freq;
  _WavePainter(this.color, this.freq);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path();
    for (var x = 0.0; x <= s.width; x += 2) {
      final t = x / s.width;
      final y = s.height * 0.55 -
          math.sin(t * math.pi * 2 * freq) * s.height * 0.32 * (0.6 + 0.4 * t);
      x == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarsPainter extends CustomPainter {
  final Color color;
  _BarsPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    const hs = [0.3, 0.5, 0.4, 0.7, 0.5, 0.8, 0.6, 0.9, 0.7, 1.0, 0.8];
    final bw = s.width / (hs.length * 1.7);
    final paint = Paint()..color = color;
    for (var i = 0; i < hs.length; i++) {
      final x = i * bw * 1.7;
      final h = s.height * hs[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, s.height - h, bw, h), Radius.circular(bw / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 10. Achievements, weekly challenge and Kemo's tip
// ---------------------------------------------------------------------------

class _BottomTrio extends StatelessWidget {
  final VoidCallback onBadges;
  final VoidCallback onChallenge;
  final VoidCallback onKemo;
  const _BottomTrio({
    required this.onBadges,
    required this.onChallenge,
    required this.onKemo,
  });

  Widget _box({required Widget child, VoidCallback? onTap}) => PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _card(),
          child: child,
        ),
      );

  Widget _footer(String text) => Row(
        children: [
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(10.5, FontWeight.w700, kInk)),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: _green),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final badges = _box(
      onTap: onBadges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Flexible(
                child: Text('Achievements',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(12.5, FontWeight.w900, kInk)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final b in ['badge_run', 'badge_fire', 'badge_gym'])
                Expanded(
                  child: Image.asset('$_img/$b.png',
                      height: 36, fit: BoxFit.contain),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _footer('5 Badges Earned'),
        ],
      ),
    );
    final challenge = _box(
      onTap: onChallenge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Flexible(
                child: Text('Weekly Challenge',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(12.5, FontWeight.w900, kInk)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Hit 50,000 steps this week',
              maxLines: 2,
              style: jakarta(11.5, FontWeight.w700, kInk, height: 1.3)),
          const SizedBox(height: 8),
          const GrowBar(value: 34200 / 50000, color: _green, height: 6),
          const SizedBox(height: 8),
          _footer('34,200 / 50,000'),
        ],
      ),
    );
    final tip = _box(
      onTap: onKemo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const KemoFace(size: 30, glow: false, bob: false),
              const SizedBox(width: 6),
              Flexible(
                child: Text("Kemo's Tip ✨",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(12.5, FontWeight.w900, kInk)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FBEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "A glass of water before your workout will boost your performance. You're 1.25 L from your goal!",
              style: jakarta(10.5, FontWeight.w600, kInk, height: 1.35),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 400) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: badges),
              const SizedBox(width: 10),
              Expanded(child: challenge),
              const SizedBox(width: 10),
              Expanded(child: tip),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pair(badges, challenge, gap: 10),
          const SizedBox(height: 10),
          tip,
        ],
      );
    });
  }
}
