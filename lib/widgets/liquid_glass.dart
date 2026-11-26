import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple-style Liquid Glass, approximated in Flutter following the HIG
/// translation notes: backdrop blur with a saturation boost, a translucent
/// fill, a light hairline rim that is brighter at the top, a soft specular
/// sheen, and (when [onTap] is set) a highlight that follows the finger
/// with a springy press.
///
/// [LiquidGlassStyle.clear] is for small floating controls (blur ~12, fill
/// ~30%); [LiquidGlassStyle.regular] for bars and text-heavy surfaces
/// (blur ~24, fill ~62%); [LiquidGlassStyle.material] is the thicker
/// content material for cards (blur ~28, fill ~72%) so text stays legible.
/// With Increase Contrast (MediaQuery.highContrast) it falls back to an
/// opaque surface, and with Reduce Motion the press/sheen animation is off.
enum LiquidGlassStyle { clear, regular, material }

class LiquidGlass extends StatefulWidget {
  /// Lite mode (on by default for web): card-style glass skips the live
  /// backdrop blur and uses a slightly denser frosted fill instead, and the
  /// remaining blurs drop the saturation pass. Live blur is the most
  /// expensive thing a browser can do per frame, so this keeps scrolling
  /// smooth while the look stays close.
  static bool lite = kIsWeb;

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final LiquidGlassStyle style;
  final Color? tint;
  final VoidCallback? onTap;
  final bool shadow;
  final BoxShape shape;

  /// Exact fill colours (top-left to bottom-right) for tinted glass such as
  /// a solid-colour widget; overrides the style's white fill.
  final List<Color>? colors;

  const LiquidGlass({
    this.colors,
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding,
    this.style = LiquidGlassStyle.regular,
    this.tint,
    this.onTap,
    this.shadow = true,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    reverseDuration: const Duration(milliseconds: 520),
  );
  Offset? _touch;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  static ImageFilter _filter(double sigma, double sat) {
    // Saturation matrix (Rec. 709 luma weights).
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final s = sat;
    final m = <double>[
      r * (1 - s) + s, g * (1 - s), b * (1 - s), 0, 0,
      r * (1 - s), g * (1 - s) + s, b * (1 - s), 0, 0,
      r * (1 - s), g * (1 - s), b * (1 - s) + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
    return ImageFilter.compose(
      outer: ColorFilter.matrix(m),
      inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.mirror),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final highContrast = mq?.highContrast ?? false;
    final reduceMotion = mq?.disableAnimations ?? false;

    final (sigma, fillTop, fillBottom) = switch (widget.style) {
      LiquidGlassStyle.clear => (12.0, 0.34, 0.18),
      LiquidGlassStyle.regular => (24.0, 0.66, 0.48),
      LiquidGlassStyle.material => (28.0, 0.76, 0.6),
    };
    final lite = LiquidGlass.lite;
    // In lite mode no surface samples the backdrop; fills get denser so the
    // frosted look holds without a live blur.
    final noBlur = lite;
    final (fTop, fBottom) = !noBlur
        ? (fillTop, fillBottom)
        : switch (widget.style) {
            LiquidGlassStyle.clear => (0.66, 0.5),
            LiquidGlassStyle.regular => (0.88, 0.76),
            LiquidGlassStyle.material => (0.86, 0.74),
          };
    final tint = widget.tint;
    final circle = widget.shape == BoxShape.circle;
    final radius = circle ? null : widget.borderRadius;

    Widget surface = AnimatedBuilder(
      animation: _press,
      child: widget.padding == null ? widget.child : Padding(padding: widget.padding!, child: widget.child),
      builder: (context, child) {
        final p = _press.value;
        return CustomPaint(
          foregroundPainter: _RimPainter(
            radius: radius,
            circle: circle,
            touch: _touch,
            press: reduceMotion ? 0 : p,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: radius,
              gradient: highContrast
                  ? null
                  : widget.colors != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.colors!,
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend((tint ?? Colors.white).withValues(alpha: tint == null ? 0 : 0.10),
                                Colors.white)
                            .withValues(alpha: fTop + 0.08 * p),
                        Color.alphaBlend((tint ?? Colors.white).withValues(alpha: tint == null ? 0 : 0.18),
                                Colors.white)
                            .withValues(alpha: fBottom + 0.08 * p),
                      ],
                    ),
              color: highContrast ? Colors.white : null,
              border: highContrast ? Border.all(color: const Color(0xFF475569), width: 1.2) : null,
            ),
            child: child,
          ),
        );
      },
    );

