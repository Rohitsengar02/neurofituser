import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared building blocks for the sign-in screens and the questionnaire:
/// an animated aurora background, floating 3D objects, staggered reveals,
/// a snapping ruler picker and the primary call-to-action button.

class OnbColors {
  static const ink = Color(0xFF101418);
  static const body = Color(0xFF5B6472);
  static const muted = Color(0xFF94A0AE);
  static const line = Color(0xFFE6EAEE);
  static const base = Color(0xFFF7F8F4);
  static const green = Color(0xFF16A34A);
  static const lime = Color(0xFF84CC16);
}

TextStyle onbFont({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = OnbColors.ink,
  double? height,
  double? spacing,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

// -----------------------------------------------------------------------------
// Aurora background: soft coloured blobs that drift slowly behind the content.
// -----------------------------------------------------------------------------
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.colors,
    required this.child,
    this.base = OnbColors.base,
  });

  final List<Color> colors;
  final Color base;
  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: widget.base),
        RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            // Cross-fades colours when the palette changes (e.g. between steps).
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            key: ValueKey(widget.colors.hashCode),
            builder: (context, t, _) => AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _AuroraPainter(_c.value, widget.colors, t),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.colors, this.fadeIn);
  final double t;
  final double fadeIn;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    final r = size.shortestSide;
    final blobs = <(Offset, double, Color)>[
      (Offset(size.width * (0.12 + 0.08 * math.sin(a)), size.height * (0.10 + 0.05 * math.cos(a))), r * 0.75, colors[0]),
      (Offset(size.width * (0.92 + 0.06 * math.cos(a * 1.3)), size.height * (0.30 + 0.06 * math.sin(a))), r * 0.65, colors[1 % colors.length]),
      (Offset(size.width * (0.30 + 0.10 * math.cos(a * 0.7)), size.height * (0.95 + 0.04 * math.sin(a * 1.1))), r * 0.80, colors[2 % colors.length]),
    ];
    for (final (center, radius, color) in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: 0.30 * fadeIn),
          color.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.fadeIn != fadeIn || old.colors != colors;
}

// -----------------------------------------------------------------------------
// A rounded 3D-object tile that gently floats and tilts.
// -----------------------------------------------------------------------------
class FloatingTile extends StatefulWidget {
  const FloatingTile({
    super.key,
    required this.asset,
    this.size = 64,
    this.phase = 0,
    this.amplitude = 8,
    this.tilt = 0.08,
    this.radius,
    this.period = const Duration(milliseconds: 3600),
  });

  final String asset;
  final double size;
  final double phase;
  final double amplitude;
  final double tilt;
  final double? radius;
  final Duration period;

  @override
  State<FloatingTile> createState() => _FloatingTileState();
}

class _FloatingTileState extends State<FloatingTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? widget.size * 0.28;
    final tile = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: widget.size * 0.35,
            offset: Offset(0, widget.size * 0.16),
          ),
        ],
        image: DecorationImage(image: AssetImage(widget.asset), fit: BoxFit.cover),
      ),
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        child: tile,
        builder: (context, child) {
          final a = _c.value * 2 * math.pi + widget.phase;
          return Transform.translate(
            offset: Offset(math.cos(a) * widget.amplitude * 0.35, math.sin(a) * widget.amplitude),
            child: Transform.rotate(angle: math.sin(a + 0.6) * widget.tilt, child: child),
          );
        },
      ),
    );
  }
}

/// Small round icon "bubbles" that drift up slowly across the background.
class DriftingIcons extends StatefulWidget {
  const DriftingIcons({super.key, required this.icons, required this.color, this.count = 7});

  final List<IconData> icons;
  final Color color;
  final int count;

  @override
  State<DriftingIcons> createState() => _DriftingIconsState();
}

class _DriftingIconsState extends State<DriftingIcons> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, box) {
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final children = <Widget>[];
              for (var i = 0; i < widget.count; i++) {
                final seed = (i * 0.618) % 1.0;
                final progress = (_c.value + seed) % 1.0;
                final x = box.maxWidth * ((0.08 + seed * 0.84) + 0.03 * math.sin(progress * 6.28 + i));
                final y = box.maxHeight * (1.05 - progress * 1.15);
                final size = 30.0 + (i % 3) * 8;
                final fade = math.sin(progress * math.pi);
                children.add(Positioned(
                  left: x - size / 2,
                  top: y,
                  child: Opacity(
                    opacity: (0.55 * fade).clamp(0.0, 1.0),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.75),
                        border: Border.all(color: widget.color.withValues(alpha: 0.18)),
                      ),
                      child: Icon(widget.icons[i % widget.icons.length],
                          size: size * 0.5, color: widget.color.withValues(alpha: 0.65)),
                    ),
                  ),
                ));
              }
              return Stack(children: children);
            },
          );
        }),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Fade + slide reveal with a delay, replayed whenever the widget is recreated.
