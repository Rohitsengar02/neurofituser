import '../../widgets/ticker_gate.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/log_meal_screen.dart';
import '../../screens/water_screen.dart';
import '../../services/hydration_store.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/side_island.dart' show IslandStats;

part 'sections/welcome_day_picker.dart';
part 'sections/calories_gauge.dart';
part 'sections/macros.dart';
part 'sections/meals.dart';
part 'sections/water.dart';
part 'sections/ai_scan.dart';
part 'sections/micronutrients.dart';
part 'sections/week.dart';
part 'sections/recipes.dart';
part 'sections/smart_swaps.dart';
part 'sections/fasting_window.dart';
part 'sections/supplements.dart';

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

  /// The tab's sections, built lazily by the home scroll view.
  static const List<Widget> sections = [
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
        ScrollReveal(child: TickerGate(child: _WaterCard())),
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
      ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
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

