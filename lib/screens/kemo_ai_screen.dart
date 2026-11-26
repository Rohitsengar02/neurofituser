import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/kemo_avatar.dart';

const _green = Color(0xFF12A37F);
const _greenDeep = Color(0xFF0B7A5F);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);

TextStyle _f(double size,
        {FontWeight w = FontWeight.w600, Color c = _ink, double? h}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: w, color: c, height: h);

/// Kemo AI: a calm, clean health assistant. Home shows four help cards
/// and an ask bar; asking opens the chat; the mic opens voice mode.
class KemoAiScreen extends StatefulWidget {
  const KemoAiScreen({super.key});

  @override
  State<KemoAiScreen> createState() => _KemoAiScreenState();
}

class _Msg {
  final bool me;
  final String text;
  _Msg(this.me, this.text);
}

class _KemoAiScreenState extends State<KemoAiScreen>
    with TickerProviderStateMixin {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _typing = false;
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _reply(String q) {
    final s = q.toLowerCase();
    if (s.contains('workout') || s.contains('exercise') || s.contains('gym')) {
      return 'Today is Upper Body day. Try 3 rounds: 12 push-ups, 10 dumbbell rows, 12 shoulder presses and a 45 second plank. Rest 60 seconds between rounds. You have got this!';
    }
    if (s.contains('meal') || s.contains('eat') || s.contains('food') ||
        s.contains('diet') || s.contains('protein')) {
      return 'You have 700 kcal and 28 g of protein left today. A paneer or grilled chicken bowl with rice and veggies fits perfectly.';
    }
    if (s.contains('sleep') || s.contains('stress') || s.contains('mind') ||
        s.contains('calm')) {
      return 'You slept 7h 32m last night, nice! For a calmer evening try 4-4 box breathing for 3 minutes and put your phone away 30 minutes before bed.';
    }
    if (s.contains('water') || s.contains('hydrat')) {
      return 'You are at 1.25 L of your 2.5 L goal. Two more glasses before lunch and you are on track.';
    }
    if (s.contains('weight') || s.contains('body') || s.contains('fat')) {
      return 'Your body score is 82 and trending up. Keep a small calorie deficit, hit your protein and walk 8-10k steps daily.';
    }
    return 'Great question! Based on today: 8,542 steps, 1,420 kcal eaten and a 12 day streak. Keep moving, drink water and I will cheer you on!';
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    _input.clear();
    setState(() {
      _msgs.add(_Msg(true, text));
      _typing = true;
    });
    _toBottom();
    Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _msgs.add(_Msg(false, _reply(text)));
      });
      _toBottom();
    });
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic);
      }
    });
  }

  void _openVoice() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, a, __) => const _KemoVoiceScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  void _openBody() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _BodyInsightsSheet(),
    );
  }

  Widget _reveal(int i, Widget child) {
    final a = CurvedAnimation(
      parent: _in,
      curve: Interval(0.1 * i, (0.1 * i + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, c) => Opacity(
        opacity: a.value,
        child:
            Transform.translate(offset: Offset(0, 20 * (1 - a.value)), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatting = _msgs.isNotEmpty;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FBF8),
        body: Stack(
          children: [
            const _MintBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  _topBar(chatting),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      child: chatting ? _chat() : _home(),
                    ),
                  ),
                  _askBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: _green.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, size: 20, color: _ink),
        ),
      );

  Widget _topBar(bool chatting) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_rounded, () {
            if (chatting) {
              setState(_msgs.clear);
            } else {
              Navigator.of(context).maybePop();
            }
          }),
          Expanded(
            child: AnimatedOpacity(
              opacity: chatting ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const KemoAvatar(size: 30, animate: false),
                  const SizedBox(width: 6),
                  Text('Kemo AI', style: _f(16, w: FontWeight.w800)),
                ],
              ),
            ),
          ),
          _circleBtn(Icons.graphic_eq_rounded, _openVoice),
        ],
      ),
    );
  }

  Widget _home() {
    final cards = [
      _HelpCard(
        title: 'Workout Coach',
        sub: 'AI suggests',
        images: const ['hero_runner', 'bolt'],
        tint: const Color(0xFFEAF7FF),
        onTap: () => _send('Plan my workout for today'),
      ),
      _HelpCard(
        title: 'Meal Advice',
        sub: 'Smart insight',
        images: const ['bowl', 'fire'],
        tint: const Color(0xFFFFF5E8),
        onTap: () => _send('What should I eat for dinner?'),
      ),
      _HelpCard(
        title: 'Mind & Sleep',
        sub: 'Calm routines',
        images: const ['moon', 'bottle'],
        tint: const Color(0xFFF1EEFF),
        onTap: () => _send('Help me sleep better and feel calm'),
      ),
      _HelpCard(
        title: 'Body Insights',
        sub: 'Your scores',
        images: const [],
        tint: const Color(0xFFE8FBF3),
        bars: true,
        onTap: _openBody,
      ),
    ];
    return ListView(
      key: const ValueKey('home'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        _reveal(
          0,
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _green.withValues(alpha: 0.22),
                        _green.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                  const KemoAvatar(size: 118),
                ],
              ),
              Text('Hey, Rohit!', style: _f(22, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'How can ', style: _f(22, w: FontWeight.w700)),
                  TextSpan(
                      text: 'I help you?',
                      style: _f(22, w: FontWeight.w700, c: _green)),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < cards.length; i++)
                _reveal(
                    i + 1,
                    SizedBox(
                        width: w,
                        height: w * 0.98,
                        child: cards[i])),
            ],
          );
        }),
        const SizedBox(height: 18),
        _reveal(
          5,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in const [
                'How much water today?',
                'Am I losing weight?',
                'Quick 10 min workout',
              ])
                GestureDetector(
                  onTap: () => _send(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2EFEA)),
                    ),
                    child: Text(s, style: _f(12.5, c: _greenDeep)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chat() {
    return ListView.builder(
      key: const ValueKey('chat'),
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _msgs.length + (_typing ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _msgs.length) return const _TypingBubble();
        final m = _msgs[i];
        final bubble = Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: m.me ? _green : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(m.me ? 20 : 6),
              bottomRight: Radius.circular(m.me ? 6 : 20),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Text(m.text,
              style: _f(14,
                  w: FontWeight.w500,
                  c: m.me ? Colors.white : _ink,
                  h: 1.4)),
        );
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 12 * (1 - t)), child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment:
                  m.me ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!m.me) ...[
                  const KemoAvatar(size: 34, animate: false),
                  const SizedBox(width: 6),
                ],
                bubble,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _askBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Container(
        height: 58,
        padding: const EdgeInsets.only(left: 18, right: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: _green.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                style: _f(14, w: FontWeight.w500),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Ask anything about your health...',
                  hintStyle: _f(13.5, w: FontWeight.w500, c: _muted),
                ),
              ),
            ),
            IconButton(
              onPressed: _openVoice,
              icon: const Icon(Icons.mic_none_rounded, color: _muted),
            ),
            GestureDetector(
              onTap: () => _send(),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF22C59A), _greenDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MintBackdrop extends StatelessWidget {
  const _MintBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD9F3EA), Color(0xFFF4FBF8), Color(0xFFF7FAF9)],
            stops: [0, 0.38, 1],
          ),
        ),
        child: Align(
          alignment: const Alignment(-1.4, -1.1),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.white.withValues(alpha: 0.8),
                Colors.white.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatefulWidget {
  final String title;
  final String sub;
  final List<String> images;
  final Color tint;
  final bool bars;
  final VoidCallback onTap;

  const _HelpCard({
    required this.title,
    required this.sub,
    required this.images,
    required this.tint,
    required this.onTap,
    this.bars = false,
  });

  @override
  State<_HelpCard> createState() => _HelpCardState();
}

class _HelpCardState extends State<_HelpCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: _green.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: _f(14.5, w: FontWeight.w700)),
              Text(widget.sub, style: _f(11.5, w: FontWeight.w500, c: _muted)),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.tint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: widget.bars ? _bars() : _imgs(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgs() {
    return LayoutBuilder(builder: (context, c) {
      final big = c.maxHeight * 0.86;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 8,
            bottom: 4,
            child: Image.asset('assets/images/island/${widget.images[0]}.png',
                height: big, cacheWidth: 260),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                  'assets/images/island/${widget.images[1]}.png',
                  cacheWidth: 100),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: _ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ],
      );
    });
  }

  Widget _bars() {
    const vals = [0.5, 0.75, 0.6, 0.9, 0.7];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < vals.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: vals[i]),
                duration: Duration(milliseconds: 700 + i * 90),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => FractionallySizedBox(
                  heightFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          i == 3 ? _green : _green.withValues(alpha: 0.35),
                          i == 3
                              ? _greenDeep
                              : _green.withValues(alpha: 0.18),
                        ],
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const KemoAvatar(size: 34),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _green.withValues(
                            alpha: 0.3 +
                                0.7 *
                                    math.sin(((_c.value - i * 0.2) % 1) *
                                            math.pi)
                                        .abs()),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice mode: a big breathing Kemo, the words Kemo is saying fading in,
