import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Kemo, Neurofit's fluffy neon-green AI buddy. Everything is drawn in code
/// so he can blink, change expressions and walk without any image assets.

enum KemoEmotion { happy, excited, wink, love, surprised, thinking }

const _furLight = Color(0xFFB8FF3D);
const _furMid = Color(0xFF7CFF1A);
const _furDeep = Color(0xFF3DDC12);
const _furShadow = Color(0xFF26A80A);
const _plate = Color(0xFFF4FFEC);
const _plateShade = Color(0xFFDDF5CF);
const _ink = Color(0xFF14210C);
const _blush = Color(0xFFFF8FA3);

// ---------------------------------------------------------------------------
// Fur painting helpers
// ---------------------------------------------------------------------------

/// Paints a fluffy blob: a soft gradient fill, a soft brushed texture
/// inside and layers of tapered tufts around the edge so it reads as fluff.
void _paintFur(
  Canvas canvas,
  Path shape,
  int seed, {
  double density = 1.0,
  double strand = 1.0,
}) {
  final rnd = math.Random(seed);
  final b = shape.getBounds();
  final scale = b.shortestSide / 100;

  // Base fill with a top-left light
  canvas.drawPath(
    shape,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.45),
        radius: 1.0,
        colors: const [_furLight, _furMid, _furDeep, _furShadow],
        stops: const [0.0, 0.42, 0.8, 1.0],
      ).createShader(b),
  );

  const palette = [_furLight, _furMid, _furMid, Color(0xFF9BFF2E), _furDeep];
  final fill = Paint();
  final soft = Paint()
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.8 * scale);

  var blurTufts = false;

  // A tapered tuft: wide soft base, curved pointed tip.
  void tuft(Offset base, Offset dir, double len, double width, Color c) {
    final n = Offset(-dir.dy, dir.dx);
    final bend = (rnd.nextDouble() - 0.5) * 0.6;
    final tip = base + dir * len + n * len * bend * 0.5;
    final path = Path()
      ..moveTo(base.dx + n.dx * width, base.dy + n.dy * width)
      ..quadraticBezierTo(
        base.dx + dir.dx * len * 0.55 + n.dx * width * (0.8 + bend),
        base.dy + dir.dy * len * 0.55 + n.dy * width * (0.8 + bend),
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        base.dx + dir.dx * len * 0.55 - n.dx * width * (0.8 - bend),
        base.dy + dir.dy * len * 0.55 - n.dy * width * (0.8 - bend),
        base.dx - n.dx * width,
        base.dy - n.dy * width,
      )
      ..close();
    canvas.drawPath(path, (blurTufts ? soft : fill)..color = c);
  }

  Offset rotate(Offset v, double a) => Offset(
        v.dx * math.cos(a) - v.dy * math.sin(a),
        v.dx * math.sin(a) + v.dy * math.cos(a),
      );

  // Soft interior texture: small tufts brushed down and outward
  final interior = (b.width * b.height / (22 * scale * scale) * density)
      .clamp(50, 700)
      .toInt();
  for (var i = 0; i < interior; i++) {
    final x = b.left + rnd.nextDouble() * b.width;
    final y = b.top + rnd.nextDouble() * b.height;
    if (!shape.contains(Offset(x, y))) continue;
    final dx = (x - b.center.dx) / (b.width / 2);
    final ang = math.pi / 2 + dx * 0.8 + (rnd.nextDouble() - 0.5) * 0.8;
    final dir = Offset(math.cos(ang), math.sin(ang));
    final lift = ((b.bottom - y) / b.height).clamp(0.0, 1.0);
    final c = Color.lerp(palette[rnd.nextInt(palette.length)], _furLight,
            lift * 0.3)!
        .withValues(alpha: 0.25 + rnd.nextDouble() * 0.3);
    tuft(Offset(x, y), dir, (2.5 + rnd.nextDouble() * 3) * scale * strand,
        (1.2 + rnd.nextDouble() * 1.0) * scale, c);
  }

  // Fluffy edge: two layers of soft tufts poking out of the outline
  blurTufts = true;
  for (final layer in [0, 1]) {
    for (final metric in shape.computeMetrics()) {
      final steps =
          (metric.length / ((layer == 0 ? 2.2 : 3.0) * scale) * density)
              .clamp(40, 520);
      for (var i = 0; i < steps; i++) {
        final t = metric.getTangentForOffset(
            metric.length * (i + rnd.nextDouble() * 0.5) / steps);
        if (t == null) continue;
        final normal = Offset(t.vector.dy, -t.vector.dx);
        final out =
            shape.contains(t.position + normal * 2) ? -normal : normal;
        // Fur falls a little downward, like gravity
        final down = Offset(0, 0.35);
        var dir = out + down;
        dir = dir / dir.distance;
        dir = rotate(dir, (rnd.nextDouble() - 0.5) * 0.7);
        final inset = layer == 0 ? 4.5 : 2.0;
        final base = t.position - dir * (inset + rnd.nextDouble() * 2) * scale;
        final len = (layer == 0 ? 5.5 : 6.5) * (0.6 + rnd.nextDouble() * 0.6) *
            scale *
            strand;
        final c = layer == 0
            ? palette[rnd.nextInt(palette.length)]
            : (rnd.nextDouble() < 0.6 ? _furMid : _furDeep);
        tuft(base, dir, len, (2.0 + rnd.nextDouble() * 1.4) * scale,
            c.withValues(alpha: layer == 0 ? 0.95 : 0.85));
      }
    }
  }

  blurTufts = false;

  // Specular sheen on the upper-left
  canvas.save();
  canvas.clipPath(shape);
  final sheenC = Offset(b.left + b.width * 0.32, b.top + b.height * 0.22);
  canvas.drawCircle(
    sheenC,
    b.width * 0.35,
    Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withValues(alpha: 0.28),
        Colors.white.withValues(alpha: 0),
      ]).createShader(
          Rect.fromCircle(center: sheenC, radius: b.width * 0.35)),
  );
  canvas.restore();
}

