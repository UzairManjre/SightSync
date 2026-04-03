import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/ambient_background.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        useImage: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // --- SS Logo (Match Screenshot: White Circle) ---
                Container(
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Text(
                    'SS',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A), // Dark blue from logo
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),

                // --- Heading (Match Screenshot: Welcome to SightSync) ---
                const Text(
                  'Welcome to\nSightSync',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -1.5,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                
                const Spacer(),

                // --- CTA Label (Match Screenshot: Let's Sync In ->) ---
                Row(
                  children: [
                    Text(
                      'Let’s Sync In',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // --- Buttons (Match Screenshot: Side-by-Side Pill Buttons) ---
                Row(
                  children: [
                    Expanded(
                      child: _PillButton(
                        label: 'Login',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PillButton(
                        label: 'Signup',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen(initialIsSignUp: true)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PillButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF0A1227).withOpacity(0.8), // Dark glassmorphic
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
