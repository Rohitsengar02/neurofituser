import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/log_meal_screen.dart';
import 'liquid_glass.dart';
import 'side_island.dart' show IslandStats;

// Nutrition tab in the Apple style shared with Overview and Workouts:
// liquid glass cards, Inter numerals (closest to SF Pro), spring reveals,
// animated gauges and real food photography.

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _faint = Color(0xFF6E7681);
const _green = Color(0xFF16A34A);
const _mint = Color(0xFF22C55E);
const _orange = Color(0xFFFF7A3D);
const _blue = Color(0xFF3B82F6);
const _sky = Color(0xFF38BDF8);
const _purple = Color(0xFF8B5CF6);
const _pink = Color(0xFFEC4899);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const Curve _spring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle _t(double s, {FontWeight w = FontWeight.w600, Color c = _ink, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

/// Display numerals: Inter with tabular figures, like SF Pro Rounded-less.
TextStyle _n(double s, {FontWeight w = FontWeight.w700, Color c = _ink, double? ls}) => GoogleFonts.inter(
      fontSize: s,
      fontWeight: w,
      color: c,
      letterSpacing: ls ?? -s * 0.035,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

const _u = 'https://images.unsplash.com/photo-';
String _img(String id) => '$_u$id?q=80&w=600&auto=format&fit=crop';

void _openLog(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogMealScreen()));

// =====================================================================

class NutritionTabV3 extends StatelessWidget {
  const NutritionTabV3({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 18),
        _Welcome(),
        SizedBox(height: 14),
        _DayPicker(),
        SizedBox(height: 14),
        ScrollReveal(child: _CaloriesCard()),
        _Head('Macros', action: 'Goals'),
        ScrollReveal(child: _MacrosCard()),
        _Head("Today's meals", action: 'Log meal'),
        _Meals(),
        _Head('Hydration'),
        ScrollReveal(child: _WaterCard()),
        SizedBox(height: 16),
        ScrollReveal(child: _ScanCard()),
        _Head('Vitamins & minerals'),
        ScrollReveal(child: _MicrosCard()),
        _Head('This week'),
        ScrollReveal(child: _WeekCard()),
        _Head('Recipes for you', action: 'See all'),
        _Recipes(),
        _Head('Smart swaps'),
        ScrollReveal(child: _Swaps()),
        _Head('Eating window'),
        ScrollReveal(child: _FastingCard()),
        _Head('Supplements'),
        ScrollReveal(child: _Supplements()),
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
          if (action != null)
            GestureDetector(
              onTap: action == 'Log meal' ? () => _openLog(context) : null,
              child: Text(action!, style: _t(13, w: FontWeight.w700, c: _blue)),
            ),
        ]),
      ),
    );
  }
}

/// Builder with a 0→1 value that starts once the widget scrolls into view.
class _Seen extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  final Duration duration;
  const _Seen({required this.builder, this.duration = const Duration(milliseconds: 1500)});

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
        builder: (context, _) => widget.builder(context, Curves.easeOutCubic.transform(_c.value)),
      );
}

Widget _photo(String id, {IconData icon = Icons.restaurant_rounded, Color c = _orange}) => Image.network(
      _img(id),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0.55)]),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 30)),
      ),
    );

Widget _glass({required Widget child, EdgeInsets padding = const EdgeInsets.all(18), double r = 28, VoidCallback? onTap}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(r),
        padding: padding,
        onTap: onTap,
        child: child,
      ),
    );

// =====================================================================
//  WELCOME + DAY PICKER
// =====================================================================

