import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? userId;
  final bool includeAdminBroadcast;
  final bool showCount;

  const NotificationBadge({
    super.key,
    required this.child,
    this.onTap,
    this.userId,
    this.includeAdminBroadcast = false,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return GestureDetector(onTap: onTap, child: child);
    }

    final notificationUserIds = {
      resolvedUserId,
      if (includeAdminBroadcast) NotificationService.adminNotificationUserId,
    }.toList();
    final stream = includeAdminBroadcast
        ? FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', whereIn: notificationUserIds)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: resolvedUserId)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final unreadCount = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['isRead'] != true;
        }).length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: child,
            ),
            if (unreadCount > 0)
              Positioned(
                right: showCount ? -10 : -3,
                top: showCount ? -8 : -3,
                child: showCount
                    ? _CountPill(count: unreadCount)
                    : const _UnreadDot(),
              ),
          ],
        );
      },
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF060B13), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withAlpha(((0.35) * 255).round()),
            blurRadius: 8,
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF060B13), width: 1.5),
      ),
    );
  }
}
