import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/kemo_ai_screen.dart';
import '../screens/streak_detail_screen.dart';

// Square health tiles for Overview, after the Neka / health-tech concepts:
// soft gradient squares, thin big numerals, dot-matrix counters and
// slow living line art. Each tile springs in with a blur-to-sharp reveal.

const Curve _spring = Cubic(0.2, 1.2, 0.32, 1);
const _lime = Color(0xFFD7F25B);

TextStyle _t(double s,
        {FontWeight w = FontWeight.w500, Color c = Colors.white, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

TextStyle _mono(double s, {Color c = Colors.white, double ls = 1.2}) =>
    GoogleFonts.spaceMono(fontSize: s, color: c, letterSpacing: ls, fontWeight: FontWeight.w400);

class HealthTilesGrid extends StatefulWidget {
  const HealthTilesGrid({super.key});

  @override
  State<HealthTilesGrid> createState() => _HealthTilesGridState();
}

class _HealthTilesGridState extends State<HealthTilesGrid> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  bool _training = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _in.forward();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  Animation<double> _stage(int i) => CurvedAnimation(
        parent: _in,
        curve: Interval((i * 0.09).clamp(0.0, 0.6), (i * 0.09 + 0.42).clamp(0.0, 1.0),
            curve: _spring),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        const g = 12.0;
        final s = (w - g) / 2;
        final toggleH = (s * 0.36).clamp(54.0, 70.0);
        return Column(
          children: [
            Row(children: [
              _Reveal(_stage(0), _OxygenTile(size: s, loop: _loop, count: _stage(0))),
              const SizedBox(width: g),
              _Reveal(
                _stage(1),
                _InsightsTile(
                  size: s,
                  loop: _loop,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const KemoAiScreen())),
                ),
              ),
            ]),
            const SizedBox(height: g),
            _Reveal(_stage(2), _HeartAgeTile(width: w, height: s * 0.98, loop: _loop, count: _stage(2))),
            const SizedBox(height: g),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Reveal(
                _stage(3),
                _StreakTile(
                  size: s,
                  loop: _loop,
                  count: _stage(3),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const StreakDetailScreen())),
                ),
              ),
              const SizedBox(width: g),
              SizedBox(
                width: s,
                child: Column(children: [
                  _Reveal(
                    _stage(4),
                    _TrainingTile(
                      width: s,
                      height: toggleH,
                      on: _training,
                      onTap: () => setState(() => _training = !_training),
                    ),
                  ),
                  const SizedBox(height: g),
                  _Reveal(
                    _stage(5),
                    _BreathTile(width: s, height: s - toggleH - g, loop: _loop, count: _stage(5)),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: g),
            Row(children: [
              _Reveal(_stage(6),
                  _VolumeTile(size: s, title: 'LEGS', when: 'TODAY · 5 SESSIONS', value: 290.9, delta: '+35% VS AVG.', up: true, count: _stage(6))),
              const SizedBox(width: g),
              _Reveal(_stage(7),
                  _VolumeTile(size: s, title: 'ARMS', when: '6 DAYS AGO · 3 SESSIONS', value: 42.1, delta: '±2% VS AVG.', up: false, count: _stage(7))),
            ]),
          ],
        );
      }),
    );
  }
}

/// Springs a tile up from a blurred, slightly shrunken state.
class _Reveal extends StatelessWidget {
  final Animation<double> a;
  final Widget child;
  const _Reveal(this.a, this.child);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, c) {
        final t = a.value;
        final o = t.clamp(0.0, 1.0);
        Widget w = Transform.translate(
          offset: Offset(0, 46 * (1 - t)),
          child: Transform.scale(scale: 0.86 + 0.14 * t, child: c),
        );
        final b = (1 - o) * 12;
        if (b > 0.2) w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: w);
        return Opacity(opacity: o, child: w);
      },
    );
  }
}

