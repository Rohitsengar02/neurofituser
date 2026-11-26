import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A human figure that sits behind the Overview sections and transforms as
/// the user scrolls: body fat melts away and muscle builds up. It stays
/// centred in the viewport while its section is on screen, so the glass
/// cards above it blur a living silhouette.
class BodyMorphBackdrop extends StatefulWidget {
  final Widget child;
  const BodyMorphBackdrop({super.key, required this.child});

  @override
  State<BodyMorphBackdrop> createState() => _BodyMorphBackdropState();
}

class _Layout {
  final double t, top, bodyH;
  const _Layout(this.t, this.top, this.bodyH);
}

class _BodyMorphBackdropState extends State<BodyMorphBackdrop>
    with SingleTickerProviderStateMixin {
  final _layout = ValueNotifier(const _Layout(0, 0, 420));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  ScrollPosition? _pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _pos) {
      _pos?.removeListener(_update);
      _pos = pos?..addListener(_update);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final scrollable = Scrollable.maybeOf(context);
    final view = scrollable?.context.findRenderObject() as RenderBox?;
    if (box == null || view == null || !box.attached || !box.hasSize || !view.hasSize) return;
    final top = box.localToGlobal(Offset.zero, ancestor: view).dy;
    final vh = view.size.height;
    final h = box.size.height;
    final bodyH = math.min(vh * 0.62, 470.0);
    final span = math.max(1.0, h - vh * 0.45);
    final t = ((vh * 0.55 - top) / span).clamp(0.0, 1.0);
    final local = (vh / 2 - bodyH / 2 - top).clamp(0.0, math.max(0.0, h - bodyH)).toDouble();
    final cur = _layout.value;
    if ((cur.t - t).abs() > 0.001 || (cur.top - local).abs() > 0.5 || cur.bodyH != bodyH) {
      _layout.value = _Layout(t, local, bodyH);
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_update);
    _pulse.dispose();
    _layout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: ValueListenableBuilder<_Layout>(
                valueListenable: _layout,
                builder: (context, l, _) => Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: l.top,
                      height: l.bodyH,
                      child: _BodyStage(t: l.t, pulse: _pulse),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BodyStage extends StatelessWidget {
  final double t;
  final Animation<double> pulse;
  const _BodyStage({required this.t, required this.pulse});

  @override
  Widget build(BuildContext context) {
    // Ease so most of the change happens mid-scroll.
    final e = Curves.easeInOutCubic.transform(t);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow behind the figure shifts from warm (fat) to green (fit).
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.6,
                colors: [
                  Color.lerp(const Color(0xFFFFC9A3), const Color(0xFF9BEFC0), e)!
                      .withValues(alpha: 0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        AspectRatio(
          aspectRatio: 200 / 440,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, _) => CustomPaint(
              painter: _BodyPainter(muscle: e, fat: 1 - e, scan: pulse.value),
            ),
          ),
        ),
      ],
    );
  }
}

