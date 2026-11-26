part of '../nutrition_tab_v3.dart';

// =====================================================================
//  WATER
// =====================================================================

class _WaterCard extends StatefulWidget {
  const _WaterCard();
  @override
  State<_WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends State<_WaterCard> with SingleTickerProviderStateMixin {
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  final _store = HydrationStore.I;

  void _add(int ml) {
    HapticFeedback.mediumImpact();
    _store.add('water', ml);
  }

  @override
  Widget build(BuildContext context) {
    return _glass(
      onTap: () => openWaterScreen(context),
      child: ListenableBuilder(
        listenable: _store,
        builder: (_, _) {
          final ml = _store.total;
          final goal = _store.goal;
          return Row(children: [
            SizedBox(
              width: 92,
              height: 150,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ml / goal),
                duration: const Duration(milliseconds: 900),
                curve: _spring,
                builder: (_, v, _) => AnimatedBuilder(
                  animation: _wave,
                  builder: (_, _) => CustomPaint(painter: _Bottle(v, _wave.value)),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: ml / 1000),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, _) => Text(v.toStringAsFixed(2), style: _n(36, w: FontWeight.w800)),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('/ ${goal / 1000} L', style: _t(13, w: FontWeight.w600, c: _muted)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${((ml / goal) * 100).round()}% of daily goal', style: _t(12.5, w: FontWeight.w600, c: _sky)),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _waterBtn('Glass +250', () => _add(250)),
                  _waterBtn('Bottle +500', () => _add(500)),
                  _waterBtn('Cup +150', () => _add(150)),
                  _waterBtn('Other', () => showAddDrinkSheet(context), icon: Icons.add_rounded),
                  if (_store.today.isNotEmpty) _waterBtn('Undo', () {
                    HapticFeedback.selectionClick();
                    _store.undo();
                  }, icon: Icons.undo_rounded, quiet: true),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Text(
                        !_store.reminders
                            ? 'Reminders off'
                            : _store.nextReminder.inMinutes == 0
                                ? 'Time for a sip'
                                : 'Next reminder in ${_store.nextReminder.inMinutes} min',
                        style: _t(11.5, w: FontWeight.w600, c: _faint)),
                  ),
                  Text('Open', style: _t(12, w: FontWeight.w800, c: const Color(0xFF0369A1))),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0369A1)),
                ]),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _waterBtn(String l, VoidCallback onTap, {IconData? icon, bool quiet = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: quiet ? Colors.white.withValues(alpha: 0.6) : _sky.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: quiet ? Colors.black12 : _sky.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: quiet ? _muted : const Color(0xFF0369A1)),
              const SizedBox(width: 3),
            ],
            Text(l, style: _t(12, w: FontWeight.w800, c: quiet ? _muted : const Color(0xFF0369A1))),
          ]),
        ),
      );
}

class _Bottle extends CustomPainter {
  final double level, phase;
  _Bottle(this.level, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.16, w * 0.76, h * 0.84),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(22),
      bottomRight: const Radius.circular(22),
    );
    final cap = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, 0, w * 0.36, h * 0.13), const Radius.circular(6));
    canvas.drawRRect(cap, Paint()..color = _sky.withValues(alpha: 0.5));
    canvas.drawRRect(body, Paint()..color = Colors.white.withValues(alpha: 0.7));
    canvas.save();
    canvas.clipRRect(body);
    final top = body.top + body.height * (1 - level.clamp(0.0, 1.0));
    for (var layer = 0; layer < 2; layer++) {
      final path = Path()..moveTo(body.left, body.bottom);
      for (var x = body.left; x <= body.right + 1; x += 2) {
        final y = top + math.sin((x / w * 2 * math.pi * 1.4) + phase * 2 * math.pi + layer * 1.6) * (4 - layer);
        path.lineTo(x, y);
      }
      path
        ..lineTo(body.right, body.bottom)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: layer == 0
                ? [const Color(0xFF7DD3FC).withValues(alpha: 0.7), const Color(0xFF38BDF8).withValues(alpha: 0.7)]
                : [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
          ).createShader(body.outerRect),
      );
    }
    // Bubbles.
    for (var k = 0; k < 5; k++) {
      final bx = body.left + body.width * (0.2 + 0.15 * k);
      final by = body.bottom - ((phase + k * 0.21) % 1) * (body.bottom - top);
      canvas.drawCircle(Offset(bx, by), 2 + k % 2.0, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _sky.withValues(alpha: 0.45),
    );
    // Glass shine.
    canvas.drawLine(Offset(body.left + 8, body.top + 16), Offset(body.left + 8, body.bottom - 20),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _Bottle o) => o.level != level || o.phase != phase;
}