/// Rounded gradient square with springy press.
class _Tile extends StatefulWidget {
  final double width, height;
  final Gradient gradient;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  const _Tile({
    required this.width,
    required this.height,
    required this.gradient,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
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
        scale: _down ? 0.95 : 1,
        duration: Duration(milliseconds: _down ? 110 : 450),
        curve: _down ? Curves.easeOut : _spring,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- tiles --

class _OxygenTile extends StatelessWidget {
  final double size;
  final Animation<double> loop, count;
  const _OxygenTile({required this.size, required this.loop, required this.count});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      width: size,
      height: size,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD9D3C7), Color(0xFFE6B567), Color(0xFFF0A93A)],
        stops: [0, 0.55, 1],
      ),
      padding: EdgeInsets.zero,
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(painter: _WavesPainter(loop)),
        ),
        Positioned(
          left: 14,
          top: 14,
          right: 14,
          child: Row(children: [
            Expanded(
              child: Text('Blood Oxygen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12.5, c: Colors.white.withValues(alpha: 0.85))),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop_outlined, size: 14, color: Colors.white),
            ),
          ]),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AnimatedBuilder(
              animation: count,
              builder: (_, __) => Text('${(99 * count.value.clamp(0.0, 1.0)).round()}',
                  style: _t(34, w: FontWeight.w300, h: 1, ls: -1)),
            ),
            const Spacer(),
            Text('Normal', style: _t(13, w: FontWeight.w400)),
          ]),
        ),
      ]),
    );
  }
}

class _WavesPainter extends CustomPainter {
  final Animation<double> loop;
  _WavesPainter(this.loop) : super(repaint: loop);

  @override
  void paint(Canvas canvas, Size size) {
    final ph = loop.value * 2 * math.pi;
    final cy = size.height * 0.5;
    final amp = size.height * 0.15;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    Offset? dot;
    for (var k = 0; k < 5; k++) {
      final path = Path();
      for (var i = 0; i <= 60; i++) {
        final x = size.width * 0.06 + (size.width * 0.88) * i / 60;
        final u = i / 60 * 2 * math.pi * 1.5;
        final y = cy + math.sin(u + ph + k * 0.7) * amp * (0.55 + 0.45 * math.cos(u * 0.5 + k));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        if (k == 2 && i == 46) dot = Offset(x, y);
      }
      canvas.drawPath(path, p..color = Colors.white.withValues(alpha: 0.32 + 0.1 * k));
    }
    if (dot != null) {
      canvas.drawCircle(dot, 9, Paint()..color = _lime.withValues(alpha: 0.25));
      canvas.drawCircle(dot, 4, Paint()..color = _lime);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => false;
}

class _InsightsTile extends StatelessWidget {
  final double size;
  final Animation<double> loop;
  final VoidCallback onTap;
  const _InsightsTile({required this.size, required this.loop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      width: size,
      height: size,
      onTap: onTap,
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFF1EFE9), Color(0xFFEDF3D2), Color(0xFFE3F0A6)],
      ),
      child: Stack(children: [
        // Soft out-of-focus figure, slowly breathing.
        Positioned(
          right: -size * 0.12,
          top: size * 0.02,
          width: size * 0.9,
          height: size * 0.9,
          child: AnimatedBuilder(
            animation: loop,
            builder: (_, c) => Transform.scale(
              scale: 1 + 0.03 * math.sin(loop.value * 2 * math.pi * 2),
              child: c,
            ),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: CustomPaint(painter: _SilhouettePainter()),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.white.withValues(alpha: 0.35),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF4A4A3F)),
                  const SizedBox(width: 4),
                  Text('5 min', style: _t(12, c: const Color(0xFF4A4A3F))),
                ]),
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 12,
          bottom: 14,
          child: Text('Heart, Body, Skin\nData: Insights',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _t(13.5, w: FontWeight.w500, c: const Color(0xFF55603A), h: 1.25)),
        ),
      ]),
    );
  }
}

