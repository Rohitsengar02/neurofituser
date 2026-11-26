import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apple_kit.dart';
import 'liquid_glass.dart';

// Sixteen short mindful games. Each one gets harder as its level rises;
// every round earns XP, best scores and play counts are saved on the
// device, and the player has an overall mind level.

typedef GameBody = Widget Function(int level, void Function(int score) done);

class MindGame {
  final String id;
  final String name;
  final String blurb;
  final String how;
  final IconData icon;
  final Color color;
  final GameBody body;
  const MindGame(this.id, this.name, this.blurb, this.how, this.icon, this.color, this.body);
}

class GameStat {
  int xp;
  int best;
  int plays;
  GameStat({this.xp = 0, this.best = 0, this.plays = 0});
  int get level => 1 + xp ~/ 120;
  double get levelProgress => (xp % 120) / 120;
  Map<String, int> toJson() => {'xp': xp, 'best': best, 'plays': plays};
}

class GameProgress {
  GameProgress._();
  static final Map<String, GameStat> _stats = {};
  static final ValueNotifier<int> changes = ValueNotifier(0);
  static bool _loaded = false;
  static const _key = 'mind_games_v1';

  static GameStat of(String id) => _stats.putIfAbsent(id, GameStat.new);
  static int get totalXp => _stats.values.fold(0, (a, s) => a + s.xp);
  static int get totalPlays => _stats.values.fold(0, (a, s) => a + s.plays);
  static int get mindLevel => 1 + totalXp ~/ 400;
  static double get mindProgress => (totalXp % 400) / 400;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        m.forEach((k, v) {
          final j = v as Map<String, dynamic>;
          _stats[k] = GameStat(xp: j['xp'] ?? 0, best: j['best'] ?? 0, plays: j['plays'] ?? 0);
        });
      } else {
        // A little history so the tab doesn't open empty.
        const seed = {'memory': 260, 'stroop': 140, 'bubbles': 90, 'breath': 200, 'schulte': 60};
        seed.forEach((k, v) => _stats[k] = GameStat(xp: v, best: v ~/ 3, plays: v ~/ 40));
      }
    } catch (_) {}
    changes.value++;
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(_stats.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}
  }

  /// Records a finished round; returns (xpGained, leveledUp).
  static (int, bool) record(String id, int score) {
    final s = of(id);
    final before = s.level;
    final gained = math.max(10, score);
    s.xp += gained;
    s.plays++;
    if (score > s.best) s.best = score;
    changes.value++;
    _save();
    return (gained, s.level > before);
  }
}

final _rnd = math.Random();

final List<MindGame> mindGames = [
  MindGame('memory', 'Memory Match', 'Flip and pair calm cards', 'Turn two cards at a time and find every pair in as few moves as you can.',
      Icons.style_rounded, const Color(0xFF8B5CF6), (l, d) => _MemoryGame(level: l, done: d)),
  MindGame('stroop', 'Color Calm', 'Name the ink, not the word', 'A colour word appears in a different ink. Tap the ink colour. 25 seconds.',
      Icons.palette_rounded, const Color(0xFFEC4899), (l, d) => _StroopGame(level: l, done: d)),
  MindGame('bubbles', 'Bubble Pop', 'Pop the calm blue bubbles', 'Pop the blue bubbles as they float up. Leave the red ones alone. 25 seconds.',
      Icons.bubble_chart_rounded, const Color(0xFF38BDF8), (l, d) => _BubbleGame(level: l, done: d)),
  MindGame('schulte', 'Number Flow', 'Tap 1 to N in order', 'Find and tap the numbers in order, as fast as you can stay calm.',
      Icons.grid_view_rounded, const Color(0xFF22C55E), (l, d) => _SchulteGame(level: l, done: d)),
  MindGame('simon', 'Pattern Echo', 'Repeat the glowing pattern', 'Watch the pads light up, then tap them back in the same order.',
      Icons.blur_on_rounded, const Color(0xFFF59E0B), (l, d) => _SimonGame(level: l, done: d)),
  MindGame('reaction', 'Zen Reflex', 'Tap the moment it turns green', 'Wait for the circle to turn green, then tap. Five rounds. Too early costs points.',
      Icons.radio_button_checked_rounded, const Color(0xFF10B981), (l, d) => _ReactionGame(level: l, done: d)),
  MindGame('odd', 'Odd One Out', 'Spot the one that differs', 'One tile is different. Find as many as you can in 25 seconds.',
      Icons.search_rounded, const Color(0xFF6366F1), (l, d) => _OddGame(level: l, done: d)),
  MindGame('breath', 'Breath Sync', 'Hold to inhale, let go to exhale', 'Press and hold while the circle grows, release while it shrinks. Six breaths.',
      Icons.air_rounded, const Color(0xFF14B8A6), (l, d) => _BreathGame(level: l, done: d)),
  MindGame('focus', 'Focus Dot', 'Keep your finger on the dot', 'Rest your finger on the drifting dot and follow it for 20 seconds.',
      Icons.adjust_rounded, const Color(0xFFEF4444), (l, d) => _FocusGame(level: l, done: d)),
  MindGame('garden', 'Zen Garden', 'Rake slow lines in the sand', 'Draw slow, flowing lines in the sand for 30 seconds. Smooth strokes score more.',
      Icons.waves_rounded, const Color(0xFFD97706), (l, d) => _GardenGame(level: l, done: d)),
  MindGame('sums', 'Calm Sums', 'Gentle quick maths', 'Pick the right answer to each sum. 30 seconds.',
      Icons.calculate_rounded, const Color(0xFF0EA5E9), (l, d) => _SumsGame(level: l, done: d)),
  MindGame('words', 'Word Garden', 'Unscramble calm words', 'Tap the letters in order to spell each calm word.',
      Icons.spellcheck_rounded, const Color(0xFF84CC16), (l, d) => _WordGame(level: l, done: d)),
  MindGame('gratitude', 'Gratitude Jar', 'Fill the jar with 3 good things', 'Write three things you are grateful for and watch the jar glow.',
      Icons.favorite_rounded, const Color(0xFFF43F5E), (l, d) => _GratitudeGame(level: l, done: d)),
  MindGame('nback', 'Shape Memory', 'Same shape as before?', 'Say whether each shape matches the one just before it. 25 seconds.',
      Icons.category_rounded, const Color(0xFFA855F7), (l, d) => _NBackGame(level: l, done: d)),
  MindGame('rain', 'Rain Catch', 'Catch the falling drops', 'Slide the leaf to catch raindrops. Miss five and the shower ends.',
      Icons.water_drop_rounded, const Color(0xFF3B82F6), (l, d) => _RainGame(level: l, done: d)),
  MindGame('stars', 'Star Path', 'Connect the stars in order', 'Tap the stars from 1 upward to draw a constellation.',
      Icons.auto_awesome_rounded, const Color(0xFF1E40AF), (l, d) => _StarsGame(level: l, done: d)),
];

