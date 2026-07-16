import 'package:flutter/material.dart';

class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Duration animationDuration;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 400),
  }) ;

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(((0.035) * 255).round()),
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 24),
            border: Border.all(
              color: Colors.white.withAlpha(((0.09) * 255).round()),
              width: 1.2,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
