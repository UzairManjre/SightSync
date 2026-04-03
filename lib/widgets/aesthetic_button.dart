import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AestheticButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final bool isGlass;

  const AestheticButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.height = 64,
    this.borderRadius = 24,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null || isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: isGlass ? null : AppGradients.primaryGradient,
            color: isGlass ? Colors.white.withOpacity(0.06) : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isGlass ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              if (!isGlass)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              
              // Glossy Overlay for non-glass buttons
              if (!isGlass)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                          Colors.black.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
