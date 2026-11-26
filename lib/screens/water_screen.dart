import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../services/hydration_store.dart';
import '../widgets/apple_kit.dart';

// Hydration page in the style of the "Drift" reference: a sky-blue hero
// with a live water wave filled to today's progress, quick Glass / Bottle
// buttons, a white log sheet over a deep navy page and a floating navy pill
// with a + button for any drink.

const _navy = Color(0xFF0B1B36);
const _navyInk = Color(0xFF0B2545);
const _deep = Color(0xFF13325B);
const _sky = Color(0xFF3B9BF0);
const _skyText = Color(0xFF2B6CB0);

String _ml(int v) {
  final s = v.toString();
  return s.length > 3 ? '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}' : s;
}

String _time(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

void openWaterScreen(BuildContext context) => Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => const WaterScreen(),
      transitionsBuilder: (_, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(c),
            child: child,
          ),
        );
      },
    ));

/// Bottom sheet to log any drink with any amount.
Future<void> showAddDrinkSheet(BuildContext context, {String drink = 'water', int ml = 250}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDrinkSheet(drink: drink, ml: ml),
    );

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _store = HydrationStore.I;
  final _scroll = ScrollController();
  final _logKey = GlobalKey(), _weekKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _quick(String drink, int ml) {
    HapticFeedback.mediumImpact();
    _store.add(drink, ml);
  }

  void _jump(GlobalKey? k) {
    HapticFeedback.selectionClick();
    if (k == null) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
    } else if (k.currentContext != null) {
      Scrollable.ensureVisible(k.currentContext!, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final heroH = math.max(440.0, MediaQuery.sizeOf(context).height * 0.56);
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _navy,
        body: ListenableBuilder(
          listenable: _store,
          builder: (context, _) => Stack(children: [
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Hero(height: heroH, top: pad.top, onQuick: _quick)),
                SliverToBoxAdapter(
                  child: Padding(
                    key: _logKey,
                    padding: const EdgeInsets.fromLTRB(24, 22, 20, 12),
                    child: Row(children: [
                      Text("Today's hydration", style: akT(14, w: FontWeight.w600, c: Colors.white70)),
                      const Spacer(),
                      Text('${_store.today.length} drinks', style: akT(12.5, w: FontWeight.w600, c: Colors.white38)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white54, size: 18),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(child: _Sheet(weekKey: _weekKey)),
                SliverToBoxAdapter(child: SizedBox(height: 120 + pad.bottom)),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18 + pad.bottom,
              child: Center(
                child: _Dock(
                  onTop: () => _jump(null),
                  onLog: () => _jump(_logKey),
                  onStats: () => _jump(_weekKey),
                  onAdd: () => showAddDrinkSheet(context),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// =====================================================================
//  HERO
// =====================================================================

class _Hero extends StatelessWidget {
  final double height, top;
  final void Function(String, int) onQuick;
  const _Hero({required this.height, required this.top, required this.onQuick});

  @override
  Widget build(BuildContext context) {
    final s = HydrationStore.I;
    final pct = (s.progress * 100).round();
    final left = math.max(0, s.goal - s.total);
    final next = s.nextReminder.inMinutes;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(42)),
      child: SizedBox(
        height: height + top,
        child: Stack(children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE6F4FF), Color(0xFFBFE2FC), Color(0xFF94CDF7)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: s.progress),
              duration: const Duration(milliseconds: 1400),
              curve: akSpring,
              builder: (_, v, _) => _Wave(level: 0.16 + v * 0.5),
            ),
          ),
          // Top bar
          Positioned(
            top: top + 8,
            left: 14,
            right: 14,
            child: Row(children: [
              _GlassCircle(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).maybePop()),
              const Spacer(),
              _Chip(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A3D), size: 16),
                  const SizedBox(width: 4),
                  Text('${s.streak}', style: akT(13, w: FontWeight.w800, c: _navyInk)),
                ]),
              ),
              const SizedBox(width: 8),
              _GlassCircle(
                icon: s.reminders ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  s.setReminders(!s.reminders);
                },
              ),
            ]),
          ),
          // Numbers
          Positioned(
            top: top + 78,
            left: 26,
            right: 26,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AkSeenFade(delay: 0, child: Text('Today', style: akT(20, w: FontWeight.w500, c: _navyInk.withValues(alpha: 0.75)))),
              const SizedBox(height: 4),
              AkSeenFade(
                delay: 90,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: s.total.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Text(_ml(v.round()), style: akN(58, w: FontWeight.w700, c: _navyInk, ls: -2.6)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text('ml', style: akT(20, w: FontWeight.w500, c: _navyInk.withValues(alpha: 0.7))),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              AkSeenFade(
                delay: 180,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '$pct% ', style: akT(14, w: FontWeight.w800, c: _navyInk)),
                  TextSpan(text: 'of ${_ml(s.goal)} ml goal', style: akT(14, w: FontWeight.w500, c: _skyText)),
                ])),
              ),
              const SizedBox(height: 14),
              AkSeenFade(
                delay: 260,
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  _Chip(
                    child: Text(left == 0 ? 'Goal reached' : '${_ml(left)} ml to go',
                        style: akT(12, w: FontWeight.w700, c: _navyInk)),
                  ),
                  if (s.reminders)
                    _Chip(
                      child: Text(next == 0 ? 'Time for a sip' : 'Next sip in $next min',
                          style: akT(12, w: FontWeight.w700, c: _navyInk)),
                    ),
                ]),
              ),
            ]),
          ),
          // Quick buttons
          Positioned(
            left: 18,
            right: 18,
            bottom: 22,
            child: Row(children: [
              Expanded(child: _QuickPill('Glass · 250 ml', () => onQuick('water', 250))),
              const SizedBox(width: 10),
              Expanded(child: _QuickPill('Bottle · 500 ml', () => onQuick('water', 500))),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Fades and lifts its child in once, after [delay] ms.
class AkSeenFade extends StatelessWidget {
  final int delay;
  final Widget child;
  const AkSeenFade({super.key, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 700 + delay),
        curve: Interval(delay / (700 + delay), 1, curve: Curves.easeOutCubic),
        child: child,
        builder: (_, t, c) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: c)),
      );
}

class _QuickPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickPill(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => AkPress(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _deep,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 19),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: akT(13.5, w: FontWeight.w700, c: Colors.white)),
              ),
            ),
          ]),
        ),
      );
}

