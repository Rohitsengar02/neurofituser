import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class VideoPlayerCard extends StatefulWidget {
  final String videoAssetPath;

  const VideoPlayerCard({
    super.key,
    required this.videoAssetPath,
  });

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _currentController;
  VideoPlayerController? _nextController;
  bool _isCurrentInitialized = false;
  bool _isNextInitialized = false;
  double _crossFadeOpacity = 0.0;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _initCurrentVideo(widget.videoAssetPath);
  }

  Future<void> _initCurrentVideo(String assetPath) async {
    try {
      final controller = VideoPlayerController.asset(assetPath);
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0); // Muted
      await controller.play();
      if (mounted) {
        setState(() {
          _currentController?.dispose();
          _currentController = controller;
          _isCurrentInitialized = true;
          _crossFadeOpacity = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Video error: $e');
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoAssetPath != widget.videoAssetPath) {
      _switchVideo(widget.videoAssetPath);
    }
  }

  Future<void> _switchVideo(String newAssetPath) async {
    try {
      final next = VideoPlayerController.asset(newAssetPath);
      await next.initialize();
      next.setLooping(true);
      next.setVolume(0.0);
      await next.play();

      if (mounted) {
        setState(() {
          _nextController?.dispose();
          _nextController = next;
          _isNextInitialized = true;
          _crossFadeOpacity = 1.0;
        });

        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _currentController?.dispose();
              _currentController = _nextController;
              _isCurrentInitialized = true;
              _nextController = null;
              _isNextInitialized = false;
              _crossFadeOpacity = 0.0;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Switch video error: $e');
      _initCurrentVideo(newAssetPath);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _currentController?.dispose();
    _nextController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Current Active Video or Skeleton Shimmer Loader
          if (_isCurrentInitialized && _currentController != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _currentController!.value.size.width > 0 ? _currentController!.value.size.width : 1.0,
                height: _currentController!.value.size.height > 0 ? _currentController!.value.size.height : 1.0,
                child: VideoPlayer(_currentController!),
              ),
            )
          else
            _buildSkeletonLoader(),

          // 2. Next Video Cross-fading in
          if (_isNextInitialized && _nextController != null)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              opacity: _crossFadeOpacity,
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _nextController!.value.size.width > 0 ? _nextController!.value.size.width : 1.0,
                  height: _nextController!.value.size.height > 0 ? _nextController!.value.size.height : 1.0,
                  child: VideoPlayer(_nextController!),
                ),
              ),
            ),

          // 3. Bottom Fade Linear Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 96,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x00EFECE6),
                      Color(0x80EFECE6),
                      Color(0xDBEFECE6),
                      AppTheme.background,
                    ],
                    stops: [0.0, 0.35, 0.7, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final progress = _shimmerController.value;

        return Container(
          color: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skeleton Header (Avatar + Title bars)
                  Row(
                    children: [
                      _buildShimmerBlock(width: 44, height: 44, borderRadius: 22, progress: progress),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerBlock(width: 120, height: 12, borderRadius: 6, progress: progress),
                            const SizedBox(height: 6),
                            _buildShimmerBlock(width: 75, height: 9, borderRadius: 4.5, progress: progress),
                          ],
                        ),
                      ),
                      _buildShimmerBlock(width: 32, height: 32, borderRadius: 16, progress: progress),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Large Featured Workout Skeleton Card
                  Container(
                    width: double.infinity,
                    height: 140,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E0D8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        _buildShimmerOverlay(progress),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildShimmerBlock(width: 70, height: 10, borderRadius: 5, progress: progress, baseColor: const Color(0xFFD6D1C7)),
                                _buildShimmerBlock(width: 36, height: 36, borderRadius: 18, progress: progress, baseColor: const Color(0xFFD6D1C7)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildShimmerBlock(width: 140, height: 14, borderRadius: 7, progress: progress, baseColor: const Color(0xFFD6D1C7)),
                                const SizedBox(height: 6),
                                _buildShimmerBlock(width: 90, height: 10, borderRadius: 5, progress: progress, baseColor: const Color(0xFFD6D1C7)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom 3 Feature Metric Chips
                  Row(
                    children: [
                      Expanded(
                        child: _buildShimmerBlock(height: 38, borderRadius: 16, progress: progress),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildShimmerBlock(height: 38, borderRadius: 16, progress: progress),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildShimmerBlock(height: 38, borderRadius: 16, progress: progress),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBlock({
    double? width,
    required double height,
    required double borderRadius,
    required double progress,
    Color baseColor = const Color(0xFFE4E0D8),
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildShimmerOverlay(progress),
      ),
    );
  }

  Widget _buildShimmerOverlay(double progress) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Colors.transparent,
            Color(0x60FFFFFF),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-2.0 + (progress * 4.0), -0.5),
          end: Alignment(0.0 + (progress * 4.0), 0.5),
        ),
      ),
    );
  }
}
