import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:currensee/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ADD THIS
import '../../core/utils/animation_utils.dart';
import '../../widgets/glow_button.dart'; // ✅ ADD THIS

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = context.read<AuthService>();

      // Wait for 2 seconds for splash animation
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // ✅ CHECK: User logged in hai?
      if (authService.isLoggedIn) {
        if (authService.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          final isBlocked =
              await authService.isCurrentUserBlockedByMaintenance();
          if (!mounted) return;

          if (!isBlocked) {
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }

          await authService.logout();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // ✅ NOT LOGGED IN: Check if onboarding already seen
        final prefs = await SharedPreferences.getInstance();
        final onboardingSeen = prefs.getBool('onboardingSeen') ?? false;

        if (!mounted) return;

        if (onboardingSeen) {
          // Onboarding already seen → Direct Login
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // ✅ FIRST TIME → Show Onboarding
          Navigator.pushReplacementNamed(context, '/onboarding1');
        }
      }
    } catch (e) {
      debugPrint('Error checking auth: $e');
      setState(() {
        _isLoading = false;
      });
      // Fallback: Show onboarding on error
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B121F),
      body: AnimationUtils.fadeIn(
        duration: const Duration(milliseconds: 800),
        child: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF08111F), Color(0xFF101F36)],
                  ),
                ),
              ),
            ),

            // Decorative Glow Orbs with Pulsing Animation
            Positioned(
              top: -80,
              right: -70,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E5FF)
                            .withAlpha(((0.10) * 255).round()),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.1 - (_pulseAnimation.value - 0.95),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8A2BE2)
                            .withAlpha(((0.10) * 255).round()),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // App Name - Staggered Animation
                    AnimationUtils.fadeInSlide(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        children: [
                          const Text(
                            'CurrenSee',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Smart Currency Converter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  Colors.white.withAlpha(((0.7) * 255).round()),
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Globe - Scale Animation
                    AnimationUtils.scaleIn(
                      duration: const Duration(milliseconds: 800),
                      begin: 0.85,
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background Grid & Connection Networks
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GlobeAtmospherePainter(),
                              ),
                            ),

                            // 3D Spherical Deep Glowing Core
                            Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-0.3, -0.3),
                                  radius: 0.7,
                                  colors: [
                                    const Color(0xFF4DD0E1)
                                        .withAlpha(((0.5) * 255).round()),
                                    const Color(0xFF0D253F)
                                        .withAlpha(((0.9) * 255).round()),
                                    const Color(0xFF040A14),
                                  ],
                                  stops: const [0.0, 0.65, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withAlpha(((0.2) * 255).round()),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withAlpha(((0.1) * 255).round()),
                                    blurRadius: 70,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),

                            // Realistic World Continents Outline & Latitude Mesh Lines
                            SizedBox(
                              width: 190,
                              height: 190,
                              child: ClipOval(
                                child: CustomPaint(
                                  painter: RealisticGlobeMeshPainter(),
                                ),
                              ),
                            ),

                            // Currency Bubbles
                            const Positioned(
                              top: 42,
                              right: 18,
                              child: _PremiumCurrencyBubble(
                                symbol: '\$',
                                baseColor: Color(0xFF00E676),
                              ),
                            ),
                            const Positioned(
                              top: 135,
                              right: 6,
                              child: _PremiumCurrencyBubble(
                                symbol: '£',
                                baseColor: Color(0xFFFF9100),
                              ),
                            ),
                            const Positioned(
                              bottom: 28,
                              right: 52,
                              child: _PremiumCurrencyBubble(
                                symbol: '¥',
                                baseColor: Color(0xFFD500F9),
                              ),
                            ),
                            const Positioned(
                              bottom: 28,
                              left: 52,
                              child: _PremiumCurrencyBubble(
                                symbol: '€',
                                baseColor: Color(0xFF651FFF),
                              ),
                            ),
                            const Positioned(
                              top: 130,
                              left: 6,
                              child: _PremiumCurrencyBubble(
                                symbol: '€',
                                baseColor: Color(0xFF00B0FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tagline - Fade Animation
                    AnimationUtils.fadeIn(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Real-time Rates. Smarter Decisions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withAlpha(((0.6) * 255).round()),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Buttons - Only show after loading
                    if (!_isLoading) ...[
                      AnimationUtils.fadeInSlide(
                        duration: const Duration(milliseconds: 600),
                        child: GlowButton(
                          // ✅ GLOW BUTTON
                          onPressed: () {
                            // ✅ Check onboarding status before going to login
                            _checkAuthStatus();
                          },
                          glowColor: const Color(0xFF00E5FF),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimationUtils.fadeIn(
                        duration: const Duration(milliseconds: 400),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            // ✅ Check onboarding status before going to login
                            _checkAuthStatus();
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: const Color(0xFF00E5FF)
                                  .withAlpha(((0.8) * 255).round()),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Loading Indicator
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white54),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white.withAlpha(((0.4) * 255).round()),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎨 Spherical Atmosphere Line Rays
class GlobeAtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(((0.08) * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 120, orbitPaint);

    final pathPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(((0.04) * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < 3; i++) {
      canvas.rotate(math.pi / 4);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: 250, height: 130 - (i * 20)),
          pathPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🎨 Real Math-based Spherical Grid & Continents
class RealisticGlobeMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(((0.12) * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawOval(
        Rect.fromLTWH(-w * 0.1, h * 0.2, w * 1.2, h * 0.6), gridPaint);
    canvas.drawOval(
        Rect.fromLTWH(-w * 0.2, h * 0.35, w * 1.4, h * 0.3), gridPaint);

    canvas.drawOval(
        Rect.fromLTWH(w * 0.2, -h * 0.1, w * 0.6, h * 1.2), gridPaint);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.35, -h * 0.2, w * 0.3, h * 1.4), gridPaint);

    final landPaint = Paint()
      ..color = const Color(0xFF4DD0E1).withAlpha(((0.24) * 255).round())
      ..style = PaintingStyle.fill;

    final mapPath = Path();
    mapPath.moveTo(w * 0.15, h * 0.25);
    mapPath.cubicTo(w * 0.3, h * 0.15, w * 0.5, h * 0.2, w * 0.55, h * 0.3);
    mapPath.cubicTo(w * 0.65, h * 0.35, w * 0.55, h * 0.45, w * 0.6, h * 0.55);
    mapPath.cubicTo(w * 0.65, h * 0.65, w * 0.5, h * 0.75, w * 0.45, h * 0.85);
    mapPath.cubicTo(w * 0.4, h * 0.92, w * 0.35, h * 0.85, w * 0.38, h * 0.75);
    mapPath.cubicTo(w * 0.42, h * 0.65, w * 0.32, h * 0.55, w * 0.35, h * 0.45);
    mapPath.cubicTo(w * 0.2, h * 0.45, w * 0.1, h * 0.35, w * 0.15, h * 0.25);
    mapPath.close();

    mapPath.moveTo(w * 0.8, h * 0.2);
    mapPath.cubicTo(w * 0.9, h * 0.18, w * 0.98, h * 0.25, w, h * 0.3);
    mapPath.lineTo(w, h * 0.65);
    mapPath.cubicTo(w * 0.9, h * 0.6, w * 0.82, h * 0.5, w * 0.85, h * 0.4);
    mapPath.cubicTo(w * 0.8, h * 0.35, w * 0.75, h * 0.25, w * 0.8, h * 0.2);
    mapPath.close();

    canvas.drawPath(mapPath, landPaint);

    final nodePaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(((0.6) * 255).round())
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.35, h * 0.3), 3, nodePaint);
    canvas.drawCircle(Offset(w * 0.52, w * 0.42), 2, nodePaint);
    canvas.drawCircle(Offset(w * 0.48, h * 0.68), 3, nodePaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.32), 2.5, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 💎 Professional Glass-morphic Currency Badges
class _PremiumCurrencyBubble extends StatelessWidget {
  final String symbol;
  final Color baseColor;

  const _PremiumCurrencyBubble({
    required this.symbol,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationUtils.scaleIn(
      duration: const Duration(milliseconds: 500),
      begin: 0.7,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor.withAlpha(((0.95) * 255).round()),
              baseColor.withAlpha(((0.75) * 255).round()),
            ],
          ),
          border: Border.all(
            color: Colors.white.withAlpha(((0.35) * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withAlpha(((0.5) * 255).round()),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(((0.3) * 255).round()),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 1.5),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
