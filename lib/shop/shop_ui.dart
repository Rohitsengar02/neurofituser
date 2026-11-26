import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import 'shop_data.dart';

// Shared pieces for the shop pages: the animated background with floating
// objects, the page frame, badges, product thumbs, cards, buttons and the
// "added to bag" bottom slider.

const shopOrange = Color(0xFFF97316);
const shopGreen = Color(0xFF16A34A);
const shopRed = Color(0xFFEF4444);
const shopAmber = Color(0xFFF59E0B);
const shopBg = Color(0xFFF6F7FB);

/// Pushes a shop page with a soft rise-and-fade.
Future<T?> shopPush<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 460),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(c), child: child),
        );
      },
    ));

// =====================================================================
//  ANIMATED BACKGROUND
// =====================================================================

/// Soft colour blobs with slowly floating shop objects (bag, dumbbell,
/// heart, gift, tag, bolt…). One painter, cached glyphs; about 25 fps on
/// web, display rate on phones.
class ShopBackdrop extends StatefulWidget {
  final Color tint;
  final Color tint2;
  /// Floating object glyphs; defaults to shop objects.
  final List<IconData>? icons;
  /// Page fill under the blobs (dark for the trainer onboarding).
  final Color base;
  final Color bubble;
  const ShopBackdrop({
    super.key,
    this.tint = shopOrange,
    this.tint2 = const Color(0xFF8B5CF6),
    this.icons,
    this.base = shopBg,
    this.bubble = const Color(0x8CFFFFFF),
  });
  @override
  State<ShopBackdrop> createState() => _ShopBackdropState();
}

class _ShopBackdropState extends State<ShopBackdrop> with SingleTickerProviderStateMixin {
  final _t = ValueNotifier<double>(0);
  Ticker? _ticker;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final sw = Stopwatch()..start();
      _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _t.value = sw.elapsedMilliseconds / 1000);
    } else {
      _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6)..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _timer?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: _BackdropPainter(_t, widget.tint, widget.tint2, widget.icons ?? _BackdropPainter._icons, widget.base, widget.bubble), size: Size.infinite),
      );
}

class _BackdropPainter extends CustomPainter {
  final ValueNotifier<double> t;
  final Color tint, tint2, base, bubble;
  final List<IconData> icons;
  _BackdropPainter(this.t, this.tint, this.tint2, this.icons, this.base, this.bubble) : super(repaint: t);

  static const _icons = [
    Icons.shopping_bag_rounded,
    Icons.fitness_center_rounded,
    Icons.favorite_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_offer_rounded,
    Icons.bolt_rounded,
    Icons.star_rounded,
    Icons.sports_basketball_rounded,
  ];
  static final _objs = List.generate(9, (i) {
    final r = math.Random(i * 13 + 5);
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      s: 18 + r.nextDouble() * 18,
      sp: 0.15 + r.nextDouble() * 0.25,
      ph: r.nextDouble() * 6.28,
    );
  });
  static final Map<String, TextPainter> _glyphs = {};

  TextPainter _glyph(IconData icon, double size, Color c) {
    final k = '${icon.codePoint}-${size.round()}-${c.toARGB32()}';
    return _glyphs.putIfAbsent(k, () {
      return TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: c),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final time = t.value;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    void blob(Offset c, double r, Color col) => canvas.drawCircle(
          c,
          r,
          Paint()..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
        );
    blob(Offset(size.width * (0.9 + 0.05 * math.sin(time * 0.3)), 60 + 20 * math.cos(time * 0.25)), 230, tint.withValues(alpha: 0.22));
    blob(Offset(size.width * (0.05 + 0.05 * math.cos(time * 0.2)), size.height * 0.42), 220, tint2.withValues(alpha: 0.14));
    blob(Offset(size.width * 0.8, size.height * (0.85 + 0.03 * math.sin(time * 0.35))), 200, const Color(0xFF38BDF8).withValues(alpha: 0.14));

    for (var i = 0; i < _objs.length; i++) {
      final o = _objs[i];
      final y = ((o.y - time * o.sp * 0.04) % 1.0) * (size.height + 80) - 40;
      final x = o.x * size.width + math.sin(time * o.sp + o.ph) * 14;
      final dark = base.computeLuminance() < 0.2;
      final col = (i.isEven ? tint : tint2).withValues(alpha: dark ? 0.32 : 0.13);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(time * 0.5 + o.ph) * 0.35);
      final bd = o.s * 1.9;
      canvas.drawCircle(Offset.zero, bd / 2, Paint()..color = bubble);
      final g = _glyph(icons[i % icons.length], o.s, col);
      g.paint(canvas, Offset(-g.width / 2, -g.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.tint != tint || old.tint2 != tint2 || old.base != base;
}

// =====================================================================
//  PAGE FRAME
// =====================================================================

/// Shop page: animated backdrop, glass back button, large title, optional
/// trailing actions, a body and an optional sticky bottom bar.
class ShopPage extends StatelessWidget {
  final String title;
  final String? caption;
  final List<Widget> actions;
  final Widget body;
  final Widget? bottom;
  final Color tint;
  final List<IconData>? icons;
  const ShopPage({
    super.key,
    this.icons,
    required this.title,
    this.caption,
    this.actions = const [],
    required this.body,
    this.bottom,
    this.tint = shopOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: shopBg,
      body: Stack(children: [
        Positioned.fill(child: ShopBackdrop(tint: tint, icons: icons)),
        SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                GlassIcon(Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).maybePop()),
                const Spacer(),
                for (final a in actions) Padding(padding: const EdgeInsets.only(left: 8), child: a),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: akSpring,
                builder: (_, v, c) => Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (caption != null) Text(caption!.toUpperCase(), style: akT(11.5, w: FontWeight.w800, c: akFaint, ls: 1.3)),
                  Text(title, style: akT(30, w: FontWeight.w800, ls: -1)),
                ]),
              ),
            ),
            Expanded(child: body),
          ]),
        ),
        if (bottom != null) Positioned(left: 0, right: 0, bottom: 0, child: bottom!),
      ]),
    );
  }
}

class GlassIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? badge;
  final Color color;
  const GlassIcon(this.icon, {super.key, this.onTap, this.badge, this.color = akInk});

  @override
  Widget build(BuildContext context) => LiquidGlass(
        style: LiquidGlassStyle.regular,
        shape: BoxShape.circle,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            Icon(icon, size: 19, color: color),
            if (badge != null) Positioned(top: 4, right: 2, child: badge!),
          ]),
        ),
      );
}

/// Bag icon with a springy live count; opens the cart.
class CartIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const CartIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: ShopStore.I.cartCount,
        builder: (_, n, _) => GlassIcon(
          Icons.shopping_bag_outlined,
          onTap: onTap,
          badge: n == 0 ? null : CountBadge(n),
        ),
      );
}

class CountBadge extends StatelessWidget {
  final int n;
  final Color color;
  const CountBadge(this.n, {super.key, this.color = shopOrange});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(n),
        tween: Tween(begin: 1.7, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: akSpring,
        builder: (_, s, c) => Transform.scale(scale: s, child: c),
        child: Container(
          constraints: const BoxConstraints(minWidth: 18),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Text('$n', textAlign: TextAlign.center, style: akT(10, w: FontWeight.w800, c: Colors.white)),
        ),
      );
}

// =====================================================================
//  BUILDING BLOCKS
// =====================================================================

class ProductThumb extends StatelessWidget {
  final Product p;
  final double size, radius;
  final String? hero;
  const ProductThumb(this.p, {super.key, this.size = 72, this.radius = 18, this.hero});

  @override
  Widget build(BuildContext context) {
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: p.cover
            ? Image.asset(p.image, fit: BoxFit.cover, cacheWidth: (size * 2.5).round())
            : ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(size * 0.08),
                  child: Image.asset(p.image, fit: BoxFit.contain, cacheWidth: (size * 2.5).round()),
                ),
              ),
      ),
    );
    return hero == null ? img : Hero(tag: hero!, child: img);
  }
}

/// White card with the shop's soft shadow (no blur, light on web).
class ShopCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final VoidCallback? onTap;
  final Color color;
  final Border? border;
  const ShopCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.radius = 24,
    this.onTap,
    this.color = Colors.white,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == Colors.white ? 0.92 : 1),
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: const Color(0xFF1F2937).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: child,
    );
    return onTap == null ? box : AkPress(onTap: onTap, scale: 0.98, child: box);
  }
}

/// Fades and lifts a child in after [delay] ms the first time it builds.
class Rise extends StatelessWidget {
  final int delay;
  final Widget child;
  final double dy;
  const Rise({super.key, this.delay = 0, this.dy = 22, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 620 + delay),
        curve: Interval(delay / (620 + delay), 1, curve: akSpring),
        child: child,
        builder: (_, t, c) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: c),
        ),
      );
}

class ShopButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color text;
  final IconData? icon;
  final bool outline;
  final double height;
  final bool busy;
  const ShopButton(
    this.label, {
    super.key,
    this.onTap,
    this.color = akInk,
    this.text = Colors.white,
    this.icon,
    this.outline = false,
    this.height = 54,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    return AkPress(
      onTap: off || busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: outline ? Colors.white : (off ? const Color(0xFFD1D5DB) : color),
          borderRadius: BorderRadius.circular(height * 0.36),
          border: outline ? Border.all(color: color.withValues(alpha: 0.35), width: 1.4) : null,
          boxShadow: outline || off
              ? null
              : [BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: outline ? color : text),
              )
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: outline ? color : text),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, style: akT(15, w: FontWeight.w800, c: outline ? color : text)),
                  ),
                ),
              ]),
      ),
    );
  }
}

