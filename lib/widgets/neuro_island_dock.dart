import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/kemo_ai_screen.dart';
import '../screens/date_nutrition_detail_screen.dart';
import '../screens/steps_screen.dart';
import '../screens/streak_detail_screen.dart';
import '../screens/trainers_screen.dart';

/// Today's demo metrics shared by the docked island and its panel.
class IslandMetrics {
  IslandMetrics._();
  static final IslandMetrics instance = IslandMetrics._();

  final int steps = 8542;
  final int stepGoal = 10000;
  final int calories = 320;
  final int calorieGoal = 600;
  final int activeMinutes = 42;
  final int activeGoal = 60;
  final int heartRate = 76;
  final int streak = 12;
  final String sleep = '7h 32m';
  final ValueNotifier<int> waterMl = ValueNotifier<int>(1250);
  final int waterGoalMl = 2500;

  double get stepProgress => (steps / stepGoal).clamp(0.0, 1.0);
  double get calorieProgress => (calories / calorieGoal).clamp(0.0, 1.0);
  double get waterProgress => (waterMl.value / waterGoalMl).clamp(0.0, 1.0);
  double get activeProgress => (activeMinutes / activeGoal).clamp(0.0, 1.0);

  /// Overall daily goal completion, used by the docked ring.
  double get dayProgress =>
      (stepProgress + calorieProgress + waterProgress + activeProgress) / 4;
}

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

// =====================================================================
// DOCKED ISLAND: a small glowing tab hugging the right edge of the screen.
// It can be dragged up and down, peeks a live stat every few seconds, and
// opens the full island panel on tap.
// =====================================================================
class NeuroIslandDock extends StatefulWidget {
  final Color accent;
  final ValueChanged<int>? onSelectTab;

  /// True while the page under the dock is scrolling; the dock tucks away.
  final ValueListenable<bool>? scrolling;

  const NeuroIslandDock({
    super.key,
    required this.accent,
    this.onSelectTab,
    this.scrolling,
  });

  @override
  State<NeuroIslandDock> createState() => _NeuroIslandDockState();
}

