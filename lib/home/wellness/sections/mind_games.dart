part of '../wellness_tab_v3.dart';

// =====================================================================
//  MIND GAMES
// =====================================================================

class _MindLevelCard extends StatelessWidget {
  const _MindLevelCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GameProgress.changes,
      builder: (_, _, _) => AkGlass(
        colors: const [Color(0xFF4C1D95), Color(0xFF7C3AED)],
        child: Row(children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 74,
                height: 74,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: GameProgress.mindProgress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: const Color(0xFFFDE68A),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('LVL', style: akT(10, w: FontWeight.w800, c: Colors.white70, ls: 1)),
                Text('${GameProgress.mindLevel}', style: akN(26, c: Colors.white)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mind level ${GameProgress.mindLevel}', style: akT(17, w: FontWeight.w800, c: Colors.white)),
              const SizedBox(height: 3),
              Text('${400 - GameProgress.totalXp % 400} XP to the next level', style: akT(12.5, c: Colors.white70)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _darkPill('${GameProgress.totalXp} XP'),
                _darkPill('${GameProgress.totalPlays} played'),
                _darkPill('16 games'),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _darkPill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: akT(11.5, w: FontWeight.w700, c: Colors.white)),
      );
}

class _GamesGrid extends StatelessWidget {
  const _GamesGrid();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GameProgress.changes,
      builder: (_, _, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mindGames.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 168,
          ),
          itemBuilder: (context, i) {
            final g = mindGames[i];
            final s = GameProgress.of(g.id);
            return ScrollReveal(
              delayMs: (i % 2) * 80,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(14),
                onTap: () => openMindGame(context, g),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [g.color.withValues(alpha: 0.7), g.color]),
                        boxShadow: [BoxShadow(color: g.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Icon(g.icon, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: g.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text('Lv ${s.level}', style: akT(11, w: FontWeight.w800, c: g.color)),
                    ),
                  ]),
                  const Spacer(),
                  Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14.5, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(g.blurb, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, c: akMuted)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s.levelProgress,
                      minHeight: 5,
                      color: g.color,
                      backgroundColor: g.color.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(s.plays == 0 ? 'New' : 'Best ${s.best} · ${s.plays} plays', style: akT(11, c: akFaint)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
