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
import '../../backend/me.dart';

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

List<Product> get _products => shopProducts;
Product _p(int i) => shopPick(i);

/// Rebuilds a section when the live catalogue changes; hidden while there are no products.
class _Live extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final bool needsProducts;
  const _Live(this.builder, {this.needsProducts = true});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: ShopStore.I.catalog,
        builder: (c, _, __) => needsProducts && shopProducts.isEmpty ? const SizedBox.shrink() : builder(c),
      );
}
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
    final st = ShopStore.I;
    return [
        const SizedBox(height: 18),
        AkWelcome(caption: 'SHOP · FREE DELIVERY OVER ₹999', words: ['Gear', 'up,', Me.first], accent: _orange),
        const SizedBox(height: 14),
        const _SearchRow(),
        const SizedBox(height: 14),
        const _QuickLinks(),
        const SizedBox(height: 16),
        const _HeroCarousel(),
        _Live((_) => st.catalogReady ? const AkHead('Products are on the way', caption: 'New products from the NeuroFit store will show up here') : const SizedBox.shrink(), needsProducts: false),
        const AkHead('Categories'),
        const _Categories(),
        _Live((_) => const AkHead('Flash deals', caption: 'Ends tonight')),
        _Live((_) => const _FlashDeals()),
        _Live((_) => AkHead('Best sellers', action: 'See all', onAction: () {})),
        _Live((_) => _Grid(items: st.bestSellers.take(4).toList())),
        _Live((_) => AkHead('Offers for you', action: 'See all', onAction: () => shopPush(context, const OffersPage()))),
        _Live((_) => const _Offers()),
        const AkHead('Shop by goal'),
        const _Goals(),
        _Live((_) => const AkHead('New arrivals')),
        _Live((_) => _Rail(items: st.newArrivals.take(5).toList())),
        _Live((_) => const AkHead('Bundle & save')),
        _Live((_) => const ScrollReveal(child: _Bundle())),
        const AkHead('Top brands'),
        const _Brands(),
        _Live((_) => const AkHead('Trending now')),
        _Live((_) => const _Trending()),
        _Live((_) => st.inCat('protein').isEmpty ? const SizedBox.shrink() : AkHead('Protein & supplements', action: 'See all', onAction: () {})),
        _Live((_) => _Grid(items: st.inCat('protein'))),
        _Live((_) => AkHead('Gym gear', action: 'See all', onAction: () {})),
        _Live((_) => _Grid(items: _products.where((p) => !p.cat.toLowerCase().contains('protein')).take(6).toList())),
        _Live((_) => const AkHead('Picked by Kemo', caption: 'Based on your workouts and goals')),
        _Live((_) => const _KemoPicks()),
        _Live((_) => st.inCat('equip').isEmpty ? const SizedBox.shrink() : const AkHead('Home gym')),
        _Live((_) => _Rail(items: st.inCat('equip').take(4).toList())),
        const AkHead('What people say'),
        const _Reviews(),
        const SizedBox(height: 18),
        const ScrollReveal(child: _Membership()),
        _Live((_) => st.recentlyViewed.isEmpty ? const SizedBox.shrink() : const AkHead('Recently viewed')),
        _Live((_) => _Rail(items: st.recentlyViewed.take(6).toList(), small: true)),
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