/// Smooth face plate with a soft rim, and a few fur strands spilling over it.
void _paintPlate(Canvas canvas, Rect r, int seed) {
  final rr = RRect.fromRectAndRadius(r, Radius.elliptical(r.width / 2, r.height / 2.2));
  canvas.drawRRect(
    rr.inflate(r.width * 0.035),
    Paint()
      ..color = _furShadow.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.03),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.95,
        colors: const [Colors.white, _plate, _plateShade],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(r),
  );
  // Strands overlapping the rim so the plate sits inside the fur
  final rnd = math.Random(seed);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final scale = r.width / 60;
  for (var i = 0; i < 90; i++) {
    final a = rnd.nextDouble() * math.pi * 2;
    final edge = Offset(
      r.center.dx + math.cos(a) * r.width / 2,
      r.center.dy + math.sin(a) * r.height / 2,
    );
    final inward = (r.center - edge) / (r.center - edge).distance;
    final len = (1.5 + rnd.nextDouble() * 3.5) * scale;
    p
      ..color = (rnd.nextBool() ? _furMid : _furDeep)
          .withValues(alpha: 0.7 + rnd.nextDouble() * 0.3)
      ..strokeWidth = (0.5 + rnd.nextDouble() * 0.7) * scale;
    final start = edge - inward * len * 0.6;
    canvas.drawLine(start, start + inward * len, p);
  }
}

