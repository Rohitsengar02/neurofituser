part of '../wellness_tab_v3.dart';

// =====================================================================
//  MINDFUL MINUTES / SOUNDS / AFFIRMATIONS
// =====================================================================

class _MindfulWeek extends StatelessWidget {
  const _MindfulWeek();

  @override
  Widget build(BuildContext context) {
    const days = ['F', 'S', 'S', 'M', 'T', 'W', 'T'];
    return ValueListenableBuilder<int>(
      valueListenable: WellnessState.mindfulMin,
      builder: (_, today, _) {
        final vals = [12, 20, 8, 15, 22, 10, today];
        const goal = 20;
        return AkGlass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$today', style: akN(38)),
              const SizedBox(width: 4),
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('min today', style: akT(13, c: akMuted))),
              const Spacer(),
              _pill('Goal $goal min', _violet),
            ]),
            const SizedBox(height: 16),
            AkSeen(
              builder: (_, t) => SizedBox(
                height: 110,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Container(
                          width: 22,
                          height: 80 * (vals[i] / 30).clamp(0.05, 1.0) * t,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: vals[i] >= goal ? [_violet, const Color(0xFFC4B5FD)] : [_violet.withValues(alpha: 0.25), _violet.withValues(alpha: 0.4)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(days[i], style: akT(11.5, w: FontWeight.w700, c: i == 6 ? akInk : akMuted)),
                      ]),
                    ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _Sounds extends StatefulWidget {
  const _Sounds();
  @override
  State<_Sounds> createState() => _SoundsState();
}

class _SoundsState extends State<_Sounds> with SingleTickerProviderStateMixin {
  int? playing;
  late final AnimationController _eq = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _eq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sounds = [
      ('Rain', '🌧️', _sky), ('Forest', '🌲', _green), ('Ocean', '🌊', _teal), ('Fireplace', '🔥', _orange),
      ('Night', '🌌', _indigo), ('Wind', '🍃', _violet),
    ];
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sounds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = sounds[i];
          final on = playing == i;
          return SizedBox(
            width: 104,
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(22),
              colors: on ? [s.$3.withValues(alpha: 0.85), s.$3] : null,
              padding: const EdgeInsets.all(12),
              onTap: () => setState(() => playing = on ? null : i),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s.$2, style: const TextStyle(fontSize: 22)),
                  const Spacer(),
                  Icon(on ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18, color: on ? Colors.white : s.$3),
                ]),
                const Spacer(),
                Text(s.$1, style: akT(13.5, w: FontWeight.w800, c: on ? Colors.white : akInk)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 14,
                  child: AnimatedBuilder(
                    animation: _eq,
                    builder: (_, _) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      for (var k = 0; k < 7; k++)
                        Container(
                          margin: const EdgeInsets.only(right: 3),
                          width: 3,
                          height: on ? 4 + 10 * (0.5 + 0.5 * math.sin(_eq.value * 2 * math.pi + k * 0.9)).abs() : 4,
                          decoration: BoxDecoration(
                            color: on ? Colors.white : s.$3.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Affirmations extends StatefulWidget {
  const _Affirmations();
  @override
  State<_Affirmations> createState() => _AffirmationsState();
}

class _AffirmationsState extends State<_Affirmations> {
  final _pc = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _t;

  static const _list = [
    ('I am allowed to rest without earning it.', [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
    ('Every breath is a fresh start.', [Color(0xFF5EEAD4), Color(0xFF0D9488)]),
    ('Progress, not perfection.', [Color(0xFFFDBA74), Color(0xFFEA580C)]),
    ('My body is strong and my mind is calm.', [Color(0xFF93C5FD), Color(0xFF2563EB)]),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pc.hasClients) return;
      _pc.animateToPage((_page + 1) % _list.length, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 150,
        child: PageView.builder(
          controller: _pc,
          itemCount: _list.length,
          onPageChanged: (p) => setState(() => _page = p),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(28),
              colors: _list[i].$2,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 28),
                const Spacer(),
                Text(_list[i].$1, style: akT(19, w: FontWeight.w800, c: Colors.white, h: 1.25)),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < _list.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(color: i == _page ? _violet : Colors.black12, borderRadius: BorderRadius.circular(3)),
          ),
      ]),
    ]);
  }
}
