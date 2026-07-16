import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String adminEmail = 'admin@currensee.com';
  static const String adminNotificationUserId = 'admin';

  bool _isAdminEmail(String? email) {
    return email?.trim().toLowerCase() == adminEmail;
  }

  String _displayNameFromEmail(String? email) {
    final value = email?.trim();
    if (value == null || value.isEmpty) return 'User';
    return value.split('@').first;
  }

  Future<bool> _currentUserIsAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    if (_isAdminEmail(currentUser.email)) return true;

    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final role = userDoc.data()?['role']?.toString().toLowerCase();
    return role == 'admin';
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? fromUserId,
    String? fromUserEmail,
    String? relatedId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'fromUserId': fromUserId ?? _auth.currentUser?.uid,
        'fromUserEmail': fromUserEmail ?? _auth.currentUser?.email,
        'relatedId': relatedId,
      });
    } catch (e) {
      // Keep app actions from failing if a notification write fails.
      // Firestore/security rule issues are visible in debug console.
      // ignore: avoid_print
      print('Error sending notification: $e');
    }
  }

  Future<void> sendToAdmin({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await sendNotification(
        userId: adminNotificationUserId,
        title: title,
        message: message,
        type: type,
        fromUserId: _auth.currentUser?.uid,
        fromUserEmail: _auth.currentUser?.email,
        relatedId: relatedId,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error sending to admin: $e');
    }
  }

  Future<void> sendUserActivityToAdmin({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      if (await _currentUserIsAdmin()) return;
      await sendToAdmin(
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error sending user activity to admin: $e');
    }
  }

  Future<void> sendToAllUsers({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      final users = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      for (final doc in users.docs) {
        final email = doc.data()['email']?.toString();
        if (_isAdminEmail(email)) continue;

        await sendNotification(
          userId: doc.id,
          title: title,
          message: message,
          type: type,
          fromUserId: _auth.currentUser?.uid,
          fromUserEmail: _auth.currentUser?.email,
          relatedId: relatedId,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error sending to all users: $e');
    }
  }

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    await sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      fromUserId: _auth.currentUser?.uid,
      fromUserEmail: _auth.currentUser?.email,
      relatedId: relatedId,
    );
  }

  Future<void> notifyAdminActionForUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    if (userId.isEmpty) return;
    await sendToUser(
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
    );
  }

  Future<void> notifyCurrentUser({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await sendNotification(
      userId: user.uid,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
    );
  }

  Future<void> notifyGenericUserActivity({
    required String action,
    String? detail,
    String? relatedId,
  }) async {
    final user = _auth.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : _displayNameFromEmail(user?.email);

    await sendUserActivityToAdmin(
      title: 'User Activity',
      message: detail == null || detail.isEmpty
          ? '$name performed: $action'
          : '$name performed: $action\n$detail',
      type: 'user_activity',
      relatedId: relatedId,
    );
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = _readCreatedAt(a.data());
          final bTime = _readCreatedAt(b.data());
          return bTime.compareTo(aTime);
        });

      return docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  DateTime _readCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final isAdmin = await _currentUserIsAdmin();
      final query = isAdmin
          ? _firestore
              .collection('notifications')
              .where('userId', whereIn: [userId, adminNotificationUserId])
              .where('isRead', isEqualTo: false)
          : _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false);

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      // ignore: avoid_print
      print('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final isAdmin = await _currentUserIsAdmin();
      final query = isAdmin
          ? _firestore
              .collection('notifications')
              .where('userId', whereIn: [userId, adminNotificationUserId])
              .where('isRead', isEqualTo: false)
          : _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false);

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting notification: $e');
    }
  }
}
