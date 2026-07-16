// lib/screens/onboarding/onboarding_screen.dart

import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';  // ✅ ADD

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key}) ;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final List<OnboardingData> slides = [
    OnboardingData(icon: Icons.currency_exchange, title: 'Real-time Rates', subtitle: 'Get live exchange rates instantly'),
    OnboardingData(icon: Icons.trending_up, title: 'Market Trends', subtitle: 'Track currency trends with charts'),
    OnboardingData(icon: Icons.notifications_active, title: 'Smart Alerts', subtitle: 'Get notified on important updates'),
  ];

  // ✅ Mark onboarding as seen
  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: slides.length,
                itemBuilder: (_, i) => _buildSlide(slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? const Color(0xFF00E5FF) : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        // ✅ Mark onboarding as seen
                        await _markOnboardingSeen();
                        if (!mounted) return;
                        navigator.pushReplacementNamed('/login');
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(data.icon, size: 120, color: const Color(0xFF00E5FF)),
        const SizedBox(height: 30),
        Text(
          data.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  
  OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
