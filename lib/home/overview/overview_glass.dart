import '../../widgets/ticker_gate.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/date_nutrition_detail_screen.dart';
import '../../screens/log_meal_screen.dart';
import '../../screens/steps_screen.dart';
import '../../screens/streak_detail_screen.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/side_island.dart' show IslandStats;

part 'glass/your_progress.dart';
part 'glass/today_widgets.dart';
part 'glass/workout_timeline.dart';

// Apple-widget style palette: light glass on the app's green.
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _green = Color(0xFF16A34A);
const _lime = Color(0xFFB5E550);
const _orange = Color(0xFFFF8A3D);
const _purple = Color(0xFF7C6CF2);
const _blue = Color(0xFF3B82F6);
const _pink = Color(0xFFF06292);
const _amber = Color(0xFFF5A524);

const Curve _spring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle _t(double s, {FontWeight w = FontWeight.w600, Color c = _ink, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

/// Frosted glass panel: blurred backdrop, soft white fill, hairline border.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<Color>? tint;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final t = tint;
    return LiquidGlass(
      style: LiquidGlassStyle.material,
      borderRadius: BorderRadius.circular(radius),
      padding: padding,
      colors: t,
      child: child,
    );
  }
}

/// Springy press feedback, like tapping an iOS widget.
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, this.onTap});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? 0.955 : 1,
        duration: Duration(milliseconds: _down ? 120 : 420),
        curve: _down ? Curves.easeOut : _spring,
        child: widget.child,
      ),
    );
  }
}

/// Fades and springs a child up once, staggered by [order].
class _Rise extends StatelessWidget {
  final int order;
  final Widget child;
  const _Rise(this.order, this.child);

  @override
  Widget build(BuildContext context) =>
      ScrollReveal(delayMs: (order % 3) * 70, child: child);
}

class _Head extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onTap;
  const _Head(this.text, {this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(text, style: _t(19, w: FontWeight.w800, ls: -0.4)),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action!, style: _t(13, w: FontWeight.w700, c: _green)),
            ),
        ],
      ),
    );
  }
}

Widget _iconBubble(IconData i, Color c, {bool alert = false, Color? bg}) => Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg ?? Colors.white.withValues(alpha: 0.9),
            border: Border.all(color: c.withValues(alpha: 0.18)),
          ),
          child: Icon(i, size: 19, color: c),
        ),
        if (alert)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
              child: const Icon(Icons.priority_high_rounded, size: 11, color: Colors.white),
            ),
          ),
      ],
    );

Widget _arrowChip({bool dark = false}) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? _ink : Colors.white.withValues(alpha: 0.75),
      ),
      child: Icon(Icons.north_east_rounded, size: 16, color: dark ? Colors.white : _ink),
    );

// =====================================================================
//  OVERVIEW GLASS SECTIONS
// =====================================================================

/// Everything below the bento grid on Overview: the Your Progress widget
/// carousel and a stack of Apple-style glass widgets.
class OverviewGlassSections extends StatelessWidget {
  const OverviewGlassSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Soft colour blobs give the frosted glass something to blur.
        const Positioned.fill(child: _AmbientBlobs()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Head('Your Progress'),
            const ProgressWidgetCarousel(),
            const SizedBox(height: 28),
            const _Head('Today'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _Rise(0, _TodaysFoodWidget()),
                  SizedBox(height: 14),
                  _Rise(1, _NetEnergyWidget()),
                  SizedBox(height: 14),
                  _Rise(2, _RingsRow()),
                  SizedBox(height: 14),
                  _Rise(3, _EnergyHydrationRow()),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _Head('Workout Timeline',
                action: 'Streak',
                onTap: () => _push(context, const StreakDetailScreen())),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _Rise(4, _WorkoutTimelineWidget()),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmbientBlobs extends StatelessWidget {
  const _AmbientBlobs();

  @override
  Widget build(BuildContext context) {
    Widget blob(Color c, double s) => Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withValues(alpha: 0.55), c.withValues(alpha: 0)]),
          ),
        );
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -80, top: 20, child: blob(const Color(0xFFB9F5CF), 300)),
          Positioned(right: -90, top: 260, child: blob(const Color(0xFFE2DBFF), 320)),
          Positioned(left: -60, top: 640, child: blob(const Color(0xFFFFE1C7), 300)),
          Positioned(right: -70, top: 980, child: blob(const Color(0xFFCFE6FF), 320)),
        ],
      ),
    );
  }
}
