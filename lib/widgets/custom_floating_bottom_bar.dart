import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass.dart';

class CustomFloatingBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onAddPressed;

  const CustomFloatingBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Left Rounded Capsule Navigation Pill
        Expanded(
          child: SizedBox(
            height: 62,
            child: LiquidGlass(
              style: LiquidGlassStyle.regular,
              borderRadius: BorderRadius.circular(36),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCapsuleItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    unselectedIcon: Icons.home_outlined,
                  ),
                  _buildCapsuleItem(
                    index: 1,
                    icon: Icons.directions_walk_rounded,
                    unselectedIcon: Icons.directions_walk_outlined,
                  ),
                  _buildCapsuleItem(
                    index: 2,
                    icon: Icons.sports_gymnastics_rounded,
                    unselectedIcon: Icons.sports_gymnastics_rounded,
                  ),
                  _buildCapsuleItem(
                    index: 3,
                    icon: Icons.people_rounded,
                    unselectedIcon: Icons.people_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Right Circular Action Button with '+' Icon
        SizedBox(
          width: 62,
          height: 62,
          child: LiquidGlass(
            style: LiquidGlassStyle.regular,
            shape: BoxShape.circle,
            onTap: () {
              HapticFeedback.heavyImpact();
              onAddPressed();
            },
            child: const Center(
              child: Icon(Icons.add_rounded, size: 28, color: Color(0xFF1E293B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapsuleItem({
    required int index,
    required IconData icon,
    required IconData unselectedIcon,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onItemSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE082), // Soft Golden Amber Top
                    Color(0xFFFFB300), // Rich Warm Golden Amber Bottom
                  ],
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(
          isSelected ? icon : unselectedIcon,
          size: 24,
          color: isSelected ? const Color(0xFF78350F) : const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