class _Welcome extends StatefulWidget {
  const _Welcome();
  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const words = ['Fuel', 'your', 'day,', 'Rohit'];
    Widget blurIn(int i, Widget w) {
      final a = CurvedAnimation(parent: _c, curve: Interval(0.06 * i, 0.5 + 0.08 * i, curve: _spring));
      return AnimatedBuilder(
        animation: a,
        child: w,
        builder: (_, c) {
          final o = a.value.clamp(0.0, 1.0);
          final b = (1 - o) * 10;
          Widget x = Transform.translate(offset: Offset(0, 22 * (1 - a.value)), child: c);
          if (b > 0.3 && !LiquidGlass.lite) x = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: x);
          return Opacity(opacity: o, child: x);
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        blurIn(0, Text('NUTRITION · ${IslandStats.left} KCAL TO GO', style: _t(11.5, w: FontWeight.w800, c: _faint, ls: 1.4))),
        const SizedBox(height: 6),
        Wrap(spacing: 9, children: [
          for (var i = 0; i < words.length; i++)
            blurIn(
              i + 1,
              Text(words[i], style: _t(32, w: FontWeight.w800, ls: -1.2, h: 1.1, c: i == 3 ? _blue : _ink)),
            ),
        ]),
      ]),
    );
  }
}

