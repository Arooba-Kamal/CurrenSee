// lib/widgets/glass_background.dart
import 'package:flutter/material.dart';
import 'gradient_background.dart';

class CurrenSeeGlassScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;

  const CurrenSeeGlassScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background transparent rakhein taaki gradient dikhe
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: CurrenSeeGradientBackground(
        child: SafeArea(child: body),
      ),
    );
  }
}