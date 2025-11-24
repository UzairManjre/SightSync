import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/ble_service.dart';
import '../../utils/theme.dart';
import '../onboarding/onboarding_screens.dart';
import '../dashboard/dashboard_screen.dart';
import '../../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  final bool isLogin;

  const LoginScreen({super.key, this.isLogin = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isLogin;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    try {
      UserModel? user;
      if (_isLogin) {
        user = await authService.login(email, password);
      } else {
        user = await authService.signUp(email, password, fullName);
      }

      if (mounted) {
        if (user != null) {
          // Success
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => _isLogin ? const DashboardScreen() : const OnboardingScreen(),
            ),
          );
        }
        // If user is null, the error is handled by the catch block
      }
    } catch (e) {
      if (mounted) {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Updated logic for the Wave/Bluetooth button
  void _handleDeviceActivation() {
    final bleService = context.read<BleService>();

    if (bleService.connectedDevice != null) {
      // Logic: Device Connected -> Activate Mic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Microphone Activated. Listening..."),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Logic: Device Not Connected + Not Auth -> Prompt to Create Account
      // We do NOT go to Onboarding/Pairing screen here.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please create an account to pair your device."),
          backgroundColor: AppColors.error, // Red to indicate restriction
          duration: Duration(seconds: 2),
        ),
      );

      // Automatically switch to "Create Account" mode to help the user
      if (_isLogin) {
        setState(() {
          _isLogin = false;
          // Clear text for a fresh start
          _emailController.clear();
          _passwordController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final isConnected = bleService.connectedDevice != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4E73DF),
              AppColors.backgroundDark,
            ],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: _handleDeviceActivation,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          // Green border if connected, standard if not
                            color: isConnected ? AppColors.success : Colors.white24
                        ),
                        color: isConnected ? AppColors.success.withOpacity(0.2) : Colors.black12,
                      ),
                      child: Icon(
                        // Mic icon if connected, Wave icon if idle
                          isConnected ? Icons.mic : Icons.graphic_eq,
                          color: isConnected ? AppColors.success : Colors.white,
                          size: 20
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // --- TITLE ---
                Text(
                  _isLogin ? "Let's Get You\nIn" : "Let's Get You\nSet Up",
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 40),

                // --- INPUTS ---
                if (!_isLogin) ...[
                  _buildPillInput(
                    controller: _nameController,
                    hint: "full name",
                  ),
                  const SizedBox(height: 20),
                ],

                _buildPillInput(
                  controller: _emailController,
                  hint: "email",
                ),

                const SizedBox(height: 20),

                _buildPillInput(
                  controller: _passwordController,
                  hint: "password",
                  isPassword: true,
                ),

                const SizedBox(height: 30),

                // --- ACTIONS ROW ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _isLogin
                        ? TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Forgot Your Password?",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),

                    InkWell(
                      onTap: _handleAuth,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white54),
                          color: Colors.black26,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                            : const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 4),

                // --- TOGGLE MODE BUTTON ---
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _emailController.clear();
                        _passwordController.clear();
                        _nameController.clear();
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        text: _isLogin ? "New here? " : "Already have an account? ",
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                        children: [
                          TextSpan(
                            text: _isLogin ? "Create Account" : "Login",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillInput({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF051025).withOpacity(0.8),
            const Color(0xFF051025),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: AppColors.primaryBlue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
      ),
    );
  }
}