/// Soft out-of-focus head-and-shoulders shape for the insights tile.
class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF2E2D24).withValues(alpha: 0.75), const Color(0xFF2E2D24).withValues(alpha: 0.1)],
      ).createShader(Offset.zero & size);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.52, h * 0.24), width: w * 0.3, height: h * 0.36), p);
    final body = Path()
      ..moveTo(w * 0.44, h * 0.38)
      ..quadraticBezierTo(w * 0.1, h * 0.46, w * 0.05, h * 1.05)
      ..lineTo(w * 1.0, h * 1.05)
      ..quadraticBezierTo(w * 0.95, h * 0.46, w * 0.6, h * 0.38)
      ..close();
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HeartAgeTile extends StatelessWidget {
  final double width, height;
  final Animation<double> loop, count;
  const _HeartAgeTile(
      {required this.width, required this.height, required this.loop, required this.count});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      width: width,
      height: height,
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3E8E4A), Color(0xFF6DAA5C), Color(0xFFB4CF8E)],
        stops: [0, 0.5, 1],
      ),
      child: Stack(children: [
        Positioned(
          right: -width * 0.04,
          bottom: -height * 0.12,
          width: width * 0.58,
          height: height * 0.62,
          child: CustomPaint(painter: _CoilPainter(loop)),
        ),
        Positioned(
          left: 18,
          top: 16,
          right: 16,
          child: Row(children: [
            Text('Heart Age', style: _t(14, c: Colors.white.withValues(alpha: 0.9))),
            const Spacer(),
            Text('Dates ', style: _t(12.5, w: FontWeight.w400, c: Colors.white.withValues(alpha: 0.7))),
            Text('2026', style: _t(13, c: Colors.white)),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
          ]),
        ),
        Positioned(
          left: 18,
          top: height * 0.34,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedBuilder(
              animation: count,
              builder: (_, __) => Text('${(25 * count.value.clamp(0.0, 1.0)).round()}',
                  style: _t(54, w: FontWeight.w300, h: 1, ls: -2)),
            ),
            Text('years', style: _t(14, w: FontWeight.w400, c: Colors.white.withValues(alpha: 0.85))),
          ]),
        ),
        Positioned(
          right: 18,
          top: height * 0.22,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('-6', style: _t(22, w: FontWeight.w400, h: 1)),
            const SizedBox(width: 3),
            Text('years', style: _t(12.5, w: FontWeight.w400, c: Colors.white.withValues(alpha: 0.8))),
          ]),
        ),
      ]),
    );
  }
}

/// Two wire-frame lobes that slowly turn, meeting at a lime point.
class _CoilPainter extends CustomPainter {
  final Animation<double> loop;
  _CoilPainter(this.loop) : super(repaint: loop);

  @override
  void paint(Canvas canvas, Size size) {
    final ph = loop.value * 2 * math.pi;
    final cy = size.height * 0.58;
    final r = math.min(size.width * 0.25, size.height * 0.4);
    final mid = Offset(size.width * 0.5, cy);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (final side in [-1.0, 1.0]) {
      final cx = mid.dx + side * r;
      for (var i = 0; i < 16; i++) {
        final a = ph * side + i / 16 * math.pi;
        final rx = (r * math.cos(a)).abs();
        final depth = 0.5 + 0.5 * math.sin(a);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + side * 0, cy), width: rx * 2 + 0.5, height: r * 2),
          p..color = Colors.white.withValues(alpha: 0.12 + 0.3 * depth),
        );
      }
    }
    canvas.drawCircle(mid, 10, Paint()..color = _lime.withValues(alpha: 0.25));
    canvas.drawCircle(mid, 4.5, Paint()..color = _lime);
  }

  @override
  bool shouldRepaint(covariant _CoilPainter old) => false;
}

