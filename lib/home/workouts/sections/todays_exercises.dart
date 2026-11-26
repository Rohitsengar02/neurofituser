part of '../workout_tab_v2.dart';

// =====================================================================
//  TODAY'S EXERCISES
// =====================================================================

class _TodayList extends StatefulWidget {
  const _TodayList();
  @override
  State<_TodayList> createState() => _TodayListState();
}

class _TodayListState extends State<_TodayList> {
  final _done = <int>{0, 1};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        for (var i = 0; i < _today.length; i++) ...[
          ScrollReveal(
            delayMs: (i % 3) * 60,
            child: LiquidGlass(
              style: LiquidGlassStyle.material,
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(10),
              onTap: () => _showExercise(context, _today[i]),
              child: Row(children: [
                _ExerciseThumb(_today[i].image, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_today[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(14.5, w: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${_today[i].sets} · ${_today[i].muscle}', style: _t(12, w: FontWeight.w600, c: _muted)),
                  ]),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: _spring,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _done.contains(i) ? _mint : Colors.white,
                      border: Border.all(color: _done.contains(i) ? _mint : const Color(0xFFE5E7EB), width: 1.5),
                    ),
                    child: AnimatedScale(
                      scale: _done.contains(i) ? 1 : 0.4,
                      duration: const Duration(milliseconds: 420),
                      curve: _spring,
                      child: Icon(Icons.check_rounded,
                          size: 22, color: _done.contains(i) ? Colors.white : Colors.transparent),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  final String file;
  final double size;
  const _ExerciseThumb(this.file, {required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: const Color(0xFFEEF0EF)),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(3),
        child: Image.asset(_ex(file), fit: BoxFit.contain),
      );
}

void _showExercise(BuildContext context, _Exercise e) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: LiquidGlass(
        style: LiquidGlassStyle.regular,
        borderRadius: BorderRadius.circular(34),
        colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.82)],
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: _spring,
                builder: (_, s, c) => Transform.scale(scale: s, child: c),
                child: _ExerciseThumb(e.image, size: 200),
              ),
            ),
            const SizedBox(height: 16),
            Text(e.name, style: _t(22, w: FontWeight.w800, ls: -0.5)),
            const SizedBox(height: 4),
            Text('${e.sets} · ${e.muscle}', style: _t(13.5, w: FontWeight.w700, c: _green)),
            const SizedBox(height: 12),
            Text(e.tip, style: _t(14, w: FontWeight.w500, c: _muted, h: 1.5)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _DarkButton(label: 'Start set 1', onTap: () => Navigator.of(ctx).pop()),
            ),
          ]),
        ),
      ),
    ),
  );
}
