import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryTabData {
  final String label;
  final String iconPath;
  final Color color;
  final String? badge;

  const CategoryTabData({
    required this.label,
    required this.iconPath,
    required this.color,
    this.badge,
  });
}

/// Top category tabs drawn as curved "folder" tabs. The active tab gets a
/// coloured outline whose bottom edges flare out into the page, a soft
/// spotlight behind its 3D icon, and a little bounce when picked.
class CategoryTabBar extends StatefulWidget {
  final List<CategoryTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Index pulsing during the guided demo, if any.
  final int? highlightIndex;

  const CategoryTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.highlightIndex,
  });

  /// Width of one tab for a given screen width (about 4.3 tabs visible on
  /// phones, all five on wider screens).
  static double tabWidthFor(double maxWidth, int count) {
    final fitAll = (maxWidth - 24) / count;
    if (fitAll >= 92) return fitAll.clamp(92.0, 120.0);
    return ((maxWidth - 16) / 4.3).clamp(74.0, 96.0);
  }

  static double heightFor(double tabWidth) => tabWidth * 0.78 + 34;

  @override
  State<CategoryTabBar> createState() => _CategoryTabBarState();
}

class _CategoryTabBarState extends State<CategoryTabBar> {
  final ScrollController _scroll = ScrollController();
  double _tabW = 86;
  static const double _gap = 6;
  static const double _sidePad = 12;

  @override
  void didUpdateWidget(covariant CategoryTabBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) _scrollToSelected();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      final center = _sidePad +
          widget.selectedIndex * (_tabW + _gap) +
          _tabW / 2 -
          pos.viewportDimension / 2;
      _scroll.animateTo(
        center.clamp(0.0, pos.maxScrollExtent),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _tabW = CategoryTabBar.tabWidthFor(c.maxWidth, widget.tabs.length);
        final h = CategoryTabBar.heightFor(_tabW);
        return SizedBox(
          height: h + 4,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: _sidePad),
            itemCount: widget.tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: _gap),
            itemBuilder: (context, i) => _FolderTab(
              data: widget.tabs[i],
              width: _tabW,
              height: h,
              selected: i == widget.selectedIndex,
              highlighted: widget.highlightIndex == i,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onSelected(i);
              },
            ),
          ),
        );
      },
    );
  }
}

class _FolderTab extends StatefulWidget {
  final CategoryTabData data;
  final double width;
  final double height;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  const _FolderTab({
    required this.data,
    required this.width,
    required this.height,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  @override
  State<_FolderTab> createState() => _FolderTabState();
}

class _FolderTabState extends State<_FolderTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _FolderTab old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final w = widget.width;
    final h = widget.height;
    final iconSize = w * 0.62;
    final darkAccent = HSLColor.fromColor(d.color)
        .withLightness(
            (HSLColor.fromColor(d.color).lightness - 0.12).clamp(0.0, 1.0))
        .toColor();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 140),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.selected ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Tab shape: frosted fill, outline and flared foot
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FolderTabPainter(
                        t: t,
                        color: d.color,
                        pulse: widget.highlighted,
                      ),
                    ),
                  ),
                  // 3D icon, lifts and bounces when selected
                  Positioned(
                    top: 7,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _bounce,
                      builder: (context, child) {
                        final b = Curves.elasticOut.transform(_bounce.value);
                        final scale = 0.9 + 0.12 * t * (0.6 + 0.4 * b);
                        return Transform.translate(
                          offset: Offset(0, -3 * t),
                          child: Transform.scale(scale: scale, child: child),
                        );
                      },
                      child: Center(
                        child: Opacity(
                          opacity: 0.82 + 0.18 * t,
                          child: Image.asset(
                            d.iconPath,
                            width: iconSize,
                            height: iconSize,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.dashboard_rounded,
                              size: iconSize * 0.5,
                              color: d.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Optional badge, sitting on the icon's bottom edge
                  if (d.badge != null)
                    Positioned(
                      top: 7 + iconSize - 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: d.color,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.white, width: 1.4),
                            boxShadow: [
                              BoxShadow(
                                color: d.color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            d.badge!,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Label
                  Positioned(
                    left: 4,
                    right: 4,
                    bottom: 9,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        d.label,
                        maxLines: 1,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight:
                              t > 0.5 ? FontWeight.w800 : FontWeight.w600,
                          color: Color.lerp(
                            const Color(0xFF64748B),
                            darkAccent,
                            t,
                          ),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FolderTabPainter extends CustomPainter {
  final double t; // 0 = idle, 1 = selected
  final Color color;
  final bool pulse;

  _FolderTabPainter({required this.t, required this.color, this.pulse = false});

  Path _shape(Size s, {required double flare}) {
    final w = s.width;
    final h = s.height;
    const top = 9.0; // how much narrower the top is than the foot
    const r = 20.0; // top corner radius
    const foot = 14.0; // height of the curved foot
    final p = Path()..moveTo(-flare, h);
    p.quadraticBezierTo(1, h, 2, h - foot);
    p.lineTo(top, r);
    p.quadraticBezierTo(top + 2, 0, top + r, 0);
    p.lineTo(w - top - r, 0);
    p.quadraticBezierTo(w - top - 2, 0, w - top, r);
    p.lineTo(w - 2, h - foot);
    p.quadraticBezierTo(w - 1, h, w + flare, h);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final flare = 12.0 * t;
    final body = _shape(size, flare: flare);
    final filled = Path.from(body)..close();

    // Frosted fill: translucent when idle, bright with a colour wash when active
    final rect = Offset.zero & size;
    canvas.drawPath(
      filled,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(Colors.white.withValues(alpha: 0.55),
                Colors.white, t)!,
            Color.lerp(Colors.white.withValues(alpha: 0.30),
                color.withValues(alpha: 0.10), t)!,
          ],
        ).createShader(rect),
    );

    // Spotlight behind the icon, kept inside the tab shape
    if (t > 0) {
      canvas.save();
      canvas.clipPath(filled);
      final c = Offset(size.width / 2, size.width * 0.30);
      final r = size.width * 0.62;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.30 * t),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.restore();
    }

    // Soft coloured shadow under the active tab
    if (t > 0) {
      canvas.drawPath(
        body,
        Paint()
          ..color = color.withValues(alpha: 0.28 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Outline: faint white when idle, tab colour when active
    canvas.drawPath(
      body,
      Paint()
        ..color = Color.lerp(
          Colors.white.withValues(alpha: 0.9),
          color,
          t,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + 0.6 * t
        ..strokeCap = StrokeCap.round,
    );

    if (pulse) {
      canvas.drawPath(
        body,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FolderTabPainter old) =>
      old.t != t || old.color != color || old.pulse != pulse;
}
