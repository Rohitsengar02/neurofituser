import 'ticker_gate.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apple_kit.dart';
import 'liquid_glass.dart';
import 'mindful_games.dart';
import 'overview_home_cards.dart' show DottedLineChart;

// Wellness tab in the shared Apple style: a 3×3 grid of today's stats,
// the stress meter, mood check-in, guided breathing and exercises, today's
// journal, sleep, mindful minutes, soundscapes, affirmations and sixteen
// levelled mind games.

const _violet = Color(0xFF8B5CF6);
const _teal = Color(0xFF14B8A6);
const _indigo = Color(0xFF6366F1);
const _pink = Color(0xFFEC4899);
const _amber = Color(0xFFF59E0B);
const _green = Color(0xFF22C55E);
const _sky = Color(0xFF38BDF8);
const _red = Color(0xFFEF4444);
const _orange = Color(0xFFF97316);

class WellnessState {
  WellnessState._();
  static final mood = ValueNotifier<int>(3);
  static final mindfulMin = ValueNotifier<int>(18);
  static final journal = ValueNotifier<List<JournalEntry>>([
    JournalEntry('7:40 AM', '🌅', 'Morning intention', 'Move slowly, drink more water, and stay kind to myself in the meeting.', 'Intention'),
    JournalEntry('1:15 PM', '🙏', 'Gratitude', 'A quiet lunch walk, Mom\'s call, and finishing the hard task early.', 'Gratitude'),
    JournalEntry('6:05 PM', '💭', 'After workout', 'Felt heavy at first, lighter after the second set. Stress went from 7 to 4.', 'Reflection'),
  ]);
}

class JournalEntry {
  final String time, mood, title, body, tag;
  JournalEntry(this.time, this.mood, this.title, this.body, this.tag);
}

// =====================================================================

class WellnessTabV3 extends StatefulWidget {
  /// The tab's sections, built lazily by the home scroll view.
  static List<Widget> get sections {
    GameProgress.load();
    return _WellnessTabV3State.sections;
  }

  const WellnessTabV3({super.key});

  @override
  State<WellnessTabV3> createState() => _WellnessTabV3State();
}

class _WellnessTabV3State extends State<WellnessTabV3> {
  @override
  void initState() {
    super.initState();
    GameProgress.load();
  }

  /// The tab's sections, built lazily by the home scroll view.
  static const List<Widget> sections = [
        SizedBox(height: 18),
        AkWelcome(
          caption: 'WELLNESS · MIND SCORE 82',
          words: ['Find', 'your', 'calm,', 'Rohit'],
          accent: _violet,
          subtitle: 'Stress is lower than yesterday. A short breath session keeps it there.',
        ),
        AkHead('Today', caption: 'Nine signals from your body and mind'),
        _StatsGrid(),
        AkHead('Stress level'),
        ScrollReveal(child: _StressCard()),
        AkHead('How are you feeling?'),
        ScrollReveal(child: _MoodCard()),
        AkHead('Breathe & unwind', caption: 'Guided sessions, 1 to 6 minutes'),
        _Exercises(),
        AkHead("Today's journal", action: 'Write'),
        _Journal(),
        AkHead('Sleep'),
        ScrollReveal(child: _SleepCard()),
        AkHead('Mind games', caption: 'Play, level up, stay sharp'),
        ScrollReveal(child: _MindLevelCard()),
        SizedBox(height: 12),
        _GamesGrid(),
        AkHead('Mindful minutes'),
        ScrollReveal(child: _MindfulWeek()),
        AkHead('Soundscapes'),
        TickerGate(child: _Sounds()),
        AkHead('Daily affirmation'),
        _Affirmations(),
        SizedBox(height: 20),
      ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

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

// =====================================================================
//  STRESS
// =====================================================================

class _StressCard extends StatelessWidget {
  const _StressCard();

  @override
  Widget build(BuildContext context) {
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AkSeen(
          duration: const Duration(milliseconds: 1800),
          builder: (_, t) => SizedBox(
            height: 150,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Positioned.fill(child: CustomPaint(painter: _StressGauge(0.32 * t))),
              Positioned(
                bottom: 6,
                child: Column(children: [
                  Text('${(32 * t).round()}', style: akN(42)),
                  const SizedBox(height: 4),
                  Text('Low · relaxed', style: akT(13, w: FontWeight.w700, c: _teal)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          for (final (l, c) in [('Calm', _teal), ('Mild', _green), ('Medium', _amber), ('High', _red)])
            Expanded(
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Flexible(child: Text(l, overflow: TextOverflow.ellipsis, style: akT(11.5, c: akMuted))),
              ]),
            ),
        ]),
        const SizedBox(height: 16),
        Text('What moved it today', style: akT(14, w: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _pill('Workout −12', _green),
          _pill('Meeting +9', _red),
          _pill('Breathing −6', _teal),
          _pill('Coffee +4', _amber),
          _pill('Walk −5', _sky),
        ]),
        const SizedBox(height: 16),
        const DottedLineChart(
          values: [58, 46, 52, 40, 44, 36, 32],
          color: _teal,
          label: 'Stress this week',
          xLabels: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
          height: 110,
        ),
      ]),
    );
  }
}

Widget _pill(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: akT(12, w: FontWeight.w700, c: Color.lerp(c, akInk, 0.25)!)),
    );