/// Front-view figure. [muscle] widens shoulders, chest and limbs and brings
/// out definition lines; [fat] widens waist, hips and thighs and adds a warm
/// belly glow. A scan line sweeps the body.
class _BodyPainter extends CustomPainter {
  final double muscle, fat, scan;
  _BodyPainter({required this.muscle, required this.fat, required this.scan});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 440);
    const cx = 100.0;
    final m = muscle, f = fat;
    final breathe = 1 + 0.012 * math.sin(scan * 2 * math.pi);

    // Body measurements (half widths).
    final neck = 8.5 + 3.5 * m;
    final sh = 43 + 15 * m + 2 * f;
    final chest = 36 + 9 * m + 6 * f;
    final waist = (25 + 19 * f + 2 * m) * breathe;
    final hip = 31 + 11 * f + 2 * m;

    final skin = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFFFFB27D), const Color(0xFF34D399), m)!,
          Color.lerp(const Color(0xFFF08A5D), const Color(0xFF0EA371), m)!,
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 200, 440));

    // Paint all parts into one layer so overlaps do not darken.
    canvas.saveLayer(const Rect.fromLTWH(-40, -20, 280, 480), Paint());

    // Torso via a smooth closed curve through mirrored points.
    final right = <Offset>[
      Offset(cx + neck, 60),
      Offset(cx + sh - 8, 80),
      Offset(cx + sh, 96),
      Offset(cx + chest, 130),
      Offset(cx + waist, 180),
      Offset(cx + hip, 216),
      Offset(cx + hip - 3, 244),
      Offset(cx + 6, 252),
    ];
    final pts = [
      ...right,
      ...right.reversed.map((o) => Offset(2 * cx - o.dx, o.dy)),
    ];
    canvas.drawPath(_smoothClosed(pts), skin);

    // Head and neck.
    canvas.drawOval(Rect.fromCenter(center: const Offset(cx, 36), width: 38, height: 46), skin);
    canvas.drawRect(Rect.fromLTRB(cx - neck, 52, cx + neck, 72), skin);

    // Arms.
    final upperR = 8.5 + 6 * m + 3 * f;
    final foreR = 6.5 + 3.5 * m + 1.5 * f;
    for (final s in [-1.0, 1.0]) {
      final shoulder = Offset(cx + s * (sh - 6), 96);
      final elbow = Offset(cx + s * (sh + 6 + 3 * f), 170);
      final wrist = Offset(cx + s * (sh + 8 + 2 * f), 240);
      _limb(canvas, shoulder, elbow, upperR + 2, upperR * 0.85, skin);
      _limb(canvas, elbow, wrist, foreR + 1, foreR * 0.7, skin);
      // Shoulder cap (deltoid) and biceps bulge grow with muscle.
      canvas.drawCircle(Offset(cx + s * (sh - 4), 98), 11 + 5 * m, skin);
      canvas.drawCircle(Offset.lerp(shoulder, elbow, 0.45)!, upperR + 2.5 * m, skin);
      canvas.drawOval(
          Rect.fromCenter(center: wrist + const Offset(0, 12), width: 13, height: 20), skin);
    }

    // Legs.
    final thighR = 14 + 7 * f + 4 * m;
    final calfR = 9 + 3 * m + 2 * f;
    for (final s in [-1.0, 1.0]) {
      final hipJ = Offset(cx + s * (hip - 15), 238);
      final knee = Offset(cx + s * (17 + 3 * f), 334);
      final ankle = Offset(cx + s * 16, 420);
      _limb(canvas, hipJ, knee, thighR + 3, thighR * 0.62, skin);
      _limb(canvas, knee, ankle, calfR, 5.5, skin);
      canvas.drawCircle(Offset.lerp(knee, ankle, 0.28)!, calfR + 1.5 * m, skin);
      canvas.drawOval(
          Rect.fromCenter(center: ankle + Offset(s * 5, 8), width: 22, height: 10), skin);
    }

    // Fat: warm glow on belly and hips.
    if (f > 0.02) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(cx, 190), width: waist * 2.1, height: 90),
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = RadialGradient(colors: [
            const Color(0xFFFF7A45).withValues(alpha: 0.55 * f),
            const Color(0xFFFF7A45).withValues(alpha: 0),
          ]).createShader(
              Rect.fromCenter(center: const Offset(cx, 190), width: waist * 2.1, height: 90)),
      );
    }

    // Muscle definition lines.
    if (m > 0.05) {
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6
        ..blendMode = BlendMode.srcATop
        ..color = Colors.white.withValues(alpha: 0.75 * m);
      // Pecs.
      for (final s in [-1.0, 1.0]) {
        final path = Path()
          ..moveTo(cx + s * 3, 108)
          ..quadraticBezierTo(cx + s * (chest * 0.55), 142, cx + s * (chest - 4), 116);
        canvas.drawPath(path, line);
      }
      // Centre line and abs.
      canvas.drawLine(const Offset(cx, 102), const Offset(cx, 214), line);
      for (var r = 0; r < 3; r++) {
        final y = 156.0 + r * 19;
        for (final s in [-1.0, 1.0]) {
          canvas.drawLine(Offset(cx + s * 4, y), Offset(cx + s * (12 + 3 * m), y - 2), line);
        }
      }
      // Obliques / V-line.
      for (final s in [-1.0, 1.0]) {
        canvas.drawLine(Offset(cx + s * (waist - 2), 200), Offset(cx + s * 8, 236), line);
      }
      // Quads.
      for (final s in [-1.0, 1.0]) {
        final path = Path()
          ..moveTo(cx + s * (hip - 20), 262)
          ..quadraticBezierTo(cx + s * (hip - 6), 300, cx + s * 20, 326);
        canvas.drawPath(path, line);
      }
    }

    // Scan line sweeping top to bottom.
    final y = 20 + 410 * scan;
    canvas.drawRect(
      Rect.fromLTWH(-10, y - 18, 220, 36),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(-10, y - 18, 220, 36))
        ..blendMode = BlendMode.srcATop,
    );
    canvas.drawLine(Offset(10, y), Offset(190, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..blendMode = BlendMode.srcATop
          ..strokeWidth = 0.8);
    canvas.restore(); // layer
    canvas.restore();
  }

  void _limb(Canvas canvas, Offset a, Offset b, double ra, double rb, Paint p) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final n = Offset(-d.dy / len, d.dx / len);
    final path = Path()
      ..moveTo(a.dx + n.dx * ra, a.dy + n.dy * ra)
      ..lineTo(b.dx + n.dx * rb, b.dy + n.dy * rb)
      ..lineTo(b.dx - n.dx * rb, b.dy - n.dy * rb)
      ..lineTo(a.dx - n.dx * ra, a.dy - n.dy * ra)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawCircle(a, ra, p);
    canvas.drawCircle(b, rb, p);
  }

  Path _smoothClosed(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _BodyPainter o) =>
      o.muscle != muscle || o.fat != fat || o.scan != scan;
}
