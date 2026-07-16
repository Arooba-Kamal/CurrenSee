import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';
import '../../core/utils/animation_utils.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMarkingAllRead = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isAdmin = user?.email?.trim().toLowerCase() == NotificationService.adminEmail;
    final notificationUserIds = [
      if (user?.uid != null) user!.uid,
      if (isAdmin) NotificationService.adminNotificationUserId,
    ];
    final notificationsStream = isAdmin
        ? FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', whereIn: notificationUserIds)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.uid ?? '')
            .snapshots();
    
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(((0.02) * 255).round()),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          _isMarkingAllRead
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.done_all_rounded, color: Color(0xFF00E5FF)),
                  tooltip: 'Mark all as read',
                  onPressed: () async {
                    if (user == null) return;
                    setState(() => _isMarkingAllRead = true);
                    
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final unreadQuery = isAdmin
                          ? FirebaseFirestore.instance
                              .collection('notifications')
                              .where('userId', whereIn: notificationUserIds)
                              .where('isRead', isEqualTo: false)
                          : FirebaseFirestore.instance
                              .collection('notifications')
                              .where('userId', isEqualTo: user.uid)
                              .where('isRead', isEqualTo: false);
                      final snapshot = await unreadQuery.get();
                      
                      if (snapshot.docs.isNotEmpty) {
                        final batch = FirebaseFirestore.instance.batch();
                        for (var doc in snapshot.docs) {
                          batch.update(doc.reference, {'isRead': true});
                        }
                        await batch.commit();
                        
                        // ✅ Update unread count in provider
                        notificationProvider.resetUnreadCount();
                      }
                      if (!mounted) return;

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'), 
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error marking notifications: $e');
                    } finally {
                      setState(() => _isMarkingAllRead = false);
                    }
                  },
                ),
        ],
      ),
      body: AnimationUtils.fadeInSlide(
        duration: const Duration(milliseconds: 500),
        child: StreamBuilder<QuerySnapshot>(
          stream: notificationsStream,
          /*
              FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user?.uid ?? '')
              .orderBy('createdAt', descending: true) // ✅ Added orderBy
              .snapshots(),
          */
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                ),
              );
            }

            final notifications = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final aTime = _readCreatedAt(a.data());
                final bTime = _readCreatedAt(b.data());
                return bTime.compareTo(aTime);
              });

            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, color: Colors.white24, size: 54),
                    SizedBox(height: 16),
                    Text(
                      'No updates or notifications found',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final doc = notifications[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Notification Update';
                final message = data['message'] ?? data['body'] ?? '';
                final type = data['type'] ?? 'info';
                final time = data['createdAt'] != null
                    ? _formatTime((data['createdAt'] as Timestamp).toDate())
                    : 'Just now';
                final isRead = data['isRead'] ?? false;
                final fromUserEmail = data['fromUserEmail'] ?? '';
                
                return _notificationCard(
                  title: title,
                  message: message,
                  type: type,
                  time: time,
                  isRead: isRead,
                  docId: doc.id,
                  fromUserEmail: fromUserEmail,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _notificationCard({
    required String title,
    required String message,
    required String type,
    required String time,
    required bool isRead,
    required String docId,
    String fromUserEmail = '',
  }) {
    // ✅ Color based on type
    Color typeColor = const Color(0xFF00E5FF);
    IconData typeIcon = Icons.notifications_active_rounded;

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
      case 'alert':
        typeColor = Colors.orange;
        typeIcon = Icons.warning;
        break;
      case 'feedback':
        typeColor = Colors.pink;
        typeIcon = Icons.feedback;
        break;
      case 'user_activity':
        typeColor = Colors.amber;
        typeIcon = Icons.bolt;
        break;
      case 'info':
        typeColor = Colors.blue;
        typeIcon = Icons.info;
        break;
      default:
        typeColor = const Color(0xFF00E5FF);
        typeIcon = Icons.notifications_active_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          if (!isRead) {
            try {
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(docId)
                  .update({'isRead': true});
            } catch (e) {
              debugPrint('Error marking notification read: $e');
            }
          }
        },
        child: GlowCard(
          glowColor: isRead ? null : typeColor,
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isRead ? Colors.transparent : typeColor.withAlpha(((0.02) * 255).round()),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white.withAlpha(((0.04) * 255).round()) : typeColor.withAlpha(((0.08) * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRead ? Icons.notifications_none_rounded : typeIcon,
                    color: isRead ? Colors.white38 : typeColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: isRead ? Colors.white.withAlpha(((0.6) * 255).round()) : Colors.white,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              color: isRead ? Colors.white24 : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message,
                        style: TextStyle(
                          color: isRead ? Colors.white38 : Colors.white70,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (fromUserEmail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'From: $fromUserEmail',
                          style: TextStyle(
                            color: isRead ? Colors.white24 : Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ✅ Unread indicator
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _readCreatedAt(Object? rawData) {
    if (rawData is! Map<String, dynamic>) return DateTime.fromMillisecondsSinceEpoch(0);
    final value = rawData['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.isNegative) {
      return 'Just now';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
