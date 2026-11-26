import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'liquid_glass.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const Curve _spring = Cubic(0.2, 1.2, 0.32, 1);

TextStyle _t(double s, {FontWeight w = FontWeight.w600, Color c = _ink, double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

/// iOS large-title style header: date caption, a big greeting whose letters
/// blur in one by one, a shimmering name, a Transform shortcut chip, a
/// flickering streak pill and an avatar inside a turning gradient ring.
class IosHeader extends StatefulWidget {
  final String name;
  final int streak;
  final VoidCallback onStreak;
  final VoidCallback onAvatar;
  const IosHeader({
    super.key,
    required this.name,
    required this.streak,
    required this.onStreak,
    required this.onAvatar,
  });

  @override
  State<IosHeader> createState() => _IosHeaderState();
}

class _IosHeaderState extends State<IosHeader> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _date {
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]}';
  }

  Animation<double> _seg(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _in, curve: Interval(a, b, curve: c));

  Widget _fadeUp(Animation<double> a, Widget child, {double dy = 14}) => AnimatedBuilder(
        animation: a,
        child: child,
        builder: (_, c) {
          final v = a.value;
          final b = (1 - v.clamp(0.0, 1.0)) * 6;
          Widget w = Transform.translate(offset: Offset(0, dy * (1 - v)), child: c);
          if (b > 0.2) w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: w);
          return Opacity(opacity: v.clamp(0.0, 1.0), child: w);
        },
      );

  @override
  Widget build(BuildContext context) {
    final letters = _greeting.split('');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeUp(
                  _seg(0, 0.35),
                  Text(_date, style: _t(11.5, w: FontWeight.w700, c: _muted, ls: 1.1)),
                  dy: 8,
                ),
                const SizedBox(height: 4),
                // Large title: letters blur in one by one.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < letters.length; i++)
                      _fadeUp(
                        _seg(0.08 + i * 0.03, math.min(1.0, 0.4 + i * 0.03), _spring),
                        Text(letters[i], style: _t(28, w: FontWeight.w800, ls: -0.8, h: 1.1)),
                        dy: 18,
                      ),
                  ]),
                ),
                // Name with a soft green shimmer.
                _fadeUp(
                  _seg(0.35, 0.8, _spring),
                  AnimatedBuilder(
                    animation: _loop,
                    builder: (_, _) => ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => LinearGradient(
                        colors: const [Color(0xFF15803D), Color(0xFF4ADE80), Color(0xFF15803D)],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(-2.2 + 4.4 * _loop.value, 0),
                        end: Alignment(-0.6 + 4.4 * _loop.value, 0),
                      ).createShader(r),
                      child: Text('${widget.name} 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(28, w: FontWeight.w800, ls: -0.8, h: 1.1)),
                    ),
                  ),
                  dy: 18,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _fadeUp(
            _seg(0.2, 0.7, _spring),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _StreakPill(streak: widget.streak, loop: _loop, onTap: widget.onStreak),
                const SizedBox(width: 8),
                _RingAvatar(initial: widget.name.isEmpty ? '?' : widget.name[0], loop: _loop, onTap: widget.onAvatar),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Tap({required this.child, required this.onTap});
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: Duration(milliseconds: _down ? 100 : 420),
          curve: _down ? Curves.easeOut : _spring,
          child: widget.child,
        ),
      );
}

Widget _glass({required Widget child, required BorderRadius radius, EdgeInsets? padding}) => LiquidGlass(
      style: LiquidGlassStyle.clear,
      borderRadius: radius,
      padding: padding,
      shadow: false,
      child: child,
    );

class _StreakPill extends StatelessWidget {
  final int streak;
  final Animation<double> loop;
  final VoidCallback onTap;
  const _StreakPill({required this.streak, required this.loop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tap(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF97316).withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: _glass(
          radius: BorderRadius.circular(20),
          padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: loop,
              builder: (_, c) {
                final f = math.sin(loop.value * 2 * math.pi * 6);
                return Transform.rotate(
                  angle: 0.08 * f,
                  child: Transform.scale(scale: 1 + 0.08 * f.abs(), child: c),
                );
              },
              child: const Text('🔥', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: streak.toDouble()),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) =>
                  Text('${v.round()}', style: _t(15, w: FontWeight.w800, c: const Color(0xFFEA580C))),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RingAvatar extends StatelessWidget {
  final String initial;
  final Animation<double> loop;
  final VoidCallback onTap;
  const _RingAvatar({required this.initial, required this.loop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tap(
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: loop,
              builder: (_, _) => DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: const [
                      Color(0xFF22C55E),
                      Color(0xFFBEF264),
                      Color(0xFF5EEAD4),
                      Color(0xFF3B82F6),
                      Color(0xFF22C55E),
                    ],
                    transform: GradientRotation(loop.value * 2 * math.pi),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial, style: _t(17, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ),
          ),
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
