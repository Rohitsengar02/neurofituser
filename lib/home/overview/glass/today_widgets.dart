part of '../overview_glass.dart';

// =====================================================================
//  TODAY WIDGETS
// =====================================================================

class _TodaysFoodWidget extends StatelessWidget {
  const _TodaysFoodWidget();

  @override
  Widget build(BuildContext context) {
    Widget matrix(Color c, double fill, String g, IconData i) {
      const cols = 8, rows = 4;
      final on = (cols * rows * fill).round();
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 3.5,
              runSpacing: 3.5,
              children: [
                for (var k = 0; k < cols * rows; k++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + k * 22),
                    builder: (context, t, _) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (cols * rows - 1 - k) < on && t > 0.9 ? c : c.withValues(alpha: 0.13),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(i, size: 13, color: c),
                const SizedBox(width: 3),
                Text(g, style: _t(12, w: FontWeight.w700, c: c)),
              ],
            ),
          ],
        ),
      );
    }

    Widget action(IconData i, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(height: 44, child: Icon(i, size: 20, color: _ink.withValues(alpha: 0.75))),
          ),
        );
    Widget divider() => Container(width: 1, height: 22, color: _ink.withValues(alpha: 0.08));

    return _Press(
      onTap: () => _push(context, DateNutritionDetailScreen(initialDate: DateTime.now())),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Today's food", style: _t(14, w: FontWeight.w700)),
                            const Spacer(),
                            Text('1,420 kcal', style: _t(14, w: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            matrix(_blue, 0.62, '92g', Icons.egg_alt_rounded),
                            const SizedBox(width: 8),
                            matrix(_amber, 0.8, '160g', Icons.grain_rounded),
                            const SizedBox(width: 8),
                            matrix(_pink, 0.55, '48g', Icons.water_drop_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _AnimRing(
                    0.72,
                    _purple,
                    size: 70,
                    stroke: 4,
                    dashed: true,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('72', style: _t(22, w: FontWeight.w800, h: 1)),
                        Text('good', style: _t(10, w: FontWeight.w600, c: _purple)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _ink.withValues(alpha: 0.06)),
            Row(
              children: [
                action(Icons.add_photo_alternate_outlined, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.photo_camera_outlined, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.qr_code_scanner_rounded, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.auto_awesome_outlined, () => _push(context, const LogMealScreen())),
                divider(),
                action(Icons.search_rounded, () => _push(context, const LogMealScreen())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetEnergyWidget extends StatelessWidget {
  const _NetEnergyWidget();

  @override
  Widget build(BuildContext context) {
    const burned = 1720, eaten = 1420;
    const net = eaten - burned; // -300
    final pos = ((net + 500) / 1000).clamp(0.0, 1.0);
    return _Press(
      onTap: () => _push(context, DateNutritionDetailScreen(initialDate: DateTime.now())),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: net.toDouble()),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) =>
                            Text('${v.round()} kcal', style: _t(26, w: FontWeight.w700, ls: -0.8)),
                      ),
                      Text('Net energy', style: _t(12.5, w: FontWeight.w500, c: _muted)),
                    ],
                  ),
                ),
                const Icon(Icons.local_fire_department_rounded, size: 16, color: _orange),
                Text(' 1,720', style: _t(14, w: FontWeight.w700, c: _orange)),
                const SizedBox(width: 10),
                const Icon(Icons.apple_rounded, size: 16, color: _purple),
                Text(' 1,420', style: _t(14, w: FontWeight.w700, c: _purple)),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B3D), Color(0xFFFFB86B), Color(0xFFDCE7F5), Color(0xFF8FA8FF), _purple],
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: pos),
                      duration: const Duration(milliseconds: 1300),
                      curve: _spring,
                      builder: (context, p, _) => Positioned(
                        left: (c.maxWidth - 22) * p,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in const ['-500', '-250', '0', '250', '500'])
                  Text(l, style: _t(10.5, w: FontWeight.w500, c: _muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingsRow extends StatelessWidget {
  const _RingsRow();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Press(
              onTap: () => _push(context, const StepsScreen()),
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(days[now.weekday - 1], style: _t(12, w: FontWeight.w500, c: _muted)),
                              Text(months[now.month - 1], style: _t(16, w: FontWeight.w700, h: 1.1)),
                              Text('${now.day}', style: _t(16, w: FontWeight.w700, h: 1.1)),
                            ],
                          ),
                        ),
                        const _AnimRing(0.42, _amber, size: 54, stroke: 6, dashed: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          _AnimRing(0.86, _green, size: 56, stroke: 6),
                          SizedBox(width: 8),
                          _AnimRing(0.65, _purple, size: 56, stroke: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Press(
              onTap: () => _push(context, const StreakDetailScreen()),
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _AnimRing(
                      0.75,
                      _orange,
                      size: 92,
                      stroke: 8,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('75%', style: _t(19, w: FontWeight.w800, h: 1)),
                          Text('workout', style: _t(9.5, w: FontWeight.w600, c: _muted)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duration', style: _t(10.5, w: FontWeight.w500, c: _muted)),
                              Text('34m', style: _t(14, w: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Energy', style: _t(10.5, w: FontWeight.w500, c: _muted)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('320 kcal', style: _t(14, w: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyHydrationRow extends StatelessWidget {
  const _EnergyHydrationRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _energyBank(context)),
          const SizedBox(width: 12),
          const Expanded(child: _HydrationWidget()),
        ],
      ),
    );
  }

  Widget _energyBank(BuildContext context) {
    return _Press(
      onTap: () => _push(context, const StreakDetailScreen()),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        tint: const [Color(0xFF4ADE80), Color(0xFF16A34A)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 2),
                Text('Energy Bank', style: _t(12.5, w: FontWeight.w700, c: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 93),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) =>
                  Text('${v.round()}%', style: _t(30, w: FontWeight.w700, c: Colors.white, ls: -1, h: 1)),
            ),
            const SizedBox(height: 4),
            Text('Recovered after sleep',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(10.5, w: FontWeight.w500, c: Colors.white70)),
            const Spacer(),
            const SizedBox(height: 10),
            Container(
              height: 26,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 16; i++)
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 300 + i * 60),
                        builder: (context, t, _) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: i < 15 && t > 0.95 ? _green : _green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pill('+40%', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                _pill('-7%', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: _t(10.5, w: FontWeight.w800, c: fg)),
      );
}

class _HydrationWidget extends StatelessWidget {
  const _HydrationWidget();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: IslandStats.waterMl,
      builder: (context, ml, _) {
        final p = ml / IslandStats.waterGoal;
        return GlassPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop_rounded, size: 15, color: _blue),
                  const SizedBox(width: 3),
                  Text('Hydration', style: _t(12.5, w: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('${_fmtInt(ml)} ml', style: _t(22, w: FontWeight.w700, ls: -0.6)),
              ),
              Text('${(p * 100).round()}% complete', style: _t(11, w: FontWeight.w600, c: _blue)),
              const Spacer(),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 110,
                  height: 62,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: p.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 900),
                    curve: _spring,
                    builder: (context, v, child) => CustomPaint(
                      painter: _ArcGauge(v, _blue),
                      child: child,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          IslandStats.waterMl.value = (ml + 250).clamp(0, IslandStats.waterGoal);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: _blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: _ink),
                        ),
                      ),
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

String _fmtInt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _ArcGauge extends CustomPainter {
  final double v;
  final Color c;
  _ArcGauge(this.v, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    const s = 11.0;
    final r = Rect.fromCircle(
        center: Offset(size.width / 2, size.height - 4), radius: size.width / 2 - s / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, math.pi, math.pi, false, p..color = c.withValues(alpha: 0.14));
    canvas.drawArc(r, math.pi, math.pi * v, false,
        p..color = Colors.white..shader = LinearGradient(colors: [c.withValues(alpha: 0.6), c]).createShader(r));
  }

  @override
  bool shouldRepaint(covariant _ArcGauge o) => o.v != v;
}
