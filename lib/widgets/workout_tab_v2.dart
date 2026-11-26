import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'liquid_glass.dart';
import 'overview_home_cards.dart' show DottedLineChart;

// Workouts tab in the Overview's Apple style: a welcome reveal, today's
// session, dot-matrix stats, animated charts and image-led liquid glass
// cards. Exercise art comes from the bundled exercise dataset.

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _faint = Color(0xFF6E7681);
const _green = Color(0xFF16A34A);
const _mint = Color(0xFF22C55E);
const _orange = Color(0xFFFF7A3D);
const _blue = Color(0xFF3B82F6);
const _purple = Color(0xFF8B5CF6);
const _pink = Color(0xFFEC4899);
const _amber = Color(0xFFF59E0B);
const Curve _spring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle _t(double s, {FontWeight w = FontWeight.w600, Color c = _ink, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

String _ex(String file) => 'assets/exercises/images/$file';

class _Exercise {
  final String name, image, sets, muscle, tip;
  const _Exercise(this.name, this.image, this.sets, this.muscle, this.tip);
}

const _today = [
  _Exercise('Barbell Bench Press', '0025-EIeI8Vf.jpg', '4 × 10', 'Chest',
      'Lie flat, grip slightly wider than shoulders, lower to mid-chest and press up in a straight line.'),
  _Exercise('Incline Dumbbell Press', '0314-ns0SIbU.jpg', '3 × 12', 'Upper chest',
      'Bench at 45°, dumbbells at shoulder height, press up and together without locking elbows.'),
  _Exercise('Seated Shoulder Press', '0405-znQUdHY.jpg', '3 × 10', 'Shoulders',
      'Sit tall, press the dumbbells overhead until arms are straight, lower slowly to ear level.'),
  _Exercise('Lateral Raise', '0334-DsgkuIt.jpg', '3 × 15', 'Side delts',
      'Soft elbows, raise to shoulder height leading with the elbows, pause, lower for 3 seconds.'),
  _Exercise('Triceps Dip', '0814-X6C6i5Y.jpg', '3 × 12', 'Triceps',
      'Hands on the bench edge, lower until elbows reach 90°, push back up through the palms.'),
  _Exercise('Push-up Finisher', '0662-I4hDWkc.jpg', '2 × max', 'Chest',
      'High plank, body in one line, chest to fist height, push the floor away.'),
];

// =====================================================================

class WorkoutTabV2 extends StatelessWidget {
  const WorkoutTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 18),
        _Welcome(),
        SizedBox(height: 16),
        ScrollReveal(child: _StatsRow()),
        _Head('This week', action: 'History'),
        ScrollReveal(child: _WeekCard()),
        _Head('Programs for you', action: 'See all'),
        _Programs(),
        _Head("Today's exercises", action: '6 · 45 min'),
        _TodayList(),
        _Head('Browse by type'),
        _TypeGrid(),
        _Head('Muscle recovery'),
        ScrollReveal(child: _RecoveryCard()),
        _Head('Quick workouts'),
        _QuickRow(),
        _Head('Personal records'),
        ScrollReveal(child: _Records()),
        _Head('Challenges'),
        ScrollReveal(child: _Challenges()),
        SizedBox(height: 20),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  final String title;
  final String? action;
  const _Head(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(children: [
          Expanded(child: Text(title, style: _t(20, w: FontWeight.w800, ls: -0.5))),
          if (action != null) Text(action!, style: _t(13, w: FontWeight.w700, c: _green)),
        ]),
      ),
    );
  }
}

/// Runs [builder] with a 0→1 value that starts when the widget scrolls into view.
class _Seen extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  final Duration duration;
  final Curve curve;
  const _Seen({
    required this.builder,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<_Seen> createState() => _SeenState();
}

class _SeenState extends State<_Seen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  ScrollPosition? _pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.value = 1;
      return;
    }
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _pos) {
      _pos?.removeListener(_check);
      _pos = pos?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _c.value > 0 || _c.isAnimating) return;
    final box = context.findRenderObject() as RenderBox?;
    final view = Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = view == null ? 0.0 : box.localToGlobal(Offset.zero, ancestor: view).dy;
    if (view == null || top < view.size.height - 40) {
      _pos?.removeListener(_check);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => widget.builder(context, widget.curve.transform(_c.value)),
      );
}

