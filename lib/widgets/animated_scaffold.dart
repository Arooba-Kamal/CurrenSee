import 'package:flutter/material.dart';
import '../core/utils/animation_utils.dart';

class AnimatedScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AnimatedScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.appBar,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: appBar ?? _buildAppBar(context),
      body: AnimationUtils.fadeInSlide(
        duration: const Duration(milliseconds: 600),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: AnimationUtils.fadeIn(
        duration: const Duration(milliseconds: 400),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: actions,
    );
  }
}
