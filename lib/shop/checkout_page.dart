import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/apple_kit.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'shop_data.dart';
import 'shop_ui.dart';
import '../backend/me.dart';

// Checkout in three steps (Address → Payment → Review) with an animated
// step header, then a processing state and the thank-you page.

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

enum _Pay { upi, card, netbanking, cod }

class _CheckoutPageState extends State<CheckoutPage> {
  final _pc = PageController();
  int step = 0;
  _Pay pay = _Pay.upi;
  String upiApp = 'Google Pay';
  String bank = 'HDFC Bank';
  final _upiId = TextEditingController();
  final _cardNo = TextEditingController(), _cardName = TextEditingController(text: Me.name);
  final _exp = TextEditingController(), _cvv = TextEditingController();
  bool placing = false;
  String? payError;

  static const _steps = ['Address', 'Payment', 'Review'];

  @override
  void initState() {
    super.initState();
    for (final c in [_upiId, _cardNo, _cardName, _exp, _cvv]) {
      c.addListener(() => setState(() => payError = null));
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    for (final c in [_upiId, _cardNo, _cardName, _exp, _cvv]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _payLabel => switch (pay) {
        _Pay.upi => 'UPI · ${_upiId.text.trim().isNotEmpty ? _upiId.text.trim() : upiApp}',
        _Pay.card => 'Card · •••• ${_digits(_cardNo.text).length >= 4 ? _digits(_cardNo.text).substring(_digits(_cardNo.text).length - 4) : '0000'}',
        _Pay.netbanking => 'Net banking · $bank',
        _Pay.cod => 'Cash on delivery',
      };

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  String? _validatePay() {
    switch (pay) {
      case _Pay.upi:
        final id = _upiId.text.trim();
        if (id.isNotEmpty && !RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$').hasMatch(id)) return 'Enter a UPI ID like name@okhdfc';
      case _Pay.card:
        if (_digits(_cardNo.text).length < 15) return 'Enter the full card number';
        if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(_exp.text)) return 'Enter expiry as MM/YY';
        if (_digits(_cvv.text).length < 3) return 'Enter the 3-digit CVV';
        if (_cardName.text.trim().isEmpty) return 'Enter the name on the card';
      default:
    }
    return null;
  }

  void _go(int s) {
    FocusScope.of(context).unfocus();
    setState(() => step = s);
    _pc.animateToPage(s, duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
  }

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    final store = ShopStore.I;
    if (step == 0) {
      if (store.address == null) {
        final a = await shopPush<Address>(context, const AddressFormPage());
        if (a == null) return;
      }
      _go(1);
    } else if (step == 1) {
      final e = _validatePay();
      if (e != null) {
        HapticFeedback.heavyImpact();
        setState(() => payError = e);
        return;
      }
      _go(2);
    } else {
      setState(() => placing = true);
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      final o = store.placeOrder(_payLabel);
      HapticFeedback.heavyImpact();
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => ThankYouPage(o),
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ShopStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.cart.isEmpty && !placing) {
          return ShopPage(
            title: 'Checkout',
            body: EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your bag is empty',
              body: 'Add something to your bag to check out.',
              action: 'Back to shop',
              onAction: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          );
        }
        final b = store.bill;
        return PopScope(
          canPop: step == 0 && !placing,
          onPopInvokedWithResult: (did, _) {
            if (!did && !placing) _go(step - 1);
          },
          child: ShopPage(
            title: 'Checkout',
            caption: 'Step ${step + 1} of 3 · ${_steps[step]}',
            actions: [
              GlassIcon(Icons.lock_outline_rounded, color: shopGreen, onTap: () => shopToast(context, 'Payments are encrypted and secure', icon: Icons.lock_rounded)),
            ],
            bottom: ShopBottomBar(
              child: Row(children: [
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rs(b.total), style: akN(22)),
                  GestureDetector(
                    onTap: () => _go(2),
                    child: Text('View details', style: akT(12, w: FontWeight.w800, c: shopOrange)),
                  ),
                ]),
                const SizedBox(width: 16),
                Expanded(
                  child: ShopButton(
                    step == 2 ? (pay == _Pay.cod ? 'Place order' : 'Pay ${rs(b.total)}') : 'Continue',
                    color: step == 2 ? shopGreen : shopOrange,
                    icon: step == 2 ? Icons.lock_rounded : null,
                    busy: placing,
                    onTap: _next,
                  ),
                ),
              ]),
            ),
            body: Column(children: [
              _StepHeader(step: step, labels: _steps, onTap: (i) => i < step ? _go(i) : null),
              Expanded(
                child: PageView(
                  controller: _pc,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_address(), _payment(), _review()],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  EdgeInsets get _listPad => EdgeInsets.fromLTRB(0, 8, 0, 130 + MediaQuery.paddingOf(context).bottom);

  // ------------------------------------------------------------ address

  Widget _address() {
    final store = ShopStore.I;
    final sel = store.address;
    return ListView(physics: const BouncingScrollPhysics(), padding: _listPad, children: [
      const AkHead('Deliver to'),
      for (var i = 0; i < store.addresses.length; i++)
        Rise(
          delay: i * 60,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AddressCard(
              store.addresses[i],
              selected: store.addresses[i].id == sel?.id,
              onTap: () {
                HapticFeedback.selectionClick();
                store.selectAddress(store.addresses[i].id);
              },
              onEdit: () => shopPush(context, AddressFormPage(edit: store.addresses[i])),
            ),
          ),
        ),
      ShopCard(
        onTap: () => shopPush(context, const AddressFormPage()),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: shopOrange.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.add_location_alt_rounded, color: shopOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Add a new address', style: akT(14.5, w: FontWeight.w800))),
          const Icon(Icons.chevron_right_rounded, color: akMuted),
        ]),
      ),
      const AkHead('Delivery speed'),
      for (final s in Speed.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Choice(
            selected: store.speed == s,
            onTap: () {
              HapticFeedback.selectionClick();
              store.setSpeed(s);
            },
            icon: s == Speed.express ? Icons.bolt_rounded : Icons.local_shipping_rounded,
            color: s == Speed.express ? shopOrange : const Color(0xFF3B82F6),
            title: s == Speed.express ? 'Express' : 'Standard',
            sub: 'Arrives ${shortDate(DateTime.now().add(Duration(days: s == Speed.express ? 1 : 3)))}',
            trailing: s == Speed.express
                ? (store.coupon?.freeShip == true ? 'FREE' : '+ ₹99')
                : (store.bill.subtotal >= ShopStore.freeOver ? 'FREE' : '₹49'),
          ),
        ),
    ]);
  }

  // ------------------------------------------------------------ payment

  Widget _payment() {
    return ListView(physics: const BouncingScrollPhysics(), padding: _listPad, children: [
      const AkHead('Pay with'),
      _payTile(_Pay.upi, Icons.qr_code_2_rounded, const Color(0xFF16A34A), 'UPI', 'Google Pay, PhonePe, Paytm or any UPI ID', _upiBody()),
      _payTile(_Pay.card, Icons.credit_card_rounded, const Color(0xFF1D4ED8), 'Credit or debit card', 'Visa, Mastercard, RuPay', _cardBody()),
      _payTile(_Pay.netbanking, Icons.account_balance_rounded, const Color(0xFF8B5CF6), 'Net banking', 'All major banks', _bankBody()),
      _payTile(_Pay.cod, Icons.payments_rounded, shopAmber, 'Cash on delivery', 'Pay when it arrives', null),
      if (payError != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: shopRed, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(payError!, style: akT(13, w: FontWeight.w700, c: shopRed))),
          ]),
        ),
      const SizedBox(height: 12),
      ShopCard(
        onTap: () => showCouponSheet(context),
        child: Row(children: [
          const Icon(Icons.local_offer_rounded, color: shopOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ShopStore.I.coupon == null ? 'Apply a coupon' : '${ShopStore.I.couponCode} applied',
                style: akT(14, w: FontWeight.w800, c: ShopStore.I.coupon == null ? akInk : shopGreen)),
          ),
          const Icon(Icons.chevron_right_rounded, color: akMuted),
        ]),
      ),
    ]);
  }

  Widget _payTile(_Pay m, IconData icon, Color color, String title, String sub, Widget? body) {
    final on = pay == m;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShopCard(
        padding: EdgeInsets.zero,
        border: Border.all(color: on ? color : Colors.white, width: on ? 1.6 : 1),
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                pay = m;
                payError = null;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: akT(14.5, w: FontWeight.w800)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12, w: FontWeight.w500, c: akMuted)),
                  ]),
                ),
                const SizedBox(width: 8),
                _Radio(on, color: color),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: on && body != null
                ? Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: body)
                : const SizedBox(width: double.infinity),
          ),
        ]),
      ),
    );
  }

  Widget _upiBody() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in const ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'])
            _Pill(a, selected: upiApp == a && _upiId.text.isEmpty, onTap: () {
              _upiId.clear();
              setState(() => upiApp = a);
            }),
        ]),
        const SizedBox(height: 10),
        _Field(_upiId, 'Or enter UPI ID', hint: 'name@okhdfc', icon: Icons.alternate_email_rounded),
      ]);

  Widget _cardBody() {
    final no = _digits(_cardNo.text);
    final shown = (no.padRight(16, '•')).replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim();
    return Column(children: [
      AspectRatio(
        aspectRatio: 1.7,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF0F172A)],
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
                ),
              ),
              const Spacer(),
              Text(no.startsWith('4') ? 'VISA' : (no.startsWith('5') ? 'Mastercard' : 'RuPay'),
                  style: akT(15, w: FontWeight.w900, c: Colors.white, ls: 1)),
            ]),
            const Spacer(),
            FittedBox(child: Text(shown, style: akN(21, w: FontWeight.w600, c: Colors.white, ls: 2))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Text(_cardName.text.isEmpty ? 'NAME' : _cardName.text.toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12, w: FontWeight.w700, c: Colors.white70, ls: 1)),
              ),
              Text(_exp.text.isEmpty ? 'MM/YY' : _exp.text, style: akT(12, w: FontWeight.w700, c: Colors.white70)),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      _Field(_cardNo, 'Card number', hint: '4111 1111 1111 1111', icon: Icons.credit_card_rounded, number: true, max: 19, fmt: _CardFormatter()),
      Row(children: [
        Expanded(child: _Field(_exp, 'Expiry', hint: 'MM/YY', number: true, max: 5, fmt: _ExpiryFormatter())),
        const SizedBox(width: 10),
        Expanded(child: _Field(_cvv, 'CVV', hint: '•••', number: true, max: 3, obscure: true)),
      ]),
      _Field(_cardName, 'Name on card', icon: Icons.person_outline_rounded),
    ]);
  }

  Widget _bankBody() => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final b in const ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Kotak'])
          _Pill(b, selected: bank == b, onTap: () => setState(() => bank = b)),
      ]);

  // ------------------------------------------------------------ review

  Widget _review() {
    final store = ShopStore.I;
    final a = store.address;
    return ListView(physics: const BouncingScrollPhysics(), padding: _listPad, children: [
      AkHead('Items (${store.count})', action: 'Edit', onAction: () => shopPush(context, const CartPage())),
      ShopCard(
        child: Column(children: [
          for (final l in store.cart)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                ProductThumb(l.product, size: 54, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(13.5, w: FontWeight.w800)),
                    Text('${l.option} · Qty ${l.qty}', style: akT(12, w: FontWeight.w600, c: akMuted)),
                  ]),
                ),
                Text(rs(l.product.price * l.qty), style: akN(14.5)),
              ]),
            ),
        ]),
      ),
      AkHead('Delivery', action: 'Change', onAction: () => _go(0)),
      if (a != null)
        ShopCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_rounded, color: shopOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${a.name} · ${a.label}', style: akT(14, w: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(a.full, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.35)),
                const SizedBox(height: 8),
                Text('${store.speed == Speed.express ? 'Express' : 'Standard'} · arrives ${shortDate(DateTime.now().add(Duration(days: store.speed == Speed.express ? 1 : 3)))}',
                    style: akT(12.5, w: FontWeight.w800, c: shopGreen)),
              ]),
            ),
          ]),
        ),
      AkHead('Payment', action: 'Change', onAction: () => _go(1)),
      ShopCard(
        child: Row(children: [
          Icon(
            switch (pay) {
              _Pay.upi => Icons.qr_code_2_rounded,
              _Pay.card => Icons.credit_card_rounded,
              _Pay.netbanking => Icons.account_balance_rounded,
              _Pay.cod => Icons.payments_rounded,
            },
            color: akInk,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(_payLabel, style: akT(14, w: FontWeight.w700))),
        ]),
      ),
      const AkHead('Price details'),
      ShopCard(child: BillRows(store.bill, coupon: store.couponCode)),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Text('By placing this order you agree to the NeuroFit terms of sale and return policy.',
            textAlign: TextAlign.center, style: akT(11.5, w: FontWeight.w500, c: akFaint, h: 1.4)),
      ),
    ]);
  }
}

