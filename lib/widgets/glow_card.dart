import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class GlowCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? glowColor;
  final bool hasGlow;
  final bool hasAnimation;

  const GlowCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.glowColor,
    this.hasGlow = true,
    this.hasAnimation = true,
  }) ;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    if (widget.hasAnimation) _controller.forward();
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: _isHovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(), child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 22.0, sigmaY: 22.0),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(((0.035) * 255).round()),
                      borderRadius: BorderRadius.circular(widget.borderRadius ?? 24),
                      border: Border.all(
                        color: _isHovered
                            ? glowColor.withAlpha(((0.6) * 255).round())
                            : Colors.white.withAlpha(((0.09) * 255).round()),
                        width: _isHovered ? 1.5 : 1.2,
                      ),
                      boxShadow: [
                        if (widget.hasGlow && _isHovered)
                          BoxShadow(
                            color: glowColor.withAlpha(((0.25) * 255).round()),
                            blurRadius: 30,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        if (widget.hasGlow && _isHovered)
                          BoxShadow(
                            color: glowColor.withAlpha(((0.1) * 255).round()),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        if (widget.hasGlow)
                          BoxShadow(
                            color: glowColor.withAlpha(((_isHovered ? 0.3 : 0.05) * 255).round()),
                            blurRadius: 40,
                            spreadRadius: _isHovered ? 10 : 0,
                            offset: Offset(_isHovered ? 0 : 0, 0),
                          ),
                      ],
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
