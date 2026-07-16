import 'package:flutter/material.dart';

class GlowInput extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color? glowColor;
  final VoidCallback? onSuffixIconPressed;
  final IconData? suffixIcon;

  const GlowInput({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.glowColor,
    this.onSuffixIconPressed,
    this.suffixIcon,
  }) ;

  @override
  State<GlowInput> createState() => _GlowInputState();
}

class _GlowInputState extends State<GlowInput> {
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        _hasText = widget.controller.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? const Color(0xFF00E5FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(((0.03) * 255).round()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused
              ? glowColor.withAlpha(((0.8) * 255).round())
              : Colors.white.withAlpha(((0.08) * 255).round()),
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: glowColor.withAlpha(((0.2) * 255).round()),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        onChanged: (_) => setState(() {}),
        onTap: () => setState(() => _isFocused = true),
        onEditingComplete: () => setState(() => _isFocused = false),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: _isFocused
                ? glowColor
                : _hasText
                    ? Colors.white70
                    : Colors.white38,
            fontSize: _isFocused || _hasText ? 14 : 16,
            fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
          ),
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? glowColor : Colors.white38,
                  size: 22,
                )
              : null,
          suffixIcon: widget.suffixIcon != null
              ? IconButton(
                  icon: Icon(
                    widget.suffixIcon,
                    color: _isFocused ? glowColor : Colors.white38,
                    size: 20,
                  ),
                  onPressed: widget.onSuffixIconPressed,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withAlpha(((0.01) * 255).round()),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}
