part of '../overview_home_cards.dart';

// =====================================================================
//  2. NUTRITION
// =====================================================================

const _macros = [
  ('Protein', 100.0, 140.0, 'g', _purple),
  ('Carbs', 245.0, 350.0, 'g', _amber),
  ('Fat', 48.0, 65.0, 'g', _pink),
  ('Fiber', 18.0, 30.0, 'g', _green),
];

class _NutritionCard extends StatelessWidget {
  const _NutritionCard();

  @override
  Widget build(BuildContext context) {
    final eaten = IslandStats.eaten.toDouble();
    final budget = IslandStats.budget.toDouble();
    return _NeuCard(
      page: () => const _NutritionDetailPage(),
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(
            'Nutrition',
            Icons.restaurant_rounded,
            _orange,
            trailing: 'Today',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 118,
                height: 118,
                child: _AnimRing(
                  value: eaten / budget,
                  color: _orange,
                  stroke: 11,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Count(eaten, _t(24, w: FontWeight.w800, ls: -0.8)),
                      Text(
                        'of ${budget.round()} kcal',
                        style: _t(11, w: FontWeight.w600, c: _faint),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final m in _macros) ...[
                      _MacroBar(
                        name: m.$1,
                        value: m.$2,
                        goal: m.$3,
                        unit: m.$4,
                        color: m.$5,
                      ),
                      if (m != _macros.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(
                Icons.water_drop_rounded,
                _blue,
                '1.25 / 2.5 L',
                'Water',
              ),
              const SizedBox(width: 10),
              _miniStat(Icons.lunch_dining_rounded, _green, '3 of 4', 'Meals'),
              const SizedBox(width: 10),
              _miniStat(
                Icons.local_fire_department_rounded,
                _orange,
                '${IslandStats.left}',
                'kcal left',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _miniStat(IconData i, Color c, String v, String l) => Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(i, size: 15, color: c),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v, style: _t(12, w: FontWeight.w800)),
              ),
              Text(
                l,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

class _MacroBar extends StatelessWidget {
  final String name, unit;
  final double value, goal;
  final Color color;
  const _MacroBar({
    required this.name,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: _t(12, w: FontWeight.w700)),
            ),
            Text('${value.round()}', style: _t(12, w: FontWeight.w800)),
            Text(
              '/${goal.round()}$unit',
              style: _t(11, w: FontWeight.w600, c: _faint),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (value / goal).clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1300),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => LayoutBuilder(
            builder: (_, c) => Stack(
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: 7,
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.6), color],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimRing extends StatelessWidget {
  final double value, stroke;
  final Color color;
  final Widget? child;
  const _AnimRing({
    required this.value,
    required this.color,
    this.stroke = 10,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => CustomPaint(
        painter: _RingPainter(v, color, stroke),
        child: Center(child: c),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, w;
  final Color c;
  _RingPainter(this.v, this.c, this.w);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - w / 2,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      p..color = c.withValues(alpha: 0.12),
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * v,
      false,
      p
        ..color = Colors.white
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [c.withValues(alpha: 0.55), c],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v;
}
