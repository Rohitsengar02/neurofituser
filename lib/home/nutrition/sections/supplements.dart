part of '../nutrition_tab_v3.dart';

// =====================================================================
//  SUPPLEMENTS
// =====================================================================

class _Supplements extends StatefulWidget {
  const _Supplements();
  @override
  State<_Supplements> createState() => _SupplementsState();
}

class _SupplementsState extends State<_Supplements> {
  final _taken = <int>{0};

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Whey protein', 'After workout · 1 scoop', Icons.fitness_center_rounded, _purple),
      ('Omega-3', 'With lunch · 2 caps', Icons.water_drop_rounded, _amber),
      ('Vitamin D3', 'Morning · 1 tab', Icons.wb_sunny_rounded, _orange),
      ('Creatine', 'Any time · 5 g', Icons.bolt_rounded, _blue),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('assets/images/nutrifit_whey_protein.jpg', width: 76, height: 76, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daily stack', style: _t(16, w: FontWeight.w800)),
                Text('${_taken.length} of ${items.length} taken today', style: _t(12, w: FontWeight.w600, c: _muted)),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: _taken.length / items.length),
                  duration: const Duration(milliseconds: 600),
                  curve: _spring,
                  builder: (_, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: _purple.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(_purple),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _taken.contains(i) ? _taken.remove(i) : _taken.add(i));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: items[i].$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(items[i].$3, size: 19, color: items[i].$4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(items[i].$1, style: _t(13.5, w: FontWeight.w700)),
                      Text(items[i].$2, style: _t(11.5, w: FontWeight.w600, c: _muted)),
                    ]),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: _spring,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _taken.contains(i) ? _mint : Colors.transparent,
                      border: Border.all(color: _taken.contains(i) ? _mint : const Color(0xFFD1D5DB), width: 1.6),
                    ),
                    child: _taken.contains(i) ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
