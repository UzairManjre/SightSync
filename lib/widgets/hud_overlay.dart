import 'package:flutter/material.dart';
import '../utils/theme.dart';

class HudObject {
  final Rect rect;
  final String label;
  final double confidence;

  HudObject({required this.rect, required this.label, required this.confidence});
}

class HudOverlay extends StatelessWidget {
  final List<HudObject> objects;
  final Size imageSize;

  const HudOverlay({
    required this.objects,
    required this.imageSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / imageSize.width;
        final scaleY = constraints.maxHeight / imageSize.height;

        return Stack(
          children: objects.map((obj) {
            final left = obj.rect.left * scaleX;
            final top = obj.rect.top * scaleY;
            final width = obj.rect.width * scaleX;
            final height = obj.rect.height * scaleY;

            return Positioned(
              left: left,
              top: top,
              child: _HudFrame(
                width: width,
                height: height,
                label: obj.label,
                confidence: obj.confidence,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HudFrame extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final double confidence;

  const _HudFrame({
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cornered Frame
        Container(
          width: width,
          height: height,
          decoration: _HudFrameDecoration(color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        // Data Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            "${label.toUpperCase()} [${(confidence * 100).toInt()}%]",
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _HudFrameDecoration extends Decoration {
  final Color color;
  const _HudFrameDecoration({required this.color});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _HudFramePainter(color);
}

class _HudFramePainter extends BoxPainter {
  final Color color;
  _HudFramePainter(this.color);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final len = 12.0;

    // Top Left
    canvas.drawLine(offset, offset + Offset(len, 0), paint);
    canvas.drawLine(offset, offset + Offset(0, len), paint);

    // Top Right
    final tr = offset + Offset(size.width, 0);
    canvas.drawLine(tr, tr + Offset(-len, 0), paint);
    canvas.drawLine(tr, tr + Offset(0, len), paint);

    // Bottom Left
    final bl = offset + Offset(0, size.height);
    canvas.drawLine(bl, bl + Offset(len, 0), paint);
    canvas.drawLine(bl, bl + Offset(0, -len), paint);

    // Bottom Right
    final br = offset + Offset(size.width, size.height);
    canvas.drawLine(br, br + Offset(-len, 0), paint);
    canvas.drawLine(br, br + Offset(0, -len), paint);
    
    // Add subtle glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    
    canvas.drawRect(offset & size, glowPaint);
  }
}

class HUDOverlayGrid extends StatelessWidget {
  const HUDOverlayGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Add peripheral brackets
    final bracketPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    const margin = 20.0;
    const len = 30.0;
    
    // Top Left
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + len, margin), bracketPaint);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin, margin + len), bracketPaint);
    
    // Top Right
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - len, margin), bracketPaint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + len), bracketPaint);
    
    // Bottom Left
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + len, size.height - margin), bracketPaint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin, size.height - margin - len), bracketPaint);
    
    // Bottom Right
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - len, size.height - margin), bracketPaint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - len), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

