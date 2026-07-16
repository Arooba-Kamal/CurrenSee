import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'approved', 'rejected', 'delivered', 'info', 'alert'
  final bool isRead;
  final DateTime createdAt;
  final String? fromUserId;
  final String? fromUserEmail;
  final String? relatedId; // productId, conversionId, etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.fromUserId,
    this.fromUserEmail,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
      'fromUserId': fromUserId,
      'fromUserEmail': fromUserEmail,
      'relatedId': relatedId,
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fromUserId: data['fromUserId'],
      fromUserEmail: data['fromUserEmail'],
      relatedId: data['relatedId'],
    );
  }
}