// =====================================================================
//  WELCOME
// =====================================================================

class _Welcome extends StatefulWidget {
  const _Welcome();
  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b, [Curve curve = _spring]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  Widget _blurIn(Animation<double> a, Widget child, {Offset from = const Offset(0, 22)}) => AnimatedBuilder(
        animation: a,
        child: child,
        builder: (_, c) {
          final v = a.value;
          final o = v.clamp(0.0, 1.0);
          final b = (1 - o) * 10;
          Widget w = Transform.translate(offset: from * (1 - v), child: c);
          if (b > 0.3) w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: w);
          return Opacity(opacity: o, child: w);
        },
      );

  @override
  Widget build(BuildContext context) {
    const words = ['Ready', 'for', 'Day', '13?'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _blurIn(
            _seg(0, 0.35, Curves.easeOut),
            Text('WEEK 3 · MUSCLE BUILDER', style: _t(11.5, w: FontWeight.w800, c: _faint, ls: 1.4)),
            from: const Offset(0, 8),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 9, children: [
            for (var i = 0; i < words.length; i++)
              _blurIn(
                _seg(0.08 + i * 0.08, 0.55 + i * 0.08),
                Text(words[i],
                    style: _t(32, w: FontWeight.w800, ls: -1.2, h: 1.1, c: i == 3 ? _green : _ink)),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      _blurIn(_seg(0.25, 0.95), const _SessionHero(), from: const Offset(0, 40)),
    ]);
  }
}

class _SessionHero extends StatelessWidget {
  const _SessionHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(30),
        colors: const [Color(0xFFFFFFFF), Color(0xFFF7FBF8)],
        onTap: () => _showExercise(context, _today.first),
        child: SizedBox(
          height: 236,
          child: Stack(children: [
            // Athlete art sliding in from the right.
            Positioned(
              right: -18,
              top: 6,
              bottom: 0,
              width: 190,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                curve: _spring,
                builder: (_, v, c) => Transform.translate(
                  offset: Offset(60 * (1 - v), 0),
                  child: Opacity(opacity: v.clamp(0.0, 1.0), child: c),
                ),
                child: Image.asset('assets/images/workout_exercise_cutout.jpg', fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("TODAY'S SESSION", style: _t(11, w: FontWeight.w800, c: _green, ls: 0.8)),
                ),
                const SizedBox(height: 10),
                Text('Upper Body\nPush', style: _t(27, w: FontWeight.w800, ls: -0.8, h: 1.05)),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _chip(Icons.timer_outlined, '45 min'),
                  _chip(Icons.fitness_center_rounded, '6 moves'),
                  _chip(Icons.local_fire_department_rounded, '380 kcal'),
                ]),
                const Spacer(),
                Row(children: [
                  _DarkButton(label: 'Start', onTap: () => _showExercise(context, _today.first)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: _Seen(
                      builder: (_, t) => CustomPaint(
                        painter: _RingPainter(0.43 * t, _green, 5),
                        child: Center(child: Text('43%', style: _t(11, w: FontWeight.w800))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('of plan', style: _t(11.5, w: FontWeight.w600, c: _muted)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget _chip(IconData i, String s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 13, color: _muted),
        const SizedBox(width: 4),
        Text(s, style: _t(11.5, w: FontWeight.w700)),
      ]),
    );

class _DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DarkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _ink.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _mint),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(label, style: _t(14, w: FontWeight.w800, c: Colors.white)),
        ]),
      ),
    );
  }
}

// =====================================================================
//  DOT MATRIX STATS
// =====================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, double value, int decimals, String suffix, String sub, Color c) => Expanded(
          child: LiquidGlass(
            style: LiquidGlassStyle.material,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, style: _t(11, w: FontWeight.w800, c: _faint, ls: 0.8)),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedDotNumber(value: value, decimals: decimals, suffix: suffix, height: 26, color: c),
              ),
              const SizedBox(height: 8),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11, w: FontWeight.w600, c: _muted)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        tile('VOLUME', 12.4, 1, 'K', 'kg lifted · +18%', _ink),
        const SizedBox(width: 10),
        tile('SESSIONS', 4, 0, '/5', 'this week', _green),
        const SizedBox(width: 10),
        tile('ACTIVE', 186, 0, '', 'minutes', _orange),
      ]),
    );
  }
}