// =====================================================================
//  SHELL: intro → play → result
// =====================================================================

void openMindGame(BuildContext context, MindGame g) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MindGamePage(game: g)));

class MindGamePage extends StatefulWidget {
  final MindGame game;
  const MindGamePage({super.key, required this.game});

  @override
  State<MindGamePage> createState() => _MindGamePageState();
}

class _MindGamePageState extends State<MindGamePage> {
  int _phase = 0; // 0 intro, 1 play, 2 result
  int _round = 0;
  int _score = 0;
  int _gained = 0;
  bool _levelUp = false;

  void _done(int score) {
    if (!mounted || _phase != 1) return;
    final (g, up) = GameProgress.record(widget.game.id, score);
    HapticFeedback.mediumImpact();
    setState(() {
      _score = score;
      _gained = g;
      _levelUp = up;
      _phase = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final s = GameProgress.of(g.id);
    return AkPage(
      title: g.name,
      caption: 'Level ${s.level} · best ${s.best}',
      tint: g.color,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: akSpring,
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c),
        ),
        child: switch (_phase) {
          0 => _intro(g, s),
          1 => Padding(
              key: ValueKey('play$_round'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: g.body(s.level, _done),
            ),
          _ => _result(g, s),
        },
      ),
    );
  }

  Widget _intro(MindGame g, GameStat s) => ListView(
        key: const ValueKey('intro'),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 30),
        children: [
          AkGlass(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [g.color.withValues(alpha: 0.7), g.color]),
                ),
                child: Icon(g.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text('How to play', style: akT(16, w: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(g.how, style: akT(14, w: FontWeight.w500, c: akMuted, h: 1.45)),
              const SizedBox(height: 18),
              Row(children: [
                _chip('Level ${s.level}', g.color),
                const SizedBox(width: 8),
                _chip('${s.plays} plays', akMuted),
                const SizedBox(width: 8),
                _chip('Best ${s.best}', const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: s.levelProgress,
                  minHeight: 8,
                  color: g.color,
                  backgroundColor: g.color.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 6),
              Text('${(120 - s.xp % 120)} XP to level ${s.level + 1}', style: akT(12, c: akMuted)),
            ]),
          ),
          const SizedBox(height: 18),
          _bigButton('Start', g.color, () => setState(() => _phase = 1)),
        ],
      );

  Widget _result(MindGame g, GameStat s) => ListView(
        key: const ValueKey('result'),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 30),
        children: [
          AkGlass(
            child: Column(children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: akSpring,
                builder: (_, v, c) => Transform.scale(scale: v, child: c),
                child: Text(_levelUp ? '🎉' : '✨', style: const TextStyle(fontSize: 54)),
              ),
              const SizedBox(height: 8),
              Text(_levelUp ? 'Level up! Now level ${s.level}' : 'Nicely done', style: akT(20, w: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _stat('Score', '$_score', g.color),
                _stat('XP', '+$_gained', const Color(0xFF22C55E)),
                _stat('Best', '${s.best}', const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: s.levelProgress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    color: g.color,
                    backgroundColor: g.color.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          _bigButton('Play again', g.color, () => setState(() {
                _round++;
                _phase = 1;
              })),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text('Done', style: akT(15, w: FontWeight.w700, c: akMuted)),
            ),
          ),
        ],
      );

  Widget _stat(String l, String v, Color c) => Expanded(
        child: Column(children: [
          Text(v, style: akN(26, c: c)),
          const SizedBox(height: 4),
          Text(l, style: akT(12, c: akMuted)),
        ]),
      );

  Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: akT(12, w: FontWeight.w700, c: c)),
      );

  Widget _bigButton(String t, Color c, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AkPress(
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: [c.withValues(alpha: 0.85), c]),
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Text(t, style: akT(16, w: FontWeight.w800, c: Colors.white)),
          ),
        ),
      );
}

// =====================================================================
//  SHARED PIECES
// =====================================================================

/// Countdown bar plus score; calls [onEnd] when time runs out.
class _Timer extends StatefulWidget {
  final int seconds;
  final VoidCallback onEnd;
  final String label;
  final Color color;
  const _Timer({required this.seconds, required this.onEnd, required this.label, required this.color});
  @override
  State<_Timer> createState() => _TimerState();
}

