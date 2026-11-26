import 'package:flutter/material.dart';

/// Lenis-style smooth scrolling for mouse wheels and trackpads.
///
/// Flutter jumps the scroll offset by each wheel delta, which feels stepped
/// on the web preview and desktop. This controller instead eases toward an
/// accumulated target, so successive wheel ticks glide together. Touch
/// scrolling keeps the platform's own physics untouched.
class SmoothScrollController extends ScrollController {
  SmoothScrollController({
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutQuart,
    this.multiplier = 1.15,
  });

  final Duration duration;
  final Curve curve;
  final double multiplier;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SmoothScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
      owner: this,
    );
  }
}

class _SmoothScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    required this.owner,
  });

  final SmoothScrollController owner;
  double? _target;
  bool _gliding = false;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) return;
    final ctx = context.notificationContext;
    final reduceMotion = ctx != null && (MediaQuery.maybeOf(ctx)?.disableAnimations ?? false);
    if (reduceMotion) {
      super.pointerScroll(delta);
      return;
    }
    final from = _gliding && _target != null ? _target! : pixels;
    final to = (from + delta * owner.multiplier).clamp(minScrollExtent, maxScrollExtent);
    if (to == pixels && !_gliding) return;
    _target = to;
    _gliding = true;
    animateTo(to, duration: owner.duration, curve: owner.curve).whenComplete(() {
      if (_target == to) _gliding = false;
    });
  }
}
