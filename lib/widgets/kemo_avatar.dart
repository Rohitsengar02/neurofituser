import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kemo, the furry AI buddy. A soft mint fur ball with big eyes that
/// blinks every few seconds and gently bobs when [animate] is on.
class KemoAvatar extends StatefulWidget {
  final double size;
  final bool animate;

  const KemoAvatar({super.key, required this.size, this.animate = true});

  static const open = 'assets/images/kemo/kemo.png';
  static const closed = 'assets/images/kemo/kemo_closed.png';

  /// Warm the image cache so Kemo never flashes in.
  static Future<void> precache(BuildContext context) async {
    await Future.wait([
      precacheImage(const AssetImage(open), context),
      precacheImage(const AssetImage(closed), context),
    ]);
  }

  @override
  State<KemoAvatar> createState() => _KemoAvatarState();
}

class _KemoAvatarState extends State<KemoAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  Timer? _blinkTimer;
  bool _blink = false;
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _bob.repeat();
      _scheduleBlink();
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 2200 + _rnd.nextInt(2200)), () {
      if (!mounted) return;
      setState(() => _blink = true);
      Timer(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() => _blink = false);
        _scheduleBlink();
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final cache = (s * 2.2).round().clamp(64, 384);
    final img = Stack(
      children: [
        Image.asset(KemoAvatar.open,
            width: s, height: s, cacheWidth: cache, gaplessPlayback: true),
        if (_blink)
          Image.asset(KemoAvatar.closed,
              width: s, height: s, cacheWidth: cache, gaplessPlayback: true),
      ],
    );
    if (!widget.animate) return SizedBox(width: s, height: s, child: img);
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) {
        final t = _bob.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, -math.sin(t) * s * 0.035),
          child: Transform.scale(
            scaleX: 1 + math.sin(t * 2) * 0.012,
            scaleY: 1 - math.sin(t * 2) * 0.012,
            child: child,
          ),
        );
      },
      child: SizedBox(width: s, height: s, child: img),
    );
  }
}
