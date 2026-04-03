import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/theme.dart';

class LinkVisualizer extends StatefulWidget {
  final bool leftActive;
  final bool rightActive;
  
  const LinkVisualizer({
    super.key,
    this.leftActive = true,
    this.rightActive = false,
  });

  @override
  State<LinkVisualizer> createState() => _LinkVisualizerState();
}

class _LinkVisualizerState extends State<LinkVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── The Silhouette ──
          CustomPaint(
            size: const Size(400, 200), // Fixed width for blueprint consistency
            painter: _GlassesOutlinePainter(),
          ),
          
          // ── Left Frame Glow ──
          if (widget.leftActive)
            Positioned(
              left: 60,
              top: 80,
              child: _GlowingIndicator(
                animation: _pulseAnimation,
                color: AppColors.primary,
              ),
            ),
            
          // ── Right Frame Glow ──
          if (widget.rightActive)
            Positioned(
              right: 60,
              top: 80,
              child: _GlowingIndicator(
                animation: _pulseAnimation,
                color: AppColors.accent, // Pink for contrast
              ),
            ),

          // ── Link Status Label ──
          Positioned(
            bottom: 20,
            child: Column(
              children: [
                const Text(
                  'SYNC ARCHITECTURE',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _LinkStatusDot(active: widget.leftActive),
                    const SizedBox(width: 4),
                    Container(width: 20, height: 1, color: Colors.white10),
                    const SizedBox(width: 4),
                    _LinkStatusDot(active: widget.rightActive),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingIndicator extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  
  const _GlowingIndicator({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(animation.value),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5 * animation.value),
                blurRadius: 15 * animation.value,
                spreadRadius: 5 * animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LinkStatusDot extends StatelessWidget {
  final bool active;
  const _LinkStatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6, height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : Colors.white10,
      ),
    );
  }
}

class _GlassesOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw stylized glasses silhouette (simplified blueprint style)
    final path = Path();
    
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    
    // Left Lens
    path.addRRect(RRect.fromLTRBR(60, centerY - 30, centerX - 10, centerY + 30, const Radius.circular(15)));
    
    // Right Lens
    path.addRRect(RRect.fromLTRBR(centerX + 10, centerY - 30, size.width - 60, centerY + 30, const Radius.circular(15)));
    
    // Bridge
    path.moveTo(centerX - 10, centerY - 5);
    path.quadraticBezierTo(centerX, centerY - 15, centerX + 10, centerY - 5);
    
    // Arms (Partial)
    path.moveTo(60, centerY - 10);
    path.lineTo(20, centerY - 15);
    
    path.moveTo(size.width - 60, centerY - 10);
    path.lineTo(size.width - 20, centerY - 15);

    canvas.drawPath(path, paint);
    
    // Draw technical grid background (Subtle)
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), dashPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
