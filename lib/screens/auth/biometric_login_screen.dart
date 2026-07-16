import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';  // ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED

class BiometricLoginScreen extends StatelessWidget {
  const BiometricLoginScreen({super.key}) ;

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00E5FF);

    return GlassScaffold(
      body: AnimationUtils.fadeInSlide(  // ✅ WRAPPED WITH ANIMATION
        duration: const Duration(milliseconds: 600),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimationUtils.scaleIn(  // ✅ SCALE ANIMATION
                  duration: const Duration(milliseconds: 600),
                  begin: 0.8,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(((0.02) * 255).round()),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(((0.08) * 255).round())),
                      boxShadow: [
                        BoxShadow(
                          color: neonCyan.withAlpha(((0.1) * 255).round()),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 85,
                      color: neonCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                AnimationUtils.fadeIn(
                  duration: const Duration(milliseconds: 500),
                  child: const Text(
                    'Biometric Login',
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
                    'Touch sensor to authenticate node credentials',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 45),
                
                GlowCard(  // ✅ GLOW CARD
                  glowColor: neonCyan,
                  padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 45),
                  child: Column(
                    children: [
                      AnimationUtils.scaleIn(
                        duration: const Duration(milliseconds: 500),
                        begin: 0.8,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: neonCyan.withAlpha(((0.05) * 255).round()),
                            shape: BoxShape.circle,
                            border: Border.all(color: neonCyan.withAlpha(((0.25) * 255).round()), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: neonCyan.withAlpha(((0.15) * 255).round()),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.touch_app_rounded,
                            size: 55,
                            color: neonCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Sensor Ready',
                        style: TextStyle(
                          color: neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 45),
                
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Use Secure Passcode Instead',
                    style: TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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
