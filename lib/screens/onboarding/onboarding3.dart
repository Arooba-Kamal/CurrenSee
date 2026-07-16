import 'package:currensee/core/theme/theme.dart';
import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:currensee/screens/auth/login_screen.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  // ✅ Mark onboarding as seen
  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, scale, _) {
                return Transform.scale(
                  scale: scale,
                  child: const Icon(
                    Icons.notifications_active,
                    size: 140,
                    color: AppTheme.accentCyan,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            
            // Title with fade
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, opacity, _) {
                return Opacity(
                  opacity: opacity,
                  child: const Text(
                    "Smart Alerts",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Subtitle with fade
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, opacity, _) {
                return Opacity(
                  opacity: opacity,
                  child: const Text(
                    "Get notified when currencies hit your target price.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            
            // Get Started Button
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              builder: (context, opacity, _) {
                return Opacity(
                  opacity: opacity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // ✅ Mark onboarding as seen (fire-and-forget)
                      _markOnboardingSeen();
                      // ✅ Navigate to Login
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Get Started 🚀",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}