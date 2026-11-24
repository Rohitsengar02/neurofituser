import 'package:flutter/material.dart';

/// Smooth, high-performance shimmer gradient effect
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.1, 0.45, 0.75],
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Generic rounded rectangle placeholder box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// -------------------------------------------------------------
// ORDERS SCREEN SKELETON
// -------------------------------------------------------------
class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status Badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonBox(width: 100, height: 14, borderRadius: 4),
              SkeletonBox(width: 75, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 14),
          // Product Thumbnail + Details
          Row(
            children: [
              const SkeletonBox(width: 64, height: 64, borderRadius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: double.infinity, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 110, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 70, height: 14, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonBox(width: 90, height: 14, borderRadius: 4),
              SkeletonBox(width: 80, height: 28, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class SkeletonOrdersList extends StatelessWidget {
  final int count;
  const SkeletonOrdersList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        children: List.generate(count, (_) => const SkeletonOrderCard()),
      ),
    );
  }
}

// -------------------------------------------------------------
// ADDRESS MANAGEMENT SCREEN SKELETON
// -------------------------------------------------------------
class SkeletonAddressCard extends StatelessWidget {
  const SkeletonAddressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag + GPS Location Chip + Radio Circle
          Row(
            children: const [
              SkeletonBox(width: 55, height: 22, borderRadius: 6),
              SizedBox(width: 8),
              SkeletonBox(width: 85, height: 22, borderRadius: 6),
              Spacer(),
              SkeletonBox(width: 20, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 14),
          // Name and Phone
          const SkeletonBox(width: 160, height: 14, borderRadius: 4),
          const SizedBox(height: 8),
          // Full Address Lines
          const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
          const SizedBox(height: 6),
          const SkeletonBox(width: 180, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

class SkeletonAddressList extends StatelessWidget {
  final int count;
  const SkeletonAddressList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        itemCount: count,
        itemBuilder: (_, __) => const SkeletonAddressCard(),
      ),
    );
  }
}

// -------------------------------------------------------------
// CHECKOUT SCREEN SKELETON
// -------------------------------------------------------------
class SkeletonCheckoutView extends StatelessWidget {
  const SkeletonCheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Card Skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 120, height: 14, borderRadius: 4),
                      SkeletonBox(width: 60, height: 14, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 14),
                  SkeletonBox(width: 140, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(width: 180, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Cart Items Skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      SkeletonBox(width: 56, height: 56, borderRadius: 12),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 140, height: 14, borderRadius: 4),
                            SizedBox(height: 8),
                            SkeletonBox(width: 80, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                      SkeletonBox(width: 60, height: 16, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      SkeletonBox(width: 56, height: 56, borderRadius: 12),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 130, height: 14, borderRadius: 4),
                            SizedBox(height: 8),
                            SkeletonBox(width: 70, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                      SkeletonBox(width: 60, height: 16, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bill Details Card Skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 70, height: 12, borderRadius: 4),
                      SkeletonBox(width: 50, height: 12, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 80, height: 12, borderRadius: 4),
                      SkeletonBox(width: 40, height: 12, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 90, height: 16, borderRadius: 4),
                      SkeletonBox(width: 70, height: 18, borderRadius: 4),
                    ],
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
