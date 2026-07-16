import 'package:flutter/material.dart';

class CustomAdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const CustomAdminCard({super.key, required this.title, required this.subtitle, this.trailing}) ;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(((0.03) * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(((0.06) * 255).round())),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(((0.7) * 255).round()))),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

