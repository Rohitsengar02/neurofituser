part of '../overview_home_cards.dart';

// =====================================================================
//  DOTTED LINE CHART
// =====================================================================

class DottedLineChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final String? label;
  final List<String>? xLabels;
  final double height;
  const DottedLineChart({
    super.key,
    required this.values,
    required this.color,
    this.label,
    this.xLabels,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOutCubic,
      builder: (_, p, _) => Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _DottedLinePainter(values, color, p, label),
            ),
          ),
          if (xLabels != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < xLabels!.length; i++)
                  Expanded(
                    child: Text(
                      xLabels![i],
                      textAlign: TextAlign.center,
                      style: _t(11,
                        w: i == xLabels!.length - 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        c: i == xLabels!.length - 1 ? _ink : _faint,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final List<double> v;
  final Color c;
  final double p;
  final String? label;
  _DottedLinePainter(this.v, this.c, this.p, this.label);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    final top = label != null ? 30.0 : 8.0;
    final h = size.height - top - 6;
    final mx = v.reduce(math.max) * 1.1;
    final mn = v.reduce(math.min) * 0.7;
    final step = size.width / v.length;
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(step * (i + 0.5), top + h - (v[i] - mn) / (mx - mn) * h),
    ];

    // Dotted grid.
    final grid = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.25);
    for (var g = 0; g < 4; g++) {
      final y = top + h * g / 3;
      for (var x = 2.0; x < size.width; x += 7) {
        canvas.drawCircle(Offset(x, y), 0.8, grid);
      }
    }

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1];
      final p3 = pts[math.min(pts.length - 1, i + 2)];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final metric = path.computeMetrics().first;
    final drawn = metric.length * p;

    // Soft fill under the drawn part.
    final reveal = Rect.fromLTWH(
      0,
      0,
      pts.first.dx + (pts.last.dx - pts.first.dx) * p,
      size.height,
    );
    canvas.save();
    canvas.clipRect(reveal);
    final fill = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.withValues(alpha: 0.16), c.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();

    // The line itself as round dots.
    final dot = Paint()..color = c;
    for (var d = 0.0; d <= drawn; d += 6.5) {
      final tan = metric.getTangentForOffset(d);
      if (tan != null) canvas.drawCircle(tan.position, 1.9, dot);
    }

    // Data points.
    for (var i = 0; i < pts.length - 1; i++) {
      if (pts[i].dx > reveal.right) break;
      canvas.drawCircle(pts[i], 2.6, Paint()..color = Colors.white);
      canvas.drawCircle(
        pts[i],
        2.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = c.withValues(alpha: 0.6),
      );
    }

    // Highlight the latest value.
    if (p > 0.97) {
      final last = pts.last;
      canvas.drawLine(
        Offset(last.dx, last.dy + 8),
        Offset(last.dx, size.height),
        Paint()
          ..color = c.withValues(alpha: 0.25)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(last, 11, Paint()..color = c.withValues(alpha: 0.18));
      canvas.drawCircle(last, 6, Paint()..color = Colors.white);
      canvas.drawCircle(last, 4, Paint()..color = c);
      if (label != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: _t(11, w: FontWeight.w800, c: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final w = tp.width + 16;
        final left = (last.dx - w / 2).clamp(0.0, size.width - w);
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, last.dy - 36, w, 22),
          const Radius.circular(11),
        );
        canvas.drawRRect(r, Paint()..color = _ink);
        tp.paint(canvas, Offset(left + 8, last.dy - 36 + (22 - tp.height) / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter o) => o.p != p || o.v != v;
}