class _TimerState extends State<_Timer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onEnd();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Column(children: [
          Row(children: [
            Text('${(widget.seconds * (1 - _c.value)).ceil()}s', style: akN(15, c: akMuted)),
            const Spacer(),
            Text(widget.label, style: akN(17, c: widget.color)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 1 - _c.value,
              minHeight: 6,
              color: widget.color,
              backgroundColor: widget.color.withValues(alpha: 0.12),
            ),
          ),
        ]),
      );
}

Widget _tile(Widget child, {Color? color, VoidCallback? onTap, double r = 18}) => AkPress(
      onTap: onTap,
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(r),
        shadow: false,
        colors: color == null ? null : [color.withValues(alpha: 0.85), color],
        child: Center(child: child),
      ),
    );

// =====================================================================
//  1. MEMORY MATCH
// =====================================================================

class _MemoryGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _MemoryGame({required this.level, required this.done});
  @override
  State<_MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<_MemoryGame> {
  static const _faces = ['🌿', '🌸', '🌙', '☀️', '🌊', '🍃', '🪷', '🦋', '⭐', '🍀'];
  late final int pairs = (3 + widget.level).clamp(4, 10);
  late final List<String> cards = ([..._faces.take(pairs), ..._faces.take(pairs)]..shuffle(_rnd));
  final Set<int> open = {}, matched = {};
  int moves = 0;
  bool busy = false;

  void _flip(int i) {
    if (busy || open.contains(i) || matched.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => open.add(i));
    if (open.length == 2) {
      moves++;
      final [a, b] = open.toList();
      if (cards[a] == cards[b]) {
        setState(() {
          matched.addAll(open);
          open.clear();
        });
        if (matched.length == cards.length) {
          Future.delayed(const Duration(milliseconds: 500), () => widget.done(math.max(10, pairs * 20 - (moves - pairs) * 4)));
        }
      } else {
        busy = true;
        Future.delayed(const Duration(milliseconds: 750), () {
          if (!mounted) return;
          setState(() {
            open.clear();
            busy = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = pairs <= 6 ? 3 : 4;
    return Column(children: [
      Row(children: [
        Text('Moves $moves', style: akN(16, c: akMuted)),
        const Spacer(),
        Text('${matched.length ~/ 2} / $pairs pairs', style: akN(16, c: const Color(0xFF8B5CF6))),
      ]),
      const SizedBox(height: 14),
      Expanded(
        child: GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (var i = 0; i < cards.length; i++)
              GestureDetector(
                onTap: () => _flip(i),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: open.contains(i) || matched.contains(i) ? 1 : 0),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) {
                    final front = v > 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateY(math.pi * v),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(front ? math.pi : 0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: front
                                ? LinearGradient(colors: [
                                    Colors.white,
                                    matched.contains(i) ? const Color(0xFFDCFCE7) : const Color(0xFFF3E8FF),
                                  ])
                                : const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          alignment: Alignment.center,
                          child: front
                              ? Text(cards[i], style: const TextStyle(fontSize: 30))
                              : const Icon(Icons.spa_rounded, color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}

// =====================================================================
//  2. COLOR CALM (Stroop)
// =====================================================================

class _StroopGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _StroopGame({required this.level, required this.done});
  @override
  State<_StroopGame> createState() => _StroopGameState();
}

class _StroopGameState extends State<_StroopGame> {
  static const _names = ['RED', 'BLUE', 'GREEN', 'ORANGE', 'PURPLE', 'PINK'];
  static const _cols = [Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEC4899)];
  late final int n = (3 + widget.level).clamp(4, 6);
  int word = 0, ink = 1, score = 0, streak = 0;
  bool? last;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    word = _rnd.nextInt(n);
    do {
      ink = _rnd.nextInt(n);
    } while (ink == word);
  }

  void _pick(int i) {
    setState(() {
      last = i == ink;
      if (last!) {
        streak++;
        score += 5 + math.min(streak, 5);
      } else {
        streak = 0;
        score = math.max(0, score - 3);
      }
      _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _Timer(seconds: 25, onEnd: () => widget.done(score), label: '$score pts', color: const Color(0xFFEC4899)),
      const Spacer(),
      Text('Tap the INK colour', style: akT(13, c: akMuted)),
      const SizedBox(height: 10),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Text(_names[word], key: ValueKey('$word$ink$score'), style: akT(48, w: FontWeight.w900, c: _cols[ink], ls: 1)),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 20,
        child: last == null ? null : Text(last! ? 'Calm and correct' : 'Breathe, try again', style: akT(13, c: last! ? const Color(0xFF16A34A) : const Color(0xFFEF4444))),
      ),
      const Spacer(),
      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          for (var i = 0; i < n; i++) _tile(const SizedBox(), color: _cols[i], onTap: () => _pick(i)),
        ],
      ),
    ]);
  }
}

// =====================================================================
//  3. BUBBLE POP
// =====================================================================

class _Bubble {
  double x, y, r, speed;
  bool bad;
  _Bubble(this.x, this.y, this.r, this.speed, this.bad);
}

class _BubbleGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _BubbleGame({required this.level, required this.done});
  @override
  State<_BubbleGame> createState() => _BubbleGameState();
}

class _BubbleGameState extends State<_BubbleGame> with SingleTickerProviderStateMixin {
  final bubbles = <_Bubble>[];
  int score = 0;
  Duration _last = Duration.zero;
  late final _tick = createTicker(_step)..start();

  void _step(Duration d) {
    final dt = (d - _last).inMicroseconds / 1e6;
    _last = d;
    if (_rnd.nextDouble() < 0.035 + widget.level * 0.006) {
      bubbles.add(_Bubble(_rnd.nextDouble(), 1.1, 22 + _rnd.nextDouble() * 18, 0.12 + _rnd.nextDouble() * 0.1 + widget.level * 0.02,
          _rnd.nextDouble() < 0.22));
    }
    for (final b in bubbles) {
      b.y -= b.speed * dt;
    }
    bubbles.removeWhere((b) => b.y < -0.15);
    setState(() {});
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _Timer(seconds: 25, onEnd: () => widget.done(score), label: '$score pts', color: const Color(0xFF38BDF8)),
      const SizedBox(height: 12),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)]),
            ),
            child: LayoutBuilder(builder: (context, c) {
              return Stack(children: [
                for (final b in bubbles)
                  Positioned(
                    left: b.x * (c.maxWidth - b.r * 2),
                    top: b.y * c.maxHeight,
                    child: GestureDetector(
                      onTapDown: (_) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          score = math.max(0, score + (b.bad ? -5 : 5));
                          bubbles.remove(b);
                        });
                      },
                      child: Container(
                        width: b.r * 2,
                        height: b.r * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.4, -0.4),
                            colors: b.bad
                                ? [const Color(0xFFFECACA), const Color(0xFFEF4444)]
                                : [Colors.white, const Color(0xFF38BDF8).withValues(alpha: 0.75)],
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
          ),
        ),
      ),
    ]);
  }
}

