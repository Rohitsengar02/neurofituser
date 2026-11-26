part of '../overview_home_cards.dart';

// =====================================================================
//  FURRY BLOB + DOODLE BACKGROUND
// =====================================================================

/// Soft, furry-edged circles in pastel tints drift slowly around behind
/// the content, with faint hand-drawn doodles floating between them.
class FurBlobsBackdrop extends StatefulWidget {
  final int blobCount;
  final bool doodles;

  /// Food theme: blobs become furry fruit (stems, leaves, kiwi seeds, citrus
  /// segments) and the doodles become food sketches.
  final bool food;
  /// When set, the backdrop sits behind the scroll view (viewport sized)
  /// and follows this controller, so only what's on screen is painted.
  final ScrollController? scroll;
  const FurBlobsBackdrop({super.key, this.blobCount = 7, this.doodles = true, this.food = false, this.scroll});

  @override
  State<FurBlobsBackdrop> createState() => _FurBlobsBackdropState();
}

class _FurBlobsBackdropState extends State<FurBlobsBackdrop> {
  // The drift is very slow (one loop a minute), so 15 updates a second look
  // the same as 60 and leave the browser free for scrolling.
  final _t = ValueNotifier<double>(0);
  final _clock = Stopwatch();
  Timer? _timer;

  void _sync(bool still) {
    if (still) {
      _timer?.cancel();
      _timer = null;
      _clock.stop();
    } else if (_timer == null) {
      _clock.start();
      _timer = Timer.periodic(const Duration(milliseconds: 66), (_) {
        // Skip while another page covers the home screen.
        if (mounted && TickerMode.valuesOf(context).enabled) {
          _t.value = (_clock.elapsedMilliseconds / 60000) % 1.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce Motion: keep the blobs but stop them drifting.
    _sync(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FurPainter(_t, widget.blobCount, widget.doodles, widget.food, widget.scroll),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _FurPainter extends CustomPainter {
  final ValueListenable<double> t;
  final int count;
  final bool doodles;
  final bool food;
  final ScrollController? scroll;
  _FurPainter(this.t, this.count, this.doodles, this.food, this.scroll)
      : super(repaint: scroll == null ? t : Listenable.merge([t, scroll]));

  static const _foodTints = [
    Color(0xFFFDBA74), // orange
    Color(0xFFBEF264), // kiwi
    Color(0xFFFCA5A5), // apple
    Color(0xFFFDE68A), // lemon
    Color(0xFFC4B5FD), // berry
    Color(0xFF86EFAC), // avocado
    Color(0xFFF9A8D4), // watermelon
  ];

  static const _tints = [
    Color(0xFF86EFAC),
    Color(0xFFC4B5FD),
    Color(0xFFFDBA74),
    Color(0xFF93C5FD),
    Color(0xFFFDE68A),
    Color(0xFFF9A8D4),
    Color(0xFF5EEAD4),
  ];

  static final Map<String, ui.Image> _sprites = {};

  ui.Image _sprite(int i, double r, Color c, double ph) {
    final rq = (r / 8).round() * 8.0;
    final key = '$food-$i-${c.toARGB32()}-$rq';
    final hit = _sprites[key];
    if (hit != null) return hit;
    final side = (rq * 2 * 1.35).ceilToDouble();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final center = Offset(side / 2, side / 2);
    final rr = rq;
    final r2 = math.Random(i * 31 + 5);
      // Soft body.
      canvas.drawCircle(
        center,
        rr,
        Paint()
          ..shader = RadialGradient(
            colors: [
              c.withValues(alpha: 0.68),
              c.withValues(alpha: 0.42),
              c.withValues(alpha: 0),
            ],
            stops: const [0, 0.7, 1],
          ).createShader(Rect.fromCircle(center: center, radius: rr))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Fur: short soft strands around the rim, gently swaying.
      final fur = Paint()
        ..color = c.withValues(alpha: 0.6)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      final strands = 90;
      for (var k = 0; k < strands; k++) {
        final ang = k / strands * 2 * math.pi + r2.nextDouble() * 0.05;
        final sway = math.sin(k * 0.7 + ph) * 0.08;
        final len = rr * (0.1 + r2.nextDouble() * 0.12);
        final p0 = center + Offset(math.cos(ang), math.sin(ang)) * (rr * 0.78);
        final p1 =
            center +
            Offset(math.cos(ang + sway), math.sin(ang + sway)) *
                (rr * 0.78 + len);
        canvas.drawLine(p0, p1, fur);
      }
      if (food) _fruit(canvas, center, rr, i % 4, c, ph);
    final img = rec.endRecording().toImageSync(side.toInt(), side.toInt());
    _sprites[key] = img;
    return img;
  }

  @override
  void paint(Canvas canvas, Size size0) {
    var size = size0;
    final a = t.value * 2 * math.pi;
    final rnd = math.Random(7);
    final unit = math.min(size.width, 430.0);
    final view = size0;
    final sc = scroll;
    final hasPos = sc != null && sc.hasClients && sc.positions.length == 1 && sc.position.hasContentDimensions;
    final off = hasPos ? sc.offset : 0.0;
    // Paint in content coordinates, but only what's inside the viewport.
    if (hasPos) {
      size = Size(size.width, sc.position.maxScrollExtent + sc.position.viewportDimension);
    }
    canvas.save();
    canvas.clipRect(Offset.zero & view);
    canvas.translate(0, -off);
    final top = off - unit * 0.7, bottom = off + view.height + unit * 0.7;

    final total = math.max(count, (size.height / 290).ceil());
    for (var i = 0; i < total; i++) {
      final bx = i.isEven ? 0.1 + rnd.nextDouble() * 0.35 : 0.55 + rnd.nextDouble() * 0.35;
      final byPx = 40 + i * 290.0 + (rnd.nextDouble() - 0.5) * 120;
      final by = byPx / math.max(1, size.height);
      final r = unit * (0.24 + rnd.nextDouble() * 0.12);
      final f1 = 1 + rnd.nextInt(3), f2 = 1 + rnd.nextInt(2);
      final ph = rnd.nextDouble() * 6.28;
      final cx = bx * size.width + math.sin(a * f1 + ph) * unit * 0.16;
      final cy = by * size.height + math.cos(a * f2 + ph * 1.3) * unit * 0.18;
      final c = food ? _foodTints[i % _foodTints.length] : _tints[i % _tints.length];
      final center = Offset(cx, cy);
      final breathe = (1 + 0.06 * math.sin(a * 3 + ph)) * r / ((r / 8).round() * 8.0);
      if (cy < top || cy > bottom) continue;

      // Each blob is drawn once into a cached sprite; per frame it only
      // moves and breathes, which keeps the animated background cheap.
      final img = _sprite(i, r, c, ph);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(breathe);
      canvas.drawImage(img, Offset(-img.width / 2, -img.height / 2), Paint()..filterQuality = FilterQuality.low);
      canvas.restore();
    }

    if (!doodles) {
      canvas.restore();
      return;
    }
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF475569).withValues(alpha: 0.42);
    final n = (size.height / 150).clamp(8, 40).round();
    for (var i = 0; i < n; i++) {
      final bx = 0.08 + rnd.nextDouble() * 0.84;
      final by = (i + rnd.nextDouble()) / n;
      final ph = rnd.nextDouble() * 6.28;
      final pos = Offset(
        bx * size.width + math.sin(a * 2 + ph) * 18,
        by * size.height + math.cos(a * 2 + ph) * 22,
      );
      final dsz = 20 + rnd.nextDouble() * 12;
      if (pos.dy < top || pos.dy > bottom) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.sin(a + ph) * 0.6);
      ink.color = [
        const Color(0xFF16A34A),
        const Color(0xFF8B5CF6),
        const Color(0xFFF97316),
        const Color(0xFF3B82F6),
        const Color(0xFF475569),
      ][i % 5].withValues(alpha: 0.38);
      if (food) {
        _foodDoodle(canvas, i % 8, dsz, ink);
      } else {
        _doodle(canvas, i % 8, dsz - 2, ink);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  /// Fruit details on a fur blob: stem and leaf, kiwi seeds, berry shine or
  /// citrus segments, kept soft so they read through glass.
  void _fruit(Canvas canvas, Offset o, double r, int kind, Color c, double a) {
    final soft = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    switch (kind) {
      case 0: // apple / orange: stem and swaying leaf
        final top = o + Offset(0, -r * 0.8);
        canvas.drawLine(top, top + Offset(r * 0.04, -r * 0.22),
            Paint()
              ..color = const Color(0xFF92400E).withValues(alpha: 0.55)
              ..strokeWidth = r * 0.05
              ..strokeCap = StrokeCap.round);
        canvas.save();
        canvas.translate(top.dx + r * 0.05, top.dy - r * 0.16);
        canvas.rotate(-0.6 + 0.15 * math.sin(a * 2));
        canvas.drawOval(Rect.fromLTWH(0, -r * 0.07, r * 0.32, r * 0.14),
            soft..color = const Color(0xFF16A34A).withValues(alpha: 0.55));
        canvas.restore();
      case 1: // kiwi: pale core and seed ring
        canvas.drawCircle(o, r * 0.5, soft..color = Colors.white.withValues(alpha: 0.35));
        canvas.drawCircle(o, r * 0.16, soft..color = const Color(0xFFFEFCE8).withValues(alpha: 0.7));
        for (var k = 0; k < 14; k++) {
          final ang = k / 14 * 2 * math.pi;
          canvas.drawOval(
            Rect.fromCenter(center: o + Offset(math.cos(ang), math.sin(ang)) * r * 0.32, width: r * 0.05, height: r * 0.09),
            Paint()..color = const Color(0xFF1F2937).withValues(alpha: 0.4),
          );
        }
      case 2: // berry: glossy highlights
        for (final d in [const Offset(-0.3, -0.3), const Offset(0.25, -0.1), const Offset(-0.05, 0.3)]) {
          canvas.drawCircle(o + d * r, r * 0.08, soft..color = Colors.white.withValues(alpha: 0.55));
        }
      default: // citrus slice: segments
        canvas.drawCircle(o, r * 0.62, soft..color = Colors.white.withValues(alpha: 0.28));
        final seg = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = r * 0.03
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 8; k++) {
          final ang = k / 8 * 2 * math.pi + a * 0.1;
          canvas.drawLine(o, o + Offset(math.cos(ang), math.sin(ang)) * r * 0.6, seg);
        }
    }
  }

  void _foodDoodle(Canvas c, int kind, double s, Paint p) {
    switch (kind) {
      case 0: // apple
        final path = Path()
          ..moveTo(0, -s * 0.3)
          ..cubicTo(-s * 0.7, -s * 0.6, -s * 0.75, s * 0.5, 0, s * 0.5)
          ..cubicTo(s * 0.75, s * 0.5, s * 0.7, -s * 0.6, 0, -s * 0.3);
        c.drawPath(path, p);
        c.drawLine(Offset(0, -s * 0.3), Offset(s * 0.08, -s * 0.6), p);
      case 1: // carrot
        final path = Path()
          ..moveTo(-s * 0.18, -s * 0.3)
          ..lineTo(0, s * 0.6)
          ..lineTo(s * 0.18, -s * 0.3)
          ..close();
        c.drawPath(path, p);
        for (final dx in [-0.12, 0.0, 0.12]) {
          c.drawLine(Offset(dx * s, -s * 0.32), Offset(dx * s * 2, -s * 0.6), p);
        }
      case 2: // leaf
        final path = Path()
          ..moveTo(-s * 0.5, s * 0.3)
          ..quadraticBezierTo(-s * 0.4, -s * 0.5, s * 0.5, -s * 0.3)
          ..quadraticBezierTo(s * 0.3, s * 0.4, -s * 0.5, s * 0.3);
        c.drawPath(path, p);
        c.drawLine(Offset(-s * 0.5, s * 0.3), Offset(s * 0.2, -s * 0.15), p);
      case 3: // cherries
        c.drawCircle(Offset(-s * 0.25, s * 0.3), s * 0.18, p);
        c.drawCircle(Offset(s * 0.22, s * 0.35), s * 0.18, p);
        final path = Path()
          ..moveTo(-s * 0.25, s * 0.12)
          ..quadraticBezierTo(-s * 0.1, -s * 0.3, s * 0.1, -s * 0.5)
          ..moveTo(s * 0.22, s * 0.17)
          ..quadraticBezierTo(s * 0.2, -s * 0.2, s * 0.1, -s * 0.5);
        c.drawPath(path, p);
      case 4: // avocado
        final path = Path()
          ..moveTo(0, -s * 0.55)
          ..cubicTo(-s * 0.3, -s * 0.5, -s * 0.5, s * 0.5, 0, s * 0.5)
          ..cubicTo(s * 0.5, s * 0.5, s * 0.3, -s * 0.5, 0, -s * 0.55);
        c.drawPath(path, p);
        c.drawCircle(Offset(0, s * 0.18), s * 0.17, p);
      case 5: // fish
        final path = Path()
          ..moveTo(-s * 0.5, 0)
          ..quadraticBezierTo(0, -s * 0.4, s * 0.35, 0)
          ..quadraticBezierTo(0, s * 0.4, -s * 0.5, 0)
          ..moveTo(s * 0.35, 0)
          ..lineTo(s * 0.6, -s * 0.22)
          ..lineTo(s * 0.6, s * 0.22)
          ..close();
        c.drawPath(path, p);
      case 6: // egg
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.75, height: s), p);
      default: // fork
        c.drawLine(Offset(0, -s * 0.1), Offset(0, s * 0.6), p);
        for (final dx in [-0.15, -0.05, 0.05, 0.15]) {
          c.drawLine(Offset(dx * s, -s * 0.55), Offset(dx * s, -s * 0.15), p);
        }
        c.drawLine(Offset(-s * 0.15, -s * 0.15), Offset(s * 0.15, -s * 0.15), p);
    }
  }

  void _doodle(Canvas c, int kind, double s, Paint p) {
    switch (kind) {
      case 0: // squiggle
        final path = Path()..moveTo(-s, 0);
        for (var i = 0; i < 4; i++) {
          path.quadraticBezierTo(
            -s + s * 0.5 * (i * 2 + 1) / 2,
            i.isEven ? -s * 0.5 : s * 0.5,
            -s + s * 0.5 * (i + 1),
            0,
          );
        }
        c.drawPath(path, p);
      case 1: // sparkle
        for (var k = 0; k < 4; k++) {
          final ang = k * math.pi / 4;
          c.drawLine(
            Offset(math.cos(ang), math.sin(ang)) * -s * 0.6,
            Offset(math.cos(ang), math.sin(ang)) * s * 0.6,
            p,
          );
        }
      case 2: // ring
        c.drawCircle(Offset.zero, s * 0.55, p);
      case 3: // zigzag
        final path = Path()..moveTo(-s, s * 0.2);
        for (var i = 1; i <= 4; i++) {
          path.lineTo(-s + i * s * 0.5, i.isEven ? s * 0.2 : -s * 0.3);
        }
        c.drawPath(path, p);
      case 4: // plus
        c.drawLine(Offset(-s * 0.45, 0), Offset(s * 0.45, 0), p);
        c.drawLine(Offset(0, -s * 0.45), Offset(0, s * 0.45), p);
      case 5: // heart
        final path = Path()
          ..moveTo(0, s * 0.45)
          ..cubicTo(-s * 0.9, -s * 0.1, -s * 0.35, -s * 0.75, 0, -s * 0.25)
          ..cubicTo(s * 0.35, -s * 0.75, s * 0.9, -s * 0.1, 0, s * 0.45);
        c.drawPath(path, p);
      case 6: // dumbbell
        c.drawLine(Offset(-s * 0.5, 0), Offset(s * 0.5, 0), p);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(-s * 0.55, 0),
              width: s * 0.22,
              height: s * 0.6,
            ),
            const Radius.circular(2),
          ),
          p,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(s * 0.55, 0),
              width: s * 0.22,
              height: s * 0.6,
            ),
            const Radius.circular(2),
          ),
          p,
        );
      default: // spiral
        final path = Path();
        for (var i = 0; i <= 40; i++) {
          final ang = i / 40 * 4 * math.pi;
          final rr = s * 0.08 + s * 0.5 * i / 40;
          final o = Offset(math.cos(ang), math.sin(ang)) * rr;
          if (i == 0) {
            path.moveTo(o.dx, o.dy);
          } else {
            path.lineTo(o.dx, o.dy);
          }
        }
        c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _FurPainter o) => false;
}
