import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/step_tracker.dart';
import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import 'walk_map_screen.dart';

// Steps, in the Apple Health style of the reference: a soft violet hero
// with today's count and a stepped day curve, a calendar carousel, glass
// stat cards and a Start button that opens the live walk map. Every
// number comes from the phone's step sensor via StepTracker.

const _v1 = Color(0xFF6E4E9E);
const _v2 = Color(0xFF9B7BB9);
const _v3 = Color(0xFFD7B3D2);
const _bg = Color(0xFFF1ECF6);
const _violet = Color(0xFF7C3AED);
const _orange = Color(0xFFF97316);
const _green = Color(0xFF16A34A);
const _blue = Color(0xFF3B82F6);
const _pink = Color(0xFFEC4899);

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final t = StepTracker.instance;
  late DateTime _sel = _today;

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isToday => _sel == _today;

  @override
  void initState() {
    super.initState();
    t.start();
  }

  @override
  Widget build(BuildContext context) {
    final pushed = Navigator.of(context).canPop() && ModalRoute.of(context)?.isFirst == false;
    final bottomGap = pushed ? 24.0 : 104.0;
    return Scaffold(
      backgroundColor: _bg,
      body: ListenableBuilder(
        listenable: t,
        builder: (context, _) {
          final steps = t.stepsOn(_sel);
          return Stack(children: [
            // Soft violet wash behind the hero, fading into the page.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 560,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_v1, _v2, _v3],
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_bg.withValues(alpha: 0), _bg],
                      stops: const [0.72, 1],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomGap + 90),
                physics: const BouncingScrollPhysics(),
                children: [
                  _top(pushed),
                  _hero(steps),
                  const SizedBox(height: 10),
                  _calendar(),
                  const SizedBox(height: 16),
                  ScrollReveal(child: _statsGrid(steps)),
                  const SizedBox(height: 12),
                  ScrollReveal(child: _hourly()),
                  const SizedBox(height: 12),
                  ScrollReveal(child: _week()),
                  const SizedBox(height: 12),
                  ScrollReveal(child: _goal()),
                  const SizedBox(height: 12),
                  ScrollReveal(child: _sensor()),
                ],
              ),
            ),
            Positioned(left: 16, right: 16, bottom: bottomGap, child: _startButton()),
          ]);
        },
      ),
    );
  }

  // ---------------------------------------------------------------- top

  Widget _top(bool pushed) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          if (pushed) ...[
            LiquidGlass(
              style: LiquidGlassStyle.clear,
              shape: BoxShape.circle,
              shadow: false,
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white)),
            ),
            const SizedBox(width: 10),
          ],
          Text('Steps', style: akT(32, w: FontWeight.w500, c: Colors.white, ls: -0.8)),
          const Spacer(),
          LiquidGlass(
            style: LiquidGlassStyle.clear,
            shadow: false,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department_outlined, size: 17, color: Colors.white),
              const SizedBox(width: 4),
              Text('${_streak()}', style: akN(15, c: Colors.white, w: FontWeight.w500)),
            ]),
          ),
        ]),
      );

  int _streak() {
    var d = _today, n = 0;
    while (t.stepsOn(d) >= t.goal) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  // ---------------------------------------------------------------- hero

  Widget _hero(int steps) {
    final label = _isToday ? 'Today' : '${_wd[_sel.weekday - 1]}, ${_sel.day} ${_mo[_sel.month - 1]}';
    final pct = steps / t.goal;
    final expected = _isToday ? (DateTime.now().hour + DateTime.now().minute / 60) / 22 : 1.0;
    final onTrack = pct >= expected.clamp(0.0, 1.0) * 0.9;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: akT(15, w: FontWeight.w500, c: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 2),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: steps.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(_fmt(v.round()), style: akN(56, c: Colors.white, w: FontWeight.w500, ls: -2)),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('steps', style: akT(17, w: FontWeight.w500, c: Colors.white.withValues(alpha: 0.85))),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: _isToday
              ? Stack(children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => CustomPaint(painter: _DayCurve(t.hours, t.goal, v)),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    child: Center(
                      child: LiquidGlass(
                        style: LiquidGlassStyle.clear,
                        shadow: false,
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        child: Text(
                          steps == 0 ? 'Start moving' : onTrack ? 'On Track' : 'Keep going',
                          style: akT(13, w: FontWeight.w500, c: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ])
              : Center(
                  child: _DayRing(pct: pct, label: '${(pct * 100).round()}% of goal'),
                ),
        ),
        if (_isToday) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final l in ['12 AM', '6 AM', '12 PM', '6 PM', '12 AM'])
              Text(l, style: akT(11.5, w: FontWeight.w600, c: Colors.white.withValues(alpha: 0.8))),
          ]),
        ],
      ]),
    );
  }

  // ------------------------------------------------------------ calendar

  Widget _calendar() {
    const n = 30;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: n,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = _today.subtract(Duration(days: i));
          final s = t.stepsOn(d);
          final sel = d == _sel;
          return AkPress(
            onTap: () => setState(() => _sel = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: akSpring,
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: sel ? Colors.white : Colors.white.withValues(alpha: 0.55),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: sel
                    ? [BoxShadow(color: _v1.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))]
                    : const [],
              ),
              child: Column(children: [
                Text(i == 0 ? 'Today' : _wd[d.weekday - 1], style: akT(11, w: FontWeight.w700, c: sel ? _violet : akMuted)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: (s / t.goal).clamp(0.0, 1.0),
                      strokeWidth: 3.5,
                      strokeCap: StrokeCap.round,
                      color: s >= t.goal ? _green : _violet,
                      backgroundColor: _violet.withValues(alpha: 0.12),
                    ),
                    Text('${d.day}', style: akN(13, c: akInk)),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------- stats

  Widget _statsGrid(int steps) {
    final km = steps * StepTracker.strideM / 1000;
    final kcal = (steps * StepTracker.kcalPerStep).round();
    final min = steps ~/ 110;
    final items = [
      ('Distance', km.toStringAsFixed(2), 'km', Icons.route_rounded, _blue),
      ('Calories', '$kcal', 'kcal', Icons.local_fire_department_rounded, _orange),
      ('Active', '$min', 'min', Icons.timer_rounded, _green),
      ('Goal', '${(steps / t.goal * 100).round()}', '%', Icons.flag_rounded, _violet),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        for (var r = 0; r < 2; r++) ...[
          Row(children: [
            for (var c = 0; c < 2; c++) ...[
              Expanded(child: _statCard(items[r * 2 + c])),
              if (c == 0) const SizedBox(width: 12),
            ],
          ]),
          if (r == 0) const SizedBox(height: 12),
        ],
      ]),
    );
  }

  Widget _statCard((String, String, String, IconData, Color) s) => LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(26),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(s.$1, style: akT(14, w: FontWeight.w500)),
            const Spacer(),
            Icon(s.$4, size: 18, color: s.$5),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(s.$2, style: akN(30, w: FontWeight.w500)))),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(s.$3, style: akT(13, c: akMuted))),
          ]),
        ]),
      );

  // -------------------------------------------------------------- hourly

  Widget _hourly() {
    final h = _isToday ? t.hours : List.filled(24, 0);
    final mx = math.max(1, h.reduce(math.max));
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('By the hour', style: akT(16, w: FontWeight.w700)),
          const Spacer(),
          Text(_isToday ? 'Today' : 'Kept for today only', style: akT(12, c: akMuted)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 24; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: h[i] / mx),
                    duration: Duration(milliseconds: 500 + i * 25),
                    curve: akSpring,
                    builder: (_, v, _) => Container(
                      height: math.max(3, 96 * v),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: h[i] == 0
                            ? _violet.withValues(alpha: 0.1)
                            : i == DateTime.now().hour && _isToday
                                ? _violet
                                : _violet.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final l in ['12a', '6a', '12p', '6p', '11p']) Text(l, style: akT(11, c: akFaint)),
        ]),
      ]),
    );
  }

  // ---------------------------------------------------------------- week

  Widget _week() {
    final days = [for (var i = 6; i >= 0; i--) _today.subtract(Duration(days: i))];
    final vals = [for (final d in days) t.stepsOn(d)];
    final mx = math.max(t.goal, vals.reduce(math.max)).toDouble();
    final logged = vals.where((v) => v > 0).toList();
    final avg = logged.isEmpty ? 0 : logged.reduce((a, b) => a + b) ~/ logged.length;
    final best = vals.reduce(math.max);
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Last 7 days', style: akT(16, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(children: [
          Text('Avg ${_fmt(avg)}', style: akT(12.5, c: akMuted)),
          const SizedBox(width: 12),
          Text('Best ${_fmt(best)}', style: akT(12.5, c: akMuted)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: 100 * (1 - t.goal / mx),
              child: Row(children: [
                Expanded(child: CustomPaint(painter: _Dash(), size: const Size(double.infinity, 1))),
                const SizedBox(width: 4),
                Text('Goal', style: akT(10.5, w: FontWeight.w700, c: _green)),
              ]),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: vals[i] / mx),
                      duration: Duration(milliseconds: 600 + i * 70),
                      curve: akSpring,
                      builder: (_, v, _) => Container(
                        width: 22,
                        height: math.max(4, 100 * v),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: vals[i] >= t.goal ? [_green, const Color(0xFF86EFAC)] : [_v1, _v3],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(i == 6 ? 'Today' : _wd[days[i].weekday - 1].substring(0, 1),
                        style: akT(11, w: FontWeight.w700, c: i == 6 ? akInk : akMuted)),
                  ]),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------- goal

  Widget _goal() => AkGlass(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Daily goal', style: akT(16, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${_fmt(t.goal)} steps', style: akN(24, w: FontWeight.w500)),
            ]),
          ),
          for (final d in [-500, 500])
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AkPress(
                onTap: () {
                  HapticFeedback.selectionClick();
                  t.setGoal((t.goal + d).clamp(2000, 30000));
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: _violet.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(d < 0 ? Icons.remove_rounded : Icons.add_rounded, color: _violet),
                ),
              ),
            ),
        ]),
      );

  // -------------------------------------------------------------- sensor

  Widget _sensor() {
    final (title, body, color, icon) = switch (t.source) {
      'sensor' => ('Phone step sensor', 'Counting with your phone\'s built-in step counter, even when the app is closed.', _green, Icons.sensors_rounded),
      'motion' => ('Motion sensor', 'No step counter chip found, so steps are counted from the accelerometer while the app is open.', _blue, Icons.vibration_rounded),
      'denied' => ('Permission needed', 'Allow Physical activity in your phone settings so NeuroFit can count steps.', _orange, Icons.lock_outline_rounded),
      'unavailable' => ('No sensor here', 'This device has no step or motion sensor. Open NeuroFit on your phone to count steps.', _pink, Icons.sensors_off_rounded),
      _ => ('Connecting to sensors…', 'Looking for your phone\'s step counter.', akMuted, Icons.sync_rounded),
    };
    return AkGlass(
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: akT(14.5, w: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(body, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.35)),
          ]),
        ),
      ]),
    );
  }

  // --------------------------------------------------------------- start

  Widget _startButton() => AkPress(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            reverseTransitionDuration: const Duration(milliseconds: 380),
            pageBuilder: (_, _, _) => const WalkMapScreen(),
            transitionsBuilder: (_, a, _, child) {
              final c = CurvedAnimation(parent: a, curve: const Cubic(0.18, 1.0, 0.3, 1), reverseCurve: Curves.easeInCubic);
              return FadeTransition(
                opacity: c,
                child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(c), child: child),
              );
            },
          ));
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF111827), Color(0xFF374151)]),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Start walk', style: akT(17, w: FontWeight.w800, c: Colors.white)),
          ]),
        ),
      );
}