    if (noBlur) {
      surface = circle ? ClipOval(child: surface) : ClipRRect(borderRadius: radius!, child: surface);
    } else {
      final f = lite
          ? ImageFilter.blur(sigmaX: sigma * 0.6, sigmaY: sigma * 0.6, tileMode: TileMode.mirror)
          : _filter(sigma, 1.45);
      surface = circle
          ? ClipOval(child: BackdropFilter(filter: f, child: surface))
          : ClipRRect(borderRadius: radius!, child: BackdropFilter(filter: f, child: surface));
    }
    surface = RepaintBoundary(child: surface);

    if (widget.shadow) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius: radius,
          boxShadow: lite
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F2A1E).withValues(alpha: 0.09),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0F2A1E).withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F2A1E).withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: surface,
      );
    }

    if (widget.onTap == null) return surface;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        setState(() => _touch = d.localPosition);
        _press.forward();
      },
      onTapCancel: () => _press.reverse(),
      onTapUp: (_) {
        _press.reverse();
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: AnimatedBuilder(
        animation: _press,
        child: surface,
        builder: (_, c) {
          final p = reduceMotion ? 0.0 : _press.value;
          // Liquid squish: a touch wider than tall while pressed.
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1 - 0.025 * p, 1 - 0.04 * p, 1),
            child: c,
          );
        },
      ),
    );
  }
}

/// Bright top rim fading to a faint bottom rim, a soft specular sheen in the
/// upper third, and a glow at the touch point while pressed.
class _RimPainter extends CustomPainter {
  final BorderRadius? radius;
  final bool circle;
  final Offset? touch;
  final double press;
  _RimPainter({required this.radius, required this.circle, required this.touch, required this.press});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = circle
        ? RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2))
        : radius!.toRRect(rect);

    // Specular sheen.
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.45),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.38), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45)),
    );
    if (touch != null && press > 0.01) {
      final r = size.shortestSide * 0.9;
      canvas.drawCircle(
        touch!,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: 0.55 * press),
            Colors.white.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: touch!, radius: r)),
      );
    }
    canvas.restore();

    // Rim.
    canvas.drawRRect(
      rr.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.6),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RimPainter o) => o.press != press || o.touch != touch;
}

/// Springs a child up from a soft blur the first time it scrolls into view,
/// like iOS content settling into place. Honours Reduce Motion.
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const ScrollReveal({super.key, required this.child, this.delayMs = 0});

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 820));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: const Cubic(0.2, 1.15, 0.3, 1));
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
    if (!mounted || _c.isAnimating || _c.value > 0) return;
    final box = context.findRenderObject() as RenderBox?;
    final view = Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    if (view == null) {
      _start();
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: view).dy;
    if (top < view.size.height - 30) _start();
  }

  void _start() {
    _pos?.removeListener(_check);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, c) {
        final t = _a.value;
        final o = _c.value.clamp(0.0, 1.0);
        Widget w = Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: Transform.scale(scale: 0.94 + 0.06 * t, child: c),
        );
        final b = (1 - o) * 10;
        if (b > 0.3 && !LiquidGlass.lite) w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: w);
        return Opacity(opacity: Curves.easeOut.transform(o), child: w);
      },
    );
  }
}
