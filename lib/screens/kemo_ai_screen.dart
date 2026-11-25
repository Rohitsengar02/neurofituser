import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/kemo.dart';

/// "Ask Kemo" chat page. Kemo walks on the spot in the hero, reacts to what
/// you ask (thinking while he replies, then happy or excited) and answers
/// with demo tips while the real AI backend is wired up.
class KemoAiScreen extends StatefulWidget {
  const KemoAiScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => const KemoAiScreen(),
        transitionsBuilder: (_, a, __, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(c),
              alignment: Alignment.topRight,
              child: child,
            ),
          );
        },
      );

  @override
  State<KemoAiScreen> createState() => _KemoAiScreenState();
}

class _Msg {
  final bool fromKemo;
  final String text;
  String shown;
  _Msg(this.fromKemo, this.text) : shown = fromKemo ? '' : text;
}

const _lime = Color(0xFFB8FF3D);
const _green = Color(0xFF3DDC12);
const _deep = Color(0xFF14210C);
const _muted = Color(0xFF5B6B52);

class _KemoAiScreenState extends State<KemoAiScreen>
    with TickerProviderStateMixin {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final List<_Msg> _msgs = [];
  late final AnimationController _talk;
  late final AnimationController _float;

  KemoEmotion? _emotion; // null = Kemo cycles expressions by himself
  bool _thinking = false;
  bool _typing = false;
  Timer? _typeTimer;
  Timer? _moodTimer;
  String _greeting = '';
  Timer? _greetTimer;

  static const _hello =
      "Hey Rohit! I'm Kemo, your Neurofit buddy. Ask me about workouts, meals, sleep or anything that keeps you moving!";

  static const _chips = [
    ('💪', 'Plan my workout'),
    ('🥗', 'What should I eat?'),
    ('😴', 'Sleep better'),
    ('💧', 'Water goal'),
    ('🔥', 'Motivate me'),
    ('🧘', 'Quick stress relief'),
  ];

  @override
  void initState() {
    super.initState();
    _talk = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    // Type the greeting into Kemo's speech bubble
    _talk.repeat(reverse: true);
    final sw = Stopwatch()..start();
    _greetTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) return;
      final i = sw.elapsedMilliseconds ~/ 14;
      if (i >= _hello.length) {
        t.cancel();
        _talk.stop();
        _talk.value = 0;
        setState(() => _greeting = _hello);
        return;
      }
      setState(() => _greeting = _hello.substring(0, i));
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _moodTimer?.cancel();
    _greetTimer?.cancel();
    _talk.dispose();
    _float.dispose();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Demo brain
  // -----------------------------------------------------------------
  String _replyFor(String q) {
    final t = q.toLowerCase();
    bool has(List<String> w) => w.any(t.contains);
    if (has(['workout', 'exercise', 'gym', 'train', 'muscle', 'plan'])) {
      return "Let's go! 💪 Today try this 25 min upper body set:\n\n"
          "1. Push-ups 3 × 12\n2. Dumbbell rows 3 × 10 each arm\n"
          "3. Shoulder press 3 × 10\n4. Plank 3 × 40 sec\n\n"
          "Rest 45 sec between sets. Tap Workouts to start it with a timer.";
    }
    if (has(['eat', 'meal', 'food', 'diet', 'protein', 'nutrition', 'hungry'])) {
      return "Yum, good question! 🥗 You have about 620 kcal left today. "
          "A great dinner: grilled paneer or chicken, a cup of brown rice and "
          "a big salad. That's around 35 g protein. Add curd for a calm tummy.";
    }
    if (has(['sleep', 'tired', 'rest', 'night'])) {
      return "Sleep is your superpower 😴 Last night you got 7 h 12 m. "
          "Tonight: screens off 30 min before bed, keep the room cool, and try "
          "4-7-8 breathing for 3 rounds. I'll remind you at 10:30 PM!";
    }
    if (has(['water', 'drink', 'hydrat', 'thirst'])) {
      return "💧 You're at 1.4 L of your 2.5 L goal. Two glasses before lunch "
          "and one with each meal gets you there. Want me to nudge you every "
          "hour?";
    }
    if (has(['stress', 'anxious', 'calm', 'relax', 'breath', 'mind'])) {
      return "I've got you 🧘 Try box breathing with me: breathe in 4, hold 4, "
          "out 4, hold 4. Do 5 rounds. Then roll your shoulders back 10 times. "
          "Feeling lighter already, right?";
    }
    if (has(['motivat', 'lazy', 'give up', 'bored', 'hard'])) {
      return "🔥 You're on a 12 day streak! That's more than most people ever "
          "do. Just start with 5 minutes. Future you is already cheering. "
          "Let's not break the chain today!";
    }
    if (has(['hi', 'hello', 'hey', 'kemo'])) {
      return "Hiii! 👋 So happy to see you. What are we working on today, "
          "body, food or mind?";
    }
    return "Ooh, interesting! 🤔 I'm still learning that one. For now I'm best "
        "at workouts, meals, sleep, water and staying motivated. Try one of "
        "the ideas below!";
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking || _typing) return;
    HapticFeedback.lightImpact();
    _input.clear();
    _moodTimer?.cancel();
    setState(() {
      _msgs.add(_Msg(false, text));
      _thinking = true;
      _emotion = KemoEmotion.thinking;
    });
    _toBottom();
    Future.delayed(Duration(milliseconds: 1100 + math.Random().nextInt(600)),
        () {
      if (!mounted) return;
      final reply = _Msg(true, _replyFor(text));
      setState(() {
        _thinking = false;
        _typing = true;
        _emotion = KemoEmotion.happy;
        _msgs.add(reply);
      });
      _talk.repeat(reverse: true);
      final sw = Stopwatch()..start();
      var lastLines = 0;
      _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
        if (!mounted) return;
        final i = math.min(reply.text.length, sw.elapsedMilliseconds ~/ 9);
        setState(() => reply.shown = reply.text.substring(0, i));
        if (i ~/ 40 != lastLines) {
          lastLines = i ~/ 40;
          _toBottom(jump: true);
        }
        if (i >= reply.text.length) {
          t.cancel();
          _talk.stop();
          _talk.value = 0;
          setState(() {
            _typing = false;
            _emotion = KemoEmotion.excited;
          });
          _toBottom();
          _moodTimer = Timer(const Duration(milliseconds: 2400), () {
            if (mounted) setState(() => _emotion = null);
          });
        }
      });
    });
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // -----------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final chatting = _msgs.isNotEmpty;
    final heroH = chatting
        ? 150.0
        : (mq.size.height * 0.46).clamp(300.0, 420.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FFF0),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated background blobs
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) =>
                  CustomPaint(painter: _BlobPainter(_float.value)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  height: heroH,
                  child: _hero(chatting, heroH),
                ),
                Expanded(
                  child: chatting ? _chatList() : _starter(),
                ),
                _inputBar(mq.padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _deep,
          ),
          const Hero(
            tag: 'kemo-face',
            child: KemoFace(size: 36, glow: false, bob: false),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kemo AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _deep,
                    letterSpacing: -0.4,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _thinking
                        ? 'thinking…'
                        : _typing
                            ? 'typing…'
                            : 'Online · your fitness buddy',
                    key: ValueKey('$_thinking$_typing'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _thinking || _typing ? _green : _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_msgs.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              onPressed: () {
                if (_thinking || _typing) return;
                HapticFeedback.selectionClick();
                setState(() {
                  _msgs.clear();
                  _emotion = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              color: _deep,
            ),
        ],
      ),
    );
  }

  Widget _hero(bool chatting, double heroH) {
    return LayoutBuilder(
      builder: (context, c) {
        final kemoH = chatting ? 130.0 : math.min(250.0, c.maxHeight * 0.66);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              bottom: 8,
              left: chatting ? 12 : (c.maxWidth - kemoH * 0.82) / 2,
              child: AnimatedBuilder(
                animation: _talk,
                builder: (context, _) => KemoBody(
                  height: kemoH,
                  emotion: _emotion,
                  walking: !_thinking,
                  talk: _talk.value,
                ),
              ),
            ),
            // Speech bubble
            if (!chatting)
              Positioned(
                top: 4,
                left: 20,
                right: 20,
                child: _bubble(_greeting.isEmpty ? '…' : _greeting),
              )
            else
              Positioned(
                left: 12 + kemoH * 0.82 + 6,
                right: 16,
                top: 18,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, a) => ScaleTransition(
                    scale: a,
                    alignment: Alignment.centerLeft,
                    child: child,
                  ),
                  child: _bubble(
                    _thinking
                        ? 'Hmm, let me think… 🤔'
                        : _typing
                            ? 'Here you go! ✨'
                            : 'Ask me anything else!',
                    key: ValueKey('$_thinking$_typing'),
                    small: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _bubble(String text, {Key? key, bool small = false}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 12 : 16,
        vertical: small ? 9 : 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lime, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: small ? 12.5 : 14,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: _deep,
        ),
      ),
    );
  }

  Widget _starter() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      children: [
        Text(
          'Try asking',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _muted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _chips.length; i++)
              _AppearIn(
                delay: 120 + i * 70,
                child: _chip(_chips[i].$1, _chips[i].$2),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String emoji, String label, {bool compact = false}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _send(label),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 13,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDF5CF), width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: compact ? 13 : 15)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: _deep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatList() {
    final showChips = !_thinking && !_typing;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: _msgs.length + (_thinking ? 1 : 0) + (showChips ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < _msgs.length) {
          return _AppearIn(
            key: ObjectKey(_msgs[i]),
            delay: 0,
            child: _msgRow(_msgs[i]),
          );
        }
        if (_thinking && i == _msgs.length) {
          return _AppearIn(
            key: const ValueKey('dots'),
            delay: 0,
            child: _kemoRow(const _TypingDots()),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4, left: 38),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in _chips)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _chip(c.$1, c.$2, compact: true),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _msgRow(_Msg m) {
    if (!m.fromKemo) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F3A10), _deep],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Text(
            m.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ),
      );
    }
    return _kemoRow(
      Text(
        m.shown,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: _deep,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _kemoRow(Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const KemoFace(size: 30, glow: false, bob: false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                ),
                border: Border.all(color: const Color(0xFFDDF5CF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(double bottomInset) {
    final busy = _thinking || _typing;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 6),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: const Color(0xFFDDF5CF), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _deep,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Ask Kemo anything…',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9AAA90),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: busy ? null : () => _send(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: busy
                        ? const [Color(0xFFCBD5C0), Color(0xFFA9B89C)]
                        : const [_lime, _green],
                  ),
                  boxShadow: [
                    if (!busy)
                      BoxShadow(
                        color: _green.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: _deep,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and slides a child in once, after [delay] ms.
class _AppearIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AppearIn({super.key, required this.child, required this.delay});

  @override
  State<_AppearIn> createState() => _AppearInState();
}

class _AppearInState extends State<_AppearIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return FadeTransition(
      opacity: _c,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.35), end: Offset.zero)
            .animate(a),
        child: widget.child,
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
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
    return SizedBox(
      height: 18,
      width: 40,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final v = math.sin((_c.value * 2 * math.pi) - i * 0.9);
            return Transform.translate(
              offset: Offset(0, -4 * v.clamp(0.0, 1.0)),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFFB7D8A3),
                    _green,
                    v.clamp(0.0, 1.0),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Soft lime and mint blobs drifting behind the page.
class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final a = t * 2 * math.pi;
    void blob(Offset c, double r, Color col) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [col, col.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    // top wash
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.45, 1],
          colors: [Color(0xFFD9FF9E), Color(0xFFF1FFE3), Color(0xFFF9FFF4)],
        ).createShader(Offset.zero & s),
    );
    blob(
      Offset(s.width * (0.15 + 0.06 * math.sin(a)),
          s.height * (0.18 + 0.03 * math.cos(a))),
      s.width * 0.45,
      _lime.withValues(alpha: 0.45),
    );
    blob(
      Offset(s.width * (0.9 + 0.05 * math.cos(a)),
          s.height * (0.32 + 0.04 * math.sin(a * 2))),
      s.width * 0.4,
      const Color(0xFF7CFFB2).withValues(alpha: 0.3),
    );
    blob(
      Offset(s.width * (0.5 + 0.08 * math.sin(a + 1)), s.height * 0.75),
      s.width * 0.5,
      const Color(0xFFE6FFC2).withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.t != t;
}
