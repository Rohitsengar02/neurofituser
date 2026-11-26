part of '../workout_tab_v2.dart';

// =====================================================================
//  PROGRAMS (image cards)
// =====================================================================

const _programs = [
  ('Train Your Core', '4 weeks · Beginner', 'assets/images/workout_category_1.png', 0.35, _orange),
  ('30 Day Shred', '30 days · Intermediate', 'assets/images/workout_category_3.png', 0.6, _green),
  ('Transformation', '8 weeks · Advanced', 'assets/images/workout_category_4.png', 0.12, _mint),
  ('Shoulder Press 4×', '2 weeks · All levels', 'assets/images/spotlight_3.png', 0.0, _pink),
  ('Push Harder', '6 weeks · Intermediate', 'assets/images/top_pick_1.png', 0.0, _blue),
];

class _Programs extends StatelessWidget {
  const _Programs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 276,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: _programs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = _programs[i];
          return ScrollReveal(
            delayMs: i * 80,
            child: _PressScale(
              onTap: () {},
              child: Container(
                width: 196,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 22, offset: const Offset(0, 12)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(p.$3, fit: BoxFit.cover),
                  // Liquid glass caption floating over the art.
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: LiquidGlass(
                      style: LiquidGlassStyle.clear,
                      borderRadius: BorderRadius.circular(20),
                      colors: [Colors.black.withValues(alpha: 0.28), Colors.black.withValues(alpha: 0.42)],
                      shadow: false,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14.5, w: FontWeight.w800, c: Colors.white)),
                        Text(p.$2, style: _t(11, w: FontWeight.w600, c: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 8),
                        _Seen(
                          builder: (_, t) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.$4 == 0 ? 0.0001 : p.$4 * t,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              valueColor: AlwaysStoppedAnimation(p.$5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(p.$4 == 0 ? 'Not started' : '${(p.$4 * 100).round()}% complete',
                            style: _t(11, w: FontWeight.w700, c: Colors.white.withValues(alpha: 0.9))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScale({required this.child, required this.onTap});
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: Duration(milliseconds: _down ? 110 : 450),
          curve: _down ? Curves.easeOut : _spring,
          child: widget.child,
        ),
      );
}