// =====================================================================
//  4. NUMBER FLOW (Schulte)
// =====================================================================

class _SchulteGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _SchulteGame({required this.level, required this.done});
  @override
  State<_SchulteGame> createState() => _SchulteGameState();
}

class _SchulteGameState extends State<_SchulteGame> {
  late final int side = (2 + widget.level).clamp(3, 5);
  late final List<int> nums = List.generate(side * side, (i) => i + 1)..shuffle(_rnd);
  int next = 1;
  final sw = Stopwatch()..start();
  int? wrong;

  void _tap(int v) {
    if (v == next) {
      HapticFeedback.selectionClick();
      setState(() => next++);
      if (next > side * side) {
        sw.stop();
        final secs = sw.elapsedMilliseconds / 1000;
        widget.done(math.max(10, (side * side * 6 - secs * 2).round()));
      }
    } else {
      setState(() => wrong = v);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text('Find', style: akT(15, c: akMuted)),
        const SizedBox(width: 8),
        Text('$next', style: akN(30, c: const Color(0xFF22C55E))),
        const Spacer(),
        StreamBuilder(
          stream: Stream.periodic(const Duration(milliseconds: 100)),
          builder: (_, _) => Text('${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s', style: akN(16, c: akMuted)),
        ),
      ]),
      const SizedBox(height: 16),
      AspectRatio(
        aspectRatio: 1,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: side,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final v in nums)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: v < next ? 0.25 : 1,
                child: _tile(
                  Text('$v', style: akN(22, c: v == wrong ? const Color(0xFFEF4444) : akInk)),
                  onTap: () => _tap(v),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}

// =====================================================================
//  5. PATTERN ECHO (Simon)
// =====================================================================

class _SimonGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _SimonGame({required this.level, required this.done});
  @override
  State<_SimonGame> createState() => _SimonGameState();
}

class _SimonGameState extends State<_SimonGame> {
  static const _c = [Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFFEC4899)];
  final seq = <int>[];
  int input = 0;
  int? lit;
  bool showing = true;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 1 + widget.level ~/ 2; i++) {
      seq.add(_rnd.nextInt(4));
    }
    _grow();
  }

  Future<void> _grow() async {
    seq.add(_rnd.nextInt(4));
    setState(() {
      showing = true;
      input = 0;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    final ms = math.max(260, 560 - widget.level * 40);
    for (final s in seq) {
      if (!mounted) return;
      setState(() => lit = s);
      await Future.delayed(Duration(milliseconds: ms));
      if (!mounted) return;
      setState(() => lit = null);
      await Future.delayed(const Duration(milliseconds: 160));
    }
    if (mounted) setState(() => showing = false);
  }

  void _tap(int i) {
    if (showing) return;
    HapticFeedback.selectionClick();
    setState(() => lit = i);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => lit = null);
    });
    if (seq[input] != i) {
      widget.done((seq.length - 1) * 10);
      return;
    }
    input++;
    if (input == seq.length) Future.delayed(const Duration(milliseconds: 400), _grow);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text(showing ? 'Watch…' : 'Your turn', style: akT(16, w: FontWeight.w700, c: akMuted)),
        const Spacer(),
        Text('Length ${seq.length}', style: akN(17, c: const Color(0xFFF59E0B))),
      ]),
      const SizedBox(height: 20),
      AspectRatio(
        aspectRatio: 1,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          children: [
            for (var i = 0; i < 4; i++)
              GestureDetector(
                onTapDown: (_) => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: _c[i].withValues(alpha: lit == i ? 1 : 0.28),
                    boxShadow: lit == i ? [BoxShadow(color: _c[i].withValues(alpha: 0.6), blurRadius: 30)] : const [],
                  ),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}

// =====================================================================
//  6. ZEN REFLEX
// =====================================================================

class _ReactionGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _ReactionGame({required this.level, required this.done});
  @override
  State<_ReactionGame> createState() => _ReactionGameState();
}