class _StreakTile extends StatelessWidget {
  final double size;
  final Animation<double> loop, count;
  final VoidCallback onTap;
  const _StreakTile(
      {required this.size, required this.loop, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      width: size,
      height: size,
      onTap: onTap,
      padding: EdgeInsets.zero,
      gradient: const RadialGradient(
        center: Alignment(-0.4, -0.6),
        radius: 1.3,
        colors: [Color(0xFF1B1B1E), Color(0xFF0B0B0D), Color(0xFF2A2A2F)],
        stops: [0, 0.6, 1],
      ),
      child: Stack(children: [
        Positioned(
          left: 16,
          top: 16,
          child: Text('Daily Streak', style: _t(13.5, c: Colors.white.withValues(alpha: 0.92))),
        ),
        Positioned(
          left: 16,
          right: 12,
          bottom: size * 0.24,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedBuilder(
              animation: count,
              builder: (_, __) => DotMatrixText(
                '${(234 * count.value.clamp(0.0, 1.0)).round()}',
                height: size * 0.17,
              ),
            ),
            const SizedBox(width: 6),
            Text('Days', style: _t(11.5, w: FontWeight.w400, c: Colors.white.withValues(alpha: 0.55))),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: size * 0.1,
          height: 16,
          child: CustomPaint(painter: _TickerPainter(loop)),
        ),
      ]),
    );
  }
}

class _TickerPainter extends CustomPainter {
  final Animation<double> loop;
  _TickerPainter(this.loop) : super(repaint: loop);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 34;
    final step = size.width / n;
    final mark = (n * 0.6).round();
    final cy = size.height / 2;
    final pulse = 0.5 + 0.5 * math.sin(loop.value * 2 * math.pi * 4);
    for (var i = 0; i < n; i++) {
      final x = step * (i + 0.5);
      if (i == mark) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, cy), width: 3.5, height: size.height), const Radius.circular(1)),
          Paint()..color = _lime.withValues(alpha: 0.7 + 0.3 * pulse),
        );
      } else {
        canvas.drawCircle(Offset(x, cy), i < mark ? 2 : 1,
            Paint()..color = Colors.white.withValues(alpha: i < mark ? 0.95 : 0.35));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TickerPainter old) => false;
}

class _TrainingTile extends StatelessWidget {
  final double width, height;
  final bool on;
  final VoidCallback onTap;
  const _TrainingTile(
      {required this.width, required this.height, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      width: width,
      height: height,
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: on
            ? const [Color(0xFF1B2470), Color(0xFF2C3BB4)]
            : const [Color(0xFF2B2E3C), Color(0xFF3D4152)],
      ),
      child: Row(children: [
        Expanded(
          child: Text('Training',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13.5, c: Colors.white)),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: _spring,
          width: 40,
          height: 22,
          padding: const EdgeInsets.all(2),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: on ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: on ? 0.6 : 0), blurRadius: 8)],
            ),
          ),
        ),
      ]),
    );
  }
}

class _BreathTile extends StatelessWidget {
  final double width, height;
  final Animation<double> loop, count;
  const _BreathTile(
      {required this.width, required this.height, required this.loop, required this.count});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      width: width,
      height: height,
      padding: EdgeInsets.zero,
      radius: 24,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF141414), Color(0xFF5A1D14), Color(0xFFE5482D)],
        stops: [0, 0.45, 1],
      ),
      child: Stack(children: [
        Positioned(
          left: 14,
          top: 12,
          right: 10,
          child: Text('Breath Volume',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5, c: Colors.white)),
        ),
        Positioned(
          left: 14,
          top: math.max(36.0, height * 0.36),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedBuilder(
              animation: count,
              builder: (_, __) => DotMatrixText(
                (5.5 * count.value.clamp(0.0, 1.0)).toStringAsFixed(1),
                height: (height * 0.17).clamp(10.0, 22.0),
              ),
            ),
            const SizedBox(width: 4),
            Text('L', style: _t(10, w: FontWeight.w400, c: Colors.white.withValues(alpha: 0.6))),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          height: height * 0.32,
          child: CustomPaint(painter: _BreathArcsPainter(loop, count)),
        ),
      ]),
    );
  }
}