/// Cumulative steps through the day as a stepped curve, like the reference.
class _DayCurve extends CustomPainter {
  final List<int> hours;
  final int goal;
  final double t;
  _DayCurve(this.hours, this.goal, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final nowX = (now.hour + now.minute / 60) / 24;
    var cum = 0;
    final pts = <Offset>[];
    final total = hours.fold(0, (a, b) => a + b);
    final top = math.max(goal * 0.6, total * 1.15).toDouble();
    final base = size.height - 6;
    final h = base - 40;
    pts.add(Offset(0, base));
    for (var i = 0; i < 24; i++) {
      final x0 = i / 24 * size.width;
      if (i / 24 > nowX) break;
      pts.add(Offset(x0, base - h * cum / top));
      cum += hours[i];
      final x1 = math.min((i + 1) / 24, nowX) * size.width;
      pts.add(Offset(x0 + (x1 - x0) * 0.35, base - h * cum / top));
      pts.add(Offset(x1, base - h * cum / top));
    }
    // Animate by revealing left to right.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * nowX * t + 2, size.height));
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(pts.last.dx, base)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.restore();
    // "Now" marker.
    final nx = pts.last.dx * t;
    canvas.drawLine(Offset(nx, pts.last.dy), Offset(nx, base), Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.2);
    canvas.drawCircle(Offset(nx, pts.last.dy), 6, Paint()..color = Colors.white);
    // Dotted axis.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (var x = 0.0; x <= size.width; x += 9) {
      canvas.drawCircle(Offset(x, size.height - 1), 1, dot);
    }
    for (final f in [0.0, 0.5, 1.0]) {
      canvas.drawLine(Offset(f * size.width, size.height - 6), Offset(f * size.width, size.height + 4),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(covariant _DayCurve o) => true;
}

class _DayRing extends StatelessWidget {
  final double pct;
  final String label;
  const _DayRing({required this.pct, required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        height: 160,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: akT(14, w: FontWeight.w700, c: Colors.white)),
        ]),
      );
}

class _Dash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _green.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 3.5, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