class _StressGauge extends CustomPainter {
  final double v;
  _StressGauge(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 4);
    final r = math.min(size.width / 2 - 10, size.height - 14);
    const segs = [_teal, _green, _amber, _red];
    const gap = 0.04;
    for (var i = 0; i < 4; i++) {
      final start = math.pi + i * math.pi / 4 + gap / 2;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        math.pi / 4 - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = segs[i].withValues(alpha: 0.85),
      );
    }
    final a = math.pi + math.pi * v;
    final tip = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(tip, 11, Paint()..color = Colors.white);
    canvas.drawCircle(tip, 11, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = akInk);
  }

  @override
  bool shouldRepaint(covariant _StressGauge o) => o.v != v;
}

// =====================================================================
//  MOOD
// =====================================================================

class _MoodCard extends StatelessWidget {
  const _MoodCard();

  @override
  Widget build(BuildContext context) {
    const moods = [('😣', 'Awful'), ('😕', 'Low'), ('😐', 'Okay'), ('😊', 'Good'), ('🤩', 'Great')];
    const tips = [
      'Rough day. Try the 4-7-8 breath below, it calms the body in a minute.',
      'Low energy is okay. A five-minute walk and some water can lift it.',
      'Steady. A short body scan can help you notice what you need.',
      'Nice. Note what went well in your journal so you can repeat it.',
      'Brilliant. Share it with the community or spend it on a strong workout.',
    ];
    return ValueListenableBuilder<int>(
      valueListenable: WellnessState.mood,
      builder: (_, m, _) => AkGlass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < moods.length; i++)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  WellnessState.mood.value = i;
                },
                child: Column(children: [
                  AnimatedScale(
                    scale: i == m ? 1.25 : 0.95,
                    duration: const Duration(milliseconds: 380),
                    curve: akSpring,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == m ? _amber.withValues(alpha: 0.18) : Colors.transparent,
                      ),
                      child: Text(moods[i].$1, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(moods[i].$2, style: akT(11.5, w: FontWeight.w700, c: i == m ? akInk : akMuted)),
                ]),
              ),
          ]),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(tips[m], key: ValueKey(m), style: akT(13.5, w: FontWeight.w500, c: akMuted, h: 1.4)),
          ),
        ]),
      ),
    );
  }
}

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

// =====================================================================
//  JOURNAL
// =====================================================================

class _Journal extends StatelessWidget {
  const _Journal();

