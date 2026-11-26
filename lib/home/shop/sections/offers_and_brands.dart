part of '../shop_tab_v3.dart';

// =====================================================================
//  OFFERS / GOALS / BUNDLE / BRANDS / TRENDING
// =====================================================================

class _Offers extends StatelessWidget {
  const _Offers();

  @override
  Widget build(BuildContext context) {
    const posters = ['offer_1.png', 'offer_2.png', 'offer_3.png', 'more_product_2.png', 'more_product_3.png'];
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: posters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ScrollReveal(
          delayMs: math.min(i, 3) * 70,
          child: AkPress(
            onTap: () => shopPush(context, const OffersPage()),
            child: Container(
              width: 175,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset('$_img${posters[i]}', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Goals extends StatelessWidget {
  const _Goals();

  @override
  Widget build(BuildContext context) {
    const goals = [
      ('Build muscle', 'Whey, creatine, weights', Icons.fitness_center_rounded, [Color(0xFFC4B5FD), Color(0xFF7C3AED)]),
      ('Lose fat', 'Cardio gear, shakers', Icons.local_fire_department_rounded, [Color(0xFFFDBA74), Color(0xFFEA580C)]),
      ('Endurance', 'Shoes, watches, ropes', Icons.directions_run_rounded, [Color(0xFF93C5FD), Color(0xFF2563EB)]),
      ('Recovery', 'Mats, rollers, sleep', Icons.spa_rounded, [Color(0xFF5EEAD4), Color(0xFF0D9488)]),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          for (var i = 0; i < goals.length; i++)
            ScrollReveal(
              delayMs: (i % 2) * 80,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(24),
                colors: goals[i].$4,
                padding: const EdgeInsets.all(14),
                onTap: () {},
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(goals[i].$3, color: Colors.white, size: 26),
                  const Spacer(),
                  Text(goals[i].$1, style: akT(15.5, w: FontWeight.w800, c: Colors.white)),
                  Text(goals[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, c: Colors.white70)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bundle extends StatelessWidget {
  const _Bundle();

  @override
  Widget build(BuildContext context) {
    final items = [_p(2), _p(13), _p(8)];
    final total = items.fold(0, (a, p) => a + p.price);
    final bundle = (total * 0.8).round();
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Starter stack', style: akT(17, w: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Text('Save 20%', style: akT(11.5, w: FontWeight.w800, c: _green)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: items[i].cover
                      ? productImage(items[i].image, fit: BoxFit.cover)
                      : ColoredBox(color: Colors.white, child: productImage(items[i].image, fit: BoxFit.contain)),
                ),
              ),
            ),
            if (i < items.length - 1)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.add_rounded, color: akMuted, size: 18)),
          ],
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_rs(bundle), style: akN(24)),
            Text(_rs(total), style: akT(12, c: akFaint).copyWith(decoration: TextDecoration.lineThrough)),
          ]),
          const Spacer(),
          AkPress(
            onTap: () {
              for (final p in items.skip(1)) {
                ShopStore.I.add(p);
              }
              _addToCart(context, items.first);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(color: akInk, borderRadius: BorderRadius.circular(16)),
              child: Text('Add bundle', style: akT(14, w: FontWeight.w800, c: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Brands extends StatelessWidget {
  const _Brands();

  @override
  Widget build(BuildContext context) {
    const brands = [
      ('NeuroFit', _green), ('Optimum', _red), ('NutriFit', akInk), ('Stride', _blue),
      ('Zen Flow', _teal), ('Pulse', _orange), ('IronCore', _violet),
    ];
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ScrollReveal(
          delayMs: math.min(i, 4) * 50,
          child: LiquidGlass(
            style: LiquidGlassStyle.material,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onTap: () {},
            child: SizedBox(
              height: 58,
              child: Center(
                child: Text(brands[i].$1, style: akT(16, w: FontWeight.w900, c: brands[i].$2, ls: -0.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Trending extends StatefulWidget {
  const _Trending();
  @override
  State<_Trending> createState() => _TrendingState();
}

class _TrendingState extends State<_Trending> {
  final _pc = PageController(viewportFraction: 0.62);
  static const _posters = [
    ('top_pick_1.png', '#1 Strawberry whey'),
    ('spotlight_1.png', 'Iso Legend'),
    ('top_pick_3.png', 'Plant protein'),
    ('spotlight_2.png', 'Pre-workout'),
    ('top_pick_4.png', 'Bone broth'),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: SizedBox(
        height: 300,
        child: PageView.builder(
          controller: _pc,
          padEnds: false,
          itemCount: _posters.length,
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _pc,
            builder: (_, c) {
              final d = _pc.hasClients && _pc.positions.length == 1 && _pc.position.haveDimensions ? (_pc.page ?? 0) - i : i.toDouble();
              return Transform.scale(scale: 1 - 0.08 * d.abs().clamp(0.0, 1.0), alignment: Alignment.centerLeft, child: c);
            },
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('$_img${_posters[i].$1}', fit: BoxFit.cover),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: LiquidGlass(
                      style: LiquidGlassStyle.regular,
                      borderRadius: BorderRadius.circular(18),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shadow: false,
                      child: Row(children: [
                        Text('${i + 1}', style: akN(20, c: _orange)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_posters[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(13, w: FontWeight.w800))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