class _DayPicker extends StatefulWidget {
  const _DayPicker();
  @override
  State<_DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<_DayPicker> {
  int _sel = 3;
  static const _fill = [0.92, 1.0, 0.85, 0.79, 0.0, 0.0, 0.0];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = now.add(Duration(days: i - 3));
          final sel = i == _sel;
          return ScrollReveal(
            delayMs: i * 40,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sel = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: _spring,
                width: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: sel ? _ink : Colors.white.withValues(alpha: 0.6),
                  border: Border.all(color: Colors.white.withValues(alpha: sel ? 0 : 0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: (sel ? _ink : const Color(0xFF64748B)).withValues(alpha: sel ? 0.25 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(names[d.weekday - 1], style: _t(11.5, w: FontWeight.w700, c: sel ? Colors.white70 : _faint)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _fill[i]),
                      duration: Duration(milliseconds: 900 + i * 80),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => CustomPaint(
                        painter: _Ring(v, sel ? _mint : _blue, 3.2, track: sel ? Colors.white24 : null),
                        child: Center(
                          child: Text('${d.day}', style: _n(13, c: sel ? Colors.white : _ink)),
                        ),
                      ),
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

class _Ring extends CustomPainter {
  final double v, w;
  final Color c;
  final Color? track;
  _Ring(this.v, this.c, this.w, {this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - w / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = track ?? c.withValues(alpha: 0.14));
    if (v > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        2 * math.pi * v,
        false,
        p
          ..color = Colors.white
          ..shader = SweepGradient(
            colors: [c.withValues(alpha: 0.6), c],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Ring o) => o.v != v || o.c != c;
}

// =====================================================================
//  CALORIES GAUGE
// =====================================================================

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard();

  @override
  Widget build(BuildContext context) {
    final eaten = IslandStats.eaten, burned = IslandStats.burned, budget = IslandStats.budget;
    final left = IslandStats.left;
    return _glass(
      child: _Seen(
        duration: const Duration(milliseconds: 1700),
        builder: (_, t) => Column(children: [
          SizedBox(
            height: 150,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Positioned.fill(child: CustomPaint(painter: _Gauge(eaten / (budget + burned) * t, burned / (budget + burned) * t))),
              Positioned(
                bottom: 4,
                child: Column(children: [
                  Text('${(left * t).round()}', style: _n(46, w: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('kcal left', style: _t(13, w: FontWeight.w600, c: _muted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            _stat('Eaten', (eaten * t).round(), _orange, Icons.restaurant_rounded),
            _divider(),
            _stat('Burned', (burned * t).round(), _red, Icons.local_fire_department_rounded),
            _divider(),
            _stat('Goal', budget, _blue, Icons.flag_rounded),
          ]),
        ]),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: const Color(0xFFE5E7EB));

  Widget _stat(String l, int v, Color c, IconData i) => Expanded(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, size: 14, color: c),
            const SizedBox(width: 4),
            Text(l, style: _t(12, w: FontWeight.w600, c: _muted)),
          ]),
          const SizedBox(height: 4),
          Text('$v', style: _n(19)),
        ]),
      );
}

/// Half-circle gauge: eaten arc in orange, burned credit in soft red.
class _Gauge extends CustomPainter {
  final double eaten, burned;
  _Gauge(this.eaten, this.burned);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 16.0;
    final r = math.min(size.width / 2, size.height) - w;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height - 4), radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, p..color = const Color(0xFFEEF2F7));
    // Ticks.
    final tick = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k <= 20; k++) {
      final a = math.pi + math.pi * k / 20;
      final o = rect.center + Offset(math.cos(a), math.sin(a)) * (r - w - 4);
      final i = rect.center + Offset(math.cos(a), math.sin(a)) * (r - w - (k % 5 == 0 ? 12 : 8));
      canvas.drawLine(i, o, tick);
    }
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * eaten,
      false,
      p
        ..color = Colors.white
        ..shader = const SweepGradient(
          startAngle: math.pi,
          endAngle: 2 * math.pi,
          colors: [Color(0xFFFFB37A), _orange],
        ).createShader(rect),
    );
    p.shader = null;
    canvas.drawArc(rect, math.pi + math.pi * eaten, math.pi * burned, false, p..color = _red.withValues(alpha: 0.35));
    final end = math.pi + math.pi * eaten;
    final knob = rect.center + Offset(math.cos(end), math.sin(end)) * r;
    canvas.drawCircle(knob, 11, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 6, Paint()..color = _orange);
  }

  @override
  bool shouldRepaint(covariant _Gauge o) => o.eaten != eaten || o.burned != burned;
}

// =====================================================================
//  MACROS
// =====================================================================

const _macros = [
  ('Protein', 100, 140, _purple),
  ('Carbs', 245, 350, _amber),
  ('Fat', 48, 65, _pink),
  ('Fiber', 18, 30, _green),
];

class _MacrosCard extends StatelessWidget {
  const _MacrosCard();

  @override
  Widget build(BuildContext context) {
    return _glass(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      child: _Seen(
        duration: const Duration(milliseconds: 1600),
        builder: (_, t) => Row(children: [
          for (var i = 0; i < _macros.length; i++)
            Expanded(
              child: Column(children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _Ring(
                      _macros[i].$2 / _macros[i].$3 * Curves.easeOutCubic.transform(((t * 1.3) - i * 0.08).clamp(0.0, 1.0)),
                      _macros[i].$4,
                      7,
                    ),
                    child: Center(child: Text('${(_macros[i].$2 * t).round()}', style: _n(16))),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_macros[i].$1, style: _t(12.5, w: FontWeight.w700)),
                Text('${_macros[i].$3 - _macros[i].$2} g left', style: _t(11, w: FontWeight.w600, c: _muted)),
              ]),
            ),
        ]),
      ),
    );
  }
}

// =====================================================================
//  MEALS
// =====================================================================

const _meals = [
  ('Breakfast', '8:10 AM', 'Avocado toast & eggs', 420, '1525351484163-7529414344d8', 22, 38, 18),
  ('Lunch', '1:05 PM', 'Chicken quinoa bowl', 610, '1546069901-ba9599a7e63c', 46, 62, 16),
  ('Snack', '4:30 PM', 'Berry yogurt parfait', 390, '1488477181946-6428a0291777', 20, 44, 12),
  ('Dinner', 'Suggested', 'Salmon & greens', 0, '1467003909585-2f8a72700288', 34, 18, 20),
];

class _Meals extends StatelessWidget {
  const _Meals();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        for (var i = 0; i < _meals.length; i++) ...[
          ScrollReveal(
            delayMs: (i % 2) * 70,
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(26),
              padding: const EdgeInsets.all(10),
              onTap: () => _openLog(context),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(width: 86, height: 86, child: _photo(_meals[i].$5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(_meals[i].$1, style: _t(15, w: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(_meals[i].$2,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11.5, w: FontWeight.w600, c: _faint)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(_meals[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5, w: FontWeight.w600, c: _muted)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _macroPill('P', _meals[i].$6, _purple),
                      const SizedBox(width: 5),
                      _macroPill('C', _meals[i].$7, _amber),
                      const SizedBox(width: 5),
                      _macroPill('F', _meals[i].$8, _pink),
                    ]),
                  ]),
                ),
                const SizedBox(width: 6),
                _meals[i].$4 == 0
                    ? Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: _ink),
                        child: const Icon(Icons.add_rounded, color: Colors.white),
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${_meals[i].$4}', style: _n(18)),
                        Text('kcal', style: _t(11, w: FontWeight.w600, c: _muted)),
                      ]),
              ]),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

Widget _macroPill(String l, int g, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text('$l ${g}g', style: _t(11, w: FontWeight.w700, c: Color.lerp(c, _ink, 0.35)!)),
    );

// =====================================================================
//  WATER
// =====================================================================

class _WaterCard extends StatefulWidget {
  const _WaterCard();
  @override
  State<_WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends State<_WaterCard> with SingleTickerProviderStateMixin {
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _add(int ml) {
    HapticFeedback.mediumImpact();
    IslandStats.waterMl.value = (IslandStats.waterMl.value + ml).clamp(0, IslandStats.waterGoal);
  }

  @override
  Widget build(BuildContext context) {
    return _glass(
      child: ValueListenableBuilder<int>(
        valueListenable: IslandStats.waterMl,
        builder: (_, ml, _) {
          final goal = IslandStats.waterGoal;
          return Row(children: [
            SizedBox(
              width: 92,
              height: 150,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ml / goal),
                duration: const Duration(milliseconds: 900),
                curve: _spring,
                builder: (_, v, _) => AnimatedBuilder(
                  animation: _wave,
                  builder: (_, _) => CustomPaint(painter: _Bottle(v, _wave.value)),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: ml / 1000),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, _) => Text(v.toStringAsFixed(2), style: _n(36, w: FontWeight.w800)),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('/ ${goal / 1000} L', style: _t(13, w: FontWeight.w600, c: _muted)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${((ml / goal) * 100).round()}% of daily goal', style: _t(12.5, w: FontWeight.w600, c: _sky)),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _waterBtn('+250 ml', () => _add(250)),
                  _waterBtn('+500 ml', () => _add(500)),
                ]),
                const SizedBox(height: 10),
                Text('Next reminder in 40 min', style: _t(11.5, w: FontWeight.w600, c: _faint)),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _waterBtn(String l, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _sky.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _sky.withValues(alpha: 0.3)),
          ),
          child: Text(l, style: _t(12.5, w: FontWeight.w800, c: const Color(0xFF0369A1))),
        ),
      );
}

class _Bottle extends CustomPainter {
  final double level, phase;
  _Bottle(this.level, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.16, w * 0.76, h * 0.84),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(22),
      bottomRight: const Radius.circular(22),
    );
    final cap = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, 0, w * 0.36, h * 0.13), const Radius.circular(6));
    canvas.drawRRect(cap, Paint()..color = _sky.withValues(alpha: 0.5));
    canvas.drawRRect(body, Paint()..color = Colors.white.withValues(alpha: 0.7));
    canvas.save();
    canvas.clipRRect(body);
    final top = body.top + body.height * (1 - level.clamp(0.0, 1.0));
    for (var layer = 0; layer < 2; layer++) {
      final path = Path()..moveTo(body.left, body.bottom);
      for (var x = body.left; x <= body.right + 1; x += 2) {
        final y = top + math.sin((x / w * 2 * math.pi * 1.4) + phase * 2 * math.pi + layer * 1.6) * (4 - layer);
        path.lineTo(x, y);
      }
      path
        ..lineTo(body.right, body.bottom)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: layer == 0
                ? [const Color(0xFF7DD3FC).withValues(alpha: 0.7), const Color(0xFF38BDF8).withValues(alpha: 0.7)]
                : [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
          ).createShader(body.outerRect),
      );
    }
    // Bubbles.
    for (var k = 0; k < 5; k++) {
      final bx = body.left + body.width * (0.2 + 0.15 * k);
      final by = body.bottom - ((phase + k * 0.21) % 1) * (body.bottom - top);
      canvas.drawCircle(Offset(bx, by), 2 + k % 2.0, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _sky.withValues(alpha: 0.45),
    );
    // Glass shine.
    canvas.drawLine(Offset(body.left + 8, body.top + 16), Offset(body.left + 8, body.bottom - 20),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _Bottle o) => o.level != level || o.phase != phase;
}

