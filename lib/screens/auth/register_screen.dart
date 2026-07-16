import 'package:currensee/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';
import '../../core/utils/animation_utils.dart';
import '../../core/services/notification_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (_emailController.text.trim().toLowerCase() == AuthService.adminEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This email is reserved for admin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final success = await authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // ✅ NOTIFICATION: Send to user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService().sendNotification(
          userId: user.uid,
          title: 'Welcome to CurrenSee! 🎉',
          message: 'Your account has been created successfully. Start exploring!',
          type: 'approved',
        );

        // ✅ NOTIFICATION: Send to admin
        await NotificationService().sendToAdmin(
          title: 'New User Registered',
          message: 'A new user "${_nameController.text}" has joined CurrenSee.',
          type: 'user_added',
          relatedId: user.uid,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;

      final errorMsg = authService.lastLoginError ??
          'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00E5FF);

    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: AnimationUtils.fadeInSlide(
        duration: const Duration(milliseconds: 600),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                      Icons.app_registration_rounded,
                      size: 60,
                      color: neonCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                AnimationUtils.fadeIn(
                  duration: const Duration(milliseconds: 500),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimationUtils.fadeIn(
                  duration: const Duration(milliseconds: 400),
                  child: const Text(
                    'Join CurrenSee smart wealth tracking node',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 35),
                
                GlassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: neonCyan, size: 22),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: "Secure Password",
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: neonCyan, size: 22),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: neonCyan, size: 22),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
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
                
                GlowButton(
                  onPressed: _isLoading ? () {} : _handleRegister,
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
                          'Register Node',
                          style: TextStyle(
                            color: Color(0xFF030712),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already possess a terminal credential? ",
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: neonCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