/// and a live waveform.
class _KemoVoiceScreen extends StatefulWidget {
  const _KemoVoiceScreen();

  @override
  State<_KemoVoiceScreen> createState() => _KemoVoiceScreenState();
}

class _KemoVoiceScreenState extends State<_KemoVoiceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  bool _paused = false;
  int _line = 0;
  Timer? _timer;
  static const _lines = [
    'Hi Rohit, I am listening.',
    'You walked 8,542 steps today.',
    'That is 85% of your goal.',
    'A 15 minute evening walk will close it.',
    'Remember to drink a glass of water.',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!_paused && mounted) {
        setState(() => _line = (_line + 1) % _lines.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      body: Stack(
        children: [
          const _MintBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _btn(Icons.arrow_back_rounded,
                          () => Navigator.of(context).pop()),
                      const Spacer(),
                      Text('Voice', style: _f(16, w: FontWeight.w800)),
                      const Spacer(),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _wave,
                  builder: (context, child) {
                    final s = _paused
                        ? 1.0
                        : 1 + 0.06 * math.sin(_wave.value * 2 * math.pi);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            width: 200 * s + i * 40,
                            height: 200 * s + i * 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _green.withValues(alpha: 0.07 - i * 0.02),
                            ),
                          ),
                        Transform.scale(scale: s, child: child),
                      ],
                    );
                  },
                  child: const KemoAvatar(size: 170),
                ),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(_lines[(_line + _lines.length - 1) % _lines.length],
                          textAlign: TextAlign.center,
                          style: _f(14,
                              w: FontWeight.w500,
                              c: _muted.withValues(alpha: 0.6))),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(_lines[_line],
                            key: ValueKey(_line),
                            textAlign: TextAlign.center,
                            style: _f(19, w: FontWeight.w700, h: 1.3)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 54,
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (context, _) => CustomPaint(
                      size: const Size(double.infinity, 54),
                      painter: _WavePainter(_wave.value, _paused),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _btn(Icons.keyboard_alt_outlined,
                        () => Navigator.of(context).pop()),
                    const SizedBox(width: 22),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _paused = !_paused);
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C59A), _greenDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: _green.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Icon(
                            _paused
                                ? Icons.mic_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                            size: 32),
                      ),
                    ),
                    const SizedBox(width: 22),
                    _btn(Icons.close_rounded,
                        () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _ink, size: 21),
        ),
      );
}

