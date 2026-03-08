import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SpotGlowBackground extends StatelessWidget {
  final Widget child;

  const SpotGlowBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Deep Black Base
        Container(color: AppColors.deepBlack),

        // 2. Large Secondary Spot Glow (Bottom Left)
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00B4DB).withOpacity(0.12), // Deep Teal/Blue
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Primary Vibrant Spot Glow (Top Right)
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4FACFE).withOpacity(0.18), // Vibrant Blue
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 4. Subtle Center Ambient Glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, 0.4),
                radius: 1.2,
                colors: [
                  const Color(0xFF0038A8).withOpacity(0.08), // Deep Royal Blue
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 5. The actual content on top
        child,
      ],
    );
  }
}
