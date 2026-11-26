import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/active_workout_screen.dart';
import '../screens/date_nutrition_detail_screen.dart';
import '../screens/kemo_ai_screen.dart';
import '../screens/log_meal_screen.dart';
import '../screens/steps_screen.dart';
import 'kemo_avatar.dart';

/// Today's numbers shared by the island and its slider.
class IslandStats {
  IslandStats._();
  static const int eaten = 1420;
  static const int burned = 320;
  static const int budget = 1800;
  static int get left => budget - eaten + burned;
  static const int steps = 8542;
  static const int stepGoal = 10000;
  static final ValueNotifier<int> waterMl = ValueNotifier<int>(1250);
  static const int waterGoal = 2500;
}

const _teal = Color(0xFF0E7F72);
const _tealDeep = Color(0xFF0A5F57);
const _tealCard = Color(0xFF15A08E);
const _mint = Color(0xFF34E3C4);
const _ink = Color(0xFF0F172A);

TextStyle _f(double size,
        {FontWeight w = FontWeight.w700, Color c = Colors.white, double? h}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: w, color: c, height: h);

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// A dynamic-island pill that floats on the left or right edge of the
/// screen. Drag it anywhere; it snaps to the nearest side. Tap it to pull
/// down the "Today" slider from the top.
class SideIsland extends StatefulWidget {
  const SideIsland({super.key});

  @override
  State<SideIsland> createState() => _SideIslandState();
}

class _SideIslandState extends State<SideIsland>
    with SingleTickerProviderStateMixin {
  static const double _w = 78;
  static const double _h = 58;

  bool _right = true;
  double _y = 0.42; // fraction of available height
  Offset? _drag; // live position while dragging
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  bool _warm = false;

  // Island menu morph (pill -> two-option capsule), iOS style spring.
  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 300),
  );
  static const _spring = Cubic(0.2, 1.25, 0.32, 1);

  void _toggleMenu() {
    HapticFeedback.mediumImpact();
    if (_menu.isCompleted || _menu.status == AnimationStatus.forward) {
      _menu.reverse();
    } else {
      _menu.forward();
    }
  }

  Alignment _origin(Size screen, double top) => Alignment(
        _right ? 1 : -1,
        ((top + _h / 2) / screen.height) * 2 - 1,
      );

  Future<void> _pick(bool stats, Size screen, double top) async {
    HapticFeedback.selectionClick();
    final origin = _origin(screen, top);
    await _menu.reverse();
    if (!mounted) return;
    if (stats) {
      showTodaySlider(context, origin: origin);
    } else {
      Navigator.of(context).push(iosZoomRoute(const KemoAiScreen(), origin));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_warm) {
      _warm = true;
      KemoAvatar.precache(context);
    }
  }

  @override
  void dispose() {
    _menu.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return LayoutBuilder(builder: (context, c) {
      final minY = pad.top + 8;
      final maxY = c.maxHeight - _h - 120;
      final restY = minY + (maxY - minY) * _y;
      final left = _drag?.dx ?? (_right ? c.maxWidth - _w : 0);
      final top = _drag?.dy ?? restY;
      return Stack(
        children: [
          AnimatedPositioned(
            duration: _drag != null
                ? Duration.zero
                : const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            left: left,
            top: top,
            child: GestureDetector(
              onTap: _toggleMenu,
              onPanStart: (_) {
                _menu.reverse();
                setState(() => _drag = Offset(left, top));
              },
              onPanUpdate: (d) => setState(() {
                final p = (_drag ?? Offset(left, top)) + d.delta;
                _drag = Offset(p.dx.clamp(0, c.maxWidth - _w),
                    p.dy.clamp(minY, maxY));
              }),
              onPanEnd: (d) {
                final p = _drag ?? Offset(left, top);
                final vx = d.velocity.pixelsPerSecond.dx;
                HapticFeedback.selectionClick();
                setState(() {
                  _right = vx.abs() > 600
                      ? vx > 0
                      : p.dx + _w / 2 > c.maxWidth / 2;
                  _y = ((p.dy - minY) / (maxY - minY)).clamp(0.0, 1.0);
                  _drag = null;
                });
              },
              child: _pill(dragging: _drag != null),
            ),
          ),
          AnimatedBuilder(
            animation: _menu,
            builder: (context, _) {
              if (_menu.isDismissed) return const SizedBox.shrink();
              final raw = _menu.value;
              final t = _menu.status == AnimationStatus.reverse
                  ? Curves.easeInCubic.transform(raw)
                  : _spring.transform(raw);
              const mw = 224.0, mh = 150.0;
              final w = _w + (mw - _w) * t;
              final h = _h + (mh - _h) * t;
              final mt = (top + _h / 2 - h / 2)
                  .clamp(pad.top + 4, c.maxHeight - h - 100);
              return Positioned.fill(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _menu.reverse(),
                        child: ColoredBox(
                          color: Colors.black
                              .withValues(alpha: 0.18 * raw.clamp(0.0, 1.0)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: mt,
                      left: _right ? null : 6 * t,
                      right: _right ? 6 * t : null,
                      width: w,
                      height: h,
                      child: _menuCapsule(t, raw, c.biggest, top),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _menuCapsule(double t, double raw, Size screen, double top) {
    final r = 22 + (_h / 2 - 22) * (1 - t);
    Widget option(int i, Widget icon, String title, String sub,
        VoidCallback onTap) {
      final a = ((raw - 0.35 - i * 0.12) / 0.45).clamp(0.0, 1.0);
      final e = Curves.easeOutCubic.transform(a);
      return Opacity(
        opacity: e,
        child: Transform.translate(
          offset: Offset((_right ? 14 : -14) * (1 - e), 0),
          child: _MenuOption(
            icon: icon,
            title: title,
            sub: sub,
            onTap: onTap,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14151B), Color(0xFF262833)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: _mint.withValues(alpha: 0.25 * t),
            blurRadius: 24,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        minWidth: 224,
        maxWidth: 224,
        minHeight: 150,
        maxHeight: 150,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: option(
                  0,
                  const KemoAvatar(size: 40, animate: false),
                  'Kemo AI',
                  'Ask anything',
                  () => _pick(false, screen, top),
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white.withValues(alpha: 0.08 * t),
              ),
              Expanded(
                child: option(
                  1,
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CustomPaint(
                      painter: _RingPainter(
                        IslandStats.eaten / IslandStats.budget,
                        color: _mint,
                        track: Colors.white.withValues(alpha: 0.14),
                        stroke: 4,
                      ),
                      child: const Icon(Icons.bar_chart_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  'Stats',
                  'Today at a glance',
                  () => _pick(true, screen, top),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({required bool dragging}) {
    final r = const Radius.circular(_h / 2);
    const edge = Radius.circular(10);
    final floating = dragging;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.25 + 0.2 * math.sin(_pulse.value * 2 * math.pi).abs();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF14151B), Color(0xFF23252E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: floating
                ? BorderRadius.all(r)
                : BorderRadius.horizontal(
                    left: _right ? r : edge,
                    right: _right ? edge : r,
                  ),
            boxShadow: [
              BoxShadow(
                color: _mint.withValues(alpha: glow),
                blurRadius: 18,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: _right ? TextDirection.ltr : TextDirection.rtl,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _RingPainter(
                IslandStats.eaten / IslandStats.budget,
                color: _mint,
                track: Colors.white.withValues(alpha: 0.12),
                stroke: 4,
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: KemoAvatar(size: 32, animate: false),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            _right ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: Colors.white54,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// iOS-style spring used when a sheet grows out of the island.
const Curve _iosSpring = Cubic(0.18, 1.12, 0.32, 1);

Widget _zoomFrom(Alignment origin, Animation<double> a, Widget child) {
  final fwd = a.status != AnimationStatus.reverse;
  final t = (fwd ? _iosSpring : Curves.easeInCubic).transform(a.value);
  return Opacity(
    opacity: Curves.easeOut.transform((a.value * 2.2).clamp(0.0, 1.0)),
    child: Transform.scale(
      scale: 0.2 + 0.8 * t,
      alignment: origin,
      child: child,
    ),
  );
}

/// Opens a page that zooms out of the island, like an iPhone app launch.
Route<void> iosZoomRoute(Widget page, Alignment origin) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 560),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => AnimatedBuilder(
        animation: a,
        builder: (_, c) => _zoomFrom(origin, a, c!),
        child: child,
      ),
    );

/// Grows the Today slider out of the island with a soft spring.
Future<void> showTodaySlider(BuildContext context,
    {Alignment origin = Alignment.topCenter}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 560),
    pageBuilder: (context, a, b) => const _TodaySlider(),
    transitionBuilder: (context, a, b, child) => AnimatedBuilder(
      animation: a,
      builder: (_, c) => _zoomFrom(origin, a, c!),
      child: child,
    ),
  );
}

class _TodaySlider extends StatefulWidget {
  const _TodaySlider();

  @override
  State<_TodaySlider> createState() => _TodaySliderState();
}

class _TodaySliderState extends State<_TodaySlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();
  double _pull = 0;

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _go(Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _reveal(int i, Widget child) {
    final a = CurvedAnimation(
      parent: _in,
      curve: Interval((0.08 * i).clamp(0.0, 0.7),
          (0.08 * i + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, c) => Opacity(
        opacity: a.value,
        child: Transform.translate(
            offset: Offset(0, 18 * (1 - a.value)), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final maxW = math.min(size.width, 520.0);
    return Align(
      alignment: Alignment.topCenter,
      child: Transform.translate(
        offset: Offset(0, -_pull),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: maxW,
            constraints: BoxConstraints(maxHeight: size.height * 0.9),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_teal, _tealDeep],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(34)),
              boxShadow: [
                BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 30,
                    offset: Offset(0, 12)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, pad.top + 12, 16, 8),
                    children: [
                      _reveal(0, _topBar()),
                      _reveal(1, _gauge()),
                      const SizedBox(height: 6),
                      _reveal(2, _foodExercise()),
                      const SizedBox(height: 12),
                      _reveal(3, _macros()),
                      const SizedBox(height: 12),
                      _reveal(4, _breakfast()),
                      const SizedBox(height: 18),
                      _reveal(5, _activity()),
                      const SizedBox(height: 18),
                      _reveal(6, _quickActions()),
                      const SizedBox(height: 18),
                      _reveal(7, _kemoTip()),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _handle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _handle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) =>
          setState(() => _pull = (_pull - d.delta.dy).clamp(0.0, 600.0)),
      onVerticalDragEnd: (d) {
        if (_pull > 80 || d.velocity.pixelsPerSecond.dy < -400) {
          Navigator.of(context).pop();
        } else {
          setState(() => _pull = 0);
        }
      },
      onTap: () => Navigator.of(context).pop(),
      child: SizedBox(
        height: 34,
        width: double.infinity,
        child: Center(
          child: Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _go(const KemoAiScreen()),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Center(child: KemoAvatar(size: 40)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: _f(18, w: FontWeight.w800)),
              Text('Your daily budget',
                  style: _f(12, w: FontWeight.w500, c: Colors.white70)),
            ],
          ),
        ),
        _glassBtn(Icons.close_rounded, () => Navigator.of(context).pop()),
      ],
    );
  }

  Widget _gauge() {
    return AspectRatio(
      aspectRatio: 1.75,
      child: AnimatedBuilder(
        animation: _in,
        builder: (context, _) {
          final t = Curves.easeOutCubic
              .transform(((_in.value - 0.1) / 0.7).clamp(0.0, 1.0));
          final left = (IslandStats.left * t).round();
          return CustomPaint(
            painter: _TickGaugePainter(
                (IslandStats.eaten / IslandStats.budget) * t),
            child: Align(
              alignment: const Alignment(0, 0.45),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(_fmt(left),
                          style: _f(62, w: FontWeight.w800, h: 1)),
                      const SizedBox(width: 4),
                      Text('kcal',
                          style: _f(16, w: FontWeight.w600, c: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('left of ${_fmt(IslandStats.budget)} kcal budget',
                      style: _f(13, w: FontWeight.w600, c: Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _foodExercise() {
    Widget card(String label, int value, String img, VoidCallback onTap) =>
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 112,
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                color: _tealCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label,
                              maxLines: 1,
                              style: _f(13,
                                  w: FontWeight.w600, c: Colors.white70)),
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_fmt(value),
                              style: _f(28, w: FontWeight.w800, h: 1)),
                        ),
                        Text('kcal',
                            style: _f(11,
                                w: FontWeight.w600, c: Colors.white60)),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(img, fit: BoxFit.cover, cacheWidth: 180),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        card('Food', IslandStats.eaten, 'assets/images/island/bowl.png',
            () => _go(DateNutritionDetailScreen(initialDate: DateTime.now()))),
        const SizedBox(width: 12),
        card('Exercise', IslandStats.burned,
            'assets/images/island/hero_runner.png',
            () => _go(const StepsScreen())),
      ],
    );
  }

  Widget _macros() {
    Widget macro(String label, int v, int goal, Color c) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 4,
                      height: 12,
                      decoration: BoxDecoration(
                          color: c, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(label,
                      style: _f(13, w: FontWeight.w700, c: _tealDeep)),
                ],
              ),
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                TextSpan(text: '$v', style: _f(22, w: FontWeight.w800, c: _ink)),
                TextSpan(
                    text: ' /${goal}g',
                    style: _f(11, w: FontWeight.w600, c: _tealDeep)),
              ])),
              const SizedBox(height: 10),
              SizedBox(
                height: 18,
                child: AnimatedBuilder(
                  animation: _in,
                  builder: (context, _) => CustomPaint(
                    size: const Size(double.infinity, 18),
                    painter: _StripeBarPainter(
                      (v / goal) *
                          Curves.easeOutCubic.transform(
                              ((_in.value - 0.25) / 0.6).clamp(0.0, 1.0)),
                      c,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_mint, Color(0xFF22D3B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          macro('Protein', 100, 140, const Color(0xFFFF7A1A)),
          const SizedBox(width: 18),
          macro('Carbs', 245, 350, const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _breakfast() {
    return GestureDetector(
      onTap: () => _go(const LogMealScreen(initialMealType: 'Breakfast')),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Breakfast',
                          style: _f(15, w: FontWeight.w700, c: _ink)),
                      const SizedBox(height: 2),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '420',
                            style: _f(30, w: FontWeight.w800, c: _ink)),
                        TextSpan(
                            text: ' kcal',
                            style: _f(12,
                                w: FontWeight.w600,
                                c: const Color(0xFF64748B))),
                      ])),
                    ],
                  ),
                ),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _DonutPainter(const [
                      (0.45, Color(0xFF22C55E)),
                      (0.3, Color(0xFFFACC15)),
                      (0.25, Color(0xFFE2E8F0)),
                    ]),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dot(const Color(0xFF22C55E), 'Protein 17g'),
                    const SizedBox(height: 6),
                    _dot(const Color(0xFFFACC15), 'Fiber 5g'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/island/meal_scan.png',
                        width: 44, height: 44, fit: BoxFit.cover, cacheWidth: 140),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Oats, berries & coffee',
                            style: _f(13, w: FontWeight.w700, c: _ink)),
                        Text('8:20 AM',
                            style: _f(11,
                                w: FontWeight.w500,
                                c: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_circle_rounded, color: _teal, size: 26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c, String t) => Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(t, style: _f(12, w: FontWeight.w600, c: _ink)),
        ],
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(t, style: _f(16, w: FontWeight.w800)),
      );

  Widget _activity() {
    Widget tile(String img, String value, String label, double p,
            {VoidCallback? onTap, Widget? action}) =>
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(img, width: 30, height: 30, cacheWidth: 100),
                      const Spacer(),
                      if (action != null) action,
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: _f(18, w: FontWeight.w800)),
                  ),
                  Text(label,
                      style: _f(11, w: FontWeight.w600, c: Colors.white70)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(_mint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Activity'),
        ValueListenableBuilder<int>(
          valueListenable: IslandStats.waterMl,
          builder: (context, ml, _) => Row(
            children: [
              tile('assets/images/island/shoe.png', _fmt(IslandStats.steps),
                  'Steps', IslandStats.steps / IslandStats.stepGoal,
                  onTap: () => _go(const StepsScreen())),
              const SizedBox(width: 10),
              tile('assets/images/island/bottle.png',
                  '${(ml / 1000).toStringAsFixed(2)} L', 'Water',
                  (ml / IslandStats.waterGoal).clamp(0.0, 1.0),
                  action: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      IslandStats.waterMl.value =
                          (ml + 250).clamp(0, IslandStats.waterGoal);
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                          color: _mint, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.add_rounded, size: 18, color: _ink),
                    ),
                  )),
              const SizedBox(width: 10),
              tile('assets/images/island/moon.png', '7h 32m', 'Sleep', 0.94),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActions() {
    Widget action(Widget icon, String label, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _f(11.5, w: FontWeight.w700)),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quick actions'),
        Row(
          children: [
            action(const KemoAvatar(size: 46, animate: false), 'Ask Kemo',
                () => _go(const KemoAiScreen())),
            action(const Icon(Icons.restaurant_rounded, color: _teal),
                'Log meal', () => _go(const LogMealScreen())),
            action(
                const Icon(Icons.fitness_center_rounded, color: _teal),
                'Workout',
                () => _go(const ActiveWorkoutScreen(
                    dayTitle: 'Upper Body Strength', dayNumber: 3))),
            action(const Icon(Icons.directions_walk_rounded, color: _teal),
                'Steps', () => _go(const StepsScreen())),
          ],
        ),
      ],
    );
  }

  Widget _kemoTip() {
    return GestureDetector(
      onTap: () => _go(const KemoAiScreen()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            const KemoAvatar(size: 56),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kemo says',
                      style: _f(12, w: FontWeight.w600, c: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(
                      'You have ${IslandStats.left} kcal left. A protein-rich dinner keeps you on track!',
                      style: _f(13, w: FontWeight.w700, h: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double stroke;
  _RingPainter(this.value,
      {required this.color, required this.track, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = track);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * value.clamp(0.0, 1.0),
        false, p..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

/// Radial tick marks over a wide arc, like a speedometer.
class _TickGaugePainter extends CustomPainter {
  final double value;
  _TickGaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.92);
    final outer = math.min(size.width * 0.46, size.height * 0.88);
    const ticks = 46;
    const start = math.pi * 1.08;
    const sweep = math.pi * 0.84;
    final active = (ticks * value).round();
    for (var i = 0; i <= ticks; i++) {
      final a = start + sweep * i / ticks;
      final long = i % 5 == 0;
      final len = long ? outer * 0.2 : outer * 0.12;
      final p1 = c + Offset(math.cos(a), math.sin(a)) * outer;
      final p2 = c + Offset(math.cos(a), math.sin(a)) * (outer - len);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = long ? 2.6 : 1.8
          ..strokeCap = StrokeCap.round
          ..color = i <= active
              ? Colors.white
              : Colors.white.withValues(alpha: 0.22),
      );
    }
    // marker triangle at the current value
    final a = start + sweep * value.clamp(0.0, 1.0);
    final tip = c + Offset(math.cos(a), math.sin(a)) * (outer * 0.74);
    final dir = Offset(math.cos(a), math.sin(a));
    final perp = Offset(-dir.dy, dir.dx);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((tip - dir * 9 + perp * 6).dx, (tip - dir * 9 + perp * 6).dy)
      ..lineTo((tip - dir * 9 - perp * 6).dx, (tip - dir * 9 - perp * 6).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TickGaugePainter old) => old.value != value;
}

/// A rounded progress bar whose empty part is diagonal stripes.
class _StripeBarPainter extends CustomPainter {
  final double value;
  final Color color;
  _StripeBarPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(size.height / 2));
    canvas.save();
    canvas.clipRRect(r);
    final stripe = Paint()
      ..color = const Color(0xFF0E7F72).withValues(alpha: 0.18)
      ..strokeWidth = 3;
    for (double x = -size.height; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
    final w = size.width * value.clamp(0.0, 1.0);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, size.height),
            Radius.circular(size.height / 2)),
        Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripeBarPainter old) => old.value != value;
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> parts;
  _DonutPainter(this.parts);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final r = (Offset.zero & size).deflate(stroke / 2);
    var a = -math.pi / 2;
    for (final (v, c) in parts) {
      final sweep = 2 * math.pi * v;
      canvas.drawArc(
          r,
          a + 0.08,
          sweep - 0.16,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = c);
      a += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MenuOption extends StatefulWidget {
  final Widget icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  State<_MenuOption> createState() => _MenuOptionState();
}

class _MenuOptionState extends State<_MenuOption> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _down ? 0.1 : 0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          child: Row(
            children: [
              SizedBox(width: 42, child: Center(child: widget.icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: _f(15, w: FontWeight.w700)),
                    Text(widget.sub,
                        style: _f(11.5,
                            w: FontWeight.w500, c: Colors.white60)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