const Map<String, List<String>> _glyphs = {
  '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': ['11110', '00001', '00001', '01110', '00001', '00001', '11110'],
  '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
  '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
  'K': ['10001', '10010', '10100', '11000', '10100', '10010', '10001'],
  '.': ['0', '0', '0', '0', '0', '0', '1'],
  '/': ['00001', '00010', '00010', '00100', '01000', '01000', '10000'],
  '%': ['11001', '11010', '00010', '00100', '01000', '01011', '10011'],
};

/// A number drawn on a 5x7 LED grid. When it scrolls into view it counts
/// up while the lit dots sweep in from left to right over a faint grid.
class AnimatedDotNumber extends StatelessWidget {
  final double value;
  final int decimals;
  final String suffix;
  final double height;
  final Color color;
  const AnimatedDotNumber({
    super.key,
    required this.value,
    this.decimals = 0,
    this.suffix = '',
    required this.height,
    this.color = _ink,
  });

  @override
  Widget build(BuildContext context) {
    final finalText = value.toStringAsFixed(decimals) + suffix;
    return _Seen(
      duration: const Duration(milliseconds: 1600),
      builder: (_, t) {
        final txt = (value * t).toStringAsFixed(decimals) + suffix;
        // Keep width stable by padding to the final length.
        final shown = txt.padLeft(finalText.length, ' ');
        return CustomPaint(
          size: Size(_width(finalText, height / 7), height),
          painter: _DotPainter(shown, height / 7, color, t),
        );
      },
    );
  }

  static double _width(String s, double cell) {
    var cols = 0;
    for (final ch in s.split('')) {
      cols += (_glyphs[ch]?.first.length ?? 3) + 1;
    }
    return math.max(0, cols - 1) * cell;
  }
}

