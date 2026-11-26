import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/steps_screen.dart';
import 'kit3.dart';

const _img = 'assets/images';

class WellnessTabV3 extends StatelessWidget {
  const WellnessTabV3({super.key});

  @override
  Widget build(BuildContext context) {
    return const NTabPage(
      top: [_Mood(), _MindScores()],
      sheet: [
        _Breathe(),
        _Sleep(),
        _MindRoutine(),
        _Relax(),
      ],
    );
  }
}

class _Mood extends StatefulWidget {
  const _Mood();

  @override
  State<_Mood> createState() => _MoodState();
}

class _MoodState extends State<_Mood> {
  int _picked = 1;
  static const _moods = [
    ('😄', 'Great', 'Love that energy. A good day for a harder workout.'),
    ('🙂', 'Good', 'Nice. A short walk will keep the good mood going.'),
    ('😐', 'Okay', 'Try five slow breaths. It can lift you a little.'),
    ('😔', 'Low', 'Be kind to yourself today. A gentle stretch helps.'),
    ('😣', 'Stressed', 'Let’s do box breathing together below.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: nCardDeco(r: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling?',
              style: tDisplay(20, w: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _moods.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _picked = i);
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          width: i == _picked ? 52 : 46,
                          height: i == _picked ? 52 : 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _picked ? kBrandSoft : kSurface,
                            border: Border.all(
                              color: i == _picked ? kBrand : Colors.transparent,
                              width: 1.6,
                            ),
                          ),
                          child: Text(_moods[i].$1,
                              style: TextStyle(
                                  fontSize: i == _picked ? 26 : 22)),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          child: Text(_moods[i].$2,
                              style: tText(11,
                                  w: i == _picked
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  c: i == _picked ? kBrand : kMuted3)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Container(
              key: ValueKey(_picked),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_moods[_picked].$3,
                  style: tText(12.5, c: kInk3, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MindScores extends StatelessWidget {
  const _MindScores();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.spa_rounded, 'Stress', 'Low', 0.3, kSuccess),
      (Icons.bolt_rounded, 'Energy', 'Good', 0.72, kAccent),
      (Icons.bedtime_rounded, 'Rest', '82%', 0.82, kBrand),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: NPopIn(
              delay: 60 * i,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: nCardDeco(r: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NIconTile(items[i].$1, size: 32, color: items[i].$5),
                    const SizedBox(height: 10),
                    Text(items[i].$3,
                        style: tDisplay(17, w: FontWeight.w700)),
                    Text(items[i].$2, style: tText(11.5)),
                    const SizedBox(height: 8),
                    NBar(items[i].$4, color: items[i].$5, height: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Breathe extends StatefulWidget {
  const _Breathe();

  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  bool _running = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _running = !_running;
      _running ? _c.repeat() : _c.stop();
    });
  }

  String _phase(double v) {
    if (v < 0.25) return 'Breathe in';
    if (v < 0.5) return 'Hold';
    if (v < 0.75) return 'Breathe out';
    return 'Hold';
  }

  double _scale(double v) {
    if (v < 0.25) return 0.6 + 0.4 * Curves.easeInOut.transform(v / 0.25);
    if (v < 0.5) return 1;
    if (v < 0.75) {
      return 1 - 0.4 * Curves.easeInOut.transform((v - 0.5) / 0.25);
    }
    return 0.6;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Breathe'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: nCardDeco(r: 26),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final s = _running ? _scale(_c.value) : 0.7;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var k = 0; k < 3; k++)
                          Container(
                            width: 120 * s * (1 - k * 0.18),
                            height: 120 * s * (1 - k * 0.18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kBrand.withValues(alpha: 0.1 + k * 0.12),
                            ),
                          ),
                        Text(
                            _running
                                ? '${(4 - (_c.value * 16) % 4).ceil()}'
                                : '4·4',
                            style: tDisplay(20,
                                w: FontWeight.w700, c: Colors.white)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => Text(
                        _running ? _phase(_c.value) : 'Box breathing',
                        style: tDisplay(19, w: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('4 min · Calm focus', style: tText(12.5)),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _toggle,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 9, 16, 9),
                        decoration: BoxDecoration(
                          color: kBrand,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                _running
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                                color: Colors.white),
                            const SizedBox(width: 4),
                            Text(_running ? 'Pause' : 'Start',
                                style: tText(13,
                                    w: FontWeight.w700, c: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Sleep extends StatelessWidget {
  const _Sleep();

  @override
  Widget build(BuildContext context) {
    const hours = [6.8, 7.2, 6.1, 7.9, 7.5, 8.2, 7.5];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Sleep'),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: nCardDeco(r: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const NIconTile(Icons.bedtime_rounded, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: '7h 32m',
                              style: tDisplay(22, w: FontWeight.w800)),
                          TextSpan(text: '  last night', style: tText(12)),
                        ])),
                        Text('Bedtime 10:45 PM · Wake 6:17 AM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tText(12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: (hours[i] - 4) / 5),
                              duration: Duration(milliseconds: 700 + i * 60),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, _) => Container(
                                width: 22,
                                height: math.max(4, 82 * t),
                                decoration: BoxDecoration(
                                  color: i == today
                                      ? kBrand
                                      : kBrand.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(days[i],
                                style: tText(11,
                                    w: i == today
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    c: i == today ? kBrand : kMuted3)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MindRoutine extends StatefulWidget {
  const _MindRoutine();

  @override
  State<_MindRoutine> createState() => _MindRoutineState();
}

class _MindRoutineState extends State<_MindRoutine> {
  final _done = [true, false, false, false];
  static const _items = [
    (Icons.self_improvement_rounded, kBrand, 'Morning meditation', 'Streak 6 days', '10 min'),
    (Icons.edit_note_rounded, kAccent, 'Gratitude journal', 'Streak 4 days', '3 min'),
    (Icons.phone_iphone_rounded, Color(0xFF3B82F6), 'Digital detox hour', 'Streak 2 days', '60 min'),
    (Icons.nightlight_round, kSuccess, 'Wind-down stretch', 'Streak 5 days', '8 min'),
  ];

  @override
  Widget build(BuildContext context) {
    final n = _done.where((d) => d).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Mindful Routine', action: '$n/${_items.length} done'),
        for (var i = 0; i < _items.length; i++)
          NRoutineRow(
            icon: _items[i].$1,
            color: _items[i].$2,
            title: _items[i].$3,
            sub: _items[i].$4,
            trailing: _items[i].$5,
            done: _done[i],
            last: i == _items.length - 1,
            onToggle: () {
              HapticFeedback.selectionClick();
              setState(() => _done[i] = !_done[i]);
            },
          ),
      ],
    );
  }
}

class _Relax extends StatelessWidget {
  const _Relax();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NHead('Relax & Recharge'),
        NSquareGrid(
          cols: 2,
          children: [
            NPhotoCard(
              image: '$_img/sleep_bg.png',
              title: 'Sleep Stories',
              tag: '12 stories',
              play: true,
              onTap: () {},
            ),
            NPhotoCard(
              image: '$_img/category_yoga_model.png',
              title: 'Meditation',
              tag: '5–20 min',
              play: true,
              focus: Alignment.topCenter,
              onTap: () {},
            ),
            NPhotoCard(
              image: '$_img/journal_bg.png',
              title: 'Journal',
              tag: '2 min',
              onTap: () {},
            ),
            NPhotoCard(
              image: '$_img/steps_walking_person.jpg',
              title: 'Mindful Walk',
              tag: '15 min',
              onTap: () => nPush(context, const StepsScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

