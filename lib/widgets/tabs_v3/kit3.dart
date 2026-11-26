import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/product_detail_screen.dart';
import '../dashboard_motion.dart';
import '../shop_home_sections.dart';

/// NeuroFit design system v3: one indigo brand colour, a warm orange accent
/// used sparingly, soft off-white surfaces and the Inter type family.

const kBrand = Color(0xFF5B5FEF);
const kBrandDeep = Color(0xFF4338CA);
const kBrandSoft = Color(0xFFEEEFFF);
const kAccent = Color(0xFFFF7A45);
const kAccentSoft = Color(0xFFFFEEE5);
const kTint = Color(0xFFEDEEFF); // page colour behind the top block
const kTintTop = Color(0xFFE1E3FF);
const kSurface = Color(0xFFF7F7FB); // the curved sheet
const kInk3 = Color(0xFF1B1B2F);
const kMuted3 = Color(0xFF8A8AA0);
const kLine3 = Color(0xFFECECF4);
const kSuccess = Color(0xFF22A06B);

TextStyle tDisplay(double size,
        {FontWeight w = FontWeight.w800,
        Color c = kInk3,
        double spacing = -0.4,
        double? height}) =>
    TextStyle(
      fontFamily: 'InterDisplay',
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: spacing,
      height: height,
    );

TextStyle tText(double size,
        {FontWeight w = FontWeight.w500,
        Color c = kMuted3,
        double? height,
        double spacing = 0}) =>
    TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: height,
      letterSpacing: spacing,
    );

void nPush(BuildContext context, Widget screen) {
  HapticFeedback.lightImpact();
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

BoxDecoration nCardDeco({Color color = Colors.white, double r = 22}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: kLine3),
      boxShadow: [
        BoxShadow(
          color: kBrand.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );

/// Page layout shared by every tab: a top block on the tinted page colour,
/// then a curved off-white sheet holding the rest.
class NTabPage extends StatelessWidget {
  final List<Widget> top;
  final List<Widget> sheet;
  const NTabPage({super.key, required this.top, required this.sheet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < top.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Reveal(
                  delay: Duration(milliseconds: 70 * i),
                  offset: 14,
                  child: top[i],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
          decoration: const BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: kLine3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              for (var i = 0; i < sheet.length; i++) ...[
                if (i > 0) const SizedBox(height: 26),
                Reveal(
                  delay: Duration(milliseconds: i < 2 ? 90 * (i + 1) : 0),
                  offset: 18,
                  child: sheet[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class NHead extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const NHead(this.text, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tDisplay(19, w: FontWeight.w700, spacing: -0.4)),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(action!,
                    style: tText(13, w: FontWeight.w600, c: kBrand)),
              ),
            ),
        ],
      ),
    );
  }
}

class NSquareGrid extends StatelessWidget {
  final List<Widget> children;
  final int cols;
  final double gap;
  final double aspect;
  const NSquareGrid({
    super.key,
    required this.children,
    this.cols = 2,
    this.gap = 12,
    this.aspect = 1,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(Row(
        children: [
          for (var j = 0; j < cols; j++) ...[
            if (j > 0) SizedBox(width: gap),
            Expanded(
              child: AspectRatio(
                aspectRatio: aspect,
                child: i + j < children.length
                    ? children[i + j]
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ));
    }
    return Column(children: rows);
  }
}

class NCountUp extends StatelessWidget {
  final double value;
  final int decimals;
  final String suffix;
  final TextStyle style;
  final TextStyle? suffixStyle;
  final bool grouping;
  const NCountUp(
    this.value, {
    super.key,
    required this.style,
    this.suffixStyle,
    this.decimals = 0,
    this.suffix = '',
    this.grouping = false,
  });

  String _fmt(double v) {
    var s = v.toStringAsFixed(decimals);
    if (grouping) {
      final parts = s.split('.');
      final whole = parts.first;
      final buf = StringBuffer();
      for (var i = 0; i < whole.length; i++) {
        if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
        buf.write(whole[i]);
      }
      s = buf.toString() + (parts.length > 1 ? '.${parts.last}' : '');
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text.rich(
        TextSpan(children: [
          TextSpan(text: _fmt(v), style: style),
          if (suffix.isNotEmpty)
            TextSpan(text: suffix, style: suffixStyle ?? style),
        ]),
        maxLines: 1,
      ),
    );
  }
}

class NPopIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const NPopIn({super.key, required this.child, this.delay = 0});

  @override
  State<NPopIn> createState() => _NPopInState();
}

class _NPopInState extends State<NPopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    whenRevealed(context, () {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position:
            Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(a),
        child: widget.child,
      ),
    );
  }
}

class NBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color? track;
  final double height;
  const NBar(this.value,
      {super.key, this.color = kBrand, this.track, this.height = 5});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: track ?? color.withValues(alpha: 0.12)),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color? track;
  final Widget? center;
  const NRing({
    super.key,
    required this.value,
    required this.size,
    required this.stroke,
    this.color = kBrand,
    this.track,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => CustomPaint(
        painter: _RingPainter(
            v, color, track ?? color.withValues(alpha: 0.12), stroke),
        child: SizedBox.square(dimension: size, child: child),
      ),
      child: Center(child: center),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  final Color track;
  final double stroke;
  const _RingPainter(this.v, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * v,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color;
}

/// Rounded-square icon tile in a soft tint.
class NIconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color? bg;
  const NIconTile(this.icon,
      {super.key, this.size = 44, this.color = kBrand, this.bg});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      );
}

/// Week strip with the current day highlighted (tap to select).
class NDateStrip extends StatefulWidget {
  const NDateStrip({super.key});

  @override
  State<NDateStrip> createState() => _NDateStripState();
}

class _NDateStripState extends State<NDateStrip> {
  late int _sel = DateTime.now().weekday - 1;
  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sel = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == _sel ? kBrand : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: i == _sel
                      ? [
                          BoxShadow(
                            color: kBrand.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    FittedBox(
                      child: Text(_names[i],
                          style: tText(11,
                              w: FontWeight.w500,
                              c: i == _sel
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : kMuted3)),
                    ),
                    const SizedBox(height: 4),
                    Text('${monday.add(Duration(days: i)).day}',
                        style: tDisplay(16,
                            w: FontWeight.w700,
                            c: i == _sel ? Colors.white : kInk3)),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < now.weekday - 1
                            ? (i == _sel ? Colors.white : kBrand)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// White hero card with a title, small tag, a CTA pill and a 3D illustration.
class NHeroCard extends StatelessWidget {
  final String tag;
  final String title;
  final String? highlight;
  final String cta;
  final String image;
  final VoidCallback onTap;
  final List<String> pills;
  const NHeroCard({
    super.key,
    required this.tag,
    required this.title,
    this.highlight,
    required this.cta,
    required this.image,
    required this.onTap,
    this.pills = const [],
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: nCardDeco(r: 26),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: 0,
              bottom: 0,
              width: 170,
              child: Image.asset(image,
                  fit: BoxFit.cover, cacheWidth: 520, alignment: Alignment.center),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.42, 0.62],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: kBrandSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag,
                        style: tText(10.5,
                            w: FontWeight.w700, c: kBrand, spacing: 0.4)),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 0.62,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: title, style: tDisplay(22, height: 1.15)),
                        if (highlight != null)
                          TextSpan(
                              text: '\n$highlight',
                              style: tDisplay(22, c: kBrand, height: 1.15)),
                      ]),
                      maxLines: 3,
                    ),
                  ),
                  if (pills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in pills)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kLine3),
                            ),
                            child: Text(p,
                                style: tText(11,
                                    w: FontWeight.w600, c: kInk3)),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: kBrand,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: kBrand.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cta,
                            style: tText(13,
                                w: FontWeight.w700, c: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: Colors.white),
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

