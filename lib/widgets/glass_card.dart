import 'dart:ui';
import 'package:flutter/material.dart';

/// ==========================================
/// 1. GLOBAL LUXURY BLUE LOOK SCAFFOLD
/// ==========================================
class GlassScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  

  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
  }) ;

  @override
  Widget build(BuildContext context) {
    // Exact match for the luxury blue aesthetic from your reference picture
    const slateBackground = Color(0xFF0B1120); // Luminous deep slate blue
    const neonBlueAccent = Color(0xFF00E5FF);  // Bright neon-blue accent orb
    const matrixPurple = Color(0xFF6366F1);    // High-end deep violet/indigo orb

    return Scaffold(
      backgroundColor: slateBackground,
      appBar: appBar,
      body: Stack(
        children: [
          // Orb 1: Neon Cyan/Blue Glow in Top Right Corner
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonBlueAccent.withAlpha(((0.24) * 255).round()),
                // High blur creates that smooth, expensive ambient look
                // blurRadius: 110, 
              ),
            ),
          ),

          // Orb 2: Deep Indigo/Purple Glow in Bottom Left Corner
          Positioned(
            bottom: -100,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: matrixPurple.withAlpha(((0.18) * 255).round()),
                // blurRadius: 130,
              ),
            ),
          ),

          // Orb 3: Center Left Ambient Node (for mid-screen glass filtering)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonBlueAccent.withAlpha(((0.06) * 255).round()),
                // blurRadius: 90,
              ),
            ),
          ),

          // Foreground Content Layer
          SafeArea(
            child: body,
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// 2. FROSTED HEAVY TRANSLUCENT GLASS CARD
/// ==========================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  }) ;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 24),
      child: BackdropFilter(
        // High Sigmas ensure a premium heavy frosted glass blur effect
        filter: ImageFilter.blur(sigmaX: 22.0, sigmaY: 22.0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Ultra transparent white tint mimicking real reflective glass sheets
            color: Colors.white.withAlpha(((0.035) * 255).round()),
            borderRadius: BorderRadius.circular(borderRadius ?? 24),
            border: Border.all(
              // Sleek, bright micro-border line to give it structural reflection
              color: Colors.white.withAlpha(((0.09) * 255).round()),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassyNavBar extends StatelessWidget {
  final Widget child;
  const GlassyNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blurred Glass effect
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(((0.1) * 255).round()), // Glass ka base color
            border: Border(top: BorderSide(color: Colors.white.withAlpha(((0.2) * 255).round()))),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withAlpha(((0.2) * 255).round()), // Glowy Shadow
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
