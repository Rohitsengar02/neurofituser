part of '../workout_tab_v2.dart';

// =====================================================================
//  DOT MATRIX STATS
// =====================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, double value, int decimals, String suffix, String sub, Color c) => Expanded(
          child: LiquidGlass(
            style: LiquidGlassStyle.material,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, style: _t(11, w: FontWeight.w800, c: _faint, ls: 0.8)),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedDotNumber(value: value, decimals: decimals, suffix: suffix, height: 26, color: c),
              ),
              const SizedBox(height: 8),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11, w: FontWeight.w600, c: _muted)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        tile('VOLUME', 12.4, 1, 'K', 'kg lifted · +18%', _ink),
        const SizedBox(width: 10),
        tile('SESSIONS', 4, 0, '/5', 'this week', _green),
        const SizedBox(width: 10),
        tile('ACTIVE', 186, 0, '', 'minutes', _orange),
      ]),
    );
  }
}

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
  '/': ['00001', '00010', '00010', '00100', '01000', '01000', '10000'],
  '%': ['11001', '11010', '00010', '00100', '01000', '01011', '10011'],
};

/// A number drawn on a 5x7 LED grid. When it scrolls into view it counts
/// up while the lit dots sweep in from left to right over a faint grid.
class AnimatedDotNumber extends StatelessWidget {
  final double value;
  final int decimals;
  final String suffix;
  final double height;
  final Color color;
  const AnimatedDotNumber({
    super.key,
    required this.value,
    this.decimals = 0,
    this.suffix = '',
    required this.height,
    this.color = _ink,
  });

  @override
  Widget build(BuildContext context) {
    final finalText = value.toStringAsFixed(decimals) + suffix;
    return _Seen(
      duration: const Duration(milliseconds: 1600),
      builder: (_, t) {
        final txt = (value * t).toStringAsFixed(decimals) + suffix;
        // Keep width stable by padding to the final length.
        final shown = txt.padLeft(finalText.length, ' ');
        return CustomPaint(
          size: Size(_width(finalText, height / 7), height),
          painter: _DotPainter(shown, height / 7, color, t),
        );
      },
    );
  }

  static double _width(String s, double cell) {
    var cols = 0;
    for (final ch in s.split('')) {
      cols += (_glyphs[ch]?.first.length ?? 3) + 1;
    }
    return math.max(0, cols - 1) * cell;
  }
}

class _DotPainter extends CustomPainter {
  final String text;
  final double cell;
  final Color color;
  final double t;
  _DotPainter(this.text, this.cell, this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final r = cell * 0.36;
    final total = AnimatedDotNumber._width(text, cell) / cell + 1;
    var x0 = 0.0;
    var col0 = 0;
    for (final ch in text.split('')) {
      final g = _glyphs[ch];
      final w = g?.first.length ?? 3;
      for (var row = 0; row < 7; row++) {
        for (var col = 0; col < w; col++) {
          final on = g != null && g[row][col] == '1';
          final c = Offset(x0 + (col + 0.5) * cell, (row + 0.5) * cell);
          if (!on) {
            canvas.drawCircle(c, r * 0.55, Paint()..color = color.withValues(alpha: 0.07));
            continue;
          }
          final sweep = ((t * 1.6 - (col0 + col) / total * 0.6) * 2.2).clamp(0.0, 1.0);
          canvas.drawCircle(c, r * (0.6 + 0.4 * sweep), Paint()..color = color.withValues(alpha: 0.15 + 0.85 * sweep));
        }
      }
      x0 += (w + 1) * cell;
      col0 += w + 1;
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter o) => o.text != text || o.t != t || o.color != color;
}