/// Timeline row: check circle, white card with icon tile, title, streak and time.
class NRoutineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final String trailing;
  final IconData trailingIcon;
  final bool done;
  final bool last;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  const NRoutineRow({
    super.key,
    required this.icon,
    this.color = kBrand,
    required this.title,
    required this.sub,
    required this.trailing,
    this.trailingIcon = Icons.schedule_rounded,
    required this.done,
    this.last = false,
    required this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                const SizedBox(height: 26),
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? kBrand : Colors.white,
                      border: Border.all(
                          color: done ? kBrand : const Color(0xFFCFCFE0),
                          width: 1.6),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.only(top: 4),
                      color: kLine3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 10),
              child: PressScale(
                onTap: onTap ?? onToggle,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: nCardDeco(r: 18),
                  child: Row(
                    children: [
                      NIconTile(icon, size: 42, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tText(14.5,
                                    w: FontWeight.w600, c: kInk3)),
                            const SizedBox(height: 2),
                            Text(sub,
                                maxLines: 1,
                                style: tText(12, w: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: kLine3,
                      ),
                      SizedBox(
                        width: 44,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(trailingIcon, size: 17, color: kInk3),
                            const SizedBox(height: 3),
                            FittedBox(
                              child: Text(trailing,
                                  style: tText(11, w: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square photo with a dark fade and a white tag.
class NPhotoCard extends StatelessWidget {
  final String image;
  final String title;
  final String tag;
  final VoidCallback onTap;
  final bool play;
  final Alignment focus;
  const NPhotoCard({
    super.key,
    required this.image,
    required this.title,
    required this.tag,
    required this.onTap,
    this.play = false,
    this.focus = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image,
                  fit: BoxFit.cover, alignment: focus, cacheWidth: 600),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1],
                    colors: [
                      kInk3.withValues(alpha: 0),
                      kInk3.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(tag,
                      style: tText(10.5, w: FontWeight.w700, c: kInk3)),
                ),
              ),
              Positioned(
                left: side * 0.08,
                right: side * 0.08,
                bottom: side * 0.08,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 2,
                          style: tDisplay(side * 0.095,
                              w: FontWeight.w700,
                              c: Colors.white,
                              height: 1.15)),
                    ),
                    if (play)
                      Container(
                        width: side * 0.2,
                        height: side * 0.2,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow_rounded,
                            color: kBrand, size: side * 0.13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

void nOpenProduct(BuildContext context, ShopDemoProduct p) {
  nPush(
    context,
    ProductDetailScreen(
      title: p.title,
      subtitle: '${p.category} · Lab certified',
      price: p.price,
      oldPrice: p.oldPrice,
      image: p.image,
      rating: p.rating,
      reviewsCount: p.sold,
      category: p.category,
    ),
  );
}

/// Product card in a grocery-app style: photo tile, name, price, ADD stepper.
class NProductCard extends StatefulWidget {
  final ShopDemoProduct p;
  final double width;
  const NProductCard(this.p, {super.key, this.width = 140});

  @override
  State<NProductCard> createState() => _NProductCardState();
}

class _NProductCardState extends State<NProductCard> {
  int _qty = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final w = widget.width;
    final off = ((1 - p.price / p.oldPrice) * 100).round();
    return GestureDetector(
      onTap: () => nOpenProduct(context, p),
      child: SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: w,
              height: w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kLine3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(p.image,
                        fit: BoxFit.cover, cacheWidth: 420),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 5, 9, 5),
                      decoration: const BoxDecoration(
                        color: kBrand,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text('$off% OFF',
                          style: tText(10,
                              w: FontWeight.w700, c: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(p.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tText(12.5, w: FontWeight.w600, c: kInk3, height: 1.3)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: kAccent),
                const SizedBox(width: 2),
                Text('${p.rating}',
                    style: tText(11, w: FontWeight.w600, c: kInk3)),
                Text(' (${p.sold})', style: tText(11)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${p.price.round()}',
                          style: tDisplay(14.5, w: FontWeight.w700)),
                      Text('₹${p.oldPrice.round()}',
                          style: tText(10.5).copyWith(
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _qty == 0
                      ? GestureDetector(
                          key: const ValueKey('add'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _qty = 1);
                          },
                          child: Container(
                            height: 32,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBrand, width: 1.3),
                            ),
                            child: Text('ADD',
                                style: tText(12,
                                    w: FontWeight.w700, c: kBrand)),
                          ),
                        )
                      : Container(
                          key: const ValueKey('qty'),
                          height: 32,
                          decoration: BoxDecoration(
                            color: kBrand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _step(Icons.remove_rounded,
                                  () => setState(() => _qty--)),
                              Text('$_qty',
                                  style: tText(12.5,
                                      w: FontWeight.w700, c: Colors.white)),
                              _step(Icons.add_rounded,
                                  () => setState(() => _qty++)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(IconData i, VoidCallback f) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          f();
        },
        child: SizedBox(
          width: 26,
          height: 32,
          child: Icon(i, size: 15, color: Colors.white),
        ),
      );
}

/// Horizontal carousel helper.
class NCarousel extends StatelessWidget {
  final double height;
  final int count;
  final IndexedWidgetBuilder builder;
  final double gap;
  const NCarousel({
    super.key,
    required this.height,
    required this.count,
    required this.builder,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: builder,
      ),
    );
  }
}

/// Stat tile used in grids: icon tile, number, label, thin bar.
class NStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final int decimals;
  final String suffix;
  final bool grouping;
  final double progress;
  final bool filled;
  final Color color;
  final VoidCallback? onTap;
  const NStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    this.decimals = 0,
    this.suffix = '',
    this.grouping = false,
    this.filled = false,
    this.color = kBrand,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : kInk3;
    final sub = filled ? Colors.white.withValues(alpha: 0.75) : kMuted3;
    return PressScale(
      onTap: onTap ?? () {},
      child: LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth;
        return Container(
          padding: EdgeInsets.all(side * 0.1),
          decoration: filled
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6E72F5), kBrandDeep],
                  ),
                  borderRadius: BorderRadius.circular(side * 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: kBrand.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                )
              : nCardDeco(r: side * 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NIconTile(icon,
                      size: side * 0.3,
                      color: filled ? Colors.white : color,
                      bg: filled
                          ? Colors.white.withValues(alpha: 0.18)
                          : color.withValues(alpha: 0.12)),
                  const Spacer(),
                  Text('${(progress * 100).round()}%',
                      style: tText(side * 0.085, w: FontWeight.w600, c: sub)),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: NCountUp(
                  value,
                  decimals: decimals,
                  suffix: suffix,
                  grouping: grouping,
                  style: tDisplay(side * 0.17,
                      w: FontWeight.w700, c: fg, height: 1.1),
                  suffixStyle: tDisplay(side * 0.1,
                      w: FontWeight.w600, c: sub, height: 1.1),
                ),
              ),
              Text(label,
                  maxLines: 1,
                  style: tText(side * 0.09,
                      w: FontWeight.w500, c: sub, height: 1.25)),
              SizedBox(height: side * 0.05),
              NBar(progress,
                  color: filled ? Colors.white : color,
                  track: filled ? Colors.white.withValues(alpha: 0.22) : null,
                  height: 4),
            ],
          ),
        );
      }),
    );
  }
}
