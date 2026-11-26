import '../../widgets/ticker_gate.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/social_screen.dart';
import '../../screens/steps_screen.dart';
import '../../screens/trainers_screen.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/side_island.dart' show IslandStats, iosZoomRoute;

part 'cards/dotted_line_chart.dart';
part 'cards/workout_streak_hero.dart';
part 'cards/nutrition.dart';
part 'cards/steps.dart';
part 'cards/top_trainers.dart';
part 'cards/community.dart';
part 'cards/detail_pages.dart';
part 'cards/fur_backdrop.dart';

// White, neumorphic Overview cards: a full-bleed workout streak hero, then
// Nutrition, Steps, Top trainers and Community. Each card zooms open into a
// bigger page with more detail.

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _faint = Color(0xFF6E7681); // secondary label, 4.6:1 on white
const _green = Color(0xFF16A34A);
const _mint = Color(0xFF22C55E);
const _orange = Color(0xFFFF7A3D);
const _blue = Color(0xFF3B82F6);
const _purple = Color(0xFF8B5CF6);
const _amber = Color(0xFFF59E0B);
const _pink = Color(0xFFEC4899);
const Curve _spring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle _t(
  double s, {
  FontWeight w = FontWeight.w600,
  Color c = _ink,
  double? h,
  double? ls,
}) => GoogleFonts.plusJakartaSans(
  fontSize: s,
  fontWeight: w,
  color: c,
  height: h,
  letterSpacing: ls,
);

/// Opens [page] with an iOS-style zoom growing out of the tapped widget.
void _openFrom(BuildContext context, Widget page) {
  final box = context.findRenderObject() as RenderBox?;
  final size = MediaQuery.of(context).size;
  var origin = Alignment.center;
  if (box != null && box.hasSize) {
    final c = box.localToGlobal(box.size.center(Offset.zero));
    origin = Alignment(
      (c.dx / size.width) * 2 - 1,
      (c.dy / size.height) * 2 - 1,
    );
  }
  Navigator.of(context).push(iosZoomRoute(page, origin));
}

// =====================================================================
//  PUBLIC SECTION
// =====================================================================

class OverviewHomeCards extends StatelessWidget {
  const OverviewHomeCards({super.key});

  /// The cards as separate sections, built lazily by the home scroll view.
  static const List<Widget> sections = [
    _Rise(0, StreakHeroCard()),
    SizedBox(height: 22),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(1, _NutritionCard())),
    SizedBox(height: 16),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(2, _StepsCard())),
    SizedBox(height: 16),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(3, _TrainersCard())),
    SizedBox(height: 16),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _Rise(4, _CommunityCard())),
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

/// Reveals a child with a spring when it scrolls into view.
class _Rise extends StatelessWidget {
  final int order;
  final Widget child;
  const _Rise(this.order, this.child);

  @override
  Widget build(BuildContext context) =>
      ScrollReveal(delayMs: (order % 3) * 70, child: child);
}


/// White card with soft neumorphic light/shadow and a springy press.
class _NeuCard extends StatefulWidget {
  final Widget child;
  final Widget Function()? page;
  final EdgeInsets padding;
  final bool glass;
  const _NeuCard({
    required this.child,
    this.page,
    this.padding = const EdgeInsets.all(18),
    this.glass = false,
  });

  @override
  State<_NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<_NeuCard> {
  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      style: LiquidGlassStyle.material,
      borderRadius: BorderRadius.circular(28),
      padding: widget.padding,
      onTap: widget.page == null ? null : () => _openFrom(context, widget.page!()),
      child: widget.child,
    );
  }
}

Widget _cardHead(String title, IconData icon, Color c, {String? trailing}) =>
    Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(15.5, w: FontWeight.w800, ls: -0.2),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: _t(12, w: FontWeight.w600, c: _faint),
          ),
        const SizedBox(width: 6),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF3F5F4),
          ),
          child: const Icon(Icons.north_east_rounded, size: 15, color: _ink),
        ),
      ],
    );

/// Counts a number up from zero once.
class _Count extends StatelessWidget {
  final double value;
  final TextStyle style;
  final int decimals;
  final String suffix;
  final bool group;
  const _Count(
    this.value,
    this.style, {
    this.decimals = 0,
    this.suffix = '',
    this.group = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) {
        var s = v.toStringAsFixed(decimals);
        if (group) s = _grouped(v.round());
        return Text('$s$suffix', style: style, maxLines: 1);
      },
    );
  }
}

String _grouped(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
