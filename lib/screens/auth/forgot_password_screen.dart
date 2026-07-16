import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';  // ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key}) ;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim()
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email address';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address';
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00E5FF);

    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: AnimationUtils.fadeInSlide(  // ✅ WRAPPED WITH ANIMATION
        duration: const Duration(milliseconds: 600),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimationUtils.scaleIn(
                  duration: const Duration(milliseconds: 500),
                  begin: 0.8,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(((0.03) * 255).round()),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(((0.12) * 255).round())),
                      boxShadow: [
                        BoxShadow(
                          color: neonCyan.withAlpha(((0.12) * 255).round()),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 65,
                      color: neonCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                AnimationUtils.fadeIn(
                  duration: const Duration(milliseconds: 500),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimationUtils.fadeIn(
                  duration: const Duration(milliseconds: 400),
                  child: const Text(
                    'Enter your email to receive recovery instructions',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 35),
                
                GlassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: "Registered Email",
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          hintText: "example@currensee.com",
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: neonCyan, size: 22),
                          filled: true,
                          fillColor: Colors.white.withAlpha(((0.01) * 255).round()),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withAlpha(((0.08) * 255).round())),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: neonCyan, width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                GlowButton(  // ✅ GLOW BUTTON
                  onPressed: _isLoading ? () {} : _handleResetPassword,
                  glowColor: neonCyan,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF030712)),
                          ),
                        )
                      : const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            color: Color(0xFF030712),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