class _Chip extends StatelessWidget {
  final Widget child;
  const _Chip({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: child,
      );
}

class _GlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassCircle({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => AkPress(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          ),
          child: Icon(icon, size: 17, color: _navyInk),
        ),
      );
}

// =====================================================================
//  WAVE
// =====================================================================

/// Live water surface. On web the phase ticks at about 30 fps on a timer to
/// keep the page light; on phones it follows the display refresh.
class _Wave extends StatefulWidget {
  final double level;
  const _Wave({required this.level});
  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  final _phase = ValueNotifier<double>(0);
  Ticker? _ticker;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final sw = Stopwatch()..start();
      _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _phase.value = sw.elapsedMilliseconds / 1000);
    } else {
      _ticker = createTicker((d) => _phase.value = d.inMicroseconds / 1e6)..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _timer?.cancel();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: _WavePainter(_phase, widget.level)),
      );
}

class _WavePainter extends CustomPainter {
  final ValueNotifier<double> t;
  final double level;
  _WavePainter(this.t, this.level) : super(repaint: t);

  static final _bubbles = List.generate(14, (i) {
    final r = math.Random(i * 7 + 3);
    return (r.nextDouble(), r.nextDouble(), 1.5 + r.nextDouble() * 3.5, 0.06 + r.nextDouble() * 0.1);
  });

  Path _wave(Size s, double base, double amp, double len, double shift) {
    final p = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width + 8; x += 8) {
      p.lineTo(x, base + math.sin(x / len * 2 * math.pi + shift) * amp + math.sin(x / (len * 0.53) + shift * 1.7) * amp * 0.35);
    }
    return p
      ..lineTo(s.width, s.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final time = t.value;
    final base = size.height * (1 - level);
    final rect = Offset(0, base - 20) & Size(size.width, size.height - base + 20);
    canvas.drawPath(
      _wave(size, base - 6, 10, size.width * 0.9, -time * 1.6 + 1.2),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    canvas.drawPath(
      _wave(size, base, 12, size.width * 1.1, time * 2.1),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8ACBF8), Color(0xFF4AA6F0), Color(0xFF2B86DA)],
        ).createShader(rect),
    );
    // Light caustic band under the surface.
    canvas.drawPath(
      _wave(size, base + 26, 7, size.width * 0.7, time * 1.3 + 2),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    final bubble = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final depth = size.height - base;
    if (depth < 30) return;
    for (final b in _bubbles) {
      final y = size.height - ((b.$2 * depth + time * b.$4 * size.height) % depth);
      final x = b.$1 * size.width + math.sin(time * 2 + b.$2 * 9) * 5;
      canvas.drawCircle(Offset(x, y), b.$3, bubble);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.level != level;
}

// =====================================================================
//  SHEET: LOG, WEEK, BREAKDOWN, REMINDERS, GOAL
// =====================================================================

class _Sheet extends StatelessWidget {
  final Key weekKey;
  const _Sheet({required this.weekKey});

  @override
  Widget build(BuildContext context) {
    final s = HydrationStore.I;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(34)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (s.today.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(children: [
              Icon(Icons.water_drop_outlined, size: 34, color: _sky.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text('No drinks yet today', style: akT(15, w: FontWeight.w700)),
              Text('Tap Glass or Bottle above to start.', style: akT(13, w: FontWeight.w500, c: akMuted)),
            ]),
          ),
        for (final e in s.today.reversed) _EntryRow(e, key: ObjectKey(e)),
        if (s.today.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Text('Swipe left on a drink to remove it.', style: akT(11.5, w: FontWeight.w500, c: akFaint)),
          ),
        _Section(key: weekKey, title: 'This week', child: const _WeekBars()),
        const _Section(title: 'By drink', child: _Breakdown()),
        const _Section(title: 'Reminders', child: _Reminders()),
        const _Section(title: 'Daily goal', child: _Goal()),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: akT(17, w: FontWeight.w800, ls: -0.4)),
          const SizedBox(height: 12),
          child,
        ]),
      );
}

