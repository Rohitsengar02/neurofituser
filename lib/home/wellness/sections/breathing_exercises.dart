part of '../wellness_tab_v3.dart';

// =====================================================================
//  BREATHING & EXERCISES
// =====================================================================

class _Phase {
  final String label;
  final double secs;
  final double scale;
  final String hint;
  const _Phase(this.label, this.secs, this.scale, [this.hint = '']);
}

class _Exercise {
  final String name, sub, emoji;
  final Color color;
  final int rounds;
  final List<_Phase> phases;
  const _Exercise(this.name, this.sub, this.emoji, this.color, this.rounds, this.phases);
  double get seconds => rounds * phases.fold(0.0, (a, p) => a + p.secs);
}

const _exercises = [
  _Exercise('Box breathing', 'Focus · 4-4-4-4', '🟦', _sky, 4, [
    _Phase('Inhale', 4, 1), _Phase('Hold', 4, 1), _Phase('Exhale', 4, 0.45), _Phase('Hold', 4, 0.45),
  ]),
  _Exercise('4-7-8 breath', 'Sleep · calm fast', '🌙', _indigo, 4, [
    _Phase('Inhale', 4, 1, 'through the nose'), _Phase('Hold', 7, 1), _Phase('Exhale', 8, 0.45, 'slowly through the mouth'),
  ]),
  _Exercise('Coherent breath', 'Balance · 5.5 s', '🌊', _teal, 6, [
    _Phase('Inhale', 5.5, 1), _Phase('Exhale', 5.5, 0.45),
  ]),
  _Exercise('Physiological sigh', 'Stress reset', '😮‍💨', _pink, 5, [
    _Phase('Inhale', 2, 0.85), _Phase('Top up', 1, 1, 'one more short sip'), _Phase('Long exhale', 6, 0.4),
  ]),
  _Exercise('Body scan', 'Notice · 2 min', '🧘', _violet, 1, [
    _Phase('Feet', 15, 0.6, 'soften your toes and heels'), _Phase('Legs', 15, 0.68, 'let the knees go loose'),
    _Phase('Belly', 15, 0.76, 'breathe into the belly'), _Phase('Chest', 15, 0.84, 'feel it rise and fall'),
    _Phase('Shoulders', 15, 0.92, 'drop them away from the ears'), _Phase('Face', 15, 1, 'unclench the jaw'),
  ]),
  _Exercise('5-4-3-2-1 grounding', 'Anxiety relief', '🌱', _green, 1, [
    _Phase('5 things', 15, 1, 'you can see'), _Phase('4 things', 15, 0.88, 'you can touch'),
    _Phase('3 things', 15, 0.76, 'you can hear'), _Phase('2 things', 12, 0.64, 'you can smell'),
    _Phase('1 thing', 10, 0.52, 'you can taste'),
  ]),
  _Exercise('Muscle release', 'Tension · PMR', '💪', _orange, 1, [
    _Phase('Tense hands', 5, 1), _Phase('Release', 10, 0.5), _Phase('Tense shoulders', 5, 1), _Phase('Release', 10, 0.5),
    _Phase('Tense face', 5, 1), _Phase('Release', 10, 0.5), _Phase('Tense legs', 5, 1), _Phase('Release', 10, 0.5),
  ]),
  _Exercise('Neck & shoulders', 'Desk break', '🙆', _amber, 2, [
    _Phase('Tilt left', 10, 0.8, 'ear toward shoulder'), _Phase('Tilt right', 10, 0.8), _Phase('Chin down', 10, 0.6),
    _Phase('Shoulder rolls', 10, 1, 'big slow circles'),
  ]),
];

class _Exercises extends StatelessWidget {
  const _Exercises();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _exercises.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final e = _exercises[i];
          return ScrollReveal(
            delayMs: math.min(i, 3) * 80,
            child: SizedBox(
              width: 150,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(26),
                colors: [e.color.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.7)],
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BreathPage(e))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(15)),
                    child: Text(e.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const Spacer(),
                  Text(e.name, maxLines: 2, style: akT(14.5, w: FontWeight.w800, h: 1.2)),
                  const SizedBox(height: 3),
                  Text(e.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, c: akMuted)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.play_circle_fill_rounded, size: 18, color: e.color),
                    const SizedBox(width: 4),
                    Text('${(e.seconds / 60).ceil()} min', style: akT(12, w: FontWeight.w800, c: e.color)),
                  ]),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BreathPage extends StatefulWidget {
  final _Exercise e;
  const _BreathPage(this.e);
  @override
  State<_BreathPage> createState() => _BreathPageState();
}

class _BreathPageState extends State<_BreathPage> with SingleTickerProviderStateMixin {
  late final List<_Phase> seq = [for (var r = 0; r < widget.e.rounds; r++) ...widget.e.phases];
  late final AnimationController _c = AnimationController(vsync: this);
  int idx = -1;
  double from = 0.45;
  bool done = false;

  Future<void> _run() async {
    for (var i = 0; i < seq.length; i++) {
      if (!mounted) return;
      setState(() {
        from = i == 0 ? 0.45 : seq[i - 1].scale;
        idx = i;
      });
      HapticFeedback.selectionClick();
      _c.duration = Duration(milliseconds: (seq[i].secs * 1000).round());
      await _c.forward(from: 0).orCancel.catchError((_) {});
    }
    if (!mounted) return;
    WellnessState.mindfulMin.value += (widget.e.seconds / 60).ceil();
    HapticFeedback.mediumImpact();
    setState(() => done = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return AkPage(
      title: e.name,
      caption: e.sub,
      tint: e.color,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(children: [
          const Spacer(),
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final p = idx < 0 ? null : seq[idx];
              final s = p == null ? 0.6 : from + (p.scale - from) * Curves.easeInOut.transform(_c.value);
              final left = p == null ? 0 : (p.secs * (1 - _c.value)).ceil();
              return SizedBox(
                width: 290,
                height: 290,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 290,
                    height: 290,
                    child: CircularProgressIndicator(
                      value: p == null ? 0 : (idx + _c.value) / seq.length,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: e.color,
                      backgroundColor: e.color.withValues(alpha: 0.12),
                    ),
                  ),
                  for (var k = 0; k < 3; k++)
                    Container(
                      width: 260 * s * (1 - k * 0.16),
                      height: 260 * s * (1 - k * 0.16),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: e.color.withValues(alpha: 0.14 + k * 0.12)),
                    ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(done ? 'Well done' : p?.label ?? 'Ready', style: akT(24, w: FontWeight.w800, c: Colors.white)),
                    if (p != null && !done) Text('$left', style: akN(40, c: Colors.white)),
                  ]),
                ]),
              );
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 22,
            child: Text(
              done ? '+${(e.seconds / 60).ceil()} mindful minutes added' : idx >= 0 ? seq[idx].hint : 'Sit comfortably and relax your shoulders',
              style: akT(14.5, w: FontWeight.w600, c: akMuted),
            ),
          ),
          const Spacer(),
          if (idx < 0 || done)
            AkPress(
              onTap: done ? () => Navigator.of(context).maybePop() : _run,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: e.color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: Text(done ? 'Done' : 'Begin', style: akT(16, w: FontWeight.w800, c: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}