// =====================================================================
//  AI SCAN
// =====================================================================

class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        onTap: () => _openLog(context),
        child: LayoutBuilder(builder: (context, c) {
          final img = (c.maxWidth * 0.42).clamp(110.0, 180.0);
          return SizedBox(
          height: 150,
          child: Stack(children: [
            Positioned(
              right: -10,
              bottom: -6,
              width: img,
              child: Image.asset('assets/images/island/meal_scan.png', fit: BoxFit.contain),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 18, img - 14, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFBAE6FD), size: 16),
                  const SizedBox(width: 6),
                  Text('AI MEAL SCAN', style: _t(11.5, w: FontWeight.w800, c: const Color(0xFFBAE6FD), ls: 1)),
                ]),
                const SizedBox(height: 8),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Snap your plate,\nKemo counts it', style: _t(19, w: FontWeight.w800, c: Colors.white, h: 1.15))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.photo_camera_rounded, size: 16, color: _blue),
                    const SizedBox(width: 6),
                    Text('Scan meal', style: _t(13, w: FontWeight.w800, c: _blue)),
                  ]),
                ),
              ]),
            ),
          ]),
          );
        }),
      ),
    );
  }
}

// =====================================================================
//  MICRONUTRIENTS
// =====================================================================

class _MicrosCard extends StatelessWidget {
  const _MicrosCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Vitamin C', 0.82, '74 / 90 mg', _orange),
      ('Iron', 0.64, '11.5 / 18 mg', _red),
      ('Calcium', 0.48, '480 / 1000 mg', _sky),
      ('Vitamin D', 0.3, '4.5 / 15 µg', _amber),
      ('Potassium', 0.71, '2.5 / 3.5 g', _green),
      ('Magnesium', 0.55, '230 / 420 mg', _purple),
    ];
    return _glass(
      child: _Seen(
        duration: const Duration(milliseconds: 1600),
        builder: (_, t) => Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(children: [
              Expanded(child: Text(rows[i].$1, style: _t(13.5, w: FontWeight.w700))),
              Text(rows[i].$3, style: _t(11.5, w: FontWeight.w600, c: _muted)),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text('${(rows[i].$2 * 100 * t).round()}%',
                    textAlign: TextAlign.right, style: _n(13, c: rows[i].$4)),
              ),
            ]),
            const SizedBox(height: 6),
            LayoutBuilder(builder: (_, c) {
              final v = rows[i].$2 * Curves.easeOutCubic.transform(((t * 1.4) - i * 0.07).clamp(0.0, 1.0));
              return Stack(children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(color: rows[i].$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                ),
                Container(
                  height: 8,
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [rows[i].$4.withValues(alpha: 0.55), rows[i].$4]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ]);
            }),
            if (i < rows.length - 1) const SizedBox(height: 14),
          ],
        ]),
      ),
    );
  }
}

