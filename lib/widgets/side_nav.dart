import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';

class SideNav extends StatelessWidget {
  final String currentPage;
  final Function(String) onPageChange;

  const SideNav({
    super.key,
    this.currentPage = 'dashboard',
    required this.onPageChange,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(((0.02) * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(((0.04) * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: Color(0xFF8A2BE2), child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 18)),
              SizedBox(width: 10),
              Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 18),
          _navItem(currentPage, Icons.dashboard, 'Dashboard', 'dashboard', onPageChange),
          _navItem(currentPage, Icons.people, 'Users', 'users', onPageChange),
          _navItem(currentPage, Icons.flag, 'Currencies', 'currencies', onPageChange),
          _navItem(currentPage, Icons.swap_horiz, 'Rates', 'rates', onPageChange),
          _navItem(currentPage, Icons.bar_chart, 'Reports', 'reports', onPageChange),
          _navItem(currentPage, Icons.analytics, 'Analytics', 'analytics', onPageChange),
          _navItem(currentPage, Icons.feedback, 'Feedbacks', 'feedbacks', onPageChange),
          _navItem(currentPage, Icons.settings, 'Settings', 'settings', onPageChange),
          const Spacer(),
          Divider(color: Colors.white.withAlpha(((0.2) * 255).round())),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.red.shade400, size: 18),
                const SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('v1.0', style: TextStyle(color: Colors.white.withAlpha(((0.4) * 255).round()))))
        ],
      ),
    );
  }

  static Widget _navItem(String currentPage, IconData icon, String label, String pageKey, Function(String) onPageChange) {
    bool isActive = currentPage == pageKey;
    return GestureDetector(
      onTap: () => onPageChange(pageKey),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: isActive ? const Color(0xFF00E5FF) : Colors.white54, size: 18),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isActive ? const Color(0xFF00E5FF) : Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