/// Bottom bar on a white frosted strip.
class ShopBottomBar extends StatelessWidget {
  final Widget child;
  const ShopBottomBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6))],
        ),
        child: child,
      );
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  final bool small;
  const QtyStepper({super.key, required this.qty, required this.onChanged, this.small = false});

  @override
  Widget build(BuildContext context) {
    final s = small ? 30.0 : 38.0;
    Widget b(IconData i, int d) => AkPress(
          scale: 0.85,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(qty + d);
          },
          child: SizedBox(
            width: s,
            height: s,
            child: Icon(i == Icons.remove_rounded && qty == 1 ? Icons.delete_outline_rounded : i,
                size: small ? 16 : 19, color: akInk),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F3F7), borderRadius: BorderRadius.circular(s)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        b(Icons.remove_rounded, -1),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (w, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: w)),
          child: SizedBox(
            key: ValueKey(qty),
            width: small ? 20 : 26,
            child: Text('$qty', textAlign: TextAlign.center, style: akN(small ? 14 : 16)),
          ),
        ),
        b(Icons.add_rounded, 1),
      ]),
    );
  }
}

class BillRows extends StatelessWidget {
  final Bill b;
  final String? coupon;
  const BillRows(this.b, {super.key, this.coupon});

  @override
  Widget build(BuildContext context) {
    Widget row(String l, String v, {Color c = akInk, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(l, style: akT(13.5, w: bold ? FontWeight.w800 : FontWeight.w500, c: bold ? akInk : akMuted))),
            Text(v, style: bold ? akN(17) : akT(13.5, w: FontWeight.w700, c: c)),
          ]),
        );
    return Column(children: [
      row('MRP', rs(b.mrp)),
      row('Discount on MRP', '-${rs(b.savings)}', c: shopGreen),
      if (b.coupon > 0) row('Coupon${coupon == null ? '' : ' ($coupon)'}', '-${rs(b.coupon)}', c: shopGreen),
      row('Delivery', b.delivery == 0 ? 'FREE' : rs(b.delivery), c: b.delivery == 0 ? shopGreen : akInk),
      row('Handling fee', rs(b.handling)),
      const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)),
      row('Total', rs(b.total), bold: true),
      if (b.saved > 0)
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: shopGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.savings_rounded, color: shopGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('You save ${rs(b.saved)} on this order', style: akT(13, w: FontWeight.w800, c: shopGreen))),
          ]),
        ),
    ]);
  }
}

/// Free-delivery progress bar.
class FreeDeliveryBar extends StatelessWidget {
  final int subtotal;
  const FreeDeliveryBar(this.subtotal, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = (subtotal / ShopStore.freeOver).clamp(0.0, 1.0);
    final done = p >= 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(done ? Icons.local_shipping_rounded : Icons.local_shipping_outlined, size: 18, color: done ? shopGreen : shopOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            done ? 'You get free delivery' : 'Add ${rs(ShopStore.freeOver - subtotal)} more for free delivery',
            style: akT(13, w: FontWeight.w700, c: done ? shopGreen : akInk),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: p),
          duration: const Duration(milliseconds: 800),
          curve: akSpring,
          builder: (_, v, _) => LinearProgressIndicator(
            value: v.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: const Color(0xFFEFF1F5),
            color: done ? shopGreen : shopOrange,
          ),
        ),
      ),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, body, action;
  final VoidCallback onAction;
  final Color color;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.color = shopOrange,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Rise(
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.04)]),
                ),
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: Icon(icon, size: 38, color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Rise(delay: 80, child: Text(title, textAlign: TextAlign.center, style: akT(21, w: FontWeight.w800, ls: -0.5))),
            const SizedBox(height: 6),
            Rise(
              delay: 140,
              child: Text(body, textAlign: TextAlign.center, style: akT(14, w: FontWeight.w500, c: akMuted, h: 1.4)),
            ),
            const SizedBox(height: 22),
            Rise(delay: 200, child: SizedBox(width: 220, child: ShopButton(action, onTap: onAction, color: color))),
          ]),
        ),
      );
}

void shopToast(BuildContext context, String text, {String? action, VoidCallback? onAction, IconData icon = Icons.check_circle_rounded}) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: akInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      duration: const Duration(milliseconds: 2200),
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: akT(13.5, c: Colors.white))),
      ]),
      action: action == null ? null : SnackBarAction(label: action, textColor: const Color(0xFFFDBA74), onPressed: onAction ?? () {}),
    ));
}
