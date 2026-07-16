import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key}) ;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF071028),
        padding: const EdgeInsets.only(top: 24, left: 12, right: 12),
        child: ListView(
          children: [
            const DrawerHeader(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFF8A2BE2),
                child: Icon(Icons.admin_panel_settings, size: 34, color: Colors.white),
              ),
            ),
            _drawerItem(context, Icons.dashboard, 'Dashboard', '/admin'),
            _drawerItem(context, Icons.people, 'Users', '/admin/users'),
            _drawerItem(context, Icons.flag, 'Currencies', '/admin/currencies'),
            _drawerItem(context, Icons.swap_horiz, 'Rates', '/admin/rates'),
            _drawerItem(context, Icons.bar_chart, 'Reports', '/admin/reports'),
            _drawerItem(context, Icons.analytics, 'Analytics', '/admin/analytics'),
            _drawerItem(context, Icons.feedback, 'Feedbacks', '/admin/feedbacks'),
            _drawerItem(context, Icons.settings, 'Settings', '/admin/settings'),
            const Divider(color: Colors.white24),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade400),
              title: Text('Logout', style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                await context.read<AuthService>().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}

