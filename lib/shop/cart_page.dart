import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/apple_kit.dart';
import 'checkout_page.dart';
import 'product_page.dart';
import 'shop_data.dart';
import 'shop_ui.dart';

// Bag, wishlist and offers pages.

// =====================================================================
//  BAG
// =====================================================================

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final b = store.bill;
        final empty = store.cart.isEmpty;
        final picks = shopProducts.where((p) => !store.cart.any((l) => l.product == p)).take(6).toList();
        return ShopPage(
          title: 'My bag',
          caption: empty ? 'Nothing here yet' : '${store.count} items · ${rs(b.total)}',
          actions: [
            ValueListenableBuilder<Set<String>>(
              valueListenable: store.saved,
              builder: (_, s, _) => GlassIcon(
                Icons.favorite_border_rounded,
                badge: s.isEmpty ? null : CountBadge(s.length, color: shopRed),
                onTap: () => shopPush(context, const WishlistPage()),
              ),
            ),
          ],
          bottom: empty
              ? null
              : ShopBottomBar(
                  child: Row(children: [
                    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(rs(b.total), style: akN(22)),
                      if (b.saved > 0) Text('Saved ${rs(b.saved)}', style: akT(12, w: FontWeight.w800, c: shopGreen)),
                    ]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ShopButton('Checkout', icon: Icons.lock_rounded, color: shopOrange, onTap: () => shopPush(context, const CheckoutPage())),
                    ),
                  ]),
                ),
          body: empty
              ? EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your bag is empty',
                  body: 'Everything you add shows up here, ready to check out.',
                  action: 'Start shopping',
                  onAction: () => Navigator.of(context).popUntil((r) => r.isFirst),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 130 + MediaQuery.paddingOf(context).bottom),
                  children: [
                    Rise(child: ShopCard(child: FreeDeliveryBar(b.subtotal))),
                    const SizedBox(height: 12),
                    for (var i = 0; i < store.cart.length; i++)
                      Rise(delay: math.min(i, 4) * 60, child: _CartLineCard(store.cart[i], key: ObjectKey(store.cart[i]))),
                    const SizedBox(height: 4),
                    const _CouponCard(),
                    const AkHead('You might also like'),
                    ProductRail(items: picks, width: 140),
                    const AkHead('Price details'),
                    ShopCard(child: BillRows(b, coupon: store.couponCode)),
                    const SizedBox(height: 14),
                    ShopCard(
                      child: Row(children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Safe and secure payments. Easy returns. 100% authentic products.',
                              style: akT(12.5, w: FontWeight.w600, c: akMuted, h: 1.4)),
                        ),
                      ]),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CartLineCard extends StatelessWidget {
  final CartLine l;
  const _CartLineCard(this.l, {super.key});

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    final p = l.product;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Dismissible(
        key: ObjectKey(l),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          store.remove(l);
          shopToast(context, '${p.name} removed', icon: Icons.delete_outline_rounded, action: 'Undo', onAction: store.undoRemove);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 26),
          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.delete_outline_rounded, color: shopRed),
        ),
        child: ShopCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(onTap: () => openProduct(context, p), child: ProductThumb(p, size: 88)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.brand, style: akT(11, w: FontWeight.w700, c: akFaint)),
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: akT(14.5, w: FontWeight.w800, h: 1.2)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                    child: Text('${p.optionLabel}: ${l.option}', style: akT(11.5, w: FontWeight.w700, c: akMuted)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(rs(p.price * l.qty), style: akN(17)),
                    const SizedBox(width: 6),
                    if (p.off > 0)
                      Flexible(
                        child: Text(rs(p.old * l.qty),
                            overflow: TextOverflow.ellipsis,
                            style: akT(11.5, c: akFaint).copyWith(decoration: TextDecoration.lineThrough)),
                      ),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              QtyStepper(qty: l.qty, small: true, onChanged: (q) => store.setQty(l, q)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  store.saveForLater(l);
                  shopToast(context, 'Moved to your wishlist', icon: Icons.favorite_rounded);
                },
                icon: const Icon(Icons.favorite_border_rounded, size: 16, color: akMuted),
                label: Text('Save for later', style: akT(12.5, w: FontWeight.w700, c: akMuted)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard();

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    final c = store.coupon;
    return ShopCard(
      onTap: () => showCouponSheet(context),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: (c?.color ?? shopOrange).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.local_offer_rounded, color: c?.color ?? shopOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            layoutBuilder: (cur, prev) => Stack(alignment: Alignment.centerLeft, children: [...prev, ?cur]),
            child: c == null
                ? Column(key: const ValueKey('none'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Apply a coupon', style: akT(14.5, w: FontWeight.w800)),
                    Text('${coupons.length} offers available', style: akT(12, w: FontWeight.w600, c: akMuted)),
                  ])
                : Column(key: ValueKey(c.code), crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${c.code} applied', style: akT(14.5, w: FontWeight.w800, c: shopGreen)),
                    Text(c.freeShip ? 'Free express delivery' : 'You save ${rs(store.bill.coupon)}',
                        style: akT(12, w: FontWeight.w600, c: akMuted)),
                  ]),
          ),
        ),
        if (c == null)
          const Icon(Icons.chevron_right_rounded, color: akMuted)
        else
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              store.removeCoupon();
            },
            child: Text('Remove', style: akT(13, w: FontWeight.w800, c: shopRed)),
          ),
      ]),
    );
  }
}