// =====================================================================
//  SMALL PIECES
// =====================================================================

class _StepHeader extends StatelessWidget {
  final int step;
  final List<String> labels;
  final void Function(int) onTap;
  const _StepHeader({required this.step, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++) ...[
          GestureDetector(
            onTap: () => onTap(i),
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: akSpring,
                width: i == step ? 34 : 28,
                height: i == step ? 34 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < step ? shopGreen : (i == step ? shopOrange : Colors.white),
                  border: Border.all(color: i <= step ? Colors.transparent : const Color(0xFFE5E7EB), width: 1.5),
                  boxShadow: i == step ? [BoxShadow(color: shopOrange.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
                ),
                child: Center(
                  child: i < step
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                      : Text('${i + 1}', style: akT(13, w: FontWeight.w800, c: i == step ? Colors.white : akMuted)),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: akT(11.5, w: FontWeight.w700, c: i <= step ? akInk : akFaint)),
            ]),
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: i < step ? 1 : 0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: shopGreen,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ]),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool on;
  final Color color;
  const _Radio(this.on, {this.color = shopOrange});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: on ? color : const Color(0xFFD1D5DB), width: on ? 7 : 2),
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(this.label, {required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => AkPress(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? akInk : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label, style: akT(13, w: FontWeight.w700, c: selected ? Colors.white : akInk)),
        ),
      );
}

