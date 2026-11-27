part of '../shop_tab_v3.dart';

// =====================================================================
//  KEMO PICKS / REVIEWS / MEMBERSHIP / TRUST
// =====================================================================

class _KemoPicks extends StatelessWidget {
  const _KemoPicks();

  @override
  Widget build(BuildContext context) {
    final picks = [
      (_p(12), 'Fits your Day 13 strength plan'),
      (_p(2), 'You are 34 g short on protein today'),
      (_p(9), 'Pairs with your evening stretch'),
    ];
    return Column(children: [
      for (final (p, why) in picks)
        ScrollReveal(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AkGlass(
              padding: const EdgeInsets.all(10),
              onTap: () => _open(context, p),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: p.cover
                        ? productImage(p.image, fit: BoxFit.cover)
                        : ColoredBox(color: Colors.white, child: productImage(p.image, fit: BoxFit.contain)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14, w: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded, size: 13, color: _teal),
                      const SizedBox(width: 4),
                      Expanded(child: Text(why, maxLines: 2, style: akT(11.5, c: akMuted, h: 1.3))),
                    ]),
                    const SizedBox(height: 4),
                    Text(_rs(p.price), style: akN(15)),
                  ]),
                ),
                AkPress(
                  onTap: () => _addToCart(context, p),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: _teal.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: _teal, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews();

  @override
  Widget build(BuildContext context) {
    const reviews = [
      ('Aarav S.', 'Gold Standard Whey', 'Mixes clean, no lumps. Recovery feels faster after leg day.', 5),
      ('Meera K.', 'Grip Yoga Mat', 'Doesn\'t slide even in hot yoga. Worth every rupee.', 5),
      ('Kabir P.', 'Pulse Smartwatch', 'Battery lasts 9 days and the HRV readings match my strap.', 4),
      ('Ishita R.', 'Cloud Run Shoes', 'Super light. Did my first 10K in them without blisters.', 5),
    ];
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: reviews.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = reviews[i];
          return ScrollReveal(
            delayMs: math.min(i, 3) * 70,
            child: SizedBox(
              width: 250,
              child: LiquidGlass(
                style: LiquidGlassStyle.material,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: [_violet, _orange, _blue, _teal][i].withValues(alpha: 0.18),
                      child: Text(r.$1[0], style: akT(13, w: FontWeight.w800, c: [_violet, _orange, _blue, _teal][i])),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.$1, style: akT(13, w: FontWeight.w800)),
                        Text(r.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11, c: akFaint)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (var k = 0; k < 5; k++)
                      Icon(Icons.star_rounded, size: 15, color: k < r.$4 ? _amber : Colors.black12),
                  ]),
                  const SizedBox(height: 6),
                  Text(r.$3, maxLines: 3, overflow: TextOverflow.ellipsis, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.4)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Membership extends StatelessWidget {
  const _Membership();

  @override
  Widget build(BuildContext context) {
    return AkGlass(
      colors: const [Color(0xFF111827), Color(0xFF374151)],
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEUROFIT PLUS', style: akT(11, w: FontWeight.w800, c: const Color(0xFFFDE68A), ls: 1.4)),
            const SizedBox(height: 6),
            Text('Free delivery, extra 10% off and early access', style: akT(16, w: FontWeight.w800, c: Colors.white, h: 1.3)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: const Color(0xFFFDE68A), borderRadius: BorderRadius.circular(14)),
              child: Text('Join for ₹99/mo', style: akT(13, w: FontWeight.w800, c: akInk)),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        const Text('👑', style: TextStyle(fontSize: 54)),
      ]),
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_rounded, 'Free delivery', _blue),
      (Icons.verified_rounded, '100% authentic', _green),
      (Icons.autorenew_rounded, '7-day returns', _orange),
      (Icons.payments_rounded, 'Cash on delivery', _violet),
    ];
    return AkGlass(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(children: [
        for (final (ic, t, c) in items)
          Expanded(
            child: Column(children: [
              Icon(ic, color: c, size: 24),
              const SizedBox(height: 6),
              Text(t, textAlign: TextAlign.center, style: akT(10.5, w: FontWeight.w700, c: akMuted)),
            ]),
          ),
      ]),
    );
  }
}
