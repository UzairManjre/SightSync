import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/size_config.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: SizeConfig.h(500),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.authGradientTop, Colors.black],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.w(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: SizeConfig.h(60)),

                  // SS Logo
                  Container(
                    width: SizeConfig.w(70),
                    height: SizeConfig.w(70),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "SS",
                        style: TextStyle(
                          color: AppColors.authGradientTop,
                          fontSize: SizeConfig.sp(38),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: SizeConfig.h(40)),

                  // Welcome Text
                  Text(
                    "Welcome to\nSightSync",
                    style: TextStyle(
                      fontSize: SizeConfig.sp(50),
                      height: 1.1,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),

                  const Spacer(),

                  // "Let's Sync In ->"
                  Row(
                    children: [
                      Text(
                        "Let's Sync In",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: SizeConfig.sp(22),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(width: SizeConfig.w(8)),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white70, size: SizeConfig.sp(22)),
                    ],
                  ),

                  SizedBox(height: SizeConfig.h(20)),

                  // Buttons
                  Wrap(
                    spacing: SizeConfig.w(16),
                    runSpacing: SizeConfig.h(12),
                    children: [
                      _buildAuthButton(
                        context: context,
                        text: "Login",
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen(isLogin: true)),
                        ),
                      ),
                      _buildAuthButton(
                        context: context,
                        text: "Create Account",
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const LoginScreen(isLogin: false)),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.h(60)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(SizeConfig.w(30)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.w(24),
          vertical: SizeConfig.h(12),
        ),
        decoration: BoxDecoration(
          color: AppColors.authGradientTop.withOpacity(0.15),
          border: Border.all(
            color: AppColors.authGradientTop.withOpacity(0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(SizeConfig.w(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeConfig.sp(14),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