class _Choice extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final String title, sub, trailing;
  const _Choice({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) => ShopCard(
        onTap: onTap,
        border: Border.all(color: selected ? color : Colors.white, width: selected ? 1.6 : 1),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: akT(14.5, w: FontWeight.w800)),
              Text(sub, style: akT(12, w: FontWeight.w500, c: akMuted)),
            ]),
          ),
          Text(trailing, style: akT(13, w: FontWeight.w800, c: trailing == 'FREE' ? shopGreen : akInk)),
          const SizedBox(width: 10),
          _Radio(selected, color: color),
        ]),
      );
}

class _AddressCard extends StatelessWidget {
  final Address a;
  final bool selected;
  final VoidCallback onTap, onEdit;
  const _AddressCard(this.a, {required this.selected, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) => ShopCard(
        onTap: onTap,
        border: Border.all(color: selected ? shopOrange : Colors.white, width: selected ? 1.6 : 1),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: _Radio(selected)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(a.name, overflow: TextOverflow.ellipsis, style: akT(15, w: FontWeight.w800))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                  child: Text(a.label.toUpperCase(), style: akT(10.5, w: FontWeight.w800, c: akMuted, ls: 0.6)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(a.full, style: akT(13, w: FontWeight.w500, c: akMuted, h: 1.35)),
              const SizedBox(height: 4),
              Text(a.phone, style: akT(12.5, w: FontWeight.w700)),
            ]),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 19, color: akMuted)),
        ]),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController c;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool number, obscure;
  final int? max;
  final TextInputFormatter? fmt;
  final String? error;
  const _Field(this.c, this.label,
      {this.hint, this.icon, this.number = false, this.obscure = false, this.max, this.fmt, this.error});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          obscureText: obscure,
          maxLength: max,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          inputFormatters: [if (number && fmt == null) FilteringTextInputFormatter.digitsOnly, if (fmt != null) fmt!],
          style: akT(14.5, w: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            labelText: label,
            hintText: hint,
            errorText: error,
            labelStyle: akT(13.5, w: FontWeight.w600, c: akMuted),
            hintStyle: akT(14, w: FontWeight.w500, c: akFaint),
            prefixIcon: icon == null ? null : Icon(icon, size: 19, color: akMuted),
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: shopOrange, width: 1.5),
            ),
          ),
        ),
      );
}

