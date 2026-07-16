import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/glow_card.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool enableNotifications = true;
  bool enableMaintenance = false;
  bool enableAnalytics = true;
  bool _isLoading = false;

  int _totalUsers = 0;
  int _activeSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStats();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('adminSettings')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          enableNotifications = data['enableNotifications'] ?? true;
          enableMaintenance = data['enableMaintenance'] ?? false;
          enableAnalytics = data['enableAnalytics'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').count().get();
      _totalUsers = usersSnapshot.count ?? 0;

      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final activeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('lastLogin', isGreaterThanOrEqualTo: yesterday)
          .count()
          .get();
      _activeSessions = activeSnapshot.count ?? 0;

      setState(() {});
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('adminSettings')
          .set({
        'enableNotifications': enableNotifications,
        'enableMaintenance': enableMaintenance,
        'enableAnalytics': enableAnalytics,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enableMaintenance', enableMaintenance);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateMaintenanceMode(bool value) async {
    setState(() => enableMaintenance = value);

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('adminSettings')
          .set({
        'enableMaintenance': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enableMaintenance', value);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              value ? 'Maintenance mode enabled' : 'Maintenance mode disabled'),
          backgroundColor: value ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => enableMaintenance = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GlowCard(
            glowColor: const Color(0xFF00E5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('General Settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _settingRow(
                  'Enable Notifications',
                  'Send alerts to users',
                  enableNotifications,
                  (value) => setState(() => enableNotifications = value),
                ),
                const Divider(color: Colors.white12),
                _settingRow(
                  'Maintenance Mode',
                  'Temporarily disable app',
                  enableMaintenance,
                  _updateMaintenanceMode,
                ),
                const Divider(color: Colors.white12),
                _settingRow(
                  'Analytics Tracking',
                  'Track user behavior',
                  enableAnalytics,
                  (value) => setState(() => enableAnalytics = value),
                ),
                const SizedBox(height: 12),
                GlowButton(
                  onPressed: _isLoading ? () {} : _saveSettings,
                  glowColor: const Color(0xFF00E5FF),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Settings',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlowCard(
            glowColor: const Color(0xFF00E5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Info',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _infoRow('App Version', 'v1.0.0'),
                const Divider(color: Colors.white12),
                _infoRow(
                    'Last Update', DateTime.now().toString().substring(0, 10)),
                const Divider(color: Colors.white12),
                _infoRow('Database Size', '125 MB'),
                const Divider(color: Colors.white12),
                _infoRow('Total Users', _totalUsers.toString()),
                const Divider(color: Colors.white12),
                _infoRow('Active Sessions', _activeSessions.toString()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlowCard(
            glowColor: const Color(0xFF00E5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Actions',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                GlowButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Backup started...'),
                          backgroundColor: Colors.blue),
                    );
                  },
                  glowColor: Colors.blue,
                  child: const Text('Backup Database',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                GlowButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cache cleared'),
                          backgroundColor: Colors.green),
                    );
                  },
                  glowColor: Colors.orange,
                  child: const Text('Clear Cache',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                GlowButton(
                  onPressed: () async {
                    final parentContext = context;
                    await FirebaseAuth.instance.signOut();
                    if (!parentContext.mounted) return;
                    Navigator.pushReplacementNamed(parentContext, '/login');
                  },
                  glowColor: Colors.red,
                  child: const Text('Logout',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(
      String title, String subtitle, bool value, Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeThumbColor: const Color(0xFF00E5FF),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Color(0xFF00E5FF))),
        ],
      ),
    );
  }
}
