import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadUnreadCount(String userId) async {
    if (userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _unreadCount = await _notificationService.getUnreadCount(userId);
    } catch (e) {
      _unreadCount = 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  void incrementUnreadCount() {
    _unreadCount++;
    notifyListeners();
  }

  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }
}