// =====================================================================
//  WEEK
// =====================================================================

class _WeekCard extends StatefulWidget {
  const _WeekCard();
  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> {
  static const _days = ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Today'];
  static const _kcal = [1650.0, 1820, 1540, 1760, 1900, 1610, 1420];
  int _sel = 6;

  @override
  Widget build(BuildContext context) {
    const goal = 1800.0, mx = 2100.0;
    return _glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_kcal[_sel].round()}', style: _n(32, w: FontWeight.w800)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('kcal · ${_days[_sel]}', style: _t(12.5, w: FontWeight.w600, c: _muted)),
          ),
          const Spacer(),
          Text('Avg 1,671', style: _t(12.5, w: FontWeight.w700, c: _muted)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: _Seen(
            duration: const Duration(milliseconds: 1400),
            builder: (_, t) => LayoutBuilder(builder: (_, c) {
              final goalY = c.maxHeight - 22 - (goal / mx) * (c.maxHeight - 30);
              return Stack(children: [
                // Goal line.
                Positioned(
                  left: 0,
                  right: 0,
                  top: goalY,
                  child: Row(children: [
                    Expanded(child: CustomPaint(size: const Size(double.infinity, 1), painter: _Dash())),
                    const SizedBox(width: 4),
                    Text('Goal', style: _t(11, w: FontWeight.w700, c: _blue)),
                  ]),
                ),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sel = i);
                        },
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Builder(builder: (_) {
                            final g = _spring.transform(((t * 1.5) - i * 0.07).clamp(0.0, 1.0));
                            final over = _kcal[i] > goal;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _sel == i ? 24 : 18,
                              height: math.max(6, (_kcal[i] / mx) * (c.maxHeight - 30) * g),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: _sel == i
                                      ? [over ? _orange : _sky, over ? const Color(0xFFEA580C) : _blue]
                                      : [(over ? _orange : _blue).withValues(alpha: 0.35), (over ? _orange : _blue).withValues(alpha: 0.18)],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          Text(_days[i],
                              maxLines: 1,
                              style: _t(11, w: _sel == i ? FontWeight.w800 : FontWeight.w600, c: _sel == i ? _ink : _faint)),
                        ]),
                      ),
                    ),
                ]),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}

