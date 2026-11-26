part of '../overview_home_cards.dart';

// =====================================================================
//  3. STEPS
// =====================================================================

const _hourly = <double>[
  0.0,
  0,
  0,
  0,
  0,
  0,
  120,
  640,
  980,
  420,
  310,
  520,
  760,
  380,
  290,
  450,
  610,
  880,
  1040,
  520,
  220,
  0,
  0,
  0,
];

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    final steps = IslandStats.steps.toDouble();
    return _NeuCard(
      page: () => const _StepsDetailPage(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(
            'Steps',
            Icons.directions_walk_rounded,
            _green,
            trailing: 'Live',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Count(
                      steps,
                      _t(38, w: FontWeight.w800, ls: -1.4, h: 1),
                      group: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of 10,000 steps · 85%',
                      style: _t(12.5, w: FontWeight.w600, c: _muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _inline(Icons.route_rounded, '6.1 km'),
                        _inline(
                          Icons.local_fire_department_rounded,
                          '320 kcal',
                        ),
                        _inline(Icons.timer_outlined, '54 min'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                height: 92,
                child: _AnimRing(
                  value: steps / 10000,
                  color: _green,
                  stroke: 9,
                  child: const Icon(
                    Icons.directions_run_rounded,
                    color: _green,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(
            height: 54,
            child: _HourBars(values: _hourly, color: _green),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '12 AM',
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
              const Spacer(),
              Text(
                '12 PM',
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
              const Spacer(),
              Text(
                'Now',
                style: _t(11, w: FontWeight.w800, c: _ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _inline(IconData i, String s) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(i, size: 14, color: _faint),
    const SizedBox(width: 4),
    Text(s, style: _t(12, w: FontWeight.w700)),
  ],
);

class _HourBars extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _HourBars({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final mx = values.reduce(math.max);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, p, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  height: math.max(4, (values[i] / mx) * 54 * p),
                  decoration: BoxDecoration(
                    color: values[i] == 0
                        ? const Color(0xFFEEF1EF)
                        : color.withValues(alpha: 0.35 + 0.65 * values[i] / mx),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