class _ReactionGameState extends State<_ReactionGame> {
  int round = 0, score = 0;
  bool green = false;
  String msg = 'Wait for green…';
  Timer? _t;
  final sw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    green = false;
    _t?.cancel();
    _t = Timer(Duration(milliseconds: 1200 + _rnd.nextInt(2200)), () {
      if (!mounted) return;
      setState(() => green = true);
      sw
        ..reset()
        ..start();
    });
  }

  void _tap() {
    if (!green) {
      setState(() {
        score = math.max(0, score - 5);
        msg = 'Too soon. Breathe.';
      });
      _arm();
      return;
    }
    final ms = sw.elapsedMilliseconds;
    HapticFeedback.mediumImpact();
    setState(() {
      score += math.max(2, (700 - ms) ~/ 12);
      msg = '$ms ms';
      round++;
    });
    if (round >= 5) {
      _t?.cancel();
      widget.done(score);
    } else {
      _arm();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = green ? const Color(0xFF10B981) : const Color(0xFFCBD5E1);
    return Column(children: [
      Row(children: [
        Text('Round ${math.min(round + 1, 5)} / 5', style: akN(16, c: akMuted)),
        const Spacer(),
        Text('$score pts', style: akN(17, c: const Color(0xFF10B981))),
      ]),
      const Spacer(),
      GestureDetector(
        onTapDown: (_) => _tap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: green ? 50 : 10)],
          ),
          alignment: Alignment.center,
          child: Text(green ? 'TAP' : 'wait', style: akT(26, w: FontWeight.w800, c: Colors.white)),
        ),
      ),
      const SizedBox(height: 20),
      Text(msg, style: akT(16, w: FontWeight.w700, c: akMuted)),
      const Spacer(),
    ]);
  }
}

// =====================================================================
//  7. ODD ONE OUT
// =====================================================================

class _OddGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _OddGame({required this.level, required this.done});
  @override
  State<_OddGame> createState() => _OddGameState();
}

class _OddGameState extends State<_OddGame> {
  static const _pairs = [
    ('🌕', '🌖'), ('🍏', '🍎'), ('🌷', '🌹'), ('🐢', '🦎'), ('🌲', '🌳'),
    ('😊', '🙂'), ('🍋', '🍊'), ('⭐', '🌟'), ('🐟', '🐠'), ('🍃', '🌿'),
  ];
  late final int side = (2 + widget.level).clamp(3, 6);
  int odd = 0, score = 0, pair = 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    odd = _rnd.nextInt(side * side);
    pair = _rnd.nextInt(_pairs.length);
  }

  @override
  Widget build(BuildContext context) {
    final p = _pairs[pair];
    return Column(children: [
      _Timer(seconds: 25, onEnd: () => widget.done(score), label: '$score pts', color: const Color(0xFF6366F1)),
      const SizedBox(height: 20),
      AspectRatio(
        aspectRatio: 1,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: side,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 0; i < side * side; i++)
              _tile(
                Text(i == odd ? p.$2 : p.$1, style: TextStyle(fontSize: 120 / side + 6)),
                r: 14,
                onTap: () => setState(() {
                  if (i == odd) {
                    score += 6;
                    _next();
                  } else {
                    score = math.max(0, score - 2);
                  }
                }),
              ),
          ],
        ),
      ),
    ]);
  }
}

// =====================================================================
//  8. BREATH SYNC
// =====================================================================

class _BreathGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _BreathGame({required this.level, required this.done});
  @override
  State<_BreathGame> createState() => _BreathGameState();
}

class _BreathGameState extends State<_BreathGame> with SingleTickerProviderStateMixin {
  late final double cycle = 8.0 + math.min(widget.level, 4); // seconds per breath
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: (cycle * 6000).round()))
    ..addListener(_sample)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.done((synced / math.max(1, samples) * 100).round());
    })
    ..forward();
  bool holding = false;
  int synced = 0, samples = 0;

  double get _phase => (_c.value * 6) % 1; // 0..1 within a breath
  bool get _inhale => _phase < 0.5;

  void _sample() {
    samples++;
    if (holding == _inhale) synced++;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF14B8A6);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final p = _phase;
        final size = 0.45 + 0.55 * (p < 0.5 ? Curves.easeInOut.transform(p * 2) : Curves.easeInOut.transform(2 - p * 2));
        final pct = samples == 0 ? 100 : (synced / samples * 100).round();
        return Column(children: [
          Row(children: [
            Text('Breath ${math.min(6, (_c.value * 6).floor() + 1)} / 6', style: akN(16, c: akMuted)),
            const Spacer(),
            Text('$pct% in sync', style: akN(17, c: teal)),
          ]),
          const Spacer(),
          GestureDetector(
            onTapDown: (_) => setState(() => holding = true),
            onTapUp: (_) => setState(() => holding = false),
            onTapCancel: () => setState(() => holding = false),
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: teal.withValues(alpha: 0.2), width: 2)),
                ),
                Container(
                  width: 280 * size,
                  height: 280 * size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [teal.withValues(alpha: holding ? 0.9 : 0.5), teal.withValues(alpha: 0.15)]),
                  ),
                ),
                Text(_inhale ? 'Inhale' : 'Exhale', style: akT(24, w: FontWeight.w800, c: Colors.white)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text(_inhale ? 'Hold your finger down' : 'Let go and breathe out', style: akT(15, w: FontWeight.w600, c: akMuted)),
          const Spacer(),
        ]);
      },
    );
  }
}

// =====================================================================
//  9. FOCUS DOT
// =====================================================================

class _FocusGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _FocusGame({required this.level, required this.done});
  @override
  State<_FocusGame> createState() => _FocusGameState();
}

