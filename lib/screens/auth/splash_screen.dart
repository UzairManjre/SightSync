import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Give the splash screen a moment to show (optional, but smoother)
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // User is already logged in, go to Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      // No session, go to Welcome Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple SS Logo
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "SS",
                  style: TextStyle(
                    color: AppColors.authGradientTop,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: AppColors.authGradientTop,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context, {required String label, required VoidCallback onPressed}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: const Color(0xFF0A1A30),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}