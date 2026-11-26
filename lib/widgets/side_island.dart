import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/active_workout_screen.dart';
import '../screens/date_nutrition_detail_screen.dart';
import '../screens/kemo_ai_screen.dart';
import '../screens/log_meal_screen.dart';
import '../screens/steps_screen.dart';
import 'island_panels.dart';
import 'kemo_avatar.dart';
import 'liquid_glass.dart';

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

/// A white liquid-glass dynamic island on the left or right edge. It cycles
/// through Kemo and today's stats one by one. Drag it anywhere and it snaps
/// to the nearest side. Tap it to reveal the menu button; tap that for the
/// full options list, each of which opens its own glass panel.
class SideIsland extends StatefulWidget {
  const SideIsland({super.key});

  @override
  State<SideIsland> createState() => _SideIslandState();
}

class _SideIslandState extends State<SideIsland> with TickerProviderStateMixin {
  static const double _w = 82;
  static const double _h = 64;
  static const _spring = Cubic(0.2, 1.25, 0.32, 1);

  bool _right = true;
  double _y = 0.42; // fraction of available height
  Offset? _drag; // live position while dragging
  bool _warm = false;
  int _slide = 0;
  Timer? _cycle;

  // Stage 1: the round menu button pops out beside the island.
  late final AnimationController _icon = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 240),
  );
  // Stage 2: the options list grows out of the island.
  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    reverseDuration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    _cycle = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (mounted && _drag == null) setState(() => _slide = (_slide + 1) % 5);
    });
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
    _cycle?.cancel();
    _icon.dispose();
    _menu.dispose();
    super.dispose();
  }

  void _tapIsland() {
    HapticFeedback.mediumImpact();
    if (_menu.value > 0) {
      _closeAll();
    } else if (_icon.value > 0) {
      _icon.reverse();
    } else {
      _icon.forward();
    }
  }

  void _openMenu() {
    HapticFeedback.mediumImpact();
    _menu.forward();
  }

  Future<void> _closeAll() async {
    await Future.wait([_menu.reverse(), _icon.reverse()]);
  }

  Alignment _origin(Size screen, double top) => Alignment(
        _right ? 1 : -1,
        ((top + _h / 2) / screen.height) * 2 - 1,
      );

  Future<void> _pick(int i, Size screen, double top) async {
    HapticFeedback.selectionClick();
    final origin = _origin(screen, top);
    await _closeAll();
    if (!mounted) return;
    final o = _options[i];
    if (o.$1 == null) {
      Navigator.of(context).push(iosZoomRoute(const KemoAiScreen(), origin));
    } else {
      showIslandPanel(context, o.$1!, origin: origin);
    }
  }

  // (panel or null for Kemo, title, subtitle, icon, colour)
  static const List<(IslandPanel?, String, String, IconData, Color)> _options = [
    (IslandPanel.stats, 'Stats', 'Today at a glance', Icons.bar_chart_rounded, Color(0xFF16A34A)),
    (null, 'Kemo AI', 'Ask anything', Icons.auto_awesome_rounded, Color(0xFF14B8A6)),
    (IslandPanel.water, 'Water', 'Log a glass', Icons.water_drop_rounded, Color(0xFF38BDF8)),
    (IslandPanel.steps, 'Steps', 'Walk & distance', Icons.directions_walk_rounded, Color(0xFFF97316)),
    (IslandPanel.meal, 'Log meal', 'Add food fast', Icons.restaurant_rounded, Color(0xFFEC4899)),
    (IslandPanel.breathe, 'Breathe', 'One-minute calm', Icons.air_rounded, Color(0xFF0D9488)),
    (IslandPanel.sleep, 'Sleep', 'Last night', Icons.bedtime_rounded, Color(0xFF6366F1)),
    (IslandPanel.mood, 'Mood', 'Quick check-in', Icons.emoji_emotions_rounded, Color(0xFFF59E0B)),
  ];

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
          // Tap-outside barrier while the button or menu is showing.
          AnimatedBuilder(
            animation: Listenable.merge([_icon, _menu]),
            builder: (context, _) {
              if (_icon.isDismissed && _menu.isDismissed) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeAll,
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.16 * _menu.value.clamp(0.0, 1.0))),
                ),
              );
            },
          ),
          AnimatedPositioned(
            duration: _drag != null ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            left: left,
            top: top,
            child: GestureDetector(
              onTap: _tapIsland,
              onPanStart: (_) {
                _closeAll();
                setState(() => _drag = Offset(left, top));
              },
              onPanUpdate: (d) => setState(() {
                final p = (_drag ?? Offset(left, top)) + d.delta;
                _drag = Offset(p.dx.clamp(0, c.maxWidth - _w), p.dy.clamp(minY, maxY));
              }),
              onPanEnd: (d) {
                final p = _drag ?? Offset(left, top);
                final vx = d.velocity.pixelsPerSecond.dx;
                HapticFeedback.selectionClick();
                setState(() {
                  _right = vx.abs() > 600 ? vx > 0 : p.dx + _w / 2 > c.maxWidth / 2;
                  _y = ((p.dy - minY) / (maxY - minY)).clamp(0.0, 1.0);
                  _drag = null;
                });
              },
              child: _pill(floating: _drag != null),
            ),
          ),
          // Stage 1: menu button beside the island.
          AnimatedBuilder(
            animation: Listenable.merge([_icon, _menu]),
            builder: (context, _) {
              if (_icon.isDismissed) return const SizedBox.shrink();
              final fwd = _icon.status != AnimationStatus.reverse;
              final t = (fwd ? _spring : Curves.easeInCubic).transform(_icon.value);
              final hide = 1 - _menu.value.clamp(0.0, 1.0);
              const s = 52.0;
              final dx = (_w + 10) * t;
              return Positioned(
                top: top + (_h - s) / 2,
                left: _right ? left - dx + _w - s : left + (_w - s) * (1 - t) + (_w + 10) * t,
                child: Opacity(
                  opacity: (_icon.value * hide).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * t,
                    child: Transform.rotate(
                      angle: (1 - t) * (_right ? -1.2 : 1.2),
                      child: LiquidGlass(
                        style: LiquidGlassStyle.regular,
                        shape: BoxShape.circle,
                        onTap: _openMenu,
                        child: const SizedBox(
                          width: s,
                          height: s,
                          child: Icon(Icons.apps_rounded, color: _ink, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Stage 2: options list.
          AnimatedBuilder(
            animation: _menu,
            builder: (context, _) {
              if (_menu.isDismissed) return const SizedBox.shrink();
              final fwd = _menu.status != AnimationStatus.reverse;
              final t = (fwd ? _spring : Curves.easeInCubic).transform(_menu.value);
              final mw = math.min(270.0, c.maxWidth - 32);
              final mh = math.min(430.0, c.maxHeight - pad.top - 140);
              final mt = (top + _h / 2 - mh / 2).clamp(pad.top + 8, c.maxHeight - mh - 100);
              final oy = ((top + _h / 2 - mt) / mh) * 2 - 1;
              return Positioned(
                top: mt,
                left: _right ? null : 10,
                right: _right ? 10 : null,
                width: mw,
                height: mh,
                child: Opacity(
                  opacity: Curves.easeOut.transform(_menu.value.clamp(0.0, 1.0)),
                  child: Transform.scale(
                    scale: 0.25 + 0.75 * t,
                    alignment: Alignment(_right ? 1 : -1, oy.clamp(-1.0, 1.0)),
                    child: _menuPanel(c.biggest, top),
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _menuPanel(Size screen, double top) {
    return Material(
      color: Colors.transparent,
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              const KemoAvatar(size: 38, animate: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi Rohit', style: _f(16, w: FontWeight.w800, c: _ink)),
                  Text('What do you need?', style: _f(11.5, w: FontWeight.w500, c: const Color(0xFF6B7280))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: _options.length,
              itemBuilder: (context, i) {
                final o = _options[i];
                final a = ((_menu.value - 0.2 - i * 0.07) / 0.5).clamp(0.0, 1.0);
                final e = Curves.easeOutCubic.transform(a);
                return Opacity(
                  opacity: e,
                  child: Transform.translate(
                    offset: Offset((_right ? 18 : -18) * (1 - e), 0),
                    child: _MenuOption(
                      icon: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [o.$5.withValues(alpha: 0.7), o.$5]),
                          boxShadow: [BoxShadow(color: o.$5.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: o.$1 == null
                            ? const Padding(padding: EdgeInsets.all(3), child: KemoAvatar(size: 32, animate: false))
                            : Icon(o.$4, color: Colors.white, size: 20),
                      ),
                      title: o.$2,
                      sub: o.$3,
                      onTap: () => _pick(i, screen, top),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _slideFor(int i) {
    Widget stat(double v, Color col, IconData ic, String label) => Column(
          key: ValueKey(i),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CustomPaint(
                painter: _RingPainter(v, color: col, track: col.withValues(alpha: 0.16), stroke: 3.5),
                child: Icon(ic, size: 15, color: col),
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: _f(11, w: FontWeight.w800, c: _ink)),
          ],
        );
    switch (i) {
      case 1:
        return stat(IslandStats.eaten / IslandStats.budget, const Color(0xFF16A34A), Icons.local_fire_department_rounded,
            '${IslandStats.left}');
      case 2:
        return stat(IslandStats.steps / IslandStats.stepGoal, const Color(0xFFF97316), Icons.directions_walk_rounded,
            '${(IslandStats.steps / 1000).toStringAsFixed(1)}k');
      case 3:
        return ValueListenableBuilder<int>(
          key: ValueKey(i),
          valueListenable: IslandStats.waterMl,
          builder: (_, ml, _) => stat(ml / IslandStats.waterGoal, const Color(0xFF38BDF8), Icons.water_drop_rounded,
              '${(ml / 1000).toStringAsFixed(1)}L'),
        );
      case 4:
        return stat(0.86, const Color(0xFF6366F1), Icons.bedtime_rounded, '7h12');
      default:
        return const KemoAvatar(key: ValueKey(0), size: 44, animate: false);
    }
  }

  Widget _pill({required bool floating}) {
    const r = Radius.circular(_h / 2);
    const edge = Radius.circular(14);
    return SizedBox(
      width: _w,
      height: _h,
      child: LiquidGlass(
        style: LiquidGlassStyle.regular,
        borderRadius: floating
            ? const BorderRadius.all(r)
            : BorderRadius.horizontal(left: _right ? r : edge, right: _right ? edge : r),
        child: Row(
          textDirection: _right ? TextDirection.ltr : TextDirection.rtl,
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 520),
                  switchInCurve: _spring,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (w, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(a),
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(a),
                        child: w,
                      ),
                    ),
                  ),
                  child: _slideFor(_slide),
                ),
              ),
            ),
            // Grab handle on the inner edge.
            Container(
              width: 4,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
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
        padding: const EdgeInsets.fromLTRB(6, 7, 8, 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: _down ? 0.05 : 0),
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
                    Text(widget.title, style: _f(15, w: FontWeight.w700, c: _ink)),
                    Text(widget.sub,
                        style: _f(11.5,
                            w: FontWeight.w500, c: const Color(0xFF6B7280))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.black26, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