/// Sheet listing every coupon with a code field; applying one closes it.
Future<void> showCouponSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CouponSheet(),
    );

class _CouponSheet extends StatefulWidget {
  const _CouponSheet();
  @override
  State<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends State<_CouponSheet> {
  final _code = TextEditingController();
  String? error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply(String code) {
    final e = ShopStore.I.applyCoupon(code);
    if (e != null) {
      HapticFeedback.heavyImpact();
      setState(() => error = e);
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    shopToast(context, '${code.toUpperCase()} applied', icon: Icons.local_offer_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ShopStore.I.cart;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        decoration: const BoxDecoration(color: shopBg, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 10),
          Center(child: Container(width: 38, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Text('Coupons', style: akT(22, w: FontWeight.w800, ls: -0.6)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: error == null ? Colors.white : shopRed.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    style: akT(15, w: FontWeight.w800, ls: 1),
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'Enter code', hintStyle: akT(14, w: FontWeight.w500, c: akFaint)),
                    onChanged: (_) => setState(() => error = null),
                    onSubmitted: _apply,
                  ),
                ),
                TextButton(onPressed: () => _apply(_code.text), child: Text('Apply', style: akT(14, w: FontWeight.w800, c: shopOrange))),
              ]),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Text(error!, style: akT(12.5, w: FontWeight.w700, c: shopRed)),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(0, 14, 0, 20 + MediaQuery.paddingOf(context).bottom),
              children: [
                for (var i = 0; i < coupons.length; i++)
                  Rise(
                    delay: i * 50,
                    child: CouponTicket(
                      coupons[i],
                      why: coupons[i].whyNot(cart),
                      saving: coupons[i].discountOn(cart),
                      applied: ShopStore.I.couponCode == coupons[i].code,
                      onApply: () => _apply(coupons[i].code),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Ticket-shaped coupon card with notches and a dashed divider.
class CouponTicket extends StatelessWidget {
  final Coupon c;
  final String? why;
  final int saving;
  final bool applied;
  final VoidCallback onApply;
  final String action;
  const CouponTicket(this.c, {super.key, this.why, this.saving = 0, this.applied = false, required this.onApply, this.action = 'Apply'});

  @override
  Widget build(BuildContext context) {
    final ok = why == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          color: Colors.white,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 74,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.color, Color.lerp(c.color, Colors.black, 0.18)!],
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      c.freeShip ? 'FREE SHIP' : (c.percent > 0 ? '${c.percent}% OFF' : '${rs(c.flat)} OFF'),
                      style: akT(15, w: FontWeight.w900, c: Colors.white, ls: 0.8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.color.withValues(alpha: 0.5)),
                          color: c.color.withValues(alpha: 0.06),
                        ),
                        child: Text(c.code, style: akT(12.5, w: FontWeight.w900, c: c.color, ls: 1)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: ok && !applied ? onApply : null,
                        child: Text(applied ? 'Applied' : action,
                            style: akT(13.5, w: FontWeight.w800, c: applied ? shopGreen : (ok ? shopOrange : akFaint))),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(c.title, style: akT(14.5, w: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(c.detail, style: akT(12.5, w: FontWeight.w500, c: akMuted)),
                    if (saving > 0 && ok) ...[
                      const SizedBox(height: 6),
                      Text('Saves ${rs(saving)} on this bag', style: akT(12, w: FontWeight.w800, c: shopGreen)),
                    ],
                    if (!ok) ...[
                      const SizedBox(height: 6),
                      Text(why!, style: akT(12, w: FontWeight.w700, c: akFaint)),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(20));
    final p = Path()..addRRect(r);
    final notch = Path()
      ..addOval(Rect.fromCircle(center: Offset(74, 0), radius: 9))
      ..addOval(Rect.fromCircle(center: Offset(74, s.height), radius: 9));
    return Path.combine(PathOperation.difference, p, notch);
  }

  @override
  bool shouldReclip(_) => false;
}

// =====================================================================
//  WISHLIST
// =====================================================================

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: store.saved,
      builder: (context, s, _) {
        final items = shopProducts.where((p) => s.contains(p.name)).toList();
        return ShopPage(
          title: 'Wishlist',
          caption: items.isEmpty ? 'Save what you love' : '${items.length} saved',
          tint: shopRed,
          actions: [CartIconButton(onTap: () => shopPush(context, const CartPage()))],
          body: items.isEmpty
              ? EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No saved items yet',
                  body: 'Tap the heart on any product to keep it here for later.',
                  action: 'Explore the shop',
                  color: shopRed,
                  onAction: () => Navigator.of(context).popUntil((r) => r.isFirst),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 40 + MediaQuery.paddingOf(context).bottom),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => Rise(delay: math.min(i, 6) * 60, child: _WishCard(items[i])),
                ),
        );
      },
    );
  }
}

class _WishCard extends StatelessWidget {
  final Product p;
  const _WishCard(this.p);

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    return AkPress(
      onTap: () => openProduct(context, p),
      scale: 0.97,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: LayoutBuilder(builder: (_, c) => ProductThumb(p, size: c.maxWidth, radius: 18))),
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    store.toggleSave(p);
                    shopToast(context, 'Removed from wishlist', icon: Icons.favorite_border_rounded, action: 'Undo', onAction: () => store.toggleSave(p));
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_rounded, color: shopRed, size: 17),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(13.5, w: FontWeight.w800)),
              const SizedBox(height: 3),
              Row(children: [
                Text(rs(p.price), style: akN(15)),
                const SizedBox(width: 6),
                if (p.off > 0) Text('${p.off}% off', style: akT(11.5, w: FontWeight.w800, c: shopGreen)),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          ShopButton('Move to bag', height: 40, icon: Icons.shopping_bag_outlined, onTap: () {
            store.moveToCart(p);
            addToBagSheetOnly(context, p);
          }),
        ]),
      ),
    );
  }
}

