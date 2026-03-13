import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/ble_service.dart';
import '../../utils/theme.dart';
import '../../utils/size_config.dart';
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
          // Check if email is verified in Firebase
          final firebaseUser = authService.firebaseUser;
          if (firebaseUser != null && !firebaseUser.emailVerified) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Please verify your email address.'),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Resend',
                  onPressed: () => authService.resendVerificationEmail(email),
                ),
              ),
            );
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  _isLogin ? const DashboardScreen() : const OnboardingScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleDeviceActivation() {
    final bleService = context.read<BleService>();

    if (bleService.leftDevice != null || bleService.rightDevice != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Microphone Activated. Listening..."),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please create an account to pair your device."),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );

      if (_isLogin) {
        setState(() {
          _isLogin = false;
          _emailController.clear();
          _passwordController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final bleService = context.watch<BleService>();
    final isConnected = bleService.leftDevice != null || bleService.rightDevice != null;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: SizeConfig.h(420),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.authGradientTop, Colors.black],
                ),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.w(40)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SizeConfig.h(20)),

                      // Audio Wave Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _handleDeviceActivation,
                          child: Container(
                            width: SizeConfig.w(48),
                            height: SizeConfig.w(48),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? AppColors.success.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.05),
                              border: Border.all(
                                color: isConnected
                                    ? AppColors.success.withOpacity(0.5)
                                    : Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              isConnected ? Icons.mic : Icons.graphic_eq,
                              color:
                                  isConnected ? AppColors.success : Colors.white,
                              size: SizeConfig.sp(24),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Title
                      Text(
                        _isLogin
                            ? "Let's Get\nYou In"
                            : "Let's Get You\nSet Up",
                        style: TextStyle(
                          fontSize: SizeConfig.sp(48),
                          height: 1.1,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1,
                        ),
                      ),

                      SizedBox(height: SizeConfig.h(50)),

                      // Inputs
                      if (!_isLogin) ...[
                        _buildAuthInputField(
                            controller: _nameController, hint: "full name"),
                        SizedBox(height: SizeConfig.h(20)),
                      ],

                      _buildAuthInputField(
                          controller: _emailController, hint: "email"),
                      SizedBox(height: SizeConfig.h(20)),
                      _buildAuthInputField(
                          controller: _passwordController,
                          hint: "password",
                          isPassword: true),

                      SizedBox(height: SizeConfig.h(36)),

                      // Footer Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_isLogin)
                            Flexible(
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerLeft,
                                ),
                                child: Text(
                                  "Forgot Your Password?",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: SizeConfig.sp(13),
                                    fontWeight: FontWeight.w300,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          else
                            const Spacer(),

                          SizedBox(width: SizeConfig.w(8)),
                          _buildContinueButton(),
                        ],
                      ),

                      const Spacer(flex: 3),

                      // Switch Link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              text: _isLogin
                                  ? "New here? "
                                  : "Already have an account? ",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: SizeConfig.sp(13)),
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

                      SizedBox(height: SizeConfig.h(20)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthInputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return Container(
      height: SizeConfig.h(60),
      decoration: BoxDecoration(
        color: const Color(0xFF030712).withOpacity(0.8),
        borderRadius: BorderRadius.circular(SizeConfig.w(30)),
        border: Border.all(
          color: AppColors.authGradientTop.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(color: Colors.white, fontSize: SizeConfig.sp(16)),
          cursorColor: AppColors.authGradientTop,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: SizeConfig.sp(16),
              fontWeight: FontWeight.w300,
            ),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: SizeConfig.w(24)),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return InkWell(
      onTap: _isLoading ? null : _handleAuth,
      borderRadius: BorderRadius.circular(SizeConfig.w(30)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.w(28),
          vertical: SizeConfig.h(12),
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(SizeConfig.w(30)),
          border: Border.all(color: Colors.white70, width: 1),
        ),
        child: _isLoading
            ? SizedBox(
                width: SizeConfig.w(20),
                height: SizeConfig.w(20),
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.sp(15),
                  fontWeight: FontWeight.w300,
                ),
              ),
      ),
    );
  }
}