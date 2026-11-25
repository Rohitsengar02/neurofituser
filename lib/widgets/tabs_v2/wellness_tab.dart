import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dashboard_highlights.dart';
import '../dashboard_motion.dart';
import 'kit.dart';

const _accent = Color(0xFFE11D48);
const _soft = Color(0xFFFFE4E6);

class WellnessTabV2 extends StatefulWidget {
  const WellnessTabV2({super.key});

  @override
  State<WellnessTabV2> createState() => _WellnessTabV2State();
}

class _WellnessTabV2State extends State<WellnessTabV2> {
  final _calmKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...revealSections([
          HeroIllustrationCard(
            eyebrow: 'MIND SCORE 82',
            title: 'You\'re feeling',
            highlight: 'balanced today',
            illustration: 'assets/images/illustrations/wellness.png',
            accent: _accent,
            soft: _soft,
            pills: const ['😌 Low stress', '⚡ Good energy', '💤 82% rest'],
            cta: 'Breathe now',
            onCta: () {
              HapticFeedback.lightImpact();
              final c = _calmKey.currentContext;
              if (c != null) {
                Scrollable.ensureVisible(
                  c,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  alignment: 0.2,
                );
              }
            },
          ),
          const _MoodCheckIn(),
          KeyedSubtree(key: _calmKey, child: const CalmMomentCard()),
          const _SleepCard(),
          const _Sessions(),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _MoodCheckIn extends StatefulWidget {
  const _MoodCheckIn();

  @override
  State<_MoodCheckIn> createState() => _MoodCheckInState();
}

class _MoodCheckInState extends State<_MoodCheckIn> {
  int? _picked;

  static const _moods = [
    ('😄', 'Great', 'Love that energy! Perfect day for a harder workout.'),
    ('🙂', 'Good', 'Nice. A short walk will keep the good mood going.'),
    ('😐', 'Okay', 'Try 5 slow breaths, it can lift you a little.'),
    ('😔', 'Low', 'Be kind to yourself today. A gentle stretch can help.'),
    ('😣', 'Stressed', 'Let\'s do box breathing together below.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(tint: _accent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: jakarta(16, FontWeight.w900, kInk),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moods.length, (i) {
                final on = _picked == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _picked = i);
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        width: on ? 50 : 44,
                        height: on ? 50 : 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? _soft : const Color(0xFFF8FAFC),
                          border: Border.all(
                            color: on ? _accent : Colors.transparent,
                            width: 1.6,
                          ),
                        ),
                        child: Text(
                          _moods[i].$1,
                          style: TextStyle(fontSize: on ? 26 : 22),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _moods[i].$2,
                        style: jakarta(
                          10.5,
                          FontWeight.w700,
                          on ? _accent : kMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _picked == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _soft.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _moods[_picked!].$3,
                        style: jakarta(
                          12.5,
                          FontWeight.w600,
                          kInk,
                          height: 1.35,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard();

  @override
  Widget build(BuildContext context) {
    const hours = [6.8, 7.2, 6.1, 7.9, 7.5, 8.2, 7.5];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const violet = Color(0xFF7C3AED);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌙', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep',
                        style: jakarta(16, FontWeight.w900, Colors.white),
                      ),
                      Text(
                        'Avg 7h 19m · bedtime 10:45 PM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          11.5,
                          FontWeight.w600,
                          const Color(0xFFC7D2FE),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '7h 32m',
                  style: jakarta(18, FontWeight.w900, Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 92,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final v = (hours[i] - 4) / 5;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: v),
                        duration: Duration(milliseconds: 700 + i * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) => Container(
                          width: 22,
                          height: 70 * t,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: i == 6
                                  ? const [Color(0xFFF9A8D4), _accent]
                                  : const [Color(0xFFA5B4FC), violet],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: jakarta(
                          10.5,
                          FontWeight.w700,
                          const Color(0xFFC7D2FE),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sessions extends StatelessWidget {
  const _Sessions();

  @override
  Widget build(BuildContext context) {
    Widget imageTile(String img, String title, String sub) => Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: DecorationImage(
          image: ResizeImage(AssetImage(img), width: 480),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              style: jakarta(14, FontWeight.w800, Colors.white),
            ),
            Text(
              sub,
              maxLines: 1,
              style: jakarta(
                11,
                FontWeight.w600,
                Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );

    Widget emojiTile(
      String e,
      String title,
      String sub,
      Color a,
      Color b,
    ) => Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a, b],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e, style: const TextStyle(fontSize: 34)),
          const Spacer(),
          Text(title, maxLines: 1, style: jakarta(14, FontWeight.w800, kInk)),
          Text(sub, maxLines: 1, style: jakarta(11, FontWeight.w600, kMuted)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Relax & recharge'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Pair(
                PressScale(
                  onTap: () {},
                  child: imageTile(
                    'assets/images/sleep_bg.png',
                    'Sleep stories',
                    '12 stories',
                  ),
                ),
                PressScale(
                  onTap: () {},
                  child: emojiTile(
                    '🧘',
                    'Meditation',
                    '5–20 min',
                    const Color(0xFFFCE7F3),
                    const Color(0xFFFBCFE8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Pair(
                PressScale(
                  onTap: () {},
                  child: emojiTile(
                    '🎧',
                    'Calm sounds',
                    'Rain, ocean, forest',
                    const Color(0xFFE0E7FF),
                    const Color(0xFFC7D2FE),
                  ),
                ),
                PressScale(
                  onTap: () {},
                  child: imageTile(
                    'assets/images/journal_bg.png',
                    'Journal',
                    '2-min reflection',
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