class _BreathArcsPainter extends CustomPainter {
  final Animation<double> loop, grow;
  _BreathArcsPainter(this.loop, this.grow) : super(repaint: Listenable.merge([loop, grow]));

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 6;
    final g = grow.value.clamp(0.0, 1.0);
    final breathe = 0.85 + 0.15 * math.sin(loop.value * 2 * math.pi * 3);
    for (var i = 0; i < 26; i++) {
      canvas.drawCircle(Offset(size.width * (i + 0.5) / 26, y), 0.9,
          Paint()..color = Colors.white.withValues(alpha: 0.45));
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.85);
    void hump(double x0, double x1, double h, Color dot) {
      final w = (x1 - x0) * size.width;
      final rect = Rect.fromLTWH(x0 * size.width, y - h * g * breathe, w, h * 2 * g * breathe);
      canvas.drawArc(rect, math.pi, math.pi, false, arc);
      canvas.drawCircle(Offset(x0 * size.width, y), 2.6, Paint()..color = dot);
      canvas.drawCircle(Offset(x1 * size.width, y), 2.6, Paint()..color = dot);
    }

    hump(0.3, 0.52, size.height * 0.4, _lime);
    hump(0.52, 0.94, size.height * 0.85, const Color(0xFFFFB199));
  }

  @override
  bool shouldRepaint(covariant _BreathArcsPainter old) => false;
}

class _VolumeTile extends StatelessWidget {
  final double size, value;
  final String title, when, delta;
  final bool up;
  final Animation<double> count;
  const _VolumeTile({
    required this.size,
    required this.title,
    required this.when,
    required this.value,
    required this.delta,
    required this.up,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return _Tile(
      width: size,
      height: size * 0.86,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7A3A12), Color(0xFFB4561C), Color(0xFFE59A32)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _t(12.5, w: FontWeight.w500, c: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(when, style: _mono(9.5, c: Colors.white.withValues(alpha: 0.85), ls: 0.6)),
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: count,
            builder: (_, __) => DotMatrixText(
              '${(value * count.value.clamp(0.0, 1.0)).toStringAsFixed(1)}K',
              height: size * 0.15,
            ),
          ),
        ),
        const Spacer(),
        Row(children: [
          Icon(up ? Icons.north_rounded : Icons.remove_rounded,
              size: 13, color: up ? _lime : Colors.white70),
          const SizedBox(width: 4),
          Expanded(
            child: Text(delta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _mono(9.5, c: Colors.white.withValues(alpha: 0.85), ls: 0.5)),
          ),
        ]),
      ]),
    );
  }
}

// ------------------------------------------------------- dot matrix text --

const Map<String, List<String>> _glyphs = {
  '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': ['11110', '00001', '00001', '01110', '00001', '00001', '11110'],
  '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
  '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
  'K': ['10001', '10010', '10100', '11000', '10100', '10010', '10001'],
  '.': ['0', '0', '0', '0', '0', '0', '1'],
};

/// Digits drawn as a 5x7 LED dot grid, like a sports watch readout.
class DotMatrixText extends StatelessWidget {
  final String text;
  final double height;
  final Color color;
  const DotMatrixText(this.text, {super.key, required this.height, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    final cell = height / 7;
    var cols = 0;
    for (final ch in text.split('')) {
      cols += (_glyphs[ch]?.first.length ?? 3) + 1;
    }
    return CustomPaint(
      size: Size(math.max(0, cols - 1) * cell, height),
      painter: _DotMatrixPainter(text, cell, color),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  final String text;
  final double cell;
  final Color color;
  _DotMatrixPainter(this.text, this.cell, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final r = cell * 0.36;
    var x0 = 0.0;
    for (final ch in text.split('')) {
      final g = _glyphs[ch];
      final w = g?.first.length ?? 3;
      if (g != null) {
        for (var row = 0; row < 7; row++) {
          for (var col = 0; col < w; col++) {
            if (g[row][col] == '1') {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromCircle(
                      center: Offset(x0 + (col + 0.5) * cell, (row + 0.5) * cell), radius: r),
                  Radius.circular(r * 0.4),
                ),
                p,
              );
            }
          }
        }
      }
      x0 += (w + 1) * cell;
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter old) =>
      old.text != text || old.cell != cell || old.color != color;
}