class _HeadFurPainter extends CustomPainter {
  const _HeadFurPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    final head = Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.86));
    _paintFur(canvas, head, 7, density: 1.2);
    _paintPlate(
      canvas,
      Rect.fromCenter(
        center: c + Offset(0, r * 0.06),
        width: r * 1.12,
        height: r * 0.92,
      ),
      11,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Face features (eyes, mouth, blush) for every emotion
// ---------------------------------------------------------------------------

class _FacePainter extends CustomPainter {
  final KemoEmotion emotion;
  final double blink; // 0 open .. 1 closed
  final Offset look; // -1..1 pupil offset
  final double talk; // 0..1 mouth open while talking

  _FacePainter({
    required this.emotion,
    required this.blink,
    required this.look,
    this.talk = 0,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final eyeY = h * 0.42;
    final eyeDx = w * 0.2;
    final eyeR = w * 0.075;
    final l = Offset(w / 2 - eyeDx, eyeY) + look * w * 0.03;
    final r = Offset(w / 2 + eyeDx, eyeY) + look * w * 0.03;
    final ink = Paint()..color = _ink;
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.035;

    // Blush
    final blushP = Paint()
      ..color = _blush.withValues(alpha: emotion == KemoEmotion.love ? 0.7 : 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.035);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.24, h * 0.6), width: w * 0.16, height: w * 0.09),
      blushP,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.76, h * 0.6), width: w * 0.16, height: w * 0.09),
      blushP,
    );

    void dotEye(Offset c, {double scale = 1}) {
      final open = (1 - blink).clamp(0.08, 1.0);
      final rect = Rect.fromCenter(
        center: c,
        width: eyeR * 2 * scale,
        height: eyeR * 2.3 * scale * open,
      );
      canvas.drawOval(rect, ink);
      if (open > 0.4) {
        canvas.drawCircle(
          c + Offset(-eyeR * 0.35, -eyeR * 0.45) * scale,
          eyeR * 0.32 * scale,
          Paint()..color = Colors.white,
        );
      }
    }

    void archEye(Offset c) {
      canvas.drawArc(
        Rect.fromCenter(center: c + Offset(0, eyeR * 0.5), width: eyeR * 2.6, height: eyeR * 2.4),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        stroke,
      );
    }

    void heartEye(Offset c) {
      final k = eyeR * 1.35;
      final path = Path()
        ..moveTo(c.dx, c.dy + k * 0.9)
        ..cubicTo(c.dx - k * 1.6, c.dy - k * 0.1, c.dx - k * 0.7, c.dy - k * 1.3,
            c.dx, c.dy - k * 0.45)
        ..cubicTo(c.dx + k * 0.7, c.dy - k * 1.3, c.dx + k * 1.6, c.dy - k * 0.1,
            c.dx, c.dy + k * 0.9);
      canvas.drawPath(path, Paint()..color = const Color(0xFFFF3B6B));
      canvas.drawCircle(c + Offset(-k * 0.45, -k * 0.45), k * 0.18,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    switch (emotion) {
      case KemoEmotion.happy:
        dotEye(l);
        dotEye(r);
        break;
      case KemoEmotion.excited:
        archEye(l);
        archEye(r);
        break;
      case KemoEmotion.wink:
        dotEye(l);
        archEye(r);
        break;
      case KemoEmotion.love:
        heartEye(l);
        heartEye(r);
        break;
      case KemoEmotion.surprised:
        dotEye(l, scale: 1.3);
        dotEye(r, scale: 1.3);
        break;
      case KemoEmotion.thinking:
        dotEye(l + Offset(w * 0.02, -h * 0.02));
        dotEye(r + Offset(w * 0.02, -h * 0.02));
        break;
    }

    // Mouth
    final m = Offset(w / 2, h * 0.62);
    switch (emotion) {
      case KemoEmotion.surprised:
        canvas.drawOval(
          Rect.fromCenter(center: m + Offset(0, h * 0.02), width: w * 0.09, height: w * 0.11),
          ink,
        );
        break;
      case KemoEmotion.excited:
      case KemoEmotion.love:
        final open = Path()
          ..moveTo(m.dx - w * 0.1, m.dy - h * 0.01)
          ..quadraticBezierTo(m.dx, m.dy + h * 0.13, m.dx + w * 0.1, m.dy - h * 0.01)
          ..close();
        canvas.drawPath(open, ink);
        canvas.drawOval(
          Rect.fromCenter(center: m + Offset(0, h * 0.055), width: w * 0.08, height: w * 0.04),
          Paint()..color = const Color(0xFFFF6B81),
        );
        break;
      case KemoEmotion.thinking:
        canvas.drawLine(m + Offset(-w * 0.05, h * 0.01), m + Offset(w * 0.05, -h * 0.01), stroke);
        break;
      default:
        if (talk > 0.05) {
          canvas.drawOval(
            Rect.fromCenter(center: m + Offset(0, h * 0.02), width: w * 0.12, height: w * 0.03 + w * 0.08 * talk),
            ink,
          );
        } else {
          canvas.drawArc(
            Rect.fromCenter(center: m, width: w * 0.16, height: h * 0.09),
            math.pi * 0.15,
            math.pi * 0.7,
            false,
            stroke,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter o) =>
      o.emotion != emotion || o.blink != blink || o.look != look || o.talk != talk;
}

/// Drives blinking, glancing around and (optionally) cycling expressions.
class _KemoLife {
  final TickerProvider vsync;
  final VoidCallback onChange;
  late final AnimationController blink;
  Timer? _blinkTimer;
  Timer? _emotionTimer;
  Timer? _lookTimer;
  Offset look = Offset.zero;
  int emotionIndex = 0;
  final _rnd = math.Random();

  static const cycle = [
    KemoEmotion.happy,
    KemoEmotion.excited,
    KemoEmotion.happy,
    KemoEmotion.wink,
    KemoEmotion.love,
    KemoEmotion.happy,
    KemoEmotion.surprised,
  ];

  _KemoLife(this.vsync, this.onChange, {bool cycleEmotions = true}) {
    blink = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 180),
    );
    _scheduleBlink();
    _lookTimer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      look = Offset(_rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 1.2 - 0.6);
      if (_rnd.nextDouble() < 0.35) look = Offset.zero;
      onChange();
    });
    if (cycleEmotions) {
      _emotionTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
        emotionIndex = (emotionIndex + 1) % cycle.length;
        onChange();
      });
    }
  }

  KemoEmotion get emotion => cycle[emotionIndex];

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 1800 + _rnd.nextInt(2600)),
      () async {
        try {
          await blink.forward();
          await blink.reverse();
          // Sometimes a quick double blink
          if (_rnd.nextDouble() < 0.25) {
            await blink.forward();
            await blink.reverse();
          }
        } catch (_) {}
        _scheduleBlink();
      },
    );
  }

  void dispose() {
    _blinkTimer?.cancel();
    _emotionTimer?.cancel();
    _lookTimer?.cancel();
    blink.dispose();
  }
}

