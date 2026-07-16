import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/glow_card.dart';
import '../../core/utils/animation_utils.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/smart_alert_service.dart';

class SmartAlertsScreen extends StatefulWidget {
  const SmartAlertsScreen({super.key});

  @override
  State<SmartAlertsScreen> createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends State<SmartAlertsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  bool _isLoading = false;

  Future<bool> _addSmartAlert() async {
    if (_titleController.text.isEmpty || _conditionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return false;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final parsedAlert = SmartAlertService().parseConditionForSave(
        _titleController.text,
        _conditionController.text,
      );

      final alertRef =
          await FirebaseFirestore.instance.collection('smartAlerts').add({
        'userId': user?.uid ?? '',
        'title': _titleController.text.trim(),
        'condition': _conditionController.text.trim(),
        if (parsedAlert != null) ...{
          'fromCurrency': parsedAlert.fromCurrency,
          'toCurrency': parsedAlert.toCurrency,
          'operator': parsedAlert.operator,
          'targetRate': parsedAlert.targetRate,
        },
        'isEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ NOTIFICATION: Send to user
      if (user != null) {
        await NotificationService().sendNotification(
          userId: user.uid,
          title: 'Smart Alert Created 🔔',
          message: 'Alert "${_titleController.text}" has been set successfully.',
          type: 'alert',
        );
        await NotificationService().sendUserActivityToAdmin(
          title: 'Smart Alert Created',
          message: '${user.displayName ?? user.email ?? 'A user'} created alert "${_titleController.text.trim()}".',
          type: 'alert',
        );
      }

      if (user != null && parsedAlert != null) {
        await SmartAlertService().notifyNewAlertIfCurrentRateMatches(
          alertRef: alertRef,
          parsedAlert: parsedAlert,
          userId: user.uid,
          title: _titleController.text,
        );
      }

      if (!mounted) return false;

      _titleController.clear();
      _conditionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Smart alert added successfully'), backgroundColor: Colors.green),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSmartAlert(String docId, bool currentStatus) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('smartAlerts').doc(docId).get();
      final title = doc.data()?['title'] ?? 'Smart alert';
      final newStatus = currentStatus ? 'disabled' : 'enabled';

      await FirebaseFirestore.instance.collection('smartAlerts').doc(docId).update({
        'isEnabled': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await NotificationService().sendUserActivityToAdmin(
        title: 'Smart Alert $newStatus',
        message: '${FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email ?? 'A user'} $newStatus alert "$title".',
        type: 'alert',
        relatedId: docId,
      );
    } catch (e) {
      debugPrint('Error toggling smart alert: $e');
    }
  }

  Future<void> _deleteSmartAlert(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Delete Alert', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this smart alert?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final doc = await FirebaseFirestore.instance.collection('smartAlerts').doc(docId).get();
        final title = doc.data()?['title'] ?? 'Smart alert';

        await FirebaseFirestore.instance.collection('smartAlerts').doc(docId).delete();
        await NotificationService().sendUserActivityToAdmin(
          title: 'Smart Alert Deleted',
          message: '${FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email ?? 'A user'} deleted alert "$title".',
          type: 'alert',
          relatedId: docId,
        );
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Smart alert deleted'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Smart Alerts', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00E5FF)),
            onPressed: () => _showAddSmartAlertDialog(),
          ),
        ],
      ),
      body: AnimationUtils.fadeInSlide(
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GlowCard(
                glowColor: const Color(0xFF00E5FF),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Alert Title',
                                labelStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _conditionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Condition',
                                labelStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlowButton(
                        onPressed: _isLoading ? () {} : () async {
                          if (await _addSmartAlert()) {
                            if (mounted) setState(() {});
                          }
                        },
                        glowColor: const Color(0xFF00E5FF),
                        height: 45,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Add Alert', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('smartAlerts')
                      .where('userId', isEqualTo: user?.uid ?? '')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        ),
                      );
                    }

                    final alerts = snapshot.data!.docs.toList();
                    alerts.sort((a, b) {
                      final aTs = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final bTs = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return 1;
                      if (bTs == null) return -1;
                      return bTs.compareTo(aTs);
                    });

                    if (alerts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology_alt, color: Colors.white24, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'No smart alerts configured',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final doc = alerts[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Alert';
                        final condition = data['condition'] ?? '';
                        final isEnabled = data['isEnabled'] is bool ? data['isEnabled'] as bool : true;
                        return _smartAlertCard(doc.id, title, condition, isEnabled);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSmartAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Add Smart Alert', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Alert Title',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conditionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Condition',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          GlowButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await _addSmartAlert()) {
                if (!mounted) return;
                navigator.pop();
              }
            },
            glowColor: const Color(0xFF00E5FF),
            height: 45,
            child: const Text('Add Alert', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _smartAlertCard(String docId, String title, String condition, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withAlpha(((0.05) * 255).round()) : Colors.white.withAlpha(((0.02) * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled 
              ? const Color(0xFF00E5FF).withAlpha(((0.3) * 255).round()) 
              : Colors.white.withAlpha(((0.05) * 255).round()),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_alt,
                      color: enabled ? const Color(0xFF00E5FF) : Colors.white24,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white38,
                        fontWeight: enabled ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  condition,
                  style: TextStyle(
                    color: enabled ? Colors.white54 : Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Switch(
                value: enabled,
                onChanged: (_) => _toggleSmartAlert(docId, enabled),
                activeThumbColor: const Color(0xFF00E5FF),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deleteSmartAlert(docId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
