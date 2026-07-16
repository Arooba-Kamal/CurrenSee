import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/glow_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF060B13),
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF060B13),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Please login to view notifications',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060B13),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF060B13),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _notificationService.markAllAsRead(_userId!),
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: Color(0xFF00E5FF)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getUserNotifications(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['isRead'] ?? false;
              final title = notification['title'] ?? '';
              final message = notification['message'] ?? '';
              final type = notification['type'] ?? 'info';
              final docId = notification['id'] ?? '';

              return _buildNotificationCard(
                docId: docId,
                title: title,
                message: message,
                type: type,
                isRead: isRead,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required String docId,
    required String title,
    required String message,
    required String type,
    required bool isRead,
  }) {
    Color typeColor = Colors.blue;
    IconData typeIcon = Icons.notifications;

    switch (type) {
      case 'approved':
        typeColor = Colors.green;
        typeIcon = Icons.check_circle;
        break;
      case 'rejected':
        typeColor = Colors.red;
        typeIcon = Icons.cancel;
        break;
      case 'delivered':
        typeColor = Colors.blue;
        typeIcon = Icons.local_shipping;
        break;
      case 'alert':
        typeColor = Colors.orange;
        typeIcon = Icons.warning;
        break;
      case 'user_added':
        typeColor = Colors.green;
        typeIcon = Icons.person_add;
        break;
      case 'user_deleted':
        typeColor = Colors.red;
        typeIcon = Icons.person_remove;
        break;
      case 'rate_updated':
        typeColor = Colors.purple;
        typeIcon = Icons.currency_exchange;
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.notifications;
    }

    return GlowCard(
      glowColor: isRead ? Colors.transparent : const Color(0xFF00E5FF),
      padding: const EdgeInsets.all(0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.2),
          child: Icon(typeIcon, color: typeColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!isRead) {
            _notificationService.markAsRead(docId);
          }
        },
      ),
    );
  }
}