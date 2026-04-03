import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/ambient_background.dart';

class GlassesTourScreen extends StatefulWidget {
  final VoidCallback onNext;
  const GlassesTourScreen({super.key, required this.onNext});

  @override
  State<GlassesTourScreen> createState() => _GlassesTourScreenState();
}

class _GlassesTourScreenState extends State<GlassesTourScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    const _LabelBadge(text: 'HARDWARE ORIENTATION'),
                    const SizedBox(height: 12),
                    const Text(
                      'Your SightSync\nGlasses',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- MOCKUP STACK ---
                    SizedBox(
                      height: 380,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // The Glasses Image
                          Image.asset(
                            'assets/images/glasses_mockup.png',
                            height: 320,
                            fit: BoxFit.contain,
                          ),

                          // --- HOTSPOTS ---
                          const Positioned(
                            top: 100,
                            right: 40,
                            child: _HardwareHotspot(
                              title: 'POWER SWITCH',
                              description: 'Slide to activate the system.',
                              alignment: HotspotAlignment.left,
                            ),
                          ),

                          const Positioned(
                            bottom: 80,
                            left: 50,
                            child: _HardwareHotspot(
                              title: 'ACTION BUTTON',
                              description: 'TAP: Scan Scene\nHOLD: AI Analysis',
                              alignment: HotspotAlignment.right,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- TRANSDUCER SECTION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HAPTIC TRANSDUCERS',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _GuideCard(
                            icon: Icons.waves_rounded,
                            title: 'BONE CONDUCTION',
                            description: 'Located in the temples. These send audio through vibrations, keeping your ears open to the environment.',
                          ),
                          const SizedBox(height: 12),
                          _GuideCard(
                            icon: Icons.spatial_audio_off_rounded,
                            title: 'SPATIAL DEPTH',
                            description: 'Feedback intensity varies based on object proximity. Feeling is believing.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            
            // --- BOTTOM NAV BAR (Fixed) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GestureDetector(
                onTap: widget.onNext,
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
                      Text('START EXPERIENCE', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      SizedBox(width: 12),
                      Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

enum HotspotAlignment { left, right }

class _HardwareHotspot extends StatefulWidget {
  final String title;
  final String description;
  final HotspotAlignment alignment;

  const _HardwareHotspot({
    required this.title,
    required this.description,
    required this.alignment,
  });

  @override
  State<_HardwareHotspot> createState() => _HardwareHotspotState();
}

class _HardwareHotspotState extends State<_HardwareHotspot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.alignment == HotspotAlignment.left ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Pulsing Circle
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 24, height: 24,
              padding: EdgeInsets.all(6 + (2 * _controller.value)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2 * (1.0 - _controller.value * 0.5)),
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Bubble
        Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuideCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
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
