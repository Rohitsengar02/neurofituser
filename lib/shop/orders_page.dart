import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/apple_kit.dart';
import 'cart_page.dart';
import 'product_page.dart';
import 'shop_data.dart';
import 'shop_ui.dart';

// Orders list (Active / Past) and order detail with a live status
// timeline, items, address, payment, bill and actions.

Color statusColor(Order o) {
  if (o.cancelled) return shopRed;
  return switch (o.step) {
    4 => shopGreen,
    3 => shopOrange,
    2 => const Color(0xFF3B82F6),
    _ => const Color(0xFF8B5CF6),
  };
}

String statusText(Order o) => o.cancelled ? 'Cancelled' : orderSteps[o.step];

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int tab = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Statuses move on the clock, so refresh every half minute.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final active = store.orders.where((o) => o.active).toList();
        final past = store.orders.where((o) => !o.active).toList();
        final list = tab == 0 ? active : past;
        return ShopPage(
          title: 'My orders',
          caption: '${store.orders.length} order${store.orders.length == 1 ? '' : 's'}',
          tint: const Color(0xFF3B82F6),
          actions: [CartIconButton(onTap: () => shopPush(context, const CartPage()))],
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: _Segment(
                labels: ['Active (${active.length})', 'Past (${past.length})'],
                index: tab,
                onChanged: (i) => setState(() => tab = i),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: list.isEmpty
                    ? EmptyState(
                        key: ValueKey('e$tab'),
                        icon: tab == 0 ? Icons.local_shipping_outlined : Icons.receipt_long_rounded,
                        title: tab == 0 ? 'No active orders' : 'No past orders yet',
                        body: tab == 0 ? 'When you place an order you can track it here.' : 'Delivered and cancelled orders show up here.',
                        action: 'Shop now',
                        color: const Color(0xFF3B82F6),
                        onAction: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      )
                    : ListView.builder(
                        key: ValueKey('l$tab'),
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(0, 8, 0, 40 + MediaQuery.paddingOf(context).bottom),
                        itemCount: list.length,
                        itemBuilder: (_, i) => Rise(
                          delay: math.min(i, 5) * 60,
                          child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(list[i])),
                        ),
                      ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _Segment({required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
        child: LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth / labels.length;
          return Stack(children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: akSpring,
              left: w * index,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(
                  color: akInk,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                ),
              ),
            ),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: akT(13.5, w: FontWeight.w700, c: i == index ? Colors.white : akInk),
                        child: Text(labels[i]),
                      ),
                    ),
                  ),
                ),
            ]),
          ]);
        }),
      );
}

class _OrderCard extends StatelessWidget {
  final Order o;
  const _OrderCard(this.o);

  @override
  Widget build(BuildContext context) {
    final col = statusColor(o);
    final shown = o.lines.take(3).toList();
    return ShopCard(
      onTap: () => shopPush(context, OrderDetailPage(o)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(statusText(o), style: akT(12, w: FontWeight.w800, c: col)),
            ]),
          ),
          const Spacer(),
          Text('#${o.id}', style: akT(12, w: FontWeight.w700, c: akFaint)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(
            width: 56.0 + 34 * (shown.length - 1),
            height: 56,
            child: Stack(children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 34.0,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2.5)),
                    child: ProductThumb(shown[i].product, size: 51, radius: 13),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.lines.first.product.name + (o.lines.length > 1 ? ' + ${o.lines.length - 1} more' : ''),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14, w: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${o.items} items · ${rs(o.bill.total)}', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
              const SizedBox(height: 2),
              Text(
                o.cancelled
                    ? 'Cancelled · refund in 3–5 days'
                    : o.step == 4
                        ? 'Delivered ${shortDate(o.stepTime(4))}'
                        : 'Arriving ${shortDate(o.eta)}',
                style: akT(12, w: FontWeight.w700, c: col),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: akMuted),
        ]),
        if (!o.cancelled) ...[
          const SizedBox(height: 12),
          Row(children: [
            for (var i = 0; i < 5; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 80),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= o.step ? col : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < 4) const SizedBox(width: 4),
            ],
          ]),
        ],
      ]),
    );
  }
}