class _Dash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _blue.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 3.5, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// =====================================================================
//  RECIPES
// =====================================================================

const _recipes = [
  ('Green power bowl', '520 kcal · 15 min · 32g protein', '1512621776951-a57141f2eefd', _green),
  ('Protein smoothie', '310 kcal · 5 min · 28g protein', '1553530666-ba11a7da3888', _pink),
  ('Mediterranean plate', '580 kcal · 20 min · 30g protein', '1467003909585-2f8a72700288', _amber),
  ('Salmon poke', '540 kcal · 15 min · 36g protein', '1546069901-ba9599a7e63c', _orange),
];

class _Recipes extends StatelessWidget {
  const _Recipes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recipes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = _recipes[i];
          return ScrollReveal(
            delayMs: i * 80,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 12))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                _photo(r.$3, c: r.$4),
                Positioned(
                  right: 10,
                  top: 10,
                  child: LiquidGlass(
                    style: LiquidGlassStyle.clear,
                    shape: BoxShape.circle,
                    shadow: false,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.favorite_border_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: LiquidGlass(
                    style: LiquidGlassStyle.clear,
                    borderRadius: BorderRadius.circular(20),
                    colors: [Colors.black.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.42)],
                    shadow: false,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14.5, w: FontWeight.w800, c: Colors.white)),
                      const SizedBox(height: 2),
                      Text(r.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11, w: FontWeight.w600, c: Colors.white.withValues(alpha: 0.85))),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
//  SMART SWAPS
// =====================================================================

class _Swaps extends StatelessWidget {
  const _Swaps();

  @override
  Widget build(BuildContext context) {
    const swaps = [
      ('White rice', 'Quinoa', '+6g protein · +3g fiber', Icons.rice_bowl_rounded, _amber),
      ('Soda', 'Sparkling water + lime', '−140 kcal · 0g sugar', Icons.local_drink_rounded, _sky),
      ('Chips', 'Roasted chickpeas', '+7g protein · −8g fat', Icons.cookie_rounded, _orange),
    ];
    return _glass(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(children: [
        for (var i = 0; i < swaps.length; i++) ...[
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: swaps[i].$5.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(swaps[i].$4, color: swaps[i].$5, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(swaps[i].$1,
                      style: _t(13.5, w: FontWeight.w600, c: _muted).copyWith(decoration: TextDecoration.lineThrough)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: _green),
                  ),
                  Text(swaps[i].$2, style: _t(13.5, w: FontWeight.w800)),
                ]),
                const SizedBox(height: 2),
                Text(swaps[i].$3, style: _t(11.5, w: FontWeight.w700, c: _green)),
              ]),
            ),
          ]),
          if (i < swaps.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
        ],
      ]),
    );
  }
}

// =====================================================================
//  FASTING WINDOW
// =====================================================================

