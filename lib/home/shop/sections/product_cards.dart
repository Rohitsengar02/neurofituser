part of '../shop_tab_v3.dart';

// =====================================================================
//  PRODUCT CARDS
// =====================================================================

class _ProductCard extends StatelessWidget {
  final Product p;
  final bool compact;
  const _ProductCard(this.p, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      style: LiquidGlassStyle.material,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(8),
      onTap: () => _open(context, p),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: p.cover
                    ? productImage(p.image, fit: BoxFit.cover)
                    : ColoredBox(
                        color: Colors.white,
                        child: Padding(padding: const EdgeInsets.all(8), child: productImage(p.image, fit: BoxFit.contain)),
                      ),
              ),
            ),
            if (p.off > 0)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(8)),
                  child: Text('${p.off}% OFF', style: akT(10, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            Positioned(right: 6, top: 6, child: _Heart(p)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!compact) Text(p.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(10.5, w: FontWeight.w700, c: akFaint)),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(13, w: FontWeight.w800)),
            const SizedBox(height: 3),
            if (!compact)
              Row(children: [
                const Icon(Icons.star_rounded, color: _amber, size: 14),
                const SizedBox(width: 2),
                Text('${p.rating}', style: akT(11.5, w: FontWeight.w700)),
                Flexible(child: Text(' (${p.reviews})', overflow: TextOverflow.ellipsis, style: akT(11, c: akFaint))),
              ]),
            const SizedBox(height: 4),
            Row(children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_rs(p.price), style: akN(15)))),
              const SizedBox(width: 5),
              if (p.off > 0 && !compact)
                Flexible(
                  child: Text(_rs(p.old),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: akT(11, c: akFaint).copyWith(decoration: TextDecoration.lineThrough)),
                ),
              if (!compact) ...[
                const Spacer(),
                AkPress(
                  onTap: () => _addToCart(context, p),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: akInk, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Heart extends StatelessWidget {
  final Product p;
  const _Heart(this.p);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ShopCart.saved,
      builder: (_, s, _) {
        final on = s.contains(p.name);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ShopStore.I.toggleSave(p);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
              child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(on), size: 16, color: on ? _red : akMuted),
            ),
          ),
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Product> items;
  const _Grid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 262,
        ),
        itemBuilder: (_, i) => ScrollReveal(delayMs: (i % 2) * 80, child: _ProductCard(items[i])),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final List<Product> items;
  final bool small;
  const _Rail({required this.items, this.small = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: small ? 190 : 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ScrollReveal(
          delayMs: math.min(i, 3) * 70,
          child: SizedBox(width: small ? 140 : 170, child: _ProductCard(items[i], compact: small)),
        ),
      ),
    );
  }
}
