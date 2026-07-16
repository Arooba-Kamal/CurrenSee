import 'package:flutter/material.dart';

class GlowButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? glowColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlowButton({
    super.key,
    this.onPressed,
    required this.child,
    this.glowColor,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? const Color(0xFF00E5FF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: _isHovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.width ?? double.infinity,
                  height: widget.height ?? 56,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        glowColor,
                        glowColor.withAlpha((0.7 * 255).round()),
                        glowColor,
                      ],
                      stops: [
                        0.0,
                        0.5 + _glowAnimation.value * 0.3,
                        1.0,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withAlpha(((0.3 + _glowAnimation.value * 0.4) * 255).round()),
                        blurRadius: 20 + _glowAnimation.value * 20,
                        spreadRadius: 2 + _glowAnimation.value * 4,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: glowColor.withAlpha((0.1 * 255).round()),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}