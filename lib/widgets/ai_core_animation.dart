import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/theme.dart';

class AiCoreAnimation extends StatefulWidget {
  final double size;
  final double confidence; // 0.0 to 1.0

  const AiCoreAnimation({
    this.size = 200,
    this.confidence = 0.5,
    super.key,
  });

  @override
  State<AiCoreAnimation> createState() => _AiCoreAnimationState();
}

class _AiCoreAnimationState extends State<AiCoreAnimation> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _liquidController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _liquidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _liquidController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LiquidCorePainter(
            pulseValue: _pulseController.value,
            liquidValue: _liquidController.value,
            confidence: widget.confidence,
          ),
        );
      },
    );
  }
}

class _LiquidCorePainter extends CustomPainter {
  final double pulseValue;
  final double liquidValue;
  final double confidence;

  _LiquidCorePainter({
    required this.pulseValue,
    required this.liquidValue,
    required this.confidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 3;
    final pulseRadius = baseRadius + (pulseValue * 15 * (1 + confidence));

    // 1. Ambient Outer Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withOpacity(0.15),
          AppColors.secondary.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 2.5));
    canvas.drawCircle(center, baseRadius * 2.5, glowPaint);

    // 2. Liquid Blobs (Multiple layers)
    for (int i = 0; i < 3; i++) {
      final layerPaint = Paint()
        ..color = (i == 0 ? AppColors.primary : AppColors.secondary)
            .withOpacity(0.3 - (i * 0.05));
      
      final path = Path();
      final points = 8;
      final angleStep = (pi * 2) / points;
      
      for (int j = 0; j <= points; j++) {
        final angle = j * angleStep;
        final noise = sin(liquidValue * pi * 2 + j * 0.5 + i) * 10 * (1 + confidence);
        final r = pulseRadius + noise;
        
        final x = center.dx + cos(angle) * r;
        final y = center.dy + sin(angle) * r;
        
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, layerPaint);
    }

    // 3. Central "Neural" Core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          AppColors.primary,
          AppColors.secondary,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 0.8));
    
    canvas.drawCircle(center, baseRadius * 0.8, corePaint);
    
    // 4. Inner Ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, baseRadius * 0.9, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
