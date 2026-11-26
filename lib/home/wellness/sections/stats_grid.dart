part of '../wellness_tab_v3.dart';

// =====================================================================
//  3×3 STATS
// =====================================================================

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('Mood', 'Good', '😊', 0.75, _amber),
      ('Stress', '32', '🌿', 0.32, _teal),
      ('Sleep', '7h 12m', '🌙', 0.9, _indigo),
      ('HRV', '58 ms', '💓', 0.64, _pink),
      ('Resting HR', '62', '❤️', 0.55, _red),
      ('Mindful', '18 min', '🧘', 0.6, _violet),
      ('Energy', '74%', '⚡', 0.74, _orange),
      ('Screen', '3h 40m', '📱', 0.45, _sky),
      ('Journal', '9 days', '📔', 0.9, _green),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.86,
        children: [
          for (var i = 0; i < stats.length; i++)
            ScrollReveal(
              delayMs: (i % 3) * 70,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                onTap: () {},
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(stats[i].$3, style: const TextStyle(fontSize: 18)),
                    const Spacer(),
                    AkSeen(
                      builder: (_, t) => SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: stats[i].$4 * t,
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          color: stats[i].$5,
                          backgroundColor: stats[i].$5.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                  ]),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(stats[i].$2, style: akN(19)),
                  ),
                  const SizedBox(height: 4),
                  Text(stats[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, w: FontWeight.w700, c: akMuted)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
