import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF030712), // Deep luxury dark base
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // 1. Top Right Neon Cyan Orb
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withAlpha(((0.14) * 255).round()),
                // blurRadius: 120,
              ),
            ),
          ),
          // 2. Center/Bottom Left Deep Purple/Blue Orb
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF651FFF).withAlpha(((0.12) * 255).round()),
                // blurRadius: 130,
              ),
            ),
          ),
          // 3. Main Screen Content Container
          SafeArea(child: body),
        ],
      ),
    );
  }
}