class _FocusGameState extends State<_FocusGame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))
    ..addListener(_sample)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.done((on / math.max(1, n) * 100).round());
    })
    ..forward();
  Offset? finger;
  Size area = Size.zero;
  int on = 0, n = 0;

  Offset _dot(double t) {
    final k = 1 + widget.level * 0.25;
    return Offset(
      area.width * (0.5 + 0.38 * math.sin(t * 2 * math.pi * 1.3 * k)),
      area.height * (0.5 + 0.38 * math.sin(t * 2 * math.pi * 0.9 * k + 1.2)),
    );
  }

  void _sample() {
    if (area == Size.zero) return;
    n++;
    if (finger != null && (finger! - _dot(_c.value)).distance < 40) on++;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return Column(children: [
      AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(children: [
          Text('${(20 * (1 - _c.value)).ceil()}s', style: akN(16, c: akMuted)),
          const Spacer(),
          Text('${n == 0 ? 0 : (on / n * 100).round()}% focus', style: akN(17, c: red)),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          area = c.biggest;
          return GestureDetector(
            onPanStart: (d) => finger = d.localPosition,
            onPanUpdate: (d) => finger = d.localPosition,
            onPanEnd: (_) => finger = null,
            child: AkGlass(
              gutter: false,
              padding: EdgeInsets.zero,
              child: SizedBox.expand(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) {
                    final p = _dot(_c.value);
                    final hit = finger != null && (finger! - p).distance < 40;
                    return Stack(children: [
                      Positioned(
                        left: p.dx - 28,
                        top: p.dy - 28,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: red.withValues(alpha: hit ? 0.9 : 0.45),
                            boxShadow: [BoxShadow(color: red.withValues(alpha: hit ? 0.6 : 0.2), blurRadius: hit ? 30 : 12)],
                          ),
                        ),
                      ),
                    ]);
                  },
                ),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

// =====================================================================
//  10. ZEN GARDEN
// =====================================================================

class _GardenGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _GardenGame({required this.level, required this.done});
  @override
  State<_GardenGame> createState() => _GardenGameState();
}

class _GardenGameState extends State<_GardenGame> {
  final strokes = <List<Offset>>[];
  double smooth = 0;

  int get _score => (strokes.length * 3 + smooth / 40).round().clamp(5, 120);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _Timer(seconds: 30, onEnd: () => widget.done(_score), label: '$_score calm', color: const Color(0xFFD97706)),
      const SizedBox(height: 12),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: GestureDetector(
            onPanStart: (d) => setState(() => strokes.add([d.localPosition])),
            onPanUpdate: (d) => setState(() {
              strokes.last.add(d.localPosition);
              if (d.delta.distance < 8) smooth += d.delta.distance;
            }),
            child: CustomPaint(painter: _SandPainter(strokes), size: Size.infinite),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text('Slow strokes earn more calm', style: akT(13, c: akMuted)),
    ]);
  }
}

class _SandPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SandPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF5E6C8));
    final r = math.Random(3);
    final dot = Paint()..color = const Color(0xFFE7D3AA);
    for (var i = 0; i < 400; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), 1, dot);
    }
    for (final s in strokes) {
      if (s.length < 2) continue;
      for (final o in [-6.0, 0.0, 6.0]) {
        final path = Path()..moveTo(s.first.dx + o, s.first.dy + o);
        for (final p in s.skip(1)) {
          path.lineTo(p.dx + o, p.dy + o);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFC8A773),
        );
      }
    }
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.22), 26, Paint()..color = const Color(0xFF9CA3AF));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.75), 18, Paint()..color = const Color(0xFFA8A29E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =====================================================================
//  11. CALM SUMS
// =====================================================================

class _SumsGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _SumsGame({required this.level, required this.done});
  @override
  State<_SumsGame> createState() => _SumsGameState();
}

class _SumsGameState extends State<_SumsGame> {
  int a = 0, b = 0, score = 0;
  bool plus = true;
  List<int> opts = [];

  @override
  void initState() {
    super.initState();
    _next();
  }

  int get ans => plus ? a + b : a - b;

  void _next() {
    final m = 8 + widget.level * 6;
    a = 2 + _rnd.nextInt(m);
    b = 1 + _rnd.nextInt(m);
    plus = widget.level < 2 || _rnd.nextBool();
    if (!plus && b > a) {
      final t = a;
      a = b;
      b = t;
    }
    final s = <int>{ans};
    while (s.length < 3) {
      s.add(ans + _rnd.nextInt(7) - 3);
    }
    opts = s.toList()..shuffle(_rnd);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _Timer(seconds: 30, onEnd: () => widget.done(score), label: '$score pts', color: const Color(0xFF0EA5E9)),
      const Spacer(),
      Text('$a ${plus ? '+' : '−'} $b', style: akN(56)),
      const Spacer(),
      Row(children: [
        for (final o in opts)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: SizedBox(
                height: 74,
                child: _tile(
                  Text('$o', style: akN(26)),
                  onTap: () => setState(() {
                    score = o == ans ? score + 6 : math.max(0, score - 3);
                    _next();
                  }),
                ),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 20),
    ]);
  }
}

// =====================================================================
//  12. WORD GARDEN
// =====================================================================

class _WordGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _WordGame({required this.level, required this.done});
  @override
  State<_WordGame> createState() => _WordGameState();
}