class _FastingCard extends StatelessWidget {
  const _FastingCard();

  @override
  Widget build(BuildContext context) {
    return _glass(
      child: Row(children: [
        SizedBox(
          width: 130,
          height: 130,
          child: _Seen(
            duration: const Duration(milliseconds: 1800),
            builder: (_, t) => CustomPaint(
              painter: _Clock(t),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('5:20', style: _n(24, w: FontWeight.w800)),
                  Text('left to eat', style: _t(11, w: FontWeight.w600, c: _muted)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('16 : 8', style: _n(22, w: FontWeight.w800)),
            Text('Intermittent fasting', style: _t(12.5, w: FontWeight.w600, c: _muted)),
            const SizedBox(height: 12),
            _legend(_green, 'Eating', '12 PM – 8 PM'),
            const SizedBox(height: 6),
            _legend(const Color(0xFFCBD5E1), 'Fasting', '8 PM – 12 PM'),
            const SizedBox(height: 10),
            Text('6-day streak', style: _t(12, w: FontWeight.w800, c: _orange)),
          ]),
        ),
      ]),
    );
  }

  Widget _legend(Color c, String a, String b) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(a, style: _t(12, w: FontWeight.w700)),
        const SizedBox(width: 6),
        Flexible(child: Text(b, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11.5, w: FontWeight.w600, c: _muted))),
      ]);
}

/// 24-hour dial: fasting track, eating window in green, a "now" knob.
class _Clock extends CustomPainter {
  final double t;
  _Clock(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 12.0;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - w / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    double ang(double h) => -math.pi / 2 + h / 24 * 2 * math.pi;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, p..color = const Color(0xFFE2E8F0));
    canvas.drawArc(rect, ang(12), (8 / 24) * 2 * math.pi * t, false, p..color = _green);
    final now = ang(14.67);
    final k = c + Offset(math.cos(now), math.sin(now)) * r;
    if (t > 0.9) {
      canvas.drawCircle(k, 9, Paint()..color = Colors.white);
      canvas.drawCircle(k, 5, Paint()..color = _ink);
    }
    for (var h = 0; h < 24; h += 6) {
      final a = ang(h.toDouble());
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r - 16), 1.8, Paint()..color = _faint);
    }
  }

  @override
  bool shouldRepaint(covariant _Clock o) => o.t != t;
}

// =====================================================================
//  SUPPLEMENTS
// =====================================================================

class _Supplements extends StatefulWidget {
  const _Supplements();
  @override
  State<_Supplements> createState() => _SupplementsState();
}

class _SupplementsState extends State<_Supplements> {
  final _taken = <int>{0};

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Whey protein', 'After workout · 1 scoop', Icons.fitness_center_rounded, _purple),
      ('Omega-3', 'With lunch · 2 caps', Icons.water_drop_rounded, _amber),
      ('Vitamin D3', 'Morning · 1 tab', Icons.wb_sunny_rounded, _orange),
      ('Creatine', 'Any time · 5 g', Icons.bolt_rounded, _blue),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('assets/images/nutrifit_whey_protein.jpg', width: 76, height: 76, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daily stack', style: _t(16, w: FontWeight.w800)),
                Text('${_taken.length} of ${items.length} taken today', style: _t(12, w: FontWeight.w600, c: _muted)),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: _taken.length / items.length),
                  duration: const Duration(milliseconds: 600),
                  curve: _spring,
                  builder: (_, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: _purple.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(_purple),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _taken.contains(i) ? _taken.remove(i) : _taken.add(i));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: items[i].$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(items[i].$3, size: 19, color: items[i].$4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(items[i].$1, style: _t(13.5, w: FontWeight.w700)),
                      Text(items[i].$2, style: _t(11.5, w: FontWeight.w600, c: _muted)),
                    ]),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: _spring,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _taken.contains(i) ? _mint : Colors.transparent,
                      border: Border.all(color: _taken.contains(i) ? _mint : const Color(0xFFD1D5DB), width: 1.6),
                    ),
                    child: _taken.contains(i) ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
