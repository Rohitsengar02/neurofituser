part of '../workout_tab_v2.dart';

// =====================================================================
//  QUICK WORKOUTS
// =====================================================================

const _quick = [
  ('10-min HIIT', '10 min · 120 kcal', '0630-RJgzwny.jpg', _pink),
  ('Core Blast', '12 min · 90 kcal', '0687-XVDdcoj.jpg', _amber),
  ('Leg Day Express', '15 min · 150 kcal', '1760-yn8yg1r.jpg', _green),
  ('Arm Pump', '8 min · 60 kcal', '0294-NbVPDMW.jpg', _blue),
  ('Kettlebell Flow', '14 min · 160 kcal', '0549-UHJlbu3.jpg', _purple),
];

class _QuickRow extends StatelessWidget {
  const _QuickRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quick.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final q = _quick[i];
          return ScrollReveal(
            delayMs: i * 70,
            child: SizedBox(
              width: 150,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(26),
                padding: const EdgeInsets.all(8),
                onTap: () {},
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Stack(children: [
                    _ExerciseThumb(q.$3, size: 134),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: q.$4),
                        child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(q.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13.5, w: FontWeight.w800)),
                      Text(q.$2, maxLines: 1, style: _t(11, w: FontWeight.w600, c: _muted)),
                    ]),
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