/// The bag slider without adding again (the item was just moved in).
void addToBagSheetOnly(BuildContext context, Product p) {
  HapticFeedback.mediumImpact();
  shopToast(context, '${p.name} moved to your bag', icon: Icons.shopping_bag_rounded, action: 'View bag', onAction: () => shopPush(context, const CartPage()));
}

// =====================================================================
//  OFFERS
// =====================================================================

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});
  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final _pc = PageController(viewportFraction: 0.86);
  Timer? _auto;
  int _page = 0;
  late DateTime _end = DateTime.now().add(const Duration(hours: 5, minutes: 42));
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pc.hasClients) return;
      _pc.animateToPage((_page + 1) % 3, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _tick?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    var left = _end.difference(DateTime.now());
    if (left.isNegative) {
      _end = DateTime.now().add(const Duration(hours: 6));
      left = _end.difference(DateTime.now());
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final deals = [...shopProducts]..sort((a, b) => b.off.compareTo(a.off));
    return ShopPage(
      title: 'Offers',
      caption: 'Coupons, deals and bank offers',
      tint: const Color(0xFF8B5CF6),
      actions: [CartIconButton(onTap: () => shopPush(context, const CartPage()))],
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 12, 0, 40 + MediaQuery.paddingOf(context).bottom),
          children: [
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _pc,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => AnimatedBuilder(
                  animation: _pc,
                  builder: (_, c) {
                    final d = _pc.hasClients && _pc.position.haveDimensions ? ((_pc.page ?? 0) - i).abs() : (i == 0 ? 0.0 : 1.0);
                    return Transform.scale(scale: 1 - d.clamp(0.0, 1.0) * 0.08, child: c);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('$shopImg${['offer_1.png', 'offer_2.png', 'offer_3.png'][i]}', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == _page ? akInk : Colors.black26, borderRadius: BorderRadius.circular(3)),
                ),
            ]),
            const SizedBox(height: 6),
            const AkHead('Coupons for you', caption: 'Tap Apply and it is added to your bag'),
            for (var i = 0; i < coupons.length; i++)
              Rise(
                delay: i * 60,
                child: CouponTicket(
                  coupons[i],
                  applied: store.couponCode == coupons[i].code,
                  why: store.cart.isEmpty ? null : coupons[i].whyNot(store.cart),
                  saving: coupons[i].discountOn(store.cart),
                  action: store.cart.isEmpty ? 'Copy' : 'Apply',
                  onApply: () {
                    if (store.cart.isEmpty) {
                      Clipboard.setData(ClipboardData(text: coupons[i].code));
                      shopToast(context, '${coupons[i].code} copied', icon: Icons.copy_rounded);
                      return;
                    }
                    final e = store.applyCoupon(coupons[i].code);
                    shopToast(context, e ?? '${coupons[i].code} applied to your bag',
                        icon: e == null ? Icons.local_offer_rounded : Icons.info_outline_rounded,
                        action: e == null ? 'View bag' : null,
                        onAction: () => shopPush(context, const CartPage()));
                  },
                ),
              ),
            AkHead('Deals of the day', caption: 'Ends in ${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}'),
            ProductRail(items: deals.take(6).toList()),
            const AkHead('Bank & wallet offers'),
            for (final b in const [
              (Icons.credit_card_rounded, 'HDFC Bank cards', '10% instant discount up to ₹1,000 on orders over ₹3,999', Color(0xFF1D4ED8)),
              (Icons.account_balance_wallet_rounded, 'Paytm wallet', 'Flat ₹75 cashback on orders over ₹999', Color(0xFF0EA5E9)),
              (Icons.qr_code_2_rounded, 'Any UPI app', '₹50 off on your first UPI payment', Color(0xFF16A34A)),
              (Icons.calendar_month_rounded, 'No-cost EMI', 'On orders over ₹5,000 with major credit cards', Color(0xFF8B5CF6)),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShopCard(
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: b.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(b.$1, color: b.$4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.$2, style: akT(14.5, w: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(b.$3, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.35)),
                      ]),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