class _WordGameState extends State<_WordGame> {
  static const _easy = ['CALM', 'REST', 'EASE', 'GLOW', 'HOPE', 'KIND', 'SOFT', 'WARM'];
  static const _hard = ['PEACE', 'SMILE', 'TRUST', 'BREATHE', 'GENTLE', 'SERENE', 'BALANCE', 'MINDFUL'];
  late final List<String> words = ([...(widget.level < 3 ? _easy : _hard)]..shuffle(_rnd)).take(5).toList();
  int w = 0, score = 0;
  String typed = '';
  late List<(int, String)> letters;
  final used = <int>{};
  final sw = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final l = words[w].split('');
    letters = [for (var i = 0; i < l.length; i++) (i, l[i])]..shuffle(_rnd);
    used.clear();
    typed = '';
  }

  void _tap(int k, String ch) {
    if (used.contains(k)) return;
    final target = words[w];
    if (target[typed.length] != ch) {
      HapticFeedback.heavyImpact();
      setState(() {
        typed = '';
        used.clear();
      });
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      used.add(k);
      typed += ch;
    });
    if (typed == target) {
      score += target.length * 4;
      if (w == words.length - 1) {
        widget.done(math.max(10, score - sw.elapsed.inSeconds ~/ 3));
      } else {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) return;
          setState(() {
            w++;
            _load();
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = words[w];
    return Column(children: [
      Row(children: [
        Text('Word ${w + 1} / ${words.length}', style: akN(16, c: akMuted)),
        const Spacer(),
        Text('$score pts', style: akN(17, c: const Color(0xFF65A30D))),
      ]),
      const Spacer(),
      Wrap(spacing: 8, children: [
        for (var i = 0; i < target.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: i < typed.length ? const Color(0xFF84CC16) : Colors.white,
              border: Border.all(color: const Color(0xFF84CC16).withValues(alpha: 0.5)),
            ),
            child: Text(i < typed.length ? typed[i] : '', style: akT(22, w: FontWeight.w800, c: Colors.white)),
          ),
      ]),
      const Spacer(),
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
        for (final (k, ch) in letters)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: used.contains(k) ? 0.2 : 1,
            child: SizedBox(width: 58, height: 58, child: _tile(Text(ch, style: akT(24, w: FontWeight.w800)), onTap: () => _tap(k, ch))),
          ),
      ]),
      const SizedBox(height: 24),
    ]);
  }
}

// =====================================================================
//  13. GRATITUDE JAR
// =====================================================================

class _GratitudeGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _GratitudeGame({required this.level, required this.done});
  @override
  State<_GratitudeGame> createState() => _GratitudeGameState();
}

class _GratitudeGameState extends State<_GratitudeGame> {
  final items = <String>[];
  final ctl = TextEditingController();

  void _add() {
    final t = ctl.text.trim();
    if (t.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      items.add(t);
      ctl.clear();
    });
    if (items.length == 3) Future.delayed(const Duration(milliseconds: 900), () => widget.done(30 + items.join().length ~/ 4));
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const rose = Color(0xFFF43F5E);
    return ListView(children: [
      Center(
        child: SizedBox(
          width: 170,
          height: 200,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Container(
              width: 150,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(40)),
                color: rose.withValues(alpha: 0.06),
                border: Border.all(color: rose.withValues(alpha: 0.35), width: 2),
              ),
            ),
            for (var i = 0; i < items.length; i++)
              Positioned(
                bottom: 20.0 + i * 46,
                left: 40.0 + (i.isOdd ? 40 : 0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: akSpring,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFDE68A),
                      boxShadow: [BoxShadow(color: const Color(0xFFFBBF24).withValues(alpha: 0.8), blurRadius: 22)],
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                  ),
                ),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Text('${items.length} / 3 good things', textAlign: TextAlign.center, style: akN(17, c: rose)),
      const SizedBox(height: 14),
      for (final t in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            const Icon(Icons.favorite_rounded, color: rose, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: akT(14.5, w: FontWeight.w600))),
          ]),
        ),
      if (items.length < 3)
        AkGlass(
          gutter: false,
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          radius: 20,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: ctl,
                onSubmitted: (_) => _add(),
                style: akT(15),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Today I am grateful for…'),
              ),
            ),
            IconButton(onPressed: _add, icon: const Icon(Icons.arrow_upward_rounded, color: rose)),
          ]),
        ),
    ]);
  }
}

// =====================================================================
//  14. SHAPE MEMORY (1-back)
// =====================================================================

class _NBackGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _NBackGame({required this.level, required this.done});
  @override
  State<_NBackGame> createState() => _NBackGameState();
}

class _NBackGameState extends State<_NBackGame> {
  static const _shapes = [Icons.circle, Icons.square_rounded, Icons.change_history_rounded, Icons.star_rounded, Icons.favorite_rounded, Icons.hexagon_rounded];
  late final int back = widget.level >= 4 ? 2 : 1;
  final hist = <int>[];
  int score = 0;
  bool? last;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i <= back; i++) {
      hist.add(_rnd.nextInt(4));
    }
  }

  void _answer(bool same) {
    final truth = hist.last == hist[hist.length - 1 - back];
    setState(() {
      last = same == truth;
      score = last! ? score + 5 : math.max(0, score - 3);
      hist.add(_rnd.nextDouble() < 0.4 ? hist[hist.length - back] : _rnd.nextInt(4));
    });
  }

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFA855F7);
    return Column(children: [
      _Timer(seconds: 25, onEnd: () => widget.done(score), label: '$score pts', color: c),
      const Spacer(),
      Text(back == 1 ? 'Same as the last shape?' : 'Same as two shapes ago?', style: akT(15, c: akMuted)),
      const SizedBox(height: 18),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
        child: Icon(_shapes[hist.last], key: ValueKey(hist.length), size: 140, color: c),
      ),
      SizedBox(
        height: 24,
        child: last == null ? null : Icon(last! ? Icons.check_circle_rounded : Icons.cancel_rounded, color: last! ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
      ),
      const Spacer(),
      Row(children: [
        Expanded(child: SizedBox(height: 64, child: _tile(Text('Different', style: akT(17, w: FontWeight.w800)), onTap: () => _answer(false)))),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 64, child: _tile(Text('Same', style: akT(17, w: FontWeight.w800, c: Colors.white)), color: c, onTap: () => _answer(true)))),
      ]),
      const SizedBox(height: 20),
    ]);
  }
}

