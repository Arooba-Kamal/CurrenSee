import 'package:flutter/material.dart';
import '../../widgets/glow_card.dart';
import '../../core/utils/animation_utils.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00E5FF);

    final features = [
      {'title': 'Favorite Pairs', 'icon': Icons.star_outline_rounded, 'route': '/currency/favorites'},
      {'title': 'Live Conversion', 'icon': Icons.sync_alt_rounded, 'route': '/converter/live'},
      {'title': 'Offline Engine', 'icon': Icons.offline_bolt_outlined, 'route': '/converter/offline'},
      {'title': 'QR Vector Share', 'icon': Icons.qr_code_2_rounded, 'route': '/converter/qr'},
      {'title': 'Exchange Chart', 'icon': Icons.show_chart_rounded, 'route': '/market/chart'},
      {'title': 'Crypto Matrix', 'icon': Icons.currency_bitcoin_rounded, 'route': '/market/crypto'},
      {'title': 'Gold Bullion', 'icon': Icons.brightness_high_outlined, 'route': '/market/gold'},
      {'title': 'AI Prediction', 'icon': Icons.psychology_outlined, 'route': '/market/ai_prediction'},
      // ✅ Rate Alerts REMOVED - Show nahi hoga
      {'title': 'Global Signals', 'icon': Icons.notifications_none_rounded, 'route': '/alerts/notifications'},
      {'title': 'Smart Alerts', 'icon': Icons.compass_calibration_outlined, 'route': '/alerts/smart'},
      {'title': 'Node History', 'icon': Icons.history_toggle_off_rounded, 'route': '/history'},
      {'title': 'Compare Pairs', 'icon': Icons.compare_arrows_rounded, 'route': '/currency/compare'},
      {'title': 'Budget Matrix', 'icon': Icons.pie_chart_outline_rounded, 'route': '/planner/budget'},
      {'title': 'Vault Tracker', 'icon': Icons.account_balance_wallet_outlined, 'route': '/planner/spending'},
      {'title': 'Travel Estimator', 'icon': Icons.flight_takeoff_rounded, 'route': '/planner/travel'},
      {'title': 'Neural Chatbot', 'icon': Icons.chat_bubble_outline_rounded, 'route': '/chatbot'},
      {'title': 'Feedback', 'icon': Icons.feedback_outlined, 'route': '/feedback'},
    ];

    return AnimationUtils.fadeInSlide(
      duration: const Duration(milliseconds: 500),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Modules',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 26, 
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'EXPLORE NETWORK FUNCTIONS',
              style: TextStyle(
                color: Colors.white54, 
                fontSize: 11, 
                fontWeight: FontWeight.w700, 
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: features.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return AnimationUtils.fadeInSlide(
                  duration: const Duration(milliseconds: 300),
                  child: _buildFeatureTile(
                    context,
                    icon: item['icon'] as IconData,
                    title: item['title'] as String,
                    route: item['route'] as String,
                    accentColor: neonCyan,
                    index: index,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String route,
    required Color accentColor,
    required int index,
  }) {
    final tileWidth = (MediaQuery.of(context).size.width - 44) / 2;

    return SizedBox(
      width: tileWidth,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: GlowCard(
          glowColor: accentColor,
          padding: const EdgeInsets.all(16),
          borderRadius: 24,
          hasGlow: true,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withAlpha(((0.1) * 255).round()),
                      accentColor.withAlpha(((0.05) * 255).round()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}