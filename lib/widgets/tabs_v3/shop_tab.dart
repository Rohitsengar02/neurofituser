import 'package:flutter/material.dart';

import '../../screens/shop_screen.dart';
import '../dashboard_motion.dart';
import '../shop_home_sections.dart';
import 'kit3.dart';

const _img = 'assets/images';

class ShopTabV3 extends StatelessWidget {
  const ShopTabV3({super.key});

  @override
  Widget build(BuildContext context) {
    return const NTabPage(
      top: [_Search(), _CategoryGrid()],
      sheet: [
        _OfferBanner(),
        _BuyAgain(),
        _Bestsellers(),
        _NewArrivals(),
        _DeliveryStrip(),
      ],
    );
  }
}

void _openStore(BuildContext context, [String? cat]) =>
    nPush(context, ShopScreen(initialCategory: cat));

class _Search extends StatelessWidget {
  const _Search();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 18, color: kBrand),
            const SizedBox(width: 4),
            Text('Delivery in 30 min',
                style: tText(13, w: FontWeight.w700, c: kInk3)),
            const Spacer(),
            Text('Free over ₹499', style: tText(12)),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _openStore(context),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: nCardDeco(r: 16),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: kInk3, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Search "whey protein"',
                      style: tText(14, w: FontWeight.w500)),
                ),
                Container(width: 1, height: 22, color: kLine3),
                const SizedBox(width: 12),
                const Icon(Icons.mic_none_rounded, color: kBrand, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const _items = [
    ('Protein', '$_img/product_1.png'),
    ('Trackers', '$_img/clean/smartwatch.jpg'),
    ('Shoes', '$_img/clean/shoe.jpg'),
    ('Yoga', '$_img/clean/yogamat.jpg'),
    ('Equipment', '$_img/clean/dumbbell.jpg'),
    ('Bottles', '$_img/clean/waterbottle.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return NSquareGrid(
      cols: 3,
      gap: 10,
      aspect: 0.86,
      children: [
        for (var i = 0; i < _items.length; i++)
          NPopIn(
            delay: 50 * i,
            child: PressScale(
              onTap: () => _openStore(context, _items[i].$1),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                decoration: nCardDeco(r: 18),
                child: Column(
                  children: [
                    Text(_items[i].$1,
                        maxLines: 1,
                        style: tText(12.5, w: FontWeight.w700, c: kInk3)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(_items[i].$2,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            cacheWidth: 300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner();

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => _openStore(context),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: kAccentSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 10,
              bottom: -10,
              width: 150,
              child: Image.asset('$_img/product_2.png',
                  fit: BoxFit.contain, cacheWidth: 420),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FIRST ORDER',
                      style: tText(10.5,
                          w: FontWeight.w700, c: kAccent, spacing: 0.6)),
                  const SizedBox(height: 6),
                  Text('Flat 30% off\non protein',
                      style: tDisplay(21, w: FontWeight.w800, height: 1.15)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B2E12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Shop now',
                            style: tText(12.5,
                                w: FontWeight.w700, c: Colors.white)),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyAgain extends StatelessWidget {
  const _BuyAgain();

  @override
  Widget build(BuildContext context) {
    final picks = [
      shopDemoProducts[0],
      shopDemoProducts[7],
      shopDemoProducts[10],
      shopDemoProducts[5],
      shopDemoProducts[8],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Buy Again',
            action: 'See all', onAction: () => _openStore(context)),
        NCarousel(
          height: 262,
          count: picks.length,
          builder: (context, i) => NProductCard(picks[i]),
        ),
      ],
    );
  }
}

class _Bestsellers extends StatelessWidget {
  const _Bestsellers();

  @override
  Widget build(BuildContext context) {
    final picks = [...shopDemoProducts]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final four = picks.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('Bestsellers',
            action: 'See all', onAction: () => _openStore(context)),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              for (var i = 0; i < four.length; i++)
                NPopIn(
                    delay: 60 * i, child: NProductCard(four[i], width: w)),
            ],
          );
        }),
      ],
    );
  }
}

class _NewArrivals extends StatelessWidget {
  const _NewArrivals();

  @override
  Widget build(BuildContext context) {
    final picks = shopDemoProducts.where((p) => p.isNew).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NHead('New Arrivals',
            action: 'See all', onAction: () => _openStore(context)),
        NCarousel(
          height: 262,
          count: picks.length,
          builder: (context, i) => NProductCard(picks[i]),
        ),
      ],
    );
  }
}

class _DeliveryStrip extends StatelessWidget {
  const _DeliveryStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: nCardDeco(r: 18),
      child: Row(
        children: [
          const NIconTile(Icons.local_shipping_rounded, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free delivery',
                    style: tText(14.5, w: FontWeight.w600, c: kInk3)),
                const SizedBox(height: 2),
                Text('On orders above ₹499', style: tText(12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kMuted3),
        ],
      ),
    );
  }
}
