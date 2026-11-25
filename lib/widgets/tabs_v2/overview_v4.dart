import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/active_workout_screen.dart';
import '../../screens/date_nutrition_detail_screen.dart';
import '../../screens/kemo_ai_screen.dart';
import '../../screens/log_meal_screen.dart';
import '../../screens/rewards_screen.dart';
import '../../screens/steps_screen.dart';
import '../../screens/transform_screen.dart';
import '../dashboard_motion.dart';
import '../kemo.dart';
import '../neuro_island_dock.dart';
import 'kit.dart';

/// Overview tab, lavender edition, following Rohit's second mockup:
/// headings and numbers only, carousels where content runs sideways.

const _p = Color(0xFF7C3AED); // primary purple
const _pSoft = Color(0xFFEDE4FF);
const _pBg = Color(0xFFF7F3FF);
const _green = Color(0xFF16A34A);
const _blue = Color(0xFF0EA5E9);
const _img = 'assets/images/overview_v4';

BoxDecoration _card({double r = 22}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: const Color(0xFFEFE9FB)),
      boxShadow: [
        BoxShadow(
          color: _p.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

Widget _title(String t, {String? trailing, VoidCallback? onTap}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(t,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(16, FontWeight.w900, kInk, spacing: -0.3)),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(trailing, style: jakarta(12, FontWeight.w800, _p)),
                  if (onTap != null) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: _p),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

class OverviewTabV4 extends StatelessWidget {
  const OverviewTabV4({super.key});

  static void push(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      const _HeroCarousel(),
      const _GoalAndWeek(),
      const _StatsCarousel(),
      const _KemoCoach(),
      const _NutritionWater(),
      const _BodyMetrics(),
      const _Achievements(),
      const _QuickActions(),
      const _Habits(),
      const _Insight(),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
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
// 1. Banner carousel + stats row
// ---------------------------------------------------------------------------

class _Slide {
  final String tag;
  final String line1;
  final String line2;
  final String emoji;
  final String cta;
  final String image;
  final bool feathered;
  final double ring;
  const _Slide(this.tag, this.line1, this.line2, this.emoji, this.cta,
      this.image, this.ring,
      {this.feathered = true});
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel>
    with SingleTickerProviderStateMixin {
  final _pc = PageController();
  int _page = 0;
  Timer? _auto;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  static const _slides = [
    _Slide('DAY 3 OF 30 · FAT LOSS PLAN', "You're ahead", 'of your goal!',
        '🎯', "Continue Today's Plan", '$_img/hero_runner.png', 0.65),
    _Slide('NUTRITION · 1,420 KCAL', 'Fuel up', 'the right way!', '🥗',
        'Log a Meal', 'assets/images/illustrations/nutrition.png', 0.79),
    _Slide('MIND · SCORE 82', 'Calm mind,', 'strong body!', '🧘',
        'Start Breathing', 'assets/images/illustrations/wellness.png', 0.82),
  ];

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pc.hasClients) return;
      _pc.animateToPage(
        (_page + 1) % _slides.length,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pc.dispose();
    _float.dispose();
    super.dispose();
  }

  void _cta(int i) {
    switch (i) {
      case 0:
        OverviewTabV4.push(
            context,
            const ActiveWorkoutScreen(
                dayTitle: 'Upper Body Strength', dayNumber: 3));
        break;
      case 1:
        OverviewTabV4.push(context, const LogMealScreen());
        break;
      default:
        Navigator.push(context, KemoAiScreen.route());
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF6F1FF), Color(0xFFEDE4FF)],
        ),
        border: Border.all(color: const Color(0xFFE9DFFC)),
        boxShadow: [
          BoxShadow(
            color: _p.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final h = (w * 0.6).clamp(196.0, 236.0);
            return SizedBox(
              height: h,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pc,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _slide(_slides[i], i, w, h),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 8,
                    child: Row(
                      children: List.generate(_slides.length, (i) {
                        final on = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          margin: const EdgeInsets.only(right: 4),
                          width: on ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: on ? _p : const Color(0xFFD8CCF5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Row(
              children: [
                _MiniStat('⏱️', '${m.activeMinutes + 3} min', 'Workout'),
                const SizedBox(width: 8),
                _MiniStat('🔥', '${m.calories} kcal', 'Burned'),
                const SizedBox(width: 8),
                _MiniStat('❤️', '${m.heartRate} bpm', 'Heart Rate'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slide(_Slide s, int i, double w, double h) {
    final narrow = w < 330;
    return Stack(
      children: [
        Positioned(
          right: 0,
          bottom: 0,
          top: 34,
          width: w * 0.52,
          child: AnimatedBuilder(
            animation: _float,
            builder: (context, child) => Transform.translate(
              offset:
                  Offset(0, -3 * Curves.easeInOut.transform(_float.value)),
              child: child,
            ),
            child: Image.asset(s.image,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium),
          ),
        ),
        // ring
        Positioned(
          right: 10,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E1035),
              boxShadow: [
                BoxShadow(
                  color: _p.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GrowRing(
              value: s.ring,
              color: const Color(0xFFA78BFA),
              size: narrow ? 52 : 60,
              stroke: 5,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(s.ring * 100).round()}%',
                      style: jakarta(narrow ? 13 : 15, FontWeight.w900,
                          Colors.white,
                          height: 1)),
                  Text('Done',
                      style: jakarta(9, FontWeight.w700,
                          const Color(0xFFDDD6FE))),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          top: 12,
          child: Row(
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(9.5, FontWeight.w900, _p,
                          spacing: 0.2)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 48,
          bottom: 22,
          width: w * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${s.line1}\n'),
                    TextSpan(
                        text: '${s.line2} ${s.emoji}',
                        style: const TextStyle(color: _p)),
                  ]),
                  style: jakarta(22, FontWeight.w900, kInk,
                      height: 1.15, spacing: -0.6),
                ),
              ),
              const Spacer(),
              PressScale(
                onTap: () => _cta(i),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _p.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(s.cta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(
                                12.5, FontWeight.w800, Colors.white)),
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
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _MiniStat(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFE9FB)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: jakarta(13, FontWeight.w900, kInk)),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Goal progress + this week
// ---------------------------------------------------------------------------

class _GoalAndWeek extends StatelessWidget {
  const _GoalAndWeek();

  @override
  Widget build(BuildContext context) {
    final goal = PressScale(
      onTap: () => OverviewTabV4.push(context, const TransformScreen()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Goal Progress',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(14, FontWeight.w900, kInk)),
                ),
                Text('65%', style: jakarta(14, FontWeight.w900, _p)),
              ],
            ),
            const SizedBox(height: 10),
            const GrowBar(value: 0.65, color: _p, height: 8),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text('Now ', style: jakarta(11, FontWeight.w600, kMuted)),
                  Text('66.5 kg', style: jakarta(11.5, FontWeight.w900, kInk)),
                  const SizedBox(width: 14),
                  Text('Target ',
                      style: jakarta(11, FontWeight.w600, kMuted)),
                  Text('62 kg', style: jakarta(11.5, FontWeight.w900, kInk)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              height: 44,
              child: CustomPaint(painter: _SparkPainter()),
            ),
          ],
        ),
      ),
    );

    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const done = [true, true, false, true, false, false, false];
    final today = DateTime.now().weekday - 1;
    final week = Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This Week',
                        style: jakarta(14, FontWeight.w900, kInk)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('3 / 5 workouts · 1h 52m',
                          style: jakarta(11, FontWeight.w700, kMuted)),
                    ),
                  ],
                ),
              ),
              GrowRing(
                value: 0.6,
                color: _p,
                size: 42,
                stroke: 4.5,
                center: Text('60%',
                    style: jakarta(10.5, FontWeight.w900, _p)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // No LayoutBuilder here: this card sits in a Pair, which measures
          // intrinsic height. Each day gets an equal slot with a square dot.
          Row(
            children: List.generate(7, (i) {
              final isToday = i == today;
              return Expanded(
                child: Column(
                  children: [
                    Text(days[i],
                        style: jakarta(10.5, FontWeight.w800,
                            isToday ? _p : kMuted)),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 26),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done[i]
                                  ? _p
                                  : isToday
                                      ? Colors.white
                                      : const Color(0xFFF4F1FA),
                              border: isToday && !done[i]
                                  ? Border.all(color: _p, width: 1.6)
                                  : null,
                            ),
                            child: done[i]
                                ? const FittedBox(
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.check_rounded,
                                          color: Colors.white),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 360) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [goal, const SizedBox(height: 12), week],
        );
      }
      return Pair(goal, week, gap: 12);
    });
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();

  @override
  void paint(Canvas canvas, Size s) {
    const v = [0.35, 0.2, 0.55, 0.38, 0.62, 0.45, 0.85, 0.5, 0.72];
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(s.width * i / (v.length - 1), s.height * (1 - v[i] * 0.85)),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      line.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    final area = Path.from(line)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_p.withValues(alpha: 0.22), _p.withValues(alpha: 0)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = _p;
    for (final p in pts.skip(1)) {
      canvas.drawCircle(p, 2.6, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 3. Stats carousel
// ---------------------------------------------------------------------------

class _StatsCarousel extends StatelessWidget {
  const _StatsCarousel();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    final items = [
      ('shoe', '8,420', 'Steps', m.stepProgress, _p),
      ('fire', '${m.calories}', 'Calories', m.calorieProgress,
          const Color(0xFFF97316)),
      ('bolt', '${m.activeMinutes + 3}', 'Active Min', m.activeProgress,
          const Color(0xFFEAB308)),
      ('moon', '7h 40m', 'Sleep', 0.96, const Color(0xFF6366F1)),
    ];
    return LayoutBuilder(builder: (context, c) {
      final tileW = math.max(120.0, (c.maxWidth - 30) / 3.3);
      return SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final it = items[i];
            return Container(
              width: tileW,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: _card(r: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('$_img/${it.$1}.png', width: 30, height: 30),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(it.$2,
                                  style: jakarta(16, FontWeight.w900, kInk)),
                            ),
                            Text(it.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    jakarta(10.5, FontWeight.w600, kMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GrowBar(value: it.$4, color: it.$5, height: 5),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// 4. Kemo coach banner
// ---------------------------------------------------------------------------

class _KemoCoach extends StatelessWidget {
  const _KemoCoach();

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => Navigator.push(context, KemoAiScreen.route()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF4C1D95)],
          ),
          boxShadow: [
            BoxShadow(
              color: _p.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const KemoFace(size: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Kemo · AI Fitness Coach',
                        style: jakarta(15, FontWeight.w900, Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  Text('65% on track · Upper Body today · 8,000+ steps',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(11.5, FontWeight.w600,
                          const Color(0xFFE9D5FF),
                          height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('Ask',
                      style: jakarta(12, FontWeight.w800, Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Nutrition + water
// ---------------------------------------------------------------------------

class _NutritionWater extends StatelessWidget {
  const _NutritionWater();

  Widget _tile({
    required String image,
    required String title,
    required String value,
    required double p,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _card(r: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset('$_img/$image.png', width: 40, height: 40),
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: _pBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      size: 18, color: _p),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(14, FontWeight.w900, kInk)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: jakarta(12, FontWeight.w700, kMuted)),
            ),
            const SizedBox(height: 8),
            GrowBar(value: p, color: color, height: 6),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    final nutrition = _tile(
      image: 'bowl',
      title: 'Nutrition',
      value: '1,420 / 1,800 kcal',
      p: 1420 / 1800,
      color: _green,
      onTap: () => OverviewTabV4.push(
          context, DateNutritionDetailScreen(initialDate: DateTime.now())),
    );
    final water = ValueListenableBuilder<int>(
      valueListenable: m.waterMl,
      builder: (context, ml, _) => _tile(
        image: 'bottle',
        title: 'Water',
        value: '${(ml / 1000).toStringAsFixed(2)} / 2.50 L',
        p: (ml / 2500).clamp(0.0, 1.0),
        color: _blue,
        onTap: () {
          HapticFeedback.selectionClick();
          m.waterMl.value = (ml + 250).clamp(0, 5000);
        },
      ),
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 260) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [nutrition, const SizedBox(height: 12), water],
        );
      }
      return Pair(nutrition, water, gap: 12);
    });
  }
}

// ---------------------------------------------------------------------------
// 6. Body metrics
// ---------------------------------------------------------------------------

class _BodyMetrics extends StatelessWidget {
  const _BodyMetrics();

  @override
  Widget build(BuildContext context) {
    Widget metric(String v, String label, Widget foot) => Container(
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: _pBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(v, style: jakarta(14, FontWeight.w900, kInk)),
              ),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(10, FontWeight.w600, kMuted)),
              const SizedBox(height: 5),
              foot,
            ],
          ),
        );
    Widget delta(String t, bool down, {Color? c}) => Text(
          '${down ? '▼' : '▲'} $t',
          style: jakarta(10, FontWeight.w800, c ?? _green),
        );
    return PressScale(
      onTap: () => OverviewTabV4.push(context, const TransformScreen()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
        decoration: _card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Image.asset('$_img/body.png', width: 34, height: 34),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Body Metrics',
                        style: jakarta(15, FontWeight.w900, kInk)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _p),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 12),
                children: [
                  metric('66.5 kg', 'Weight', delta('2.4 kg', true)),
                  const SizedBox(width: 8),
                  metric(
                    '22.9',
                    'BMI',
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Normal',
                          style: jakarta(9, FontWeight.w800, _green)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  metric('15.8%', 'Body Fat', delta('1.9%', true)),
                  const SizedBox(width: 8),
                  metric('72.4 kg', 'Muscle', delta('1.2 kg', false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Achievements carousel
// ---------------------------------------------------------------------------

class _Achievements extends StatelessWidget {
  const _Achievements();

  @override
  Widget build(BuildContext context) {
    const badges = ['b_streak', 'b_workouts', 'b_steps', 'b_water', 'b_clean'];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 0, 12),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _title('Achievements',
                trailing: 'View All',
                onTap: () =>
                    OverviewTabV4.push(context, const RewardsScreen())),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 12),
              itemCount: badges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) => _PopIn(
                delay: 80 * i,
                child: Image.asset('$_img/${badges[i]}.png',
                    height: 96, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _PopIn({required this.child, required this.delay});

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    whenRevealed(context, () {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
        child: widget.child,
      );
}

// ---------------------------------------------------------------------------
// 8. Quick actions carousel
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final m = IslandMetrics.instance;
    final actions = <(IconData, String, VoidCallback)>[
      (
        Icons.play_circle_fill_rounded,
        'Start Workout',
        () => OverviewTabV4.push(
            context,
            const ActiveWorkoutScreen(
                dayTitle: 'Upper Body Strength', dayNumber: 3)),
      ),
      (
        Icons.restaurant_rounded,
        'Log Meal',
        () => OverviewTabV4.push(context, const LogMealScreen()),
      ),
      (
        Icons.water_drop_rounded,
        'Log Water',
        () {
          HapticFeedback.selectionClick();
          m.waterMl.value = (m.waterMl.value + 250).clamp(0, 5000);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('+250 ml logged 💧'),
              duration: Duration(seconds: 1),
            ));
        },
      ),
      (
        Icons.monitor_weight_rounded,
        'Log Weight',
        () => OverviewTabV4.push(context, const TransformScreen()),
      ),
      (
        Icons.photo_camera_rounded,
        'Progress Photo',
        () => OverviewTabV4.push(context, const TransformScreen()),
      ),
      (
        Icons.directions_walk_rounded,
        'Steps',
        () => OverviewTabV4.push(context, const StepsScreen()),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Quick Actions'),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = actions[i];
              return PressScale(
                onTap: a.$3,
                child: Container(
                  width: 92,
                  decoration: _card(r: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _pSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.$1, color: _p, size: 20),
                      ),
                      const SizedBox(height: 7),
                      Text(a.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(11, FontWeight.w800, kInk)),
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

// ---------------------------------------------------------------------------
// 9. Habit tracker
// ---------------------------------------------------------------------------

class _Habits extends StatefulWidget {
  const _Habits();

  @override
  State<_Habits> createState() => _HabitsState();
}

class _HabitsState extends State<_Habits> {
  final _done = [true, true, true, false];
  static const _names = ['Workout', 'Nutrition', 'Water', 'Sleep 8h'];

  @override
  Widget build(BuildContext context) {
    final count = _done.where((d) => d).length;
    Widget chip(int i) {
      final on = _done[i];
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _done[i] = !_done[i]);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFEAF9EE) : const Color(0xFFF6F3FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? const Color(0xFF22C55E) : Colors.white,
                  border: Border.all(
                    color: on ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                    width: 1.6,
                  ),
                ),
                child: on
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_names[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(12.5, FontWeight.w800, kInk)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Habit Tracker', trailing: '$count / 4 done'),
          Pair(chip(0), chip(1), gap: 8),
          const SizedBox(height: 8),
          Pair(chip(2), chip(3), gap: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 10. Insight
// ---------------------------------------------------------------------------

class _Insight extends StatelessWidget {
  const _Insight();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _card(),
      child: Row(
        children: [
          Image.asset('$_img/bulb.png', width: 46, height: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Insight",
                    style: jakarta(14, FontWeight.w900, kInk)),
                const SizedBox(height: 3),
                Text('+18% calories burned vs last week 💪',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(11.5, FontWeight.w700, kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('▲ 18%',
                    style: jakarta(10.5, FontWeight.w900, _green)),
              ),
              const SizedBox(height: 4),
              Image.asset('$_img/bars.png', width: 52, height: 34),
            ],
          ),
        ],
      ),
    );
  }
}
