import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/theme.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;
  final bool   useImage;
  final bool   isPremium;
  final String? imagePath;

  const AmbientBackground({
    super.key,
    required this.child,
    this.useImage  = false,
    this.isPremium = false,
    this.imagePath = 'assets/images/bg4.jpg',
  });

  @override
  Widget build(BuildContext context) {
    const premiumGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F172A), // Lighter Navy
        Color(0xFF1E3A8A), // Royal Blue
        Color(0xFF2563EB), // Azure Blue
      ],
    );

    return Stack(
      children: [
        // ── Base Layer ──
        Container(
          decoration: BoxDecoration(
            gradient: isPremium ? premiumGradient : AppGradients.mainBackground,
          ),
        ),
        
        // ── Decoration Layer ──
        if (isPremium) ...[
          // Starfield / Particle Layer
          const Positioned.fill(child: _StarField()),

          // Radiant Light Source (To prevent Dashboard from feeling too dark)
          const Positioned(
            top: -150,
            left: 50,
            right: 50,
            child: _GlowOrb(
              size: 600,
              color: AppColors.primary,
              opacity: 0.1,
            ),
          ),
          const Positioned.fill(child: _MovingNeuralAether()),
        ] else ...[
          const Positioned(
            top: -100, right: -50,
            child: _GlowOrb(size: 300, color: Color(0xFF1E3A8A), opacity: 0.15),
          ),
          const Positioned(
            bottom: 100, left: -80,
            child: _GlowOrb(size: 400, color: Color(0xFF1D4ED8), opacity: 0.1),
          ),
          const Positioned(
            top: 300, right: -100,
            child: _GlowOrb(size: 250, color: AppColors.primary, opacity: 0.05),
          ),
        ],
        
        // ── Image Overlay (Onboarding Style Only) ──
        if (!isPremium && useImage && imagePath != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                ),
              ),
            ),
          ),

        // ── Premium HUD Texture ──
        if (isPremium) ...[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.012),
                backgroundBlendMode: BlendMode.overlay,
              ),
            ),
          ),
          // Subtle vignette to focus on content
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.2)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
        ],

        // ── Content ──
        child,
      ],
    );
  }
}

class _MovingNeuralAether extends StatefulWidget {
  const _MovingNeuralAether();

  @override
  State<_MovingNeuralAether> createState() => _MovingNeuralAetherState();
}

class _MovingNeuralAetherState extends State<_MovingNeuralAether> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            _GlowingNode(
              size: 600,
              color: const Color(0xFF3B82F6), // Brighter Blue
              opacity: 0.2, 
              offset: Offset(
                math.sin(_ctrl.value * math.pi * 2) * 100,
                math.cos(_ctrl.value * math.pi * 2) * 50 - 100,
              ),
              alignment: Alignment.topLeft,
            ),
            _GlowingNode(
              size: 500,
              color: const Color(0xFF60A5FA), // Lighter Blue
              opacity: 0.15,
              offset: Offset(
                math.cos(_ctrl.value * math.pi * 2) * 80,
                math.sin(_ctrl.value * math.pi * 2) * 120 + 200,
              ),
              alignment: Alignment.bottomRight,
            ),
            _GlowingNode(
              size: 400,
              color: const Color(0xFF93C5FD), // Soft Sky Blue
              opacity: 0.1,
              offset: Offset(
                math.sin(_ctrl.value * math.pi * 2 + 1) * 150 - 50,
                math.cos(_ctrl.value * math.pi * 2 + 1) * 100 + 400,
              ),
              alignment: Alignment.centerRight,
            ),
          ],
        );
      },
    );
  }
}

class _GlowingNode extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final Offset offset;
  final Alignment alignment;

  const _GlowingNode({
    required this.size,
    required this.color,
    required this.opacity,
    required this.offset,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  PARTICLE STARFIELD
// ──────────────────────────────────────────────────────────────────────────────
class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Star> _stars = List.generate(40, (_) => _Star());

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarPainter(_stars, _ctrl.value),
        );
      },
    );
  }
}

class _Star {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble();
  final double size = 0.5 + math.Random().nextDouble() * 1.5;
  final double speed = 0.05 + math.Random().nextDouble() * 0.1;
  final double opacity = 0.1 + math.Random().nextDouble() * 0.4;
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;

  _StarPainter(this.stars, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var star in stars) {
      // Calculate drifting position
      double curX = (star.x * size.width);
      double curY = (star.y * size.height - (progress * size.height * star.speed)) % size.height;

      paint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(Offset(curX, curY), star.size, paint);
      
      // Add subtle glow to larger stars
      if (star.size > 1.2) {
        canvas.drawCircle(
          Offset(curX, curY), 
          star.size * 2, 
          Paint()..color = Colors.white.withOpacity(star.opacity * 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => true;
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}