  static const _tagColor = {'Intention': _amber, 'Gratitude': _pink, 'Reflection': _violet, 'Note': _teal};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<JournalEntry>>(
      valueListenable: WellnessState.journal,
      builder: (_, list, _) => Column(children: [
        ScrollReveal(
          child: AkGlass(
            colors: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
            onTap: () => _write(context),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("TODAY'S PROMPT", style: akT(11, w: FontWeight.w800, c: _violet, ls: 1.2)),
                  const SizedBox(height: 6),
                  Text('What is one small thing that made today lighter?', style: akT(16, w: FontWeight.w800, h: 1.3)),
                ]),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: _violet, shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        for (final j in list.reversed)
          ScrollReveal(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AkGlass(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: (_tagColor[j.tag] ?? _teal).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                    child: Text(j.mood, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(j.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14.5, w: FontWeight.w800))),
                        Text(j.time, style: akT(11.5, c: akFaint)),
                      ]),
                      const SizedBox(height: 4),
                      Text(j.body, style: akT(13, w: FontWeight.w500, c: akMuted, h: 1.4)),
                      const SizedBox(height: 8),
                      _pill(j.tag, _tagColor[j.tag] ?? _teal),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  static void _write(BuildContext context) {
    final ctl = TextEditingController();
    var mood = '😊';
    var tag = 'Note';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: LiquidGlass(
            style: LiquidGlassStyle.material,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 14),
              Text('New entry', style: akT(20, w: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(children: [
                for (final m in ['😣', '😕', '😐', '😊', '🤩'])
                  GestureDetector(
                    onTap: () => set(() => mood = m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: m == mood ? _amber.withValues(alpha: 0.2) : Colors.transparent),
                      child: Text(m, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final t in _tagColor.keys)
                  ChoiceChip(
                    label: Text(t, style: akT(12, w: FontWeight.w700)),
                    selected: t == tag,
                    onSelected: (_) => set(() => tag = t),
                  ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: TextField(
                  controller: ctl,
                  maxLines: 4,
                  autofocus: true,
                  style: akT(15, w: FontWeight.w500),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Write freely…'),
                ),
              ),
              const SizedBox(height: 14),
              AkPress(
                onTap: () {
                  final t = ctl.text.trim();
                  if (t.isEmpty) return;
                  final n = TimeOfDay.now();
                  final time = '${n.hourOfPeriod == 0 ? 12 : n.hourOfPeriod}:${n.minute.toString().padLeft(2, '0')} ${n.period == DayPeriod.am ? 'AM' : 'PM'}';
                  WellnessState.journal.value = [
                    ...WellnessState.journal.value,
                    JournalEntry(time, mood, tag == 'Note' ? 'Quick note' : tag, t, tag),
                  ];
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _violet, borderRadius: BorderRadius.circular(16)),
                  child: Text('Save entry', style: akT(15, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  SLEEP
// =====================================================================

class _SleepCard extends StatelessWidget {
  const _SleepCard();

  @override
  Widget build(BuildContext context) {
    const stages = [('Deep', 1.4, Color(0xFF4338CA)), ('Core', 3.6, Color(0xFF6366F1)), ('REM', 1.8, Color(0xFFA78BFA)), ('Awake', 0.4, Color(0xFFFBBF24))];
    const total = 7.2;
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('7', style: akN(40)),
          Text('h ', style: akT(16, c: akMuted)),
          Text('12', style: akN(40)),
          Text('m', style: akT(16, c: akMuted)),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('11:20 PM – 6:42 AM', style: akT(12, c: akMuted)),
            const SizedBox(height: 4),
            _pill('Score 86', _indigo),
          ]),
        ]),
        const SizedBox(height: 16),
        AkSeen(
          builder: (_, t) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 18,
              child: Row(children: [
                for (final s in stages)
                  Expanded(
                    flex: (s.$2 * 100).round(),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(widthFactor: t, child: Container(color: s.$3)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          for (final s in stages)
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(s.$1, style: akT(11.5, c: akMuted)),
                ]),
                const SizedBox(height: 3),
                Text('${(s.$2 / total * 100).round()}%', style: akN(15)),
              ]),
            ),
        ]),
      ]),
    );
  }
}

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