// =====================================================================
//  15. RAIN CATCH
// =====================================================================

class _RainGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _RainGame({required this.level, required this.done});
  @override
  State<_RainGame> createState() => _RainGameState();
}

class _RainGameState extends State<_RainGame> with SingleTickerProviderStateMixin {
  final drops = <Offset>[]; // x 0..1, y 0..1
  double leaf = 0.5;
  int caught = 0, missed = 0;
  bool over = false;
  Duration _last = Duration.zero;
  late final _tick = createTicker(_step)..start();

  void _step(Duration d) {
    if (over) return;
    final dt = (d - _last).inMicroseconds / 1e6;
    _last = d;
    final speed = 0.32 + widget.level * 0.05 + caught * 0.004;
    if (_rnd.nextDouble() < 0.03 + widget.level * 0.004) drops.add(Offset(0.05 + _rnd.nextDouble() * 0.9, -0.05));
    for (var i = drops.length - 1; i >= 0; i--) {
      final p = drops[i].translate(0, speed * dt);
      if (p.dy > 0.88 && p.dy < 0.95 && (p.dx - leaf).abs() < 0.12) {
        caught++;
        HapticFeedback.selectionClick();
        drops.removeAt(i);
      } else if (p.dy > 1.02) {
        missed++;
        drops.removeAt(i);
      } else {
        drops[i] = p;
      }
    }
    if (missed >= 5) {
      over = true;
      widget.done(caught * 3);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text('Caught $caught', style: akN(17, c: const Color(0xFF3B82F6))),
        const Spacer(),
        for (var i = 0; i < 5; i++)
          Icon(Icons.water_drop_rounded, size: 18, color: i < 5 - missed ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
      ]),
      const SizedBox(height: 12),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: LayoutBuilder(builder: (context, c) {
            return GestureDetector(
              onPanUpdate: (d) => setState(() => leaf = (leaf + d.delta.dx / c.maxWidth).clamp(0.08, 0.92)),
              onTapDown: (d) => setState(() => leaf = (d.localPosition.dx / c.maxWidth).clamp(0.08, 0.92)),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDBEAFE), Color(0xFFF0FDF4)]),
                ),
                child: Stack(children: [
                  for (final p in drops)
                    Positioned(
                      left: p.dx * c.maxWidth - 7,
                      top: p.dy * c.maxHeight,
                      child: const Icon(Icons.water_drop_rounded, color: Color(0xFF3B82F6), size: 16),
                    ),
                  Positioned(
                    left: leaf * c.maxWidth - 40,
                    top: c.maxHeight * 0.9,
                    child: Container(
                      width: 80,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40), top: Radius.circular(6)),
                        boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.4), blurRadius: 12)],
                      ),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ),
      ),
    ]);
  }
}

// =====================================================================
//  16. STAR PATH
// =====================================================================

class _StarsGame extends StatefulWidget {
  final int level;
  final void Function(int) done;
  const _StarsGame({required this.level, required this.done});
  @override
  State<_StarsGame> createState() => _StarsGameState();
}

class _StarsGameState extends State<_StarsGame> {
  late final int n = (4 + widget.level * 2).clamp(6, 16);
  late final List<Offset> pts = _spread();
  int next = 0;
  final sw = Stopwatch()..start();

  List<Offset> _spread() {
    final out = <Offset>[];
    while (out.length < n) {
      final p = Offset(0.1 + _rnd.nextDouble() * 0.8, 0.08 + _rnd.nextDouble() * 0.84);
      if (out.every((q) => (q - p).distance > 0.16)) out.add(p);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text('Star ${math.min(next + 1, n)} / $n', style: akN(16, c: akMuted)),
        const Spacer(),
        StreamBuilder(
          stream: Stream.periodic(const Duration(milliseconds: 100)),
          builder: (_, _) => Text('${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s', style: akN(16, c: const Color(0xFF1E40AF))),
        ),
      ]),
      const SizedBox(height: 12),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: LayoutBuilder(builder: (context, c) {
            Offset at(Offset p) => Offset(p.dx * c.maxWidth, p.dy * c.maxHeight);
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B1437), Color(0xFF1E3A8A)]),
              ),
              child: Stack(children: [
                CustomPaint(size: c.biggest, painter: _LinePainter([for (var i = 0; i < next; i++) at(pts[i])])),
                for (var i = 0; i < n; i++)
                  Positioned(
                    left: at(pts[i]).dx - 22,
                    top: at(pts[i]).dy - 22,
                    child: GestureDetector(
                      onTapDown: (_) {
                        if (i != next) return;
                        HapticFeedback.selectionClick();
                        setState(() => next++);
                        if (next == n) {
                          sw.stop();
                          widget.done(math.max(10, n * 8 - sw.elapsed.inSeconds * 2));
                        }
                      },
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(alignment: Alignment.center, children: [
                          Icon(Icons.star_rounded, size: 34, color: i < next ? const Color(0xFFFDE68A) : Colors.white54),
                          Text('${i + 1}', style: akT(10, w: FontWeight.w800, c: const Color(0xFF0B1437))),
                        ]),
                      ),
                    ),
                  ),
              ]),
            );
          }),
        ),
      ),
    ]);
  }
}

class _LinePainter extends CustomPainter {
  final List<Offset> pts;
  _LinePainter(this.pts);
  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFDE68A).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter o) => o.pts.length != pts.length;
}
