import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'liquid_glass.dart';

// Shared building blocks for the Apple-style tabs (Wellness, Shop): text
// styles, section heads, glass cards, a scroll-triggered 0→1 builder and the
// word-by-word blur-in welcome title.

const akInk = Color(0xFF111827);
const akMuted = Color(0xFF6B7280);
const akFaint = Color(0xFF6E7681);
const akBlue = Color(0xFF3B82F6);
const Curve akSpring = Cubic(0.2, 1.18, 0.32, 1);

TextStyle akT(double s, {FontWeight w = FontWeight.w600, Color c = akInk, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

TextStyle akN(double s, {FontWeight w = FontWeight.w700, Color c = akInk, double? ls}) => GoogleFonts.inter(
      fontSize: s,
      fontWeight: w,
      color: c,
      letterSpacing: ls ?? -s * 0.035,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// Section title with an optional blue action on the right.
class AkHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? caption;
  const AkHead(this.title, {super.key, this.action, this.onAction, this.caption});

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: akT(20, w: FontWeight.w800, ls: -0.5)),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(caption!, style: akT(12.5, w: FontWeight.w600, c: akMuted)),
              ],
            ]),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: akT(13, w: FontWeight.w700, c: akBlue)),
            ),
        ]),
      ),
    );
  }
}

/// Liquid glass card with the usual 16 px page gutter.
class AkGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final List<Color>? colors;
  final bool gutter;
  const AkGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.onTap,
    this.colors,
    this.gutter = true,
  });

  @override
  Widget build(BuildContext context) {
    final g = LiquidGlass(
      style: LiquidGlassStyle.material,
      borderRadius: BorderRadius.circular(radius),
      padding: padding,
      onTap: onTap,
      colors: colors,
      child: child,
    );
    return gutter ? Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: g) : g;
  }
}

/// Builder with a 0→1 value that starts once the widget scrolls into view.
class AkSeen extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  final Duration duration;
  const AkSeen({super.key, required this.builder, this.duration = const Duration(milliseconds: 1500)});

  @override
  State<AkSeen> createState() => _AkSeenState();
}

class _AkSeenState extends State<AkSeen> with SingleTickerProviderStateMixin {
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

/// Caption plus a large title whose words blur in one by one; the last word
/// takes [accent].
class AkWelcome extends StatefulWidget {
  final String caption;
  final List<String> words;
  final Color accent;
  final String? subtitle;
  const AkWelcome({super.key, required this.caption, required this.words, required this.accent, this.subtitle});

  @override
  State<AkWelcome> createState() => _AkWelcomeState();
}

class _AkWelcomeState extends State<AkWelcome> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blurIn(int i, Widget w) {
    final a = CurvedAnimation(parent: _c, curve: Interval(0.06 * i, (0.5 + 0.08 * i).clamp(0.0, 1.0), curve: akSpring));
    return AnimatedBuilder(
      animation: a,
      child: w,
      builder: (_, c) {
        final o = a.value.clamp(0.0, 1.0);
        final b = (1 - o) * 10;
        Widget x = Transform.translate(offset: Offset(0, 22 * (1 - a.value)), child: c);
        if (b > 0.3) x = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: x);
        return Opacity(opacity: o, child: x);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _blurIn(0, Text(widget.caption, style: akT(11.5, w: FontWeight.w800, c: akFaint, ls: 1.4))),
        const SizedBox(height: 6),
        Wrap(spacing: 9, children: [
          for (var i = 0; i < words.length; i++)
            _blurIn(
              i + 1,
              Text(words[i],
                  style: akT(32, w: FontWeight.w800, ls: -1.1, h: 1.12, c: i == words.length - 1 ? widget.accent : akInk)),
            ),
        ]),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          _blurIn(words.length + 1, Text(widget.subtitle!, style: akT(14, w: FontWeight.w500, c: akMuted, h: 1.35))),
        ],
      ]),
    );
  }
}

/// Springy press-to-shrink wrapper with a selection haptic.
class AkPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const AkPress({super.key, required this.child, this.onTap, this.scale = 0.95});

  @override
  State<AkPress> createState() => _AkPressState();
}

class _AkPressState extends State<AkPress> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Duration(milliseconds: _down ? 100 : 420),
          curve: _down ? Curves.easeOut : akSpring,
          child: widget.child,
        ),
      );
}

/// Count-up number that starts when scrolled into view.
class AkCount extends StatelessWidget {
  final double value;
  final int decimals;
  final TextStyle style;
  final String suffix;
  const AkCount(this.value, {super.key, required this.style, this.decimals = 0, this.suffix = ''});

  @override
  Widget build(BuildContext context) => AkSeen(
        duration: const Duration(milliseconds: 1300),
        builder: (_, t) => Text('${(value * t).toStringAsFixed(decimals)}$suffix', style: style),
      );
}

/// Plain white page with a glass back button, a large title and a body.
class AkPage extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget body;
  final Color tint;
  const AkPage({super.key, required this.title, this.caption, required this.body, this.tint = akBlue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(children: [
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [tint.withValues(alpha: 0.28), tint.withValues(alpha: 0)]),
            ),
          ),
        ),
        SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                LiquidGlass(
                  style: LiquidGlassStyle.regular,
                  shape: BoxShape.circle,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: akInk),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (caption != null) Text(caption!.toUpperCase(), style: akT(11.5, w: FontWeight.w800, c: akFaint, ls: 1.3)),
                Text(title, style: akT(28, w: FontWeight.w800, ls: -0.9)),
              ]),
            ),
            Expanded(child: body),
          ]),
        ),
      ]),
    );
  }
}