class _NeuroIslandDockState extends State<NeuroIslandDock>
    with TickerProviderStateMixin {
  // Remember where the person left the dock while the app is open.
  static double? _savedFraction;

  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _intro;
  Timer? _peekTimer;
  int _peekIndex = 0;
  bool _peeking = false;
  double _fraction = 0.42;
  bool _tucked = false;
  Timer? _untuckTimer; // vertical position as a fraction of the height
  bool _dragging = false;
  double _lastTop = 0;

  static const double _dockW = 58;
  static const double _dockH = 60;

  final _metrics = IslandMetrics.instance;

  List<_PeekStat> get _peeks => [
    _PeekStat(
      Icons.directions_walk_rounded,
      _fmt(_metrics.steps),
      'steps',
      const Color(0xFF22C55E),
    ),
    _PeekStat(
      Icons.local_fire_department_rounded,
      '${_metrics.calories}',
      'kcal',
      const Color(0xFFF97316),
    ),
    _PeekStat(
      Icons.water_drop_rounded,
      '${(_metrics.waterMl.value / 1000).toStringAsFixed(2)} L',
      'water',
      const Color(0xFF38BDF8),
    ),
    _PeekStat(
      Icons.favorite_rounded,
      '${_metrics.heartRate}',
      'bpm',
      const Color(0xFFF43F5E),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fraction = _savedFraction ?? 0.42;
    widget.scrolling?.addListener(_onScroll);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _intro.forward();
    });
    // Peek a live stat out of the dock, then tuck it back in.
    _peekTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || _dragging || _tucked) return;
      setState(() {
        _peekIndex = (_peekIndex + 1) % _peeks.length;
        _peeking = true;
      });
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) setState(() => _peeking = false);
      });
    });
  }

  void _onScroll() {
    final moving = widget.scrolling?.value ?? false;
    if (moving) {
      _untuckTimer?.cancel();
      if (!_tucked) {
        setState(() {
          _tucked = true;
          _peeking = false;
        });
      }
    } else {
      _untuckTimer?.cancel();
      _untuckTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _tucked = false);
      });
    }
  }

  @override
  void didUpdateWidget(covariant NeuroIslandDock old) {
    super.didUpdateWidget(old);
    if (old.scrolling != widget.scrolling) {
      old.scrolling?.removeListener(_onScroll);
      widget.scrolling?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrolling?.removeListener(_onScroll);
    _untuckTimer?.cancel();
    _peekTimer?.cancel();
    _spin.dispose();
    _pulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _open() {
    HapticFeedback.mediumImpact();
    setState(() => _peeking = false);
    final box = context.findRenderObject() as RenderBox?;
    final size = MediaQuery.of(context).size;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(
            Offset(box.size.width - _dockW / 2, _lastTop + _dockH / 2),
          )
        : Offset(size.width, size.height * 0.3);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, anim, __) => NeuroIslandPanel(
          accent: widget.accent,
          animation: anim,
          origin: origin,
          onSelectTab: widget.onSelectTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTop = math.max(0.0, constraints.maxHeight - _dockH - 120);
        final top = 70 + (maxTop - 70).clamp(0.0, double.infinity) * _fraction;
        _lastTop = top;
        final peek = _peeks[_peekIndex];

        return Stack(
          children: [
            Positioned(
              right: 0,
              top: top,
              child: AnimatedBuilder(
                animation: _intro,
                builder: (context, child) {
                  final t = Curves.easeOutBack.transform(_intro.value);
                  return Transform.translate(
                    offset: Offset((1 - t) * 80, 0),
                    child: Opacity(
                      opacity: _intro.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _open,
                  onVerticalDragStart: (_) => setState(() {
                    _dragging = true;
                    _peeking = false;
                  }),
                  onVerticalDragUpdate: (d) {
                    final range = (maxTop - 70).clamp(1.0, double.infinity);
                    setState(() {
                      _fraction = (_fraction + d.delta.dy / range).clamp(
                        0.0,
                        1.0,
                      );
                    });
                  },
                  onVerticalDragEnd: (_) {
                    _savedFraction = _fraction;
                    setState(() => _dragging = false);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Peek bubble that slides out from the dock.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0.35, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: ScaleTransition(
                              scale: anim,
                              alignment: Alignment.centerRight,
                              child: child,
                            ),
                          ),
                        ),
                        child: _peeking
                            ? _PeekBubble(key: ValueKey(_peekIndex), stat: peek)
                            : const SizedBox(key: ValueKey('none')),
                      ),
                      const SizedBox(width: 6),
                      AnimatedSlide(
                        // While the page scrolls, slide mostly off the edge.
                        offset: Offset(_tucked ? 0.55 : 0, 0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: _tucked ? 0.55 : 1,
                          duration: const Duration(milliseconds: 320),
                          child: AnimatedScale(
                            scale: _dragging ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: _buildDock(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDock() {
    final accent = widget.accent;
    final hsl = HSLColor.fromColor(accent);
    final deep = hsl.withSaturation(0.55).withLightness(0.10).toColor();
    final bright = hsl
        .withLightness((hsl.lightness + 0.2).clamp(0.0, 0.92))
        .toColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: _dockW,
      height: _dockH,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep, const Color(0xFF05070D)],
        ),
        border: Border.all(
          color: bright.withValues(alpha: 0.45),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(-2, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grip line on the edge, hints it can be dragged.
          Positioned(
            left: 5,
            child: Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: AnimatedBuilder(
                animation: Listenable.merge([_spin, _pulse]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DockRingPainter(
                      progress: _metrics.dayProgress,
                      spin: _spin.value,
                      pulse: _pulse.value,
                      color: bright,
                      accent: accent,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (c, a) => ScaleTransition(
                          scale: a,
                          child: FadeTransition(opacity: a, child: c),
                        ),
                        child: _peeking
                            ? Icon(
                                _peeks[_peekIndex].icon,
                                key: ValueKey('i$_peekIndex'),
                                color: _peeks[_peekIndex].color,
                                size: 18,
                              )
                            : Text(
                                '${(_metrics.dayProgress * 100).round()}%',
                                key: const ValueKey('pct'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeekStat {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _PeekStat(this.icon, this.value, this.label, this.color);
}

class _PeekBubble extends StatelessWidget {
  final _PeekStat stat;
  const _PeekBubble({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stat.color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: stat.color.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, size: 13, color: stat.color),
          ),
          const SizedBox(width: 6),
          Text(
            stat.value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            stat.label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockRingPainter extends CustomPainter {
  final double progress;
  final double spin;
  final double pulse;
  final Color color;
  final Color accent;

  _DockRingPainter({
    required this.progress,
    required this.spin,
    required this.pulse,
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;

    // Breathing halo
    final haloR = r + 2 + pulse * 6;
    canvas.drawCircle(
      c,
      haloR,
      Paint()
        ..color = accent.withValues(alpha: 0.35 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Track
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Progress arc with a sweeping gradient
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [accent, color, Colors.white, accent],
      stops: const [0.0, 0.45, 0.7, 1.0],
      transform: GradientRotation(spin * math.pi * 2),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = sweep.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4,
    );

    // Orbiting spark at the tip of the arc
    final tip = -math.pi / 2 + math.pi * 2 * progress;
    final p = c + Offset(math.cos(tip), math.sin(tip)) * r;
    canvas.drawCircle(
      p,
      3.2,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DockRingPainter old) =>
      old.spin != spin || old.pulse != pulse || old.progress != progress;
}

// =====================================================================
// FULL ISLAND PANEL: opens from the dock with a circular reveal.
// =====================================================================
class NeuroIslandPanel extends StatefulWidget {
  final Color accent;
  final Animation<double> animation;
  final Offset origin;
  final ValueChanged<int>? onSelectTab;

  const NeuroIslandPanel({
    super.key,
    required this.accent,
    required this.animation,
    required this.origin,
    this.onSelectTab,
  });

  @override
  State<NeuroIslandPanel> createState() => _NeuroIslandPanelState();
}

class _NeuroIslandPanelState extends State<NeuroIslandPanel>
    with TickerProviderStateMixin {
  late final AnimationController _content;
  late final AnimationController _heart;
  final _m = IslandMetrics.instance;

  Color get _accent => widget.accent;
  Color get _bright {
    final hsl = HSLColor.fromColor(_accent);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 0.92)).toColor();
  }

  Color get _deep {
    final hsl = HSLColor.fromColor(_accent);
    return hsl.withSaturation(0.6).withLightness(0.09).toColor();
  }

  @override
  void initState() {
    super.initState();
    _content = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _heart = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000 / _m.heartRate).round()),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _content.forward();
    });
  }

  @override
  void dispose() {
    _content.dispose();
    _heart.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int i, {int of = 8}) {
    final start = (i / of) * 0.55;
    return CurvedAnimation(
      parent: _content,
      curve: Interval(
        start,
        (start + 0.45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _reveal(int i, Widget child) {
    final a = _stagger(i);
    return AnimatedBuilder(
      animation: a,
      builder: (_, c) => Opacity(
        opacity: a.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - a.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.of(context).maybePop();
  }

  void _go(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _tab(int index) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    widget.onSelectTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    final panelW = math.min(size.width - 20, 460.0);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(widget.animation.value);
        return Stack(
          children: [
            // Blurred, tinted backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
                  child: Container(
                    color: const Color(0xFF020617).withValues(alpha: 0.45 * t),
                  ),
                ),
              ),
            ),
            // Circular reveal growing out of the dock
            Positioned.fill(
              child: IgnorePointer(
                ignoring: t < 0.6,
                child: ClipPath(
                  clipper: _CircleRevealClipper(
                    center: widget.origin,
                    radius: maxR * t,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: pad.bottom > 0 ? 0 : 10),
            child: SizedBox(
              width: panelW,
              child: Material(color: Colors.transparent, child: _buildPanel()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deep, const Color(0xFF05070D)],
        ),
        border: Border.all(color: _bright.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.45),
            blurRadius: 40,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Soft accent glow in the corner
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withValues(alpha: 0.45),
                      _accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical -
                    24,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _reveal(0, _header()),
                    const SizedBox(height: 18),
                    _reveal(1, _ringsCard()),
                    const SizedBox(height: 12),
                    _reveal(2, _statsGrid()),
                    const SizedBox(height: 16),
                    _reveal(3, _sectionTitle('Quick actions')),
                    const SizedBox(height: 10),
                    _reveal(4, _quickActions()),
                    const SizedBox(height: 16),
                    _reveal(5, _sectionTitle('Up next')),
                    const SizedBox(height: 10),
                    _reveal(6, _upNext()),
                    const SizedBox(height: 14),
                    _reveal(
                      7,
                      Center(
                        child: GestureDetector(
                          onTap: _close,
                          child: Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _bright,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_bright, _accent]),
            boxShadow: [
              BoxShadow(color: _accent.withValues(alpha: 0.6), blurRadius: 12),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today at a glance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} · ${(_m.dayProgress * 100).round()}% of daily goals',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _PressScale(
          onTap: _close,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _glass({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _ringsCard() {
    const move = Color(0xFFF97316);
    const steps = Color(0xFF22C55E);
    const water = Color(0xFF38BDF8);
    return _glass(
      child: LayoutBuilder(
        builder: (context, c) {
          final ringSize = c.maxWidth < 300 ? 108.0 : 124.0;
          return Row(
            children: [
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: ValueListenableBuilder<int>(
                  valueListenable: _m.waterMl,
                  builder: (_, __, ___) => AnimatedBuilder(
                    animation: _content,
                    builder: (_, __) {
                      final a = Curves.easeOutCubic.transform(
                        ((_content.value - 0.1) / 0.8).clamp(0.0, 1.0),
                      );
                      return CustomPaint(
                        painter: _RingsPainter(
                          values: [
                            _m.calorieProgress * a,
                            _m.stepProgress * a,
                            _m.waterProgress * a,
                          ],
                          colors: const [move, steps, water],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_m.dayProgress * 100 * a).round()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'done',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _m.waterMl,
                  builder: (_, ml, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ringLegend(
                        move,
                        'Move',
                        '${_m.calories}',
                        '/ ${_m.calorieGoal} kcal',
                      ),
                      const SizedBox(height: 10),
                      _ringLegend(
                        steps,
                        'Steps',
                        _fmt(_m.steps),
                        '/ ${_fmt(_m.stepGoal)}',
                      ),
                      const SizedBox(height: 10),
                      _ringLegend(
                        water,
                        'Water',
                        (ml / 1000).toStringAsFixed(2),
                        '/ ${(_m.waterGoalMl / 1000).toStringAsFixed(1)} L',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ringLegend(Color color, String label, String value, String goal) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color, blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: ' $goal',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsGrid() {
    final tiles = <Widget>[
      _StatTile(
        icon: Icons.favorite_rounded,
        color: const Color(0xFFF43F5E),
        label: 'Heart rate',
        value: '${_m.heartRate}',
        unit: 'bpm',
        trailing: AnimatedBuilder(
          animation: _heart,
          builder: (_, __) => CustomPaint(
            size: const Size(54, 22),
            painter: _EcgPainter(_heart.value, const Color(0xFFF43F5E)),
          ),
        ),
      ),
      _StatTile(
        icon: Icons.timer_rounded,
        color: const Color(0xFFA78BFA),
        label: 'Active',
        value: '${_m.activeMinutes}',
        unit: 'min',
        trailing: _MiniBar(
          progress: _m.activeProgress,
          color: const Color(0xFFA78BFA),
          anim: _content,
        ),
      ),
      _StatTile(
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF818CF8),
        label: 'Sleep',
        value: _m.sleep,
        unit: '',
        trailing: _MiniBar(
          progress: 0.88,
          color: const Color(0xFF818CF8),
          anim: _content,
        ),
      ),
      _StatTile(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFBBF24),
        label: 'Streak',
        value: '${_m.streak}',
        unit: 'days',
        onTap: () => _go(const StreakDetailScreen()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (i) => Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFBBF24,
                ).withValues(alpha: i < 4 ? 1 : 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tiles.map((t) => SizedBox(width: w, child: t)).toList(),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      _QA(
        Icons.play_arrow_rounded,
        'Workout',
        const Color(0xFF9333EA),
        () => _tab(1),
      ),
      _QA(
        Icons.restaurant_rounded,
        'Log meal',
        const Color(0xFFD97706),
        () => _go(DateNutritionDetailScreen(initialDate: DateTime.now())),
      ),
      _QA(Icons.water_drop_rounded, '+250 ml', const Color(0xFF0EA5E9), () {
        HapticFeedback.lightImpact();
        _m.waterMl.value = math.min(
          _m.waterGoalMl + 1000,
          _m.waterMl.value + 250,
        );
      }),
      _QA(
        Icons.directions_walk_rounded,
        'Steps',
        const Color(0xFF16A34A),
        () => _go(const StepsScreen()),
      ),
      _QA(
        Icons.self_improvement_rounded,
        'Breathe',
        const Color(0xFFE11D48),
        () => _tab(3),
      ),
      _QA(
        Icons.auto_awesome_rounded,
        'Ask Kemo',
        const Color(0xFF3DDC12),
        () => _go(const KemoAiScreen()),
      ),
      _QA(
        Icons.person_rounded,
        'Trainer',
        const Color(0xFF0D9488),
        () => _go(const TrainersScreen()),
      ),
      _QA(
        Icons.shopping_bag_rounded,
        'Shop',
        const Color(0xFF0284C7),
        () => _tab(4),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 4;
        const gap = 8.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map(
                (a) => SizedBox(
                  width: w,
                  child: _QuickActionTile(qa: a),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _upNext() {
    return _PressScale(
      onTap: () => _tab(1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              _accent.withValues(alpha: 0.35),
              _accent.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: _bright.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upper Body Strength',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '45 min · 3 of 4 sets done',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _content,
                      builder: (_, __) => LinearProgressIndicator(
                        value:
                            0.75 *
                            Curves.easeOutCubic.transform(
                              ((_content.value - 0.5) / 0.5).clamp(0.0, 1.0),
                            ),
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(_bright),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(Icons.play_arrow_rounded, color: _accent, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QA(this.icon, this.label, this.color, this.onTap);
}

class _QuickActionTile extends StatelessWidget {
  final _QA qa;
  const _QuickActionTile({required this.qa});

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: qa.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(qa.color, Colors.white, 0.25)!, qa.color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: qa.color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(qa.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 7),
            Text(
              qa.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final Widget trailing;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: value,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (unit.isNotEmpty)
                            TextSpan(
                              text: ' $unit',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Animation<double> anim;
  const _MiniBar({
    required this.progress,
    required this.color,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final a = Curves.easeOutCubic.transform(
          ((anim.value - 0.3) / 0.7).clamp(0.0, 1.0),
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (i) {
            final h = [0.45, 0.7, 0.55, 0.9, progress][i];
            return Container(
              width: 5,
              height: 4 + 18 * h * a,
              margin: const EdgeInsets.only(left: 2.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: i == 4 ? 1 : 0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Shrinks slightly while pressed, for a tactile feel.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressScale({required this.child, this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _RingsPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const stroke = 10.0;
    const gap = 3.0;
    for (var i = 0; i < values.length; i++) {
      final r = size.width / 2 - stroke / 2 - i * (stroke + gap);
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = colors[i].withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      final v = values[i].clamp(0.0, 1.0);
      if (v <= 0) continue;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * v,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: -math.pi / 2 + math.pi * 2 * v,
            colors: [
              Color.lerp(colors[i], Colors.black, 0.15)!,
              Color.lerp(colors[i], Colors.white, 0.25)!,
            ],
            transform: const GradientRotation(0),
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => true;
}

class _EcgPainter extends CustomPainter {
  final double t;
  final Color color;
  _EcgPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final w = size.width;
    // One heartbeat shape that scrolls across the box.
    const shape = <Offset>[
      Offset(0, 0),
      Offset(0.30, 0),
      Offset(0.36, -0.25),
      Offset(0.42, 0),
      Offset(0.48, 0.15),
      Offset(0.54, -0.95),
      Offset(0.60, 0.6),
      Offset(0.66, 0),
      Offset(1.0, 0),
    ];
    // Draw as a simple sweeping line to avoid wrap artifacts.
    final pts = <Offset>[];
    for (var x = 0.0; x <= 1.0; x += 0.02) {
      final u = (x + t) % 1.0;
      double y = 0;
      for (var i = 0; i < shape.length - 1; i++) {
        if (u >= shape[i].dx && u <= shape[i + 1].dx) {
          final f = (u - shape[i].dx) / (shape[i + 1].dx - shape[i].dx);
          y = shape[i].dy + (shape[i + 1].dy - shape[i].dy) * f;
          break;
        }
      }
      pts.add(Offset(x * w, mid + y * mid * 0.9));
    }
    final line = Path()..addPolygon(pts, false);
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) => old.t != t;
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  _CircleRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(covariant _CircleRevealClipper old) =>
      old.radius != radius || old.center != center;
}
