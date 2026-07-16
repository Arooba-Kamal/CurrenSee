import 'package:flutter/material.dart';

class AnimationUtils {
  // ============================================
  // FADE ANIMATIONS
  // ============================================
  
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeIn,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
    );
  }

  static Widget fadeInSlide({
    required Widget child,
    Duration duration = const Duration(milliseconds: 700),
    Curve curve = Curves.easeOut,
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, offset, _) {
        return FractionalTranslation(
          translation: offset,
          child: Opacity(
            opacity: 1 - (offset.dy + offset.dx).abs(),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================
  // SCALE ANIMATIONS
  // ============================================
  
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.elasticOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }

  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }

  // ============================================
  // SLIDE ANIMATIONS
  // ============================================
  
  static Widget slideInLeft({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ),
      duration: duration,
      curve: curve,
      builder: (context, offset, _) {
        return FractionalTranslation(
          translation: offset,
          child: child,
        );
      },
    );
  }

  static Widget slideInRight({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ),
      duration: duration,
      curve: curve,
      builder: (context, offset, _) {
        return FractionalTranslation(
          translation: offset,
          child: child,
        );
      },
    );
  }

  static Widget slideInUp({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ),
      duration: duration,
      curve: curve,
      builder: (context, offset, _) {
        return FractionalTranslation(
          translation: offset,
          child: child,
        );
      },
    );
  }

  // ============================================
  // ROTATION ANIMATIONS
  // ============================================
  
  static Widget rotate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    double begin = 0.0,
    double end = 0.1,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, angle, _) {
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
    );
  }

  static Widget spin({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, _) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
    );
  }

  // ============================================
  // STAGGERED ANIMATIONS
  // ============================================
  
  static Widget stagger({
    required List<Widget> children,
    Duration interval = const Duration(milliseconds: 150),
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOut,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final child = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: duration,
          curve: curve,
          builder: (_, value, __) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: child,
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // ============================================
  // GLASS CARD ANIMATIONS
  // ============================================
  
  static Widget glassCardAnimated({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }
}