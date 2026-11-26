import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shop/cart_page.dart';
import '../../shop/orders_page.dart';
import '../../shop/product_page.dart';
import '../../shop/shop_data.dart';
import '../../shop/shop_ui.dart';
import '../../widgets/apple_kit.dart';
import '../../widgets/liquid_glass.dart';

part 'sections/search_cart.dart';
part 'sections/hero_carousel.dart';
part 'sections/categories.dart';
part 'sections/product_cards.dart';
part 'sections/flash_deals.dart';
part 'sections/offers_and_brands.dart';
part 'sections/kemo_picks_and_trust.dart';
part 'sections/quick_links.dart';

// Shop tab in the shared Apple style: banner carousel, category carousel,
// flash deals with a live countdown, product grids and rails, offers,
// bundles, brands, reviews and a membership banner. Product cards open a
// glass product page with a working cart counter.

const _green = Color(0xFF16A34A);
const _orange = Color(0xFFF97316);
const _red = Color(0xFFEF4444);
const _amber = Color(0xFFF59E0B);
const _violet = Color(0xFF8B5CF6);
const _blue = Color(0xFF3B82F6);
const _teal = Color(0xFF14B8A6);

const _img = 'assets/images/';

const _products = shopProducts;
String _rs(int v) => rs(v);

/// Badge listenables kept for older callers; the real state is ShopStore.
class ShopCart {
  ShopCart._();
  static ValueNotifier<int> get count => ShopStore.I.cartCount;
  static ValueNotifier<Set<String>> get saved => ShopStore.I.saved;
}

void _open(BuildContext context, Product p) => openProduct(context, p);
void _addToCart(BuildContext context, Product p) => addToBag(context, p);

// =====================================================================

class ShopTabV3 extends StatelessWidget {
  const ShopTabV3({super.key});

  /// The tab's sections, built lazily by the home scroll view.
  static List<Widget> sections(BuildContext context) {
    final protein = _products.where((p) => p.cat == 'Protein').toList();
    final gear = _products.where((p) => p.cover).toList();
    return [
        const SizedBox(height: 18),
        const AkWelcome(caption: 'SHOP · FREE DELIVERY OVER ₹999', words: ['Gear', 'up,', 'Rohit'], accent: _orange),
        const SizedBox(height: 14),
        const _SearchRow(),
        const SizedBox(height: 14),
        const _QuickLinks(),
        const SizedBox(height: 16),
        const _HeroCarousel(),
        const AkHead('Categories'),
        const _Categories(),
        const AkHead('Flash deals', caption: 'Ends tonight'),
        const _FlashDeals(),
        AkHead('Best sellers', action: 'See all', onAction: () {}),
        _Grid(items: [_products[0], _products[5], _products[7], _products[2]]),
        AkHead('Offers for you', action: 'See all', onAction: () => shopPush(context, const OffersPage())),
        const _Offers(),
        const AkHead('Shop by goal'),
        const _Goals(),
        const AkHead('New arrivals'),
        _Rail(items: [_products[6], _products[9], _products[11], _products[12], _products[14]]),
        const AkHead('Bundle & save'),
        const ScrollReveal(child: _Bundle()),
        const AkHead('Top brands'),
        const _Brands(),
        const AkHead('Trending now'),
        const _Trending(),
        AkHead('Protein & supplements', action: 'See all', onAction: () {}),
        _Grid(items: protein),
        AkHead('Gym gear', action: 'See all', onAction: () {}),
        _Grid(items: gear.take(6).toList()),
        const AkHead('Picked by Kemo', caption: 'Based on your workouts and goals'),
        const _KemoPicks(),
        const AkHead('Home gym'),
        _Rail(items: [_products[3], _products[4], _products[5], _products[12]]),
        const AkHead('What people say'),
        const _Reviews(),
        const SizedBox(height: 18),
        const ScrollReveal(child: _Membership()),
        const AkHead('Recently viewed'),
        _Rail(items: [_products[1], _products[8], _products[13], _products[10]], small: true),
        const SizedBox(height: 18),
        const ScrollReveal(child: _Trust()),
        const SizedBox(height: 24),
      ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections(context),
    );
  }
}

