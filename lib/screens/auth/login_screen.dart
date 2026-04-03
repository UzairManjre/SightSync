import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/aesthetic_button.dart';
import '../onboarding/onboarding_screens.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsSignUp;
  const LoginScreen({super.key, this.initialIsSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl  = TextEditingController();
  final _nameCtl  = TextEditingController();
  
  bool _isSignUp  = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  Future<void> _submit() async {
    if (_emailCtl.text.isEmpty || _passCtl.text.isEmpty) return;
    if (_isSignUp && _nameCtl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtl.text.trim(),
          password: _passCtl.text.trim(),
        );
        await cred.user?.updateDisplayName(_nameCtl.text.trim());
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtl.text.trim(),
          password: _passCtl.text.trim(),
        );
      }
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        useImage: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures full screen coverage
                      children: [
                        // --- Top Section ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              _isSignUp ? 'Signup' : 'Welcome\nBack',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 44,
                                fontWeight: FontWeight.w800, height: 1.1,
                                letterSpacing: -1.5, fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                            const SizedBox(height: 48),

                            // --- Input Fields ---
                            if (_isSignUp) ...[
                              _InputField(label: 'USERNAME', controller: _nameCtl, hint: 'alexsync'),
                              const SizedBox(height: 24),
                            ],
                            
                            _InputField(label: 'EMAIL ADDRESS', controller: _emailCtl, hint: 'alex@example.com'),
                            const SizedBox(height: 24),
                            _InputField(label: 'PASSWORD', controller: _passCtl, hint: '••••••••', isObscure: true),
                          ],
                        ),

                        // --- Bottom Section ---
                        Column(
                          children: [
                            const SizedBox(height: 48),
                            AestheticButton(
                              onTap: _submit,
                              isLoading: _isLoading,
                              isGlass: true,
                              label: _isSignUp ? 'Signup' : 'Welcome Back',
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () => setState(() {
                                _isSignUp = !_isSignUp;
                                _nameCtl.clear();
                              }),
                              child: Text(
                                _isSignUp ? 'Already have an account? Login' : "Don't have an account? Signup",
                                style: const TextStyle(
                                  color: AppColors.primary, 
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 14,
                                  fontFamily: 'SpaceGrotesk',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isObscure;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.isObscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5), // Brightened for better visibility
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 2,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            cursorColor: AppColors.primary,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.12), fontSize: 15),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}