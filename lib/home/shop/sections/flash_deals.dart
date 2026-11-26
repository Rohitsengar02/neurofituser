part of '../shop_tab_v3.dart';

// =====================================================================
//  FLASH DEALS
// =====================================================================

class _FlashDeals extends StatefulWidget {
  const _FlashDeals();
  @override
  State<_FlashDeals> createState() => _FlashDealsState();
}

class _FlashDealsState extends State<_FlashDeals> {
  Timer? _t;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _end = DateTime(n.year, n.month, n.day, 23, 59, 59);
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = _end.difference(DateTime.now());
    String two(int v) => v.toString().padLeft(2, '0');
    final parts = [two(left.inHours), two(left.inMinutes % 60), two(left.inSeconds % 60)];
    final deals = [_p(1), _p(7), _p(12), _p(6), _p(9)];
    const claimed = [0.72, 0.48, 0.85, 0.6, 0.35];
    return Column(children: [
      ScrollReveal(
        child: AkGlass(
          colors: const [Color(0xFFFF8A3D), Color(0xFFEF4444)],
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            const Icon(Icons.bolt_rounded, color: Colors.white),
            const SizedBox(width: 6),
            Expanded(child: Text('Lightning deals', style: akT(15, w: FontWeight.w800, c: Colors.white))),
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: 34,
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                child: Text(parts[i], style: akN(14, c: _red)),
              ),
              if (i < 2) Text(' : ', style: akT(14, w: FontWeight.w800, c: Colors.white)),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 238,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: deals.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final p = deals[i];
            return ScrollReveal(
              delayMs: math.min(i, 3) * 70,
              child: SizedBox(
                width: 158,
                child: LiquidGlass(
                  style: LiquidGlassStyle.material,
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(8),
                  onTap: () => _open(context, p),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox.expand(
                          child: p.cover
                              ? productImage(p.image, fit: BoxFit.cover)
                              : ColoredBox(color: Colors.white, child: productImage(p.image, fit: BoxFit.contain)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12.5, w: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(_rs(p.price), style: akN(14.5, c: _red)),
                          const SizedBox(width: 5),
                          Text('-${p.off}%', style: akT(11, w: FontWeight.w800, c: _green)),
                        ]),
                        const SizedBox(height: 6),
                        AkSeen(
                          builder: (_, t) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: claimed[i] * t,
                              minHeight: 5,
                              color: _orange,
                              backgroundColor: _orange.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${(claimed[i] * 100).round()}% claimed', style: akT(10.5, c: akFaint)),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