class _DotPainter extends CustomPainter {
  final String text;
  final double cell;
  final Color color;
  final double t;
  _DotPainter(this.text, this.cell, this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final r = cell * 0.36;
    final total = AnimatedDotNumber._width(text, cell) / cell + 1;
    var x0 = 0.0;
    var col0 = 0;
    for (final ch in text.split('')) {
      final g = _glyphs[ch];
      final w = g?.first.length ?? 3;
      for (var row = 0; row < 7; row++) {
        for (var col = 0; col < w; col++) {
          final on = g != null && g[row][col] == '1';
          final c = Offset(x0 + (col + 0.5) * cell, (row + 0.5) * cell);
          if (!on) {
            canvas.drawCircle(c, r * 0.55, Paint()..color = color.withValues(alpha: 0.07));
            continue;
          }
          final sweep = ((t * 1.6 - (col0 + col) / total * 0.6) * 2.2).clamp(0.0, 1.0);
          canvas.drawCircle(c, r * (0.6 + 0.4 * sweep), Paint()..color = color.withValues(alpha: 0.15 + 0.85 * sweep));
        }
      }
      x0 += (w + 1) * cell;
      col0 += w + 1;
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter o) => o.text != text || o.t != t || o.color != color;
}

// =====================================================================
//  WEEK CHART
// =====================================================================

class _WeekCard extends StatefulWidget {
  const _WeekCard();
  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> {
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _mins = [42.0, 0, 38, 51, 45, 48, 0];
  int _sel = 5;

  @override
  Widget build(BuildContext context) {
    const mx = 60.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AnimatedDotNumber(value: 224, height: 30, color: _ink),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('min trained', style: _t(12.5, w: FontWeight.w600, c: _muted)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('↑ 12%', style: _t(12, w: FontWeight.w800, c: _green)),
            ),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: _Seen(
              duration: const Duration(milliseconds: 1400),
              builder: (_, t) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sel = i);
                        },
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _sel == i ? 1 : 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(8)),
                              child: Text('${_mins[i].round()}m', style: _t(11, w: FontWeight.w800, c: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final stagger = ((t * 1.5) - i * 0.07).clamp(0.0, 1.0);
                            final grow = _spring.transform(stagger);
                            final h = _mins[i] == 0 ? 8.0 : math.max(8.0, (_mins[i] / mx) * 104 * grow);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _sel == i ? 26 : 22,
                              height: h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                gradient: _mins[i] == 0
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: _sel == i
                                            ? const [Color(0xFF4ADE80), _green]
                                            : [_green.withValues(alpha: 0.35), _green.withValues(alpha: 0.18)],
                                      ),
                                color: _mins[i] == 0 ? const Color(0xFFEDEFEE) : null,
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Text(_days[i],
                              style: _t(11.5, w: _sel == i ? FontWeight.w800 : FontWeight.w600, c: _sel == i ? _ink : _faint)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Avg heart rate per session', style: _t(12.5, w: FontWeight.w700, c: _muted)),
          const SizedBox(height: 6),
          const DottedLineChart(
            values: <double>[128, 134, 131, 142, 139, 146, 141, 149],
            color: _pink,
            label: '149 bpm',
            height: 96,
          ),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, w;
  final Color c;
  _RingPainter(this.v, this.c, this.w);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - w / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = c.withValues(alpha: 0.14));
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * v, false, p..color = c);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v;
}

// =====================================================================
//  PROGRAMS (image cards)
// =====================================================================

const _programs = [
  ('Train Your Core', '4 weeks · Beginner', 'assets/images/workout_category_1.png', 0.35, _orange),
  ('30 Day Shred', '30 days · Intermediate', 'assets/images/workout_category_3.png', 0.6, _green),
  ('Transformation', '8 weeks · Advanced', 'assets/images/workout_category_4.png', 0.12, _mint),
  ('Shoulder Press 4×', '2 weeks · All levels', 'assets/images/spotlight_3.png', 0.0, _pink),
  ('Push Harder', '6 weeks · Intermediate', 'assets/images/top_pick_1.png', 0.0, _blue),
];

class _Programs extends StatelessWidget {
  const _Programs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 276,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: _programs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = _programs[i];
          return ScrollReveal(
            delayMs: i * 80,
            child: _PressScale(
              onTap: () {},
              child: Container(
                width: 196,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 22, offset: const Offset(0, 12)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(p.$3, fit: BoxFit.cover),
                  // Liquid glass caption floating over the art.
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: LiquidGlass(
                      style: LiquidGlassStyle.clear,
                      borderRadius: BorderRadius.circular(20),
                      colors: [Colors.black.withValues(alpha: 0.28), Colors.black.withValues(alpha: 0.42)],
                      shadow: false,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14.5, w: FontWeight.w800, c: Colors.white)),
                        Text(p.$2, style: _t(11, w: FontWeight.w600, c: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 8),
                        _Seen(
                          builder: (_, t) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.$4 == 0 ? 0.0001 : p.$4 * t,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              valueColor: AlwaysStoppedAnimation(p.$5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(p.$4 == 0 ? 'Not started' : '${(p.$4 * 100).round()}% complete',
                            style: _t(11, w: FontWeight.w700, c: Colors.white.withValues(alpha: 0.9))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScale({required this.child, required this.onTap});
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: Duration(milliseconds: _down ? 110 : 450),
          curve: _down ? Curves.easeOut : _spring,
          child: widget.child,
        ),
      );
}

// =====================================================================
//  TODAY'S EXERCISES
// =====================================================================

class _TodayList extends StatefulWidget {
  const _TodayList();
  @override
  State<_TodayList> createState() => _TodayListState();
}

class _TodayListState extends State<_TodayList> {
  final _done = <int>{0, 1};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        for (var i = 0; i < _today.length; i++) ...[
          ScrollReveal(
            delayMs: (i % 3) * 60,
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(10),
              onTap: () => _showExercise(context, _today[i]),
              child: Row(children: [
                _ExerciseThumb(_today[i].image, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_today[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14.5, w: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${_today[i].sets} · ${_today[i].muscle}', style: _t(12, w: FontWeight.w600, c: _muted)),
                  ]),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: _spring,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _done.contains(i) ? _mint : Colors.white,
                      border: Border.all(color: _done.contains(i) ? _mint : const Color(0xFFE5E7EB), width: 1.5),
                    ),
                    child: AnimatedScale(
                      scale: _done.contains(i) ? 1 : 0.4,
                      duration: const Duration(milliseconds: 420),
                      curve: _spring,
                      child: Icon(Icons.check_rounded,
                          size: 22, color: _done.contains(i) ? Colors.white : Colors.transparent),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  final String file;
  final double size;
  const _ExerciseThumb(this.file, {required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: const Color(0xFFEEF0EF)),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(3),
        child: Image.asset(_ex(file), fit: BoxFit.contain),
      );
}

void _showExercise(BuildContext context, _Exercise e) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: LiquidGlass(
        style: LiquidGlassStyle.regular,
        borderRadius: BorderRadius.circular(34),
        colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.82)],
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: _spring,
                builder: (_, s, c) => Transform.scale(scale: s, child: c),
                child: _ExerciseThumb(e.image, size: 200),
              ),
            ),
            const SizedBox(height: 16),
            Text(e.name, style: _t(22, w: FontWeight.w800, ls: -0.5)),
            const SizedBox(height: 4),
            Text('${e.sets} · ${e.muscle}', style: _t(13.5, w: FontWeight.w700, c: _green)),
            const SizedBox(height: 12),
            Text(e.tip, style: _t(14, w: FontWeight.w500, c: _muted, h: 1.5)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _DarkButton(label: 'Start set 1', onTap: () => Navigator.of(ctx).pop()),
            ),
          ]),
        ),
      ),
    ),
  );
}