class _EntryRow extends StatelessWidget {
  final DrinkEntry e;
  const _EntryRow(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = drinkById(e.drink);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: c)),
      child: Dismissible(
        key: ObjectKey(e),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          HydrationStore.I.remove(e);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: _navy,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Text('${d.name} removed', style: akT(13.5, c: Colors.white)),
              action: SnackBarAction(label: 'Undo', textColor: const Color(0xFF7CC4F5), onPressed: HydrationStore.I.undo),
            ));
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [d.color.withValues(alpha: 0.55), d.color],
                ),
              ),
              child: Icon(d.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: akT(15, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(_time(e.at), style: akT(12.5, w: FontWeight.w500, c: akFaint)),
              ]),
            ),
            Text('${e.ml} ml', style: akN(15, w: FontWeight.w700, c: _navyInk)),
          ]),
        ),
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars();
  @override
  Widget build(BuildContext context) {
    final s = HydrationStore.I;
    final now = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
    final vals = [for (final d in days) s.mlOn(d)];
    final maxV = math.max(s.goal, vals.reduce(math.max)).toDouble();
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final avg = vals.reduce((a, b) => a + b) ~/ 7;
    final hit = vals.where((v) => v >= s.goal).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Row(children: [
          _Stat('Average', '${_ml(avg)} ml'),
          _Stat('Goal hit', '$hit of 7 days'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: AkSeen(
            builder: (_, t) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      height: 100 * (vals[i] / maxV) * t + 4,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: i == 6
                              ? const [Color(0xFF2B86DA), Color(0xFF7CC4F5)]
                              : vals[i] >= s.goal
                                  ? const [Color(0xFF8CC8F5), Color(0xFFBFE2FC)]
                                  : const [Color(0xFFCBD5E1), Color(0xFFE2E8F0)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(names[days[i].weekday - 1],
                        style: akT(11.5, w: FontWeight.w700, c: i == 6 ? _navyInk : akFaint)),
                  ]),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: akT(12, w: FontWeight.w600, c: akMuted)),
          const SizedBox(height: 3),
          Text(value, style: akN(18, c: _navyInk)),
        ]),
      );
}

class _Breakdown extends StatelessWidget {
  const _Breakdown();
  @override
  Widget build(BuildContext context) {
    final s = HydrationStore.I;
    final by = <String, int>{};
    for (final e in s.today) {
      by[e.drink] = (by[e.drink] ?? 0) + e.ml;
    }
    final total = by.values.fold(0, (a, b) => a + b);
    if (total == 0) return Text('Log a drink to see the mix.', style: akT(13, w: FontWeight.w500, c: akMuted));
    final items = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 14,
          child: Row(children: [
            for (final e in items)
              Expanded(flex: e.value, child: ColoredBox(color: drinkById(e.key).color)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      for (final e in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: drinkById(e.key).color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(drinkById(e.key).name, style: akT(13.5, w: FontWeight.w600))),
            Text('${e.value} ml', style: akT(13, w: FontWeight.w700, c: akMuted)),
            SizedBox(
              width: 48,
              child: Text('${(e.value / total * 100).round()}%',
                  textAlign: TextAlign.right, style: akT(13, w: FontWeight.w800, c: _navyInk)),
            ),
          ]),
        ),
    ]);
  }
}

