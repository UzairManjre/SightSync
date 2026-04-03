import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/ambient_background.dart';
import 'user_guide_screen.dart'; // Navigate to UserGuideScreen at the end

class ButtonMappingTutorial extends StatelessWidget {
  const ButtonMappingTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const _LabelBadge(text: 'SYSTEM PROTOCOLS'),
                const SizedBox(height: 12),
                const Text(
                  'Interaction\nTutorial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your SightSync module uses precise haptic triggers. Learn the primary interaction gestures below.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                
                const Spacer(),
                
                const Center(
                  child: HapticModuleBlueprint(),
                ),
                
                const Spacer(),
                
                const _InteractionCard(
                  icon: Icons.touch_app_rounded,
                  title: 'SINGLE PRESS',
                  description: 'Triggers instant AI vocalization of surroundings.',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                const _InteractionCard(
                  icon: Icons.timer_rounded,
                  title: 'LONG PRESS',
                  description: 'Activates full scene narration & spatial depth.',
                  color: AppColors.accent,
                ),
                
                const SizedBox(height: 48),
                
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const UserGuideScreen()),
                    );
                  },
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryGradient,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('COMPLETE SYNCHRONIZATION', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        SizedBox(width: 12),
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HapticModuleBlueprint extends StatelessWidget {
  const HapticModuleBlueprint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceBright.withOpacity(0.1),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Schematic Lines
          CustomPaint(
            size: const Size(280, 280),
            painter: _BlueprintPainter(),
          ),
          
          // Central Node
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 40),
          ),
          
          // Action Points
          Positioned(
            top: 40,
            right: 40,
            child: _ActionPoint(label: 'TRIGGER A', color: AppColors.primary),
          ),
          Positioned(
            bottom: 60,
            left: 20,
            child: _ActionPoint(label: 'MODIFIER', color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _ActionPoint extends StatelessWidget {
  final String label;
  final Color color;
  const _ActionPoint({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw crosshair circles
    canvas.drawCircle(center, size.width * 0.4, paint);
    canvas.drawCircle(center, size.width * 0.3, paint);
    
    // Draw guide lines
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InteractionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InteractionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(opacity: 0.05, radius: 24),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelBadge extends StatelessWidget {
  final String text;
  const _LabelBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

Future<void> _dummyUpdate(String key, String value) async {}
