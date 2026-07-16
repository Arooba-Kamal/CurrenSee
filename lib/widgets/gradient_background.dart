// lib/widgets/gradient_background.dart
import 'package:flutter/material.dart';

class CurrenSeeGradientBackground extends StatelessWidget {
  final Widget child;

  const CurrenSeeGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Blue-Black Layer
        Container(color: const Color(0xFF030712)),
        
        // Top Right Glowing Orb (Neon Cyan/Blue)
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E5FF).withAlpha(((0.12) * 255).round()),
              // blurRadius: 120,
            ),
          ),
        ),
        
        // Bottom Left Glowing Orb (Electric Purple)
        Positioned(
          bottom: -50,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF651FFF).withAlpha(((0.10) * 255).round()),
              // blurRadius: 110,
            ),
          ),
        ),
        
        // Foreground Content
        child,
      ],
    );
  }
}