// =====================================================================
//  ORDER DETAIL
// =====================================================================

class OrderDetailPage extends StatefulWidget {
  final Order order;
  const OrderDetailPage(this.order, {super.key});
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.fromLTRB(20, 22, 20, 20 + MediaQuery.paddingOf(c).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.cancel_outlined, color: shopRed, size: 44),
          const SizedBox(height: 10),
          Text('Cancel this order?', textAlign: TextAlign.center, style: akT(20, w: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Any amount you paid is refunded to the original method in 3–5 days.',
              textAlign: TextAlign.center, style: akT(13.5, w: FontWeight.w500, c: akMuted, h: 1.4)),
          const SizedBox(height: 18),
          ShopButton('Yes, cancel order', color: shopRed, onTap: () => Navigator.of(c).pop(true)),
          const SizedBox(height: 8),
          ShopButton('Keep order', outline: true, onTap: () => Navigator.of(c).pop(false)),
        ]),
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      ShopStore.I.cancel(widget.order);
      if (mounted) shopToast(context, 'Order cancelled', icon: Icons.cancel_rounded);
    }
  }

  void _help() => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (c) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.fromLTRB(8, 18, 8, 12 + MediaQuery.paddingOf(c).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('How can we help?', style: akT(19, w: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final h in const [
              (Icons.local_shipping_outlined, 'Where is my order?'),
              (Icons.autorenew_rounded, 'Return or exchange an item'),
              (Icons.payments_outlined, 'Payment or refund question'),
              (Icons.chat_bubble_outline_rounded, 'Chat with support'),
            ])
              ListTile(
                leading: Icon(h.$1, color: akInk),
                title: Text(h.$2, style: akT(14.5, w: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(c).pop();
                  shopToast(context, 'Support will reach you on ${widget.order.address.phone} shortly', icon: Icons.support_agent_rounded);
                },
              ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ShopStore.I,
      builder: (context, _) {
        final o = widget.order;
        final col = statusColor(o);
        return ShopPage(
          title: 'Order details',
          caption: '#${o.id} · ${shortDate(o.at)}',
          tint: col,
          actions: [GlassIcon(Icons.support_agent_rounded, onTap: _help)],
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 12, 0, 40 + MediaQuery.paddingOf(context).bottom),
            children: [
              Rise(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [col, Color.lerp(col, Colors.black, 0.25)!],
                    ),
                    boxShadow: [BoxShadow(color: col.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(statusText(o).toUpperCase(), style: akT(11.5, w: FontWeight.w800, c: Colors.white70, ls: 1.2)),
                        const SizedBox(height: 4),
                        Text(
                          o.cancelled
                              ? 'Order cancelled'
                              : o.step == 4
                                  ? 'Delivered'
                                  : 'Arriving ${shortDate(o.eta)}',
                          style: akT(24, w: FontWeight.w800, c: Colors.white, ls: -0.6),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          o.cancelled
                              ? 'Refund of ${rs(o.bill.total)} in 3–5 days'
                              : '${o.speed == Speed.express ? 'Express' : 'Standard'} delivery to ${o.address.label}',
                          style: akT(13, w: FontWeight.w600, c: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ]),
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                      child: Icon(
                        o.cancelled
                            ? Icons.close_rounded
                            : [Icons.receipt_long_rounded, Icons.inventory_2_rounded, Icons.local_shipping_rounded, Icons.delivery_dining_rounded, Icons.check_rounded][o.step],
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ]),
                ),
              ),
              if (!o.cancelled) ...[
                const AkHead('Tracking'),
                Rise(delay: 80, child: ShopCard(child: _Timeline(o))),
              ],
              AkHead('Items (${o.items})'),
              ShopCard(
                child: Column(children: [
                  for (final l in o.lines)
                    InkWell(
                      onTap: () => openProduct(context, l.product),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(children: [
                          ProductThumb(l.product, size: 60, radius: 15),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14, w: FontWeight.w800)),
                              Text('${l.option} · Qty ${l.qty}', style: akT(12, w: FontWeight.w600, c: akMuted)),
                              if (o.step == 4)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Row(children: [
                                    for (var k = 0; k < 5; k++) const Icon(Icons.star_outline_rounded, size: 16, color: shopAmber),
                                    const SizedBox(width: 4),
                                    Text('Rate', style: akT(11.5, w: FontWeight.w700, c: akMuted)),
                                  ]),
                                ),
                            ]),
                          ),
                          Text(rs(l.product.price * l.qty), style: akN(14.5)),
                        ]),
                      ),
                    ),
                ]),
              ),
              const AkHead('Delivery address'),
              ShopCard(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_rounded, color: shopOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${o.address.name} · ${o.address.label}', style: akT(14, w: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(o.address.full, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.35)),
                      const SizedBox(height: 4),
                      Text(o.address.phone, style: akT(12.5, w: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ),
              const AkHead('Payment'),
              ShopCard(
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: akInk),
                    const SizedBox(width: 10),
                    Expanded(child: Text(o.payment, style: akT(14, w: FontWeight.w700))),
                    Text(o.payment.startsWith('Cash') ? 'Pay on delivery' : 'Paid',
                        style: akT(12.5, w: FontWeight.w800, c: o.payment.startsWith('Cash') ? shopOrange : shopGreen)),
                  ]),
                  const SizedBox(height: 12),
                  BillRows(o.bill, coupon: o.coupon),
                ]),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  if (o.canCancel) ...[
                    Expanded(child: ShopButton('Cancel order', outline: true, color: shopRed, onTap: _cancel)),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ShopButton('Buy again', icon: Icons.replay_rounded, onTap: () {
                      HapticFeedback.mediumImpact();
                      ShopStore.I.reorder(o);
                      shopToast(context, 'Items added to your bag', icon: Icons.shopping_bag_rounded, action: 'View bag', onAction: () => shopPush(context, const CartPage()));
                    }),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShopButton('Need help?', outline: true, icon: Icons.support_agent_rounded, onTap: _help),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Timeline extends StatelessWidget {
  final Order o;
  const _Timeline(this.o);

  @override
  Widget build(BuildContext context) {
    final col = statusColor(o);
    const icons = [
      Icons.receipt_long_rounded,
      Icons.inventory_2_rounded,
      Icons.local_shipping_rounded,
      Icons.delivery_dining_rounded,
      Icons.home_rounded,
    ];
    return AkSeen(
      duration: const Duration(milliseconds: 1400),
      builder: (_, t) {
        final reach = t * (o.step + 0.999);
        return Column(children: [
          for (var i = 0; i < 5; i++)
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                  width: 36,
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reach >= i ? col : const Color(0xFFF1F2F4),
                        boxShadow: i == o.step && reach >= i ? [BoxShadow(color: col.withValues(alpha: 0.4), blurRadius: 10)] : null,
                      ),
                      child: Icon(icons[i], size: 16, color: reach >= i ? Colors.white : akFaint),
                    ),
                    if (i < 4)
                      Expanded(
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(2)),
                          alignment: Alignment.topCenter,
                          child: FractionallySizedBox(
                            heightFactor: (reach - i).clamp(0.0, 1.0),
                            child: Container(decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2))),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(orderSteps[i], style: akT(14, w: FontWeight.w800, c: i <= o.step ? akInk : akFaint)),
                      const SizedBox(height: 2),
                      Text(
                        i <= o.step
                            ? '${shortDate(o.stepTime(i))}, ${clock(o.stepTime(i))}'
                            : (i == 4 ? 'Expected ${shortDate(o.eta)}' : 'Pending'),
                        style: akT(12, w: FontWeight.w600, c: akMuted),
                      ),
                    ]),
                  ),
                ),
                if (i == o.step && i < 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text('Now', style: akT(11, w: FontWeight.w800, c: col)),
                    ),
                  ),
              ]),
            ),
        ]);
      },
    );
  }
}