class _Reminders extends StatelessWidget {
  const _Reminders();
  @override
  Widget build(BuildContext context) {
    final s = HydrationStore.I;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.notifications_active_rounded, color: _sky, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Remind me to drink', style: akT(14.5, w: FontWeight.w700))),
          Switch.adaptive(
            value: s.reminders,
            activeTrackColor: _sky,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              s.setReminders(v);
            },
          ),
        ]),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: s.reminders ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          secondChild: const SizedBox(width: double.infinity),
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in const [30, 60, 90, 120])
                AkPress(
                  onTap: () => s.setReminders(true, m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: s.reminderEveryMin == m ? _deep : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m < 60 ? 'Every $m min' : 'Every ${m / 60 == 1 ? '1 h' : '${(m / 60).toStringAsFixed(m % 60 == 0 ? 0 : 1)} h'}',
                        style: akT(12.5, w: FontWeight.w700, c: s.reminderEveryMin == m ? Colors.white : _navyInk)),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Goal extends StatelessWidget {
  const _Goal();
  @override
  Widget build(BuildContext context) {
    final s = HydrationStore.I;
    Widget btn(IconData i, int d) => AkPress(
          onTap: () => s.setGoal((s.goal + d).clamp(1000, 5000)),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(i, color: _navyInk),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        btn(Icons.remove_rounded, -250),
        Expanded(
          child: Column(children: [
            Text('${_ml(s.goal)} ml', style: akN(24, c: _navyInk)),
            const SizedBox(height: 3),
            Text('About ${(s.goal / 250).round()} glasses', style: akT(12, w: FontWeight.w600, c: akMuted)),
          ]),
        ),
        btn(Icons.add_rounded, 250),
      ]),
    );
  }
}

// =====================================================================
//  DOCK + ADD SHEET
// =====================================================================

class _Dock extends StatelessWidget {
  final VoidCallback onTop, onLog, onStats, onAdd;
  const _Dock({required this.onTop, required this.onLog, required this.onStats, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    Widget icon(IconData i, VoidCallback f) => AkPress(
          onTap: f,
          child: SizedBox(width: 48, height: 48, child: Icon(i, color: Colors.white.withValues(alpha: 0.85), size: 21)),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _deep,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(children: [
          icon(Icons.local_drink_rounded, onTop),
          icon(Icons.receipt_long_rounded, onLog),
          icon(Icons.donut_large_rounded, onStats),
        ]),
      ),
      const SizedBox(width: 10),
      AkPress(
        onTap: onAdd,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _deep,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    ]);
  }
}

class _AddDrinkSheet extends StatefulWidget {
  final String drink;
  final int ml;
  const _AddDrinkSheet({required this.drink, required this.ml});
  @override
  State<_AddDrinkSheet> createState() => _AddDrinkSheetState();
}

class _AddDrinkSheetState extends State<_AddDrinkSheet> {
  late String drink = widget.drink;
  late double ml = widget.ml.toDouble();

  @override
  Widget build(BuildContext context) {
    final d = drinkById(drink);
    final counted = (ml * d.hydration).round();
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.paddingOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(
            width: 38,
            height: 5,
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Add a drink', style: akT(22, w: FontWeight.w800, ls: -0.6)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.86,
          children: [
            for (final x in drinks)
              AkPress(
                onTap: () => setState(() => drink = x.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: x.id == drink ? x.color.withValues(alpha: 0.14) : const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: x.id == drink ? x.color : Colors.transparent, width: 1.6),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(x.icon, color: x.color, size: 24),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(x.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: akT(11, w: FontWeight.w700, c: x.id == drink ? akInk : akMuted)),
                    ),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${ml.round()}', style: akN(40, c: _navyInk)),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text('ml', style: akT(16, w: FontWeight.w600, c: akMuted)),
          ),
          const Spacer(),
          if (d.hydration < 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Counts as $counted ml', style: akT(12.5, w: FontWeight.w700, c: _skyText)),
            ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: d.color,
            thumbColor: Colors.white,
            inactiveTrackColor: d.color.withValues(alpha: 0.15),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13, elevation: 4),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: ml,
            min: 50,
            max: 1000,
            divisions: 95,
            onChanged: (v) {
              if (v.round() != ml.round()) HapticFeedback.selectionClick();
              setState(() => ml = v);
            },
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in const [150, 250, 330, 500, 750])
            AkPress(
              onTap: () => setState(() => ml = p.toDouble()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: ml.round() == p ? _deep : const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('$p ml', style: akT(12.5, w: FontWeight.w700, c: ml.round() == p ? Colors.white : _navyInk)),
              ),
            ),
        ]),
        const SizedBox(height: 18),
        AkPress(
          onTap: () {
            HapticFeedback.mediumImpact();
            HydrationStore.I.add(drink, ml.round());
            Navigator.of(context).pop();
          },
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _deep, borderRadius: BorderRadius.circular(20)),
            child: Text('Add ${d.name.toLowerCase()} · ${ml.round()} ml', style: akT(15.5, w: FontWeight.w800, c: Colors.white)),
          ),
        ),
      ]),
    );
  }
}
