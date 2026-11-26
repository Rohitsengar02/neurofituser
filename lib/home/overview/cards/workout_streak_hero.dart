part of '../overview_home_cards.dart';

// =====================================================================
//  1. WORKOUT STREAK HERO (full bleed, square corners)
// =====================================================================

const _streakMinutes = <double>[
  32.0,
  40,
  28,
  45,
  38,
  0,
  42,
  50,
  36,
  44,
  30,
  46,
  41,
  48,
];
const _todayPlan = [
  ('Bench Press', '4 × 10', Icons.fitness_center_rounded),
  ('Incline Dumbbell Press', '3 × 12', Icons.fitness_center_rounded),
  ('Shoulder Press', '3 × 10', Icons.accessibility_new_rounded),
  ('Lateral Raises', '3 × 15', Icons.open_with_rounded),
  ('Tricep Dips', '3 × 12', Icons.sports_gymnastics_rounded),
  ('Push-up Finisher', '2 × max', Icons.bolt_rounded),
];

class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => _openFrom(context, const _StreakDetailPage()),
          child: LiquidGlass(
          style: LiquidGlassStyle.material,
          borderRadius: BorderRadius.zero,
          shadow: false,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'WORKOUT STREAK',
                          style: _t(
                            11.5,
                            w: FontWeight.w800,
                            c: _faint,
                            ls: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 15,
                                color: _orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '12 day streak',
                                style: _t(12, w: FontWeight.w800, c: _orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Day ',
                          style: _t(30, w: FontWeight.w300, c: _ink, h: 1),
                        ),
                        _Count(13, _t(44, w: FontWeight.w800, h: 1, ls: -1.5)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              'of 30 · Muscle Builder',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(12.5, w: FontWeight.w600, c: _muted),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upper Body Push · 45 min · 6 exercises',
                      style: _t(13.5, w: FontWeight.w600, c: _muted),
                    ),
                    const SizedBox(height: 16),
                    const DottedLineChart(
                      values: _streakMinutes,
                      color: _green,
                      label: '48 min',
                      height: 118,
                    ),
                    const SizedBox(height: 14),
                    const _WeekStrip(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'Continue Day 13',
                            onTap: () =>
                                _openFrom(context, const _StreakDetailPage()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Plan',
                            style: _t(14, w: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const done = [true, true, false, true, true, true, false];
    const today = 5;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: [
                Text(
                  days[i],
                  style: _t(
                    11,
                    w: FontWeight.w700,
                    c: i == today ? _ink : _faint,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + i * 90),
                  curve: _spring,
                  builder: (_, s, c) => Transform.scale(scale: s, child: c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == today
                          ? _ink
                          : done[i]
                          ? _green.withValues(alpha: 0.12)
                          : const Color(0xFFF3F4F6),
                      border: i > today
                          ? Border.all(color: const Color(0xFFE5E7EB))
                          : null,
                    ),
                    child: Icon(
                      i == today
                          ? Icons.play_arrow_rounded
                          : done[i]
                          ? Icons.check_rounded
                          : i < today
                          ? Icons.close_rounded
                          : null,
                      size: 15,
                      color: i == today
                          ? Colors.white
                          : done[i]
                          ? _green
                          : _faint,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _mint,
                ),
                child: Icon(widget.icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(14.5, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