class _CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(RegExp(r'\D'), '');
    final s = d.substring(0, math.min(16, d.length)).replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trimRight();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var d = n.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    final s = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

// =====================================================================
//  ADDRESS FORM
// =====================================================================

class AddressFormPage extends StatefulWidget {
  final Address? edit;
  const AddressFormPage({super.key, this.edit});
  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final _name = TextEditingController(text: widget.edit?.name ?? Me.name);
  late final _phone = TextEditingController(text: widget.edit?.phone ?? '');
  late final _pin = TextEditingController(text: widget.edit?.pin ?? '');
  late final _l1 = TextEditingController(text: widget.edit?.line1 ?? '');
  late final _l2 = TextEditingController(text: widget.edit?.line2 ?? '');
  late final _city = TextEditingController(text: widget.edit?.city ?? '');
  late final _state = TextEditingController(text: widget.edit?.state ?? '');
  late String label = widget.edit?.label ?? 'Home';
  Map<String, String> errors = {};

  static const _pinCities = {
    '11': ('New Delhi', 'Delhi'),
    '40': ('Mumbai', 'Maharashtra'),
    '56': ('Bengaluru', 'Karnataka'),
    '60': ('Chennai', 'Tamil Nadu'),
    '70': ('Kolkata', 'West Bengal'),
    '50': ('Hyderabad', 'Telangana'),
    '41': ('Pune', 'Maharashtra'),
    '38': ('Ahmedabad', 'Gujarat'),
    '30': ('Jaipur', 'Rajasthan'),
    '22': ('Lucknow', 'Uttar Pradesh'),
    '20': ('Noida', 'Uttar Pradesh'),
    '12': ('Gurugram', 'Haryana'),
  };

