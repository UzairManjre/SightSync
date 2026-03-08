import 'package:flutter/material.dart';

class HollowGlowBackground extends StatefulWidget {
  final Widget child;

  const HollowGlowBackground({super.key, required this.child});

  @override
  State<HollowGlowBackground> createState() => _HollowGlowBackgroundState();
}

class _HollowGlowBackgroundState extends State<HollowGlowBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2s ease-in-out infinite (will reverse)
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // bg-nebula base color
      color: const Color(0xFF020617), 
      child: Stack(
        alignment: Alignment.center,
        children: [
          // bg-nebula spot 1: 20% 20%
          Positioned(
            left: MediaQuery.of(context).size.width * 0.2 - (MediaQuery.of(context).size.width * 0.4),
            top: MediaQuery.of(context).size.height * 0.2 - (MediaQuery.of(context).size.width * 0.4),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color.fromRGBO(14, 165, 233, 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0], // mapped to 40% of parent in CSS
                ),
              ),
            ),
          ),
          
          // bg-nebula spot 2: 80% 80%
          Positioned(
            left: MediaQuery.of(context).size.width * 0.8 - (MediaQuery.of(context).size.width * 0.4),
            top: MediaQuery.of(context).size.height * 0.8 - (MediaQuery.of(context).size.width * 0.4),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color.fromRGBO(20, 184, 166, 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // bg-nebula spot 3: 50% 50%
          Positioned(
            child: Container(
              width: MediaQuery.of(context).size.width * 1.2,
              height: MediaQuery.of(context).size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color.fromRGBO(14, 165, 233, 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central pulsing ring
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Interpolate values based on animation progress (0.0 to 1.0)
              final scale = 1.0 + (_animation.value * 0.03); // 1.0 to 1.03
              
              final insetShadowBlur = 30.0 + (_animation.value * 30.0); // 30 to 60
              final insetShadowOpacity = 0.1 + (_animation.value * 0.1); // 0.1 to 0.2
              
              final outsetShadowBlur = 40.0 + (_animation.value * 50.0); // 40 to 90
              final outsetShadowOpacity = 0.2 + (_animation.value * 0.2); // 0.2 to 0.4
              
              final borderOpacity = 0.3 + (_animation.value * 0.3); // 0.3 to 0.6

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.width * 0.85,
                  constraints: const BoxConstraints(
                    maxWidth: 380, // slightly smaller than 500px for mobile aesthetic
                    maxHeight: 380,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.fromRGBO(56, 189, 248, borderOpacity),
                      width: 1.0,
                    ),
                    boxShadow: [
                      // Outset shadow (exact from CSS)
                      BoxShadow(
                        color: Color.fromRGBO(56, 189, 248, outsetShadowOpacity),
                        blurRadius: outsetShadowBlur,
                        blurStyle: BlurStyle.outer, // crucial so it acts as outset only
                      ),
                    ],
                  ),
                  child: Container(
                     decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Exact CSS: background: radial-gradient(circle, rgba(2, 6, 23, 0.8) 0%, transparent 100%);
                        gradient: RadialGradient(
                          colors: [
                            const Color.fromRGBO(2, 6, 23, 0.8), // rgba(2, 6, 23, 0.8) center
                            Colors.transparent, // transparent outer
                          ],
                          stops: const [0.0, 1.0], 
                        ),
                     ),
                     child: Container(
                        decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           boxShadow: [
                              // Exact CSS inset shadow simulation
                              BoxShadow(
                                 color: Color.fromRGBO(56, 189, 248, insetShadowOpacity),
                                 blurStyle: BlurStyle.inner, 
                                 blurRadius: insetShadowBlur,
                              )
                           ]
                        ),
                     ),
                  ),
                ),
              );
            },
          ),

          // The Content
          widget.child,
        ],
      ),
    );
  }
}
