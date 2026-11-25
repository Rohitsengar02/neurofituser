import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../dashboard_motion.dart';

/// Shared building blocks for the redesigned dashboard tabs. Everything here
/// is light to draw: plain decorations, a few cached painters, and animations
/// that only run once (except the hero illustration's slow float).

const kInk = Color(0xFF0F172A);
const kMuted = Color(0xFF64748B);
const kLine = Color(0xFFE2E8F0);

TextStyle jakarta(
  double size,
  FontWeight w,
  Color c, {
  double? height,
  double spacing = 0,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: w,
  color: c,
  height: height,
  letterSpacing: spacing,
);

/// White card with a soft tinted shadow.
BoxDecoration softCard({Color tint = Colors.black, double radius = 24}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: tint.withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );

/// Big white hero card with a 3D illustration on the right, a headline on the
/// left, small info pills and a call to action.
class HeroIllustrationCard extends StatefulWidget {
  final String eyebrow;
  final String title;
  final String? highlight;
  final String illustration;
  final Color accent;
  final Color soft;
  final List<String> pills;
  final String cta;
  final VoidCallback onCta;
  final Widget? footer;

  const HeroIllustrationCard({
    super.key,
    required this.eyebrow,
    required this.title,
    this.highlight,
    required this.illustration,
    required this.accent,
    required this.soft,
    this.pills = const [],
    required this.cta,
    required this.onCta,
    this.footer,
  });

  @override
  State<HeroIllustrationCard> createState() => _HeroIllustrationCardState();
}

class _HeroIllustrationCardState extends State<HeroIllustrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: softCard(tint: w.accent, radius: 28),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final illoW = c.maxWidth * 0.56;
                return SizedBox(
                  height: (c.maxWidth * 0.5).clamp(184.0, 210.0),
                  child: Stack(
                    children: [
                      // soft colour wash behind the illustration
                      Positioned(
                        right: -c.maxWidth * 0.12,
                        top: -c.maxWidth * 0.1,
                        child: Container(
                          width: c.maxWidth * 0.75,
                          height: c.maxWidth * 0.75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [w.soft, w.soft.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        top: 6,
                        width: illoW,
                        child: AnimatedBuilder(
                          animation: _float,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              0,
                              -4 * Curves.easeInOut.transform(_float.value),
                            ),
                            child: child,
                          ),
                          child: RepaintBoundary(
                            child: Image.asset(
                              w.illustration,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomRight,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 18,
                        bottom: 16,
                        width: c.maxWidth - illoW + 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: w.soft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                w.eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(10.5, FontWeight.w800, w.accent),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: w.title),
                                  if (w.highlight != null)
                                    TextSpan(
                                      text: '\n${w.highlight}',
                                      style: TextStyle(color: w.accent),
                                    ),
                                ],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(
                                19,
                                FontWeight.w900,
                                kInk,
                                height: 1.15,
                                spacing: -0.5,
                              ),
                            ),

                            const Spacer(),
                            PressScale(
                              onTap: w.onCta,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  9,
                                  10,
                                  9,
                                ),
                                decoration: BoxDecoration(
                                  color: w.accent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: w.accent.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        w.cta,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: jakarta(
                                          12.5,
                                          FontWeight.w800,
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (w.pills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    for (var i = 0; i < w.pills.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              w.pills[i],
                              style: jakarta(11.5, FontWeight.w800, kInk),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (w.footer != null) w.footer!,
          ],
        ),
      ),
    );
  }
}

/// Section heading with an optional "See all" action.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Color accent;

  const SectionTitle(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.accent = kInk,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(17, FontWeight.w900, kInk, spacing: -0.4),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: jakarta(12.5, FontWeight.w800, accent),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thin rounded progress bar that fills once when first shown.
class GrowBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const GrowBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: color.withValues(alpha: 0.14)),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ring that sweeps to [value] once.
class GrowRing extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? center;

  const GrowRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 56,
    this.stroke = 6,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(v, color, stroke),
        child: SizedBox.square(dimension: size, child: child),
      ),
      child: Center(child: center),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  final double stroke;
  _RingPainter(this.v, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      s.width - stroke,
      s.height - stroke,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      p..color = color.withValues(alpha: 0.14),
    );
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v || o.color != color;
}

/// Small stat tile: emoji in a tinted bubble, value, label and a bar.
class StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String unit;
  final String label;
  final double progress;
  final Color color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.emoji,
    required this.value,
    this.unit = '',
    required this.label,
    required this.progress,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: softCard(tint: color, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 17)),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: jakarta(11, FontWeight.w800, color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: ' $unit',
                        style: jakarta(12, FontWeight.w700, kMuted),
                      ),
                  ],
                ),
                style: jakarta(20, FontWeight.w900, kInk, spacing: -0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(11.5, FontWeight.w700, kMuted),
            ),
            const SizedBox(height: 10),
            GrowBar(value: progress, color: color),
          ],
        ),
      ),
    );
  }
}

/// Two widgets side by side with a gap (keeps grids simple and responsive).
class Pair extends StatelessWidget {
  final Widget a;
  final Widget b;
  final double gap;
  const Pair(this.a, this.b, {super.key, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          SizedBox(width: gap),
          Expanded(child: b),
        ],
      ),
    );
  }
}

/// Square emoji badge with a two-tone gradient, for list rows.
class EmojiBadge extends StatelessWidget {
  final String emoji;
  final Color a;
  final Color b;
  final double size;
  const EmojiBadge(this.emoji, this.a, this.b, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a, b],
        ),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
    );
  }
}

/// Staggers a list of sections with [Reveal] and consistent spacing.
List<Widget> revealSections(List<Widget> sections, {double gap = 24}) {
  final out = <Widget>[];
  for (var i = 0; i < sections.length; i++) {
    if (i > 0) out.add(SizedBox(height: gap));
    out.add(
      Reveal(
        delay: Duration(milliseconds: i < 3 ? 70 * i : 0),
        child: sections[i],
      ),
    );
  }
  return out;
}

/// The 3D category icons have their name printed at the bottom; this shows
/// only the artwork.
class IconArt extends StatelessWidget {
  final String path;
  final double size;
  const IconArt(this.path, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.7,
          child: Image.asset(
            path,
            width: size / 0.8,
            height: size / 0.8,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
