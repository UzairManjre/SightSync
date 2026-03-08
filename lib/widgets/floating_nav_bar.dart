import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 34,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              gradient: AppGradients.cardOverlay,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.sensors_outlined, Icons.sensors_rounded, 'Sync'),
                _buildNavItem(2, Icons.history_edu_outlined, Icons.history_edu_rounded, 'Logs'),
                _buildNavItem(3, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryBlue.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primaryBlue : Colors.white24,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white24,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
