part of '../shop_tab_v3.dart';

// =====================================================================
//  HERO CAROUSEL
// =====================================================================

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _pc = PageController(viewportFraction: 0.9);
  int _page = 0;
  Timer? _t;

  static const _slides = [
    ('${_img}hero_banner_1.png', 'Mega protein week', 'Up to 40% off whey', _orange),
    ('${_img}hero_banner_2.png', 'Build your home gym', 'No-cost EMI from ₹2,083/mo', _blue),
    ('${_img}hero_banner_3.png', 'Run lighter', 'New Cloud Run shoes', _green),
    ('${_img}hero_banner_4.png', 'Recovery essentials', 'Buy 2, get 1 free', _violet),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pc.hasClients) return;
      _pc.animateToPage((_page + 1) % _slides.length, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Column(children: [
        AspectRatio(
          aspectRatio: 1.85,
          child: PageView.builder(
            controller: _pc,
            itemCount: _slides.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (_, i) => AnimatedBuilder(
              animation: _pc,
              builder: (_, c) {
                final d = _pc.hasClients && _pc.positions.length == 1 && _pc.position.haveDimensions ? (_pc.page ?? 0) - i : (_page - i).toDouble();
                return Transform.scale(scale: 1 - 0.06 * d.abs().clamp(0.0, 1.0), child: c);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(_slides[i].$1, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xB3000000), Color(0x00000000)],
                          stops: [0, 0.7],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 14,
                      right: 90,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _slides[i].$4, borderRadius: BorderRadius.circular(8)),
                          child: Text('LIMITED', style: akT(10, w: FontWeight.w800, c: Colors.white, ls: 1)),
                        ),
                        const SizedBox(height: 6),
                        Text(_slides[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(19, w: FontWeight.w800, c: Colors.white)),
                        Text(_slides[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12.5, c: Colors.white70)),
                      ]),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: LiquidGlass(
                        style: LiquidGlassStyle.clear,
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shadow: false,
                        onTap: () => shopPush(context, const OffersPage()),
                        child: Text('Shop', style: akT(13, w: FontWeight.w800, c: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _slides.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == _page ? _orange : Colors.black12, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
      ]),
    );
  }
}