// -----------------------------------------------------------------------------
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.25),
    this.duration = const Duration(milliseconds: 520),
    this.scale = 1.0,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;
  final double scale;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final v = _curve.value;
        return Opacity(
          opacity: v,
          child: FractionalTranslation(
            translation: Offset(widget.offset.dx * (1 - v), widget.offset.dy * (1 - v)),
            child: Transform.scale(scale: widget.scale + (1 - widget.scale) * v, child: child),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Primary call-to-action: gradient pill with press-scale, shimmer and arrow.
// -----------------------------------------------------------------------------
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = OnbColors.ink,
    this.icon = Icons.arrow_forward_rounded,
    this.loading = false,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final bool loading;
  final double height;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shine =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  bool _down = false;

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final dark = Color.lerp(c, Colors.black, 0.28)!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              gradient: LinearGradient(colors: [c, dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(color: c.withValues(alpha: 0.38), blurRadius: 22, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _shine,
                    builder: (context, _) {
                      final x = -1.6 + _shine.value * 3.2;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(x - 0.5, -1),
                            end: Alignment(x + 0.5, 1),
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: widget.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  widget.label,
                                  key: ValueKey(widget.label),
                                  style: onbFont(size: 16, weight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                              if (widget.icon != null) ...[
                                const SizedBox(width: 10),
                                _NudgeIcon(icon: widget.icon!),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NudgeIcon extends StatefulWidget {
  const _NudgeIcon({required this.icon});
  final IconData icon;

  @override
  State<_NudgeIcon> createState() => _NudgeIconState();
}

class _NudgeIconState extends State<_NudgeIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(4 * Curves.easeInOut.transform(_c.value), 0),
        child: child,
      ),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: Icon(widget.icon, color: Colors.white, size: 17),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Horizontal snapping ruler. Drag, scroll wheel or tap +/- to change the value.
// -----------------------------------------------------------------------------
class SnapRuler extends StatefulWidget {
  const SnapRuler({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    required this.color,
    this.majorEvery = 10,
    this.labelFor,
    this.tickSpacing = 11,
  });

  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;
  final int majorEvery;
  final String Function(double value)? labelFor;
  final double tickSpacing;

  @override
  State<SnapRuler> createState() => _SnapRulerState();
}

class _SnapRulerState extends State<SnapRuler> {
  late ScrollController _controller;
  late int _index;
  bool _snapping = false;

  int get _count => ((widget.max - widget.min) / widget.step).round() + 1;
  int _indexOf(double v) => ((v - widget.min) / widget.step).round().clamp(0, _count - 1);

  @override
  void initState() {
    super.initState();
    _index = _indexOf(widget.value);
    _controller = ScrollController(initialScrollOffset: _index * widget.tickSpacing);
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(SnapRuler old) {
    super.didUpdateWidget(old);
    final target = _indexOf(widget.value);
    if (target != _index && _controller.hasClients) {
      _index = target;
      _controller.animateTo(target * widget.tickSpacing,
          duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final i = (_controller.offset / widget.tickSpacing).round().clamp(0, _count - 1);
    if (i != _index) {
      _index = i;
      HapticFeedback.selectionClick();
      widget.onChanged(widget.min + i * widget.step);
    }
  }

  void _snap() {
    if (_snapping || !_controller.hasClients) return;
    final target = _index * widget.tickSpacing;
    if ((target - _controller.offset).abs() < 0.5) return;
    _snapping = true;
    _controller
        .animateTo(target, duration: const Duration(milliseconds: 180), curve: Curves.easeOut)
        .whenComplete(() => _snapping = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: LayoutBuilder(builder: (context, box) {
        final pad = box.maxWidth / 2;
        return Stack(
          alignment: Alignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.18, 0.82, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _snap());
                  return false;
                },
                child: ScrollConfiguration(
                  behavior: const _DragEverywhere(),
                  child: SingleChildScrollView(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: pad * 2 + (_count - 1) * widget.tickSpacing,
                      height: 92,
                      child: CustomPaint(
                        painter: _RulerPainter(
                          count: _count,
                          spacing: widget.tickSpacing,
                          pad: pad,
                          majorEvery: widget.majorEvery,
                          label: (i) => widget.labelFor?.call(widget.min + i * widget.step) ??
                              (widget.min + i * widget.step).round().toString(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.arrow_drop_up_rounded, color: widget.color, size: 22),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DragEverywhere extends MaterialScrollBehavior {
  const _DragEverywhere();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.count,
    required this.spacing,
    required this.pad,
    required this.majorEvery,
    required this.label,
  });

  final int count;
  final double spacing;
  final double pad;
  final int majorEvery;
  final String Function(int i) label;

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = const Color(0xFFC9D1D9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final major = Paint()
      ..color = const Color(0xFF6B7684)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    const top = 8.0;
    for (var i = 0; i < count; i++) {
      final x = pad + i * spacing;
      final isMajor = i % majorEvery == 0;
      final isHalf = !isMajor && majorEvery % 2 == 0 && i % (majorEvery ~/ 2) == 0;
      final h = isMajor ? 40.0 : (isHalf ? 28.0 : 18.0);
      canvas.drawLine(Offset(x, top), Offset(x, top + h), isMajor ? major : minor);
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: label(i),
            style: onbFont(size: 12, weight: FontWeight.w600, color: const Color(0xFF8792A0)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, top + h + 10));
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.count != count || old.pad != pad || old.spacing != spacing;
}

/// Small round icon button used for +/- steppers and the back button.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.size = 44, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(side: BorderSide(color: OnbColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.45, color: color ?? OnbColors.ink),
        ),
      ),
    );
  }
}

/// Big animated number, e.g. "72.5 kg".
class BigValue extends StatelessWidget {
  const BigValue({super.key, required this.text, required this.unit, required this.color, this.size = 72});

  final String text;
  final String unit;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child),
          ),
          child: Text(
            text,
            key: ValueKey(text),
            style: onbFont(size: size, weight: FontWeight.w800, color: OnbColors.ink, spacing: -2.5, height: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(unit, style: onbFont(size: size * 0.3, weight: FontWeight.w700, color: color)),
      ],
    );
  }
}

/// A gradient-coloured word inside a headline.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style, required this.colors});

  final String text;
  final TextStyle style;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(colors: colors).createShader(Rect.fromLTWH(0, 0, r.width, r.height)),
      child: Text(text, style: style),
    );
  }
}
