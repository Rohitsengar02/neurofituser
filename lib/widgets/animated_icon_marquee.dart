import 'package:flutter/material.dart';

class AnimatedIconMarquee extends StatefulWidget {
  const AnimatedIconMarquee({super.key});

  @override
  State<AnimatedIconMarquee> createState() => _AnimatedIconMarqueeState();
}

class _AnimatedIconMarqueeState extends State<AnimatedIconMarquee>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<String> _neonGreenImages = const [
    'assets/images/neon_green_dumbbell_1787819274202.jpg',
    'assets/images/neon_green_shoe_1787819288631.jpg',
    'assets/images/neon_green_smartwatch_1787819302325.jpg',
    'assets/images/neon_green_waterbottle_1787819315145.jpg',
    'assets/images/neon_green_yogamat_1787819327380.jpg',
  ];

  final List<String> _neonOrangeImages = const [
    'assets/images/neon_orange_gymbag_1787819375587.jpg',
    'assets/images/neon_orange_heartrate_1787819363247.jpg',
    'assets/images/neon_orange_kettlebell_1787819340750.jpg',
    'assets/images/neon_orange_proteinshaker_1787819387813.jpg',
    'assets/images/neon_orange_skippingrope_1787819351491.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // 22 seconds for a smooth, gentle infinite scroll
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Clean Background
            Container(color: const Color(0xFFF9FAFB)),

            // Row 1: Neon Green (Left scrolling)
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              child: _MarqueeRow(
                imagePaths: _neonGreenImages,
                animation: _controller,
                scrollLeft: true,
              ),
            ),

            // Row 2: Neon Orange (Right scrolling)
            Positioned(
              top: 102,
              left: 0,
              right: 0,
              child: _MarqueeRow(
                imagePaths: _neonOrangeImages,
                animation: _controller,
                scrollLeft: false,
              ),
            ),

            // Row 3: Neon Green reversed (Left scrolling)
            Positioned(
              top: 189,
              left: 0,
              right: 0,
              child: _MarqueeRow(
                imagePaths: _neonGreenImages.reversed.toList(),
                animation: _controller,
                scrollLeft: true,
              ),
            ),

            // Row 4: Neon Orange reversed (Right scrolling)
            Positioned(
              top: 276,
              left: 0,
              right: 0,
              child: _MarqueeRow(
                imagePaths: _neonOrangeImages.reversed.toList(),
                animation: _controller,
                scrollLeft: false,
              ),
            ),

            // Bottom Linear Gradient to fade cleanly into the white lower section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x99FFFFFF),
                      Color(0xFFFFFFFF),
                    ],
                    stops: [0.0, 0.5, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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

class _MarqueeRow extends StatelessWidget {
  final List<String> imagePaths;
  final Animation<double> animation;
  final bool scrollLeft;

  const _MarqueeRow({
    required this.imagePaths,
    required this.animation,
    required this.scrollLeft,
  });

  @override
  Widget build(BuildContext context) {
    const double itemSize = 72.0;
    const double spacing = 14.0;
    const double itemTotalWidth = itemSize + spacing;
    final double setWidth = imagePaths.length * itemTotalWidth;

    return SizedBox(
      height: itemSize,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final double progress = animation.value.clamp(0.0, 1.0);
          final double shift = progress * setWidth;
          // Calculate horizontal offset safely without modulo or Infinity
          final double leftPos = scrollLeft ? -shift : shift - (setWidth * 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: leftPos,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildImageSet(itemSize, spacing),
                    ..._buildImageSet(itemSize, spacing),
                    ..._buildImageSet(itemSize, spacing),
                    ..._buildImageSet(itemSize, spacing),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildImageSet(double itemSize, double spacing) {
    return imagePaths.map((path) {
      return Padding(
        padding: EdgeInsets.only(right: spacing),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.0),
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            width: itemSize,
            height: itemSize,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14),
                  borderRadius: BorderRadius.circular(18.0),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.black87),
              );
            },
          ),
        ),
      );
    }).toList();
  }
}
