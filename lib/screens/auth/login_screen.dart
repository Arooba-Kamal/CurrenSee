import 'package:currensee/screens/home/home_screen.dart';
import 'package:currensee/screens/admin/admin_dashboard.dart';
import 'package:currensee/core/services/auth_service.dart';
import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/glow_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isAdminAttempt =
        email.toLowerCase() == AuthService.adminEmail.toLowerCase() &&
            password == AuthService.adminPassword;
    final role = isAdminAttempt ? 'admin' : 'user';

    try {
      final success = await authService.login(email, password, role);

      setState(() => _isLoading = false);

      if (success && mounted) {
        if (authService.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else if (authService.isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        final errorMsg = authService.lastLoginError ??
            'Login failed. Please check your credentials.';
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00E5FF);

    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, _) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(((0.03) * 255).round()),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: neonCyan.withAlpha(((0.3) * 255).round())),
                        boxShadow: [
                          BoxShadow(
                            color: neonCyan.withAlpha(((0.2) * 255).round()),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.currency_exchange_rounded,
                        size: 65,
                        color: neonCyan,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Secure global transaction access metrics",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 35),

              // Simple Container (Replaced GlowCard)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(((0.05) * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withAlpha(((0.1) * 255).round())),
                ),
                child: Column(
                  children: [
                    GlowInput(
                      controller: _emailController,
                      labelText: "Email Address",
                      hintText: "example@currensee.com",
                      prefixIcon: Icons.mail_outline_rounded,
                      glowColor: neonCyan,
                    ),
                    const SizedBox(height: 18),
                    GlowInput(
                      controller: _passwordController,
                      labelText: "Account Password",
                      hintText: "••••••••",
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      glowColor: neonCyan,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixIconPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              GlowButton(
                onPressed: _isLoading ? () {} : _handleLogin,
                glowColor: neonCyan,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF0B1329)),
                        ),
                      )
                    : const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Color(0xFF0B1329),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/forgot_password'),
                child: const Text(
                  "Recover Password?",
                  style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "New to the ecosystem? ",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        color: neonCyan,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