// ---------------------------------------------------------------------------
// Public widgets
// ---------------------------------------------------------------------------

/// Circular Kemo face for headers and chat avatars. Blinks, glances around,
/// cycles through expressions forever and gently bobs.
class KemoFace extends StatefulWidget {
  final double size;
  final KemoEmotion? emotion; // fixed expression, or null to cycle
  final bool glow;
  final bool bob;
  final double talk;

  const KemoFace({
    super.key,
    this.size = 48,
    this.emotion,
    this.glow = true,
    this.bob = true,
    this.talk = 0,
  });

  @override
  State<KemoFace> createState() => _KemoFaceState();
}

class _KemoFaceState extends State<KemoFace> with TickerProviderStateMixin {
  late final _KemoLife _life;
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _life = _KemoLife(this, () {
      if (mounted) setState(() {});
    });
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _life.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final emotion = widget.emotion ?? _life.emotion;
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _life.blink]),
      builder: (context, _) {
        final b = widget.bob ? Curves.easeInOut.transform(_bob.value) : 0.5;
        return Transform.translate(
          offset: Offset(0, (b - 0.5) * s * 0.05),
          child: Transform.rotate(
            angle: (b - 0.5) * 0.08,
            child: Container(
              width: s,
              height: s,
              decoration: widget.glow
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _furMid.withValues(alpha: 0.55),
                          blurRadius: s * 0.3,
                          spreadRadius: s * 0.02,
                        ),
                      ],
                    )
                  : null,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _HeadFurPainter()),
                    ),
                  ),
                  Positioned(
                    left: s * 0.22,
                    right: s * 0.22,
                    top: s * 0.27,
                    bottom: s * 0.19,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.85, end: 1.0).animate(a),
                          child: c,
                        ),
                      ),
                      child: CustomPaint(
                        size: Size.infinite,
                        key: ValueKey(emotion),
                        painter: _FacePainter(
                          emotion: emotion,
                          blink: emotion == KemoEmotion.excited ||
                                  emotion == KemoEmotion.love
                              ? 0
                              : _life.blink.value,
                          look: _life.look,
                          talk: widget.talk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BodyFurPainter extends CustomPainter {
  const _BodyFurPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    // Hooded head flowing into a chubby body, one fluffy mass
    final head = Path()
      ..addOval(Rect.fromLTWH(w * 0.08, h * 0.03, w * 0.84, h * 0.6));
    final belly = Path()
      ..addOval(Rect.fromLTWH(w * 0.17, h * 0.4, w * 0.66, h * 0.58));
    final merged = Path.combine(ui.PathOperation.union, head, belly);
    _paintFur(canvas, merged, 21, density: 1.0, strand: 1.0);
    _paintPlate(
      canvas,
      Rect.fromLTWH(w * 0.22, h * 0.14, w * 0.56, h * 0.36),
      31,
    );
    // Lighter tummy patch
    final tummy = Rect.fromLTWH(w * 0.34, h * 0.62, w * 0.32, h * 0.26);
    canvas.drawOval(
      tummy,
      Paint()
        ..shader = RadialGradient(colors: [
          _furLight.withValues(alpha: 0.9),
          _furLight.withValues(alpha: 0),
        ]).createShader(tummy),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LimbPainter extends CustomPainter {
  final int seed;
  _LimbPainter(this.seed);

  @override
  void paint(Canvas canvas, Size s) {
    final shape = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & s,
        Radius.circular(s.shortestSide / 2),
      ));
    _paintFur(canvas, shape, seed, density: 1.4, strand: 0.8);
  }

  @override
  bool shouldRepaint(covariant _LimbPainter old) => false;
}

/// Full-body Kemo that walks on the spot, swings his arms, blinks and
/// changes expression. Set [walking] false for an idle sway.
class KemoBody extends StatefulWidget {
  final double height;
  final KemoEmotion? emotion;
  final bool walking;
  final double talk;

  const KemoBody({
    super.key,
    this.height = 220,
    this.emotion,
    this.walking = true,
    this.talk = 0,
  });

  @override
  State<KemoBody> createState() => _KemoBodyState();
}

class _KemoBodyState extends State<KemoBody> with TickerProviderStateMixin {
  late final _KemoLife _life;
  late final AnimationController _step;

  @override
  void initState() {
    super.initState();
    _life = _KemoLife(this, () {
      if (mounted) setState(() {});
    });
    _step = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _life.dispose();
    _step.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final w = h * 0.82;
    final emotion = widget.emotion ?? _life.emotion;
    final bodyH = h * 0.86;

    return AnimatedBuilder(
      animation: Listenable.merge([_step, _life.blink]),
      builder: (context, _) {
        final t = _step.value * math.pi * 2;
        final walk = widget.walking ? 1.0 : 0.25;
        final bob = -(math.sin(t * 2).abs()) * h * 0.025 * walk;
        final sway = math.sin(t) * 0.05 * walk;
        final legL = math.max(0.0, math.sin(t)) * h * 0.05 * walk;
        final legR = math.max(0.0, -math.sin(t)) * h * 0.05 * walk;
        final arm = math.sin(t) * 0.35 * walk;

        Widget limb(double lw, double lh, int seed) => SizedBox(
              width: lw,
              height: lh,
              child: RepaintBoundary(
                child: CustomPaint(painter: _LimbPainter(seed)),
              ),
            );

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Ground shadow
              Positioned(
                bottom: 0,
                left: w * 0.18,
                right: w * 0.18,
                child: Transform.scale(
                  scaleX: 1 + bob / h * 4,
                  child: Container(
                    height: h * 0.05,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(h),
                      gradient: RadialGradient(
                        colors: [
                          _furShadow.withValues(alpha: 0.35),
                          _furShadow.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Legs
              Positioned(
                bottom: h * 0.02 + legL,
                left: w * 0.3,
                child: limb(w * 0.17, h * 0.17, 41),
              ),
              Positioned(
                bottom: h * 0.02 + legR,
                right: w * 0.3,
                child: limb(w * 0.17, h * 0.17, 43),
              ),
              // Body + head + face
              Positioned(
                top: bob,
                child: Transform.rotate(
                  angle: sway,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: w,
                    height: bodyH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Arms behind the body edge
                        Positioned(
                          left: w * 0.06,
                          top: bodyH * 0.54,
                          child: Transform.rotate(
                            angle: 0.35 + arm,
                            alignment: Alignment.topCenter,
                            child: limb(w * 0.16, bodyH * 0.26, 51),
                          ),
                        ),
                        Positioned(
                          right: w * 0.06,
                          top: bodyH * 0.54,
                          child: Transform.rotate(
                            angle: -0.35 + arm,
                            alignment: Alignment.topCenter,
                            child: limb(w * 0.16, bodyH * 0.26, 53),
                          ),
                        ),
                        const Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(painter: _BodyFurPainter()),
                          ),
                        ),
                        Positioned(
                          left: w * 0.22,
                          top: bodyH * 0.14,
                          width: w * 0.56,
                          height: bodyH * 0.36,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: CustomPaint(
                              size: Size.infinite,
                              key: ValueKey(emotion),
                              painter: _FacePainter(
                                emotion: emotion,
                                blink: emotion == KemoEmotion.excited ||
                                        emotion == KemoEmotion.love
                                    ? 0
                                    : _life.blink.value,
                                look: _life.look,
                                talk: widget.talk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