  @override
  void initState() {
    super.initState();
    _pin.addListener(() {
      final p = _pin.text;
      if (p.length == 6 && _city.text.isEmpty) {
        final m = _pinCities[p.substring(0, 2)];
        if (m != null) {
          setState(() {
            _city.text = m.$1;
            _state.text = m.$2;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _pin, _l1, _l2, _city, _state]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final e = <String, String>{};
    if (_name.text.trim().length < 2) e['name'] = 'Enter a name';
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length != 10) e['phone'] = 'Enter a 10-digit mobile number';
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(_pin.text)) e['pin'] = 'Enter a 6-digit PIN code';
    if (_l1.text.trim().length < 3) e['l1'] = 'Enter house and street';
    if (_city.text.trim().isEmpty) e['city'] = 'Enter the city';
    if (_state.text.trim().isEmpty) e['state'] = 'Enter the state';
    setState(() => errors = e);
    if (e.isNotEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    final a = Address(
      widget.edit?.id ?? 'a${DateTime.now().millisecondsSinceEpoch}',
      label,
      _name.text.trim(),
      _phone.text.trim(),
      _l1.text.trim(),
      _l2.text.trim().isEmpty ? 'Near landmark' : _l2.text.trim(),
      _city.text.trim(),
      _state.text.trim(),
      _pin.text.trim(),
    );
    ShopStore.I.saveAddress(a);
    Navigator.of(context).pop(a);
  }

  @override
  Widget build(BuildContext context) {
    return ShopPage(
      title: widget.edit == null ? 'New address' : 'Edit address',
      caption: 'Where should we deliver?',
      actions: [
        if (widget.edit != null)
          GlassIcon(Icons.delete_outline_rounded, color: shopRed, onTap: () {
            ShopStore.I.deleteAddress(widget.edit!);
            Navigator.of(context).pop();
          }),
      ],
      bottom: ShopBottomBar(child: ShopButton('Save address', color: shopOrange, icon: Icons.check_rounded, onTap: _save)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 14, 16, 120 + MediaQuery.paddingOf(context).bottom),
        children: [
          Rise(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFFFFEDD5), Color(0xFFFED7AA)]),
              ),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _MapLines())),
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_rounded, color: shopOrange, size: 38),
                    Text('Use the form below to set your pin', style: akT(12, w: FontWeight.w700, c: const Color(0xFF9A3412))),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Rise(
            delay: 60,
            child: Row(children: [
              for (final l in const [('Home', Icons.home_rounded), ('Work', Icons.work_rounded), ('Other', Icons.place_rounded)])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AkPress(
                    onTap: () => setState(() => label = l.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: label == l.$1 ? akInk : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Icon(l.$2, size: 16, color: label == l.$1 ? Colors.white : akMuted),
                        const SizedBox(width: 6),
                        Text(l.$1, style: akT(13, w: FontWeight.w700, c: label == l.$1 ? Colors.white : akInk)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          Rise(
            delay: 120,
            child: ShopCard(
              margin: EdgeInsets.zero,
              child: Column(children: [
                _Field(_name, 'Full name', icon: Icons.person_outline_rounded, error: errors['name']),
                _Field(_phone, 'Mobile number', hint: '98765 43210', icon: Icons.phone_rounded, number: true, max: 10, error: errors['phone']),
                _Field(_pin, 'PIN code', icon: Icons.pin_drop_outlined, number: true, max: 6, error: errors['pin']),
                _Field(_l1, 'House no., building, street', icon: Icons.home_outlined, error: errors['l1']),
                _Field(_l2, 'Area, landmark (optional)', icon: Icons.signpost_outlined),
                Row(children: [
                  Expanded(child: _Field(_city, 'City', error: errors['city'])),
                  const SizedBox(width: 10),
                  Expanded(child: _Field(_state, 'State', error: errors['state'])),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, s.height * 0.35), Offset(s.width, s.height * 0.55), road);
    canvas.drawLine(Offset(s.width * 0.3, 0), Offset(s.width * 0.42, s.height), road..strokeWidth = 6);
    canvas.drawLine(Offset(s.width * 0.75, 0), Offset(s.width * 0.68, s.height), road..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(_) => false;
}

// =====================================================================
//  THANK YOU
// =====================================================================

class ThankYouPage extends StatefulWidget {
  final Order order;
  const ThankYouPage(this.order, {super.key});
  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      backgroundColor: shopBg,
      body: Stack(children: [
        const Positioned.fill(child: ShopBackdrop(tint: shopGreen, tint2: shopOrange)),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(animation: _c, builder: (_, _) => CustomPaint(painter: _Confetti(_c.value))),
            ),
          ),
        ),
        SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 30),
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: akSpring,
                  builder: (_, v, _) => Transform.scale(
                    scale: v,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF4ADE80), shopGreen]),
                        boxShadow: [BoxShadow(color: shopGreen.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 14))],
                      ),
                      child: CustomPaint(painter: _Tick(Curves.easeOutCubic.transform(((v - 0.4) / 0.6).clamp(0.0, 1.0)))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Rise(delay: 300, child: Text('Order placed!', textAlign: TextAlign.center, style: akT(30, w: FontWeight.w800, ls: -1))),
              const SizedBox(height: 6),
              Rise(
                delay: 380,
                child: Text('Thank you, ${o.address.name}. We have sent the details to your phone.',
                    textAlign: TextAlign.center, style: akT(14.5, w: FontWeight.w500, c: akMuted, h: 1.4)),
              ),
              const SizedBox(height: 24),
              Rise(
                delay: 460,
                child: ShopCard(
                  margin: EdgeInsets.zero,
                  child: Column(children: [
                    _kv('Order ID', '#${o.id}'),
                    _kv('Arriving', shortDate(o.eta)),
                    _kv('Deliver to', '${o.address.label} · ${o.address.city}'),
                    _kv('Paid with', o.payment),
                    _kv('Total', rs(o.bill.total), bold: true),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Rise(
                delay: 540,
                child: ShopCard(
                  margin: EdgeInsets.zero,
                  child: Row(children: [
                    SizedBox(
                      width: 40.0 + 26 * (math.min(o.lines.length, 3) - 1),
                      height: 40,
                      child: Stack(children: [
                        for (var i = 0; i < math.min(o.lines.length, 3); i++)
                          Positioned(
                            left: i * 26.0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: ProductThumb(o.lines[i].product, size: 36, radius: 10),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${o.items} items on the way', style: akT(14, w: FontWeight.w800))),
                    if (o.bill.saved > 0) Text('Saved ${rs(o.bill.saved)}', style: akT(12.5, w: FontWeight.w800, c: shopGreen)),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              Rise(
                delay: 620,
                child: ShopButton('Track order', color: akInk, icon: Icons.route_rounded, onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderDetailPage(o)));
                }),
              ),
              const SizedBox(height: 10),
              Rise(
                delay: 680,
                child: ShopButton('Continue shopping', outline: true, onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(k, style: akT(13.5, w: FontWeight.w500, c: akMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bold ? akN(18) : akT(13.5, w: FontWeight.w800)),
          ),
        ]),
      );
}

class _Tick extends CustomPainter {
  final double t;
  _Tick(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(s.width * 0.3, s.height * 0.52)
      ..lineTo(s.width * 0.45, s.height * 0.66)
      ..lineTo(s.width * 0.72, s.height * 0.38);
    final m = p.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Tick o) => o.t != t;
}

class _Confetti extends CustomPainter {
  final double t;
  _Confetti(this.t);
  static final _bits = List.generate(70, (i) {
    final r = math.Random(i * 31 + 7);
    return (
      a: -math.pi / 2 + (r.nextDouble() - 0.5) * 2.4,
      v: 0.5 + r.nextDouble() * 0.7,
      s: 5 + r.nextDouble() * 6,
      spin: (r.nextDouble() - 0.5) * 14,
      c: [shopOrange, shopGreen, const Color(0xFF3B82F6), const Color(0xFF8B5CF6), shopAmber, const Color(0xFFEC4899)][i % 6],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, 150);
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final b in _bits) {
      final d = b.v * size.height * 0.9 * Curves.easeOutCubic.transform(t);
      final g = 600 * t * t;
      final p = origin + Offset(math.cos(b.a) * d, math.sin(b.a) * d + g);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(b.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: b.s, height: b.s * 0.55), const Radius.circular(2)),
        Paint()..color = b.c.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => o.t != t;
}