// =====================================================================
//  BROWSE BY TYPE
// =====================================================================

const _types = [
  ('Strength', '42 workouts', '0043-qXTaZnJ.jpg', _green),
  ('Cardio', '28 workouts', '0685-oLrKqDH.jpg', _orange),
  ('HIIT', '19 workouts', '1160-dK9394r.jpg', _pink),
  ('Core', '24 workouts', '0274-TFqbd8t.jpg', _amber),
  ('Mobility', '16 workouts', '1460-IZVHb27.jpg', _purple),
  ('Back', '21 workouts', '0027-eZyBC3j.jpg', _blue),
];

class _TypeGrid extends StatelessWidget {
  const _TypeGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < _types.length; i++)
            SizedBox(
              width: w,
              child: ScrollReveal(
                delayMs: (i % 2) * 90,
                child: LiquidGlass(
                  style: LiquidGlassStyle.material,
                  borderRadius: BorderRadius.circular(24),
                  tint: _types[i].$4,
                  padding: const EdgeInsets.all(12),
                  onTap: () {},
                  child: SizedBox(
                    height: 128,
                    child: Stack(children: [
                      Positioned(
                        right: -6,
                        bottom: -6,
                        width: w * 0.58,
                        height: w * 0.58,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(_ex(_types[i].$3), fit: BoxFit.contain),
                        ),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _types[i].$4),
                        ),
                        const SizedBox(height: 8),
                        Text(_types[i].$1, style: _t(16, w: FontWeight.w800, ls: -0.3)),
                        Text(_types[i].$2, style: _t(11.5, w: FontWeight.w600, c: _muted)),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

// =====================================================================
//  MUSCLE RECOVERY
// =====================================================================

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Chest', 0.62, _orange, 'Trained today'),
      ('Shoulders', 0.55, _orange, 'Trained today'),
      ('Back', 0.9, _green, 'Ready'),
      ('Legs', 1.0, _green, 'Fully recovered'),
      ('Arms', 0.74, _amber, 'Almost ready'),
      ('Core', 0.86, _green, 'Ready'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(18),
        child: _Seen(
          duration: const Duration(milliseconds: 1600),
          builder: (_, t) => Column(children: [
            for (var i = 0; i < rows.length; i++) ...[
              Row(children: [
                SizedBox(width: 82, child: Text(rows[i].$1, style: _t(13.5, w: FontWeight.w700))),
                Expanded(
                  child: LayoutBuilder(builder: (_, c) {
                    final v = rows[i].$2 * Curves.easeOutCubic.transform(((t * 1.4) - i * 0.08).clamp(0.0, 1.0));
                    // Segmented capsule meter.
                    const seg = 14;
                    return Row(children: [
                      for (var k = 0; k < seg; k++)
                        Expanded(
                          child: Container(
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 1.2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: k / seg < v ? rows[i].$3 : rows[i].$3.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                    ]);
                  }),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text('${(rows[i].$2 * 100 * t).round()}%',
                      textAlign: TextAlign.right, style: _t(12.5, w: FontWeight.w800, c: rows[i].$3)),
                ),
              ]),
              if (i < rows.length - 1) const SizedBox(height: 12),
            ],
          ]),
        ),
      ),
    );
  }
}

// =====================================================================
//  QUICK WORKOUTS
// =====================================================================

const _quick = [
  ('10-min HIIT', '10 min · 120 kcal', '0630-RJgzwny.jpg', _pink),
  ('Core Blast', '12 min · 90 kcal', '0687-XVDdcoj.jpg', _amber),
  ('Leg Day Express', '15 min · 150 kcal', '1760-yn8yg1r.jpg', _green),
  ('Arm Pump', '8 min · 60 kcal', '0294-NbVPDMW.jpg', _blue),
  ('Kettlebell Flow', '14 min · 160 kcal', '0549-UHJlbu3.jpg', _purple),
];

class _QuickRow extends StatelessWidget {
  const _QuickRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quick.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final q = _quick[i];
          return ScrollReveal(
            delayMs: i * 70,
            child: SizedBox(
              width: 150,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(26),
                padding: const EdgeInsets.all(8),
                onTap: () {},
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Stack(children: [
                    _ExerciseThumb(q.$3, size: 134),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: q.$4),
                        child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(q.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13.5, w: FontWeight.w800)),
                      Text(q.$2, maxLines: 1, style: _t(11, w: FontWeight.w600, c: _muted)),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
//  PERSONAL RECORDS
// =====================================================================

class _Records extends StatelessWidget {
  const _Records();

  @override
  Widget build(BuildContext context) {
    const recs = [
      ('Bench', 80.0, '0025-EIeI8Vf.jpg', _orange, <double>[60, 65, 67.5, 70, 72.5, 75, 80]),
      ('Squat', 110.0, '0043-qXTaZnJ.jpg', _green, <double>[85, 90, 95, 100, 100, 105, 110]),
      ('Deadlift', 140.0, '0032-ila4NZS.jpg', _purple, <double>[110, 115, 120, 125, 130, 135, 140]),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        for (var i = 0; i < recs.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LayoutBuilder(
                  builder: (_, c) => Row(children: [
                    if (c.maxWidth > 104) ...[
                      _ExerciseThumb(recs[i].$3, size: 34),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(recs[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5, w: FontWeight.w800)),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedDotNumber(value: recs[i].$2, height: 22, color: recs[i].$4),
                ),
                Text('kg · best', style: _t(11, w: FontWeight.w600, c: _muted)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: _Seen(builder: (_, t) => CustomPaint(painter: _Spark(recs[i].$5, recs[i].$4, t))),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Spark extends CustomPainter {
  final List<double> v;
  final Color c;
  final double t;
  _Spark(this.v, this.c, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final mn = v.reduce(math.min), mx = v.reduce(math.max);
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(size.width * i / (v.length - 1), size.height - 3 - (v[i] - mn) / (mx - mn) * (size.height - 6)),
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (t > 0.98) canvas.drawCircle(pts.last, 3.5, Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _Spark o) => o.t != t;
}

// =====================================================================
//  CHALLENGES (banner carousel)
// =====================================================================

class _Challenges extends StatefulWidget {
  const _Challenges();
  @override
  State<_Challenges> createState() => _ChallengesState();
}

class _ChallengesState extends State<_Challenges> {
  final _pc = PageController(viewportFraction: 0.9);
  int _page = 0;
  static const _banners = [
    'assets/images/workout_banner_2.png',
    'assets/images/workout_banner_1.png',
    'assets/images/workout_banner_4.png',
    'assets/images/workout_banner_3.png',
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 190,
        child: PageView.builder(
          controller: _pc,
          itemCount: _banners.length,
          onPageChanged: (p) => setState(() => _page = p),
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _pc,
            builder: (_, c) {
              var d = 0.0;
              if (_pc.hasClients && _pc.position.haveDimensions) d = (_pc.page ?? 0) - i;
              final s = 1 - (d.abs() * 0.08).clamp(0.0, 0.08);
              return Transform.scale(scale: s, child: c);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(_banners[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < _banners.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            curve: _spring,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _page ? _ink : _ink.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ]),
    ]);
  }
}
