import 'package:flutter/material.dart';

/// Wrap a scroll view with this so [Reveal] children know when the page moves.
class RevealScope extends StatefulWidget {
  final Widget child;
  const RevealScope({super.key, required this.child});

  static ValueNotifier<int>? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealInherited>()?.notifier;

  @override
  State<RevealScope> createState() => _RevealScopeState();
}

class _RevealScopeState extends State<RevealScope> {
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Only the main vertical page scroll matters; carousels don't.
        if (n.metrics.axis == Axis.vertical) _tick.value++;
        return false;
      },
      child: _RevealInherited(notifier: _tick, child: widget.child),
    );
  }
}

class _RevealInherited extends InheritedNotifier<ValueNotifier<int>> {
  const _RevealInherited({required super.notifier, required super.child});

  @override
  bool updateShouldNotify(
    covariant InheritedNotifier<ValueNotifier<int>> old,
  ) => false;
}

/// Fades, lifts and gently scales its child in the first time it scrolls into
/// view. Sections already on screen animate in right away, one after another.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
    this.duration = const Duration(milliseconds: 620),
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  ValueNotifier<int>? _scope;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    // Layout can still move after the first frame (images loading, skeletons
    // swapping out) without any scroll event, so look again a few times.
    for (final ms in const [250, 700, 1400, 2600]) {
      Future.delayed(Duration(milliseconds: ms), _check);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = RevealScope._of(context);
    if (s != _scope) {
      _scope?.removeListener(_check);
      _scope = s;
      if (!_triggered) _scope?.addListener(_check);
    }
  }

  void _check() {
    if (_triggered || !mounted) return;
    if (_scope == null) return _start(); // nowhere to listen: just play
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.of(context).size.height;
    if (top < screenH * 0.94) _start();
  }

  void _start() {
    _triggered = true;
    _scope?.removeListener(_check);
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _scope?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RevealProgress(animation: _a, child: _buildAnimated());
  }

  Widget _buildAnimated() {
    // Same widget tree at every step so the child's state is never rebuilt.
    // FadeTransition + a plain translate are cheap to composite while
    // scrolling.
    return FadeTransition(
      opacity: _a,
      child: AnimatedBuilder(
        animation: _a,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offset * (1 - _a.value)),
          child: child,
        ),
      ),
    );
  }
}

class _RevealProgress extends InheritedWidget {
  final Animation<double> animation;
  const _RevealProgress({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_RevealProgress old) => old.animation != animation;
}

/// Runs [start] once the nearest [Reveal] has brought its section into view,
/// or after [fallback] when there is no [Reveal] above.
void whenRevealed(
  BuildContext context,
  VoidCallback start, {
  Duration fallback = const Duration(milliseconds: 250),
}) {
  final a = context.getInheritedWidgetOfExactType<_RevealProgress>()?.animation;
  if (a == null) {
    Future.delayed(fallback, start);
    return;
  }
  if (a.value > 0.25) {
    start();
    return;
  }
  void listener() {
    if (a.value > 0.25) {
      a.removeListener(listener);
      start();
    }
  }

  a.addListener(listener);
}

/// Shrinks a little while pressed, for a tactile feel on cards and buttons.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A light shimmer block used by quick skeleton layouts.
class ShimmerBlock extends StatelessWidget {
  final Animation<double> shimmer;
  final double? width;
  final double height;
  final double radius;

  const ShimmerBlock({
    super.key,
    required this.shimmer,
    this.width,
    required this.height,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, _) {
        final t = shimmer.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 3 * t - 1, -0.3),
              end: Alignment(1.0 + 3 * t - 1, 0.3),
              colors: const [
                Color(0xFFE9EEF5),
                Color(0xFFF8FAFC),
                Color(0xFFE9EEF5),
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}
