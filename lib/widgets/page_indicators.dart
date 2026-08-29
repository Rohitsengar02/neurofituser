import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PageIndicators extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Function(int)? onDotTap;

  const PageIndicators({
    super.key,
    required this.count,
    required this.currentIndex,
    this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return GestureDetector(
          onTap: () => onDotTap?.call(index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? 10 : 7,
              height: isActive ? 10 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.accentCoral : AppTheme.dotInactive,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0x66FF5238),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