class _WavePainter extends CustomPainter {
  final double t;
  final bool paused;
  _WavePainter(this.t, this.paused);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 48;
    final gap = size.width / n;
    for (var i = 0; i < n; i++) {
      final x = gap * (i + 0.5);
      final center = 1 - ((i - n / 2).abs() / (n / 2));
      final amp = paused
          ? 0.08
          : (0.15 +
                  0.85 *
                      center *
                      (0.5 +
                          0.5 *
                              math.sin(t * 2 * math.pi * 2 + i * 0.7) *
                              math.cos(i * 1.3 + t * 2 * math.pi)))
              .abs();
      final h = math.max(3.0, size.height * amp);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, size.height / 2), width: 3, height: h),
          const Radius.circular(2),
        ),
        Paint()
          ..color = _green.withValues(alpha: 0.35 + 0.65 * center),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.t != t || old.paused != paused;
}

class _BodyInsightsSheet extends StatelessWidget {
  const _BodyInsightsSheet();

  @override
  Widget build(BuildContext context) {
    Widget bar(String label, String value, double p, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label, style: _f(13, w: FontWeight.w600, c: _muted)),
                  const Spacer(),
                  Text(value, style: _f(13, w: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: p),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEDF2F0),
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const KemoAvatar(size: 52),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Body Insights', style: _f(18, w: FontWeight.w800)),
                    Text('Updated today',
                        style: _f(12, w: FontWeight.w500, c: _muted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FBF3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: _green, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Normal',
                        style: _f(11.5, w: FontWeight.w700, c: _greenDeep)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          bar('Health score', '82 / 100', 0.82, _green),
          bar('Body fat', '18.4%', 0.46, const Color(0xFFFACC15)),
          bar('Muscle mass', '34.2 kg', 0.68, const Color(0xFF3B82F6)),
          bar('Hydration', '58%', 0.58, const Color(0xFF06B6D4)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
              child: Text('Got it',
                  style: _f(15, w: FontWeight.w700, c: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
