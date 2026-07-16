// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================
  // 1. USER DATA
  // ============================================
  
  /// Save user data to Firestore
  static Future<void> saveUserData(Map<String, dynamic> data) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      await _firestore.collection('users').doc(userId).set(
        data,
        SetOptions(merge: true),
      );
      debugPrint('✅ User data saved: $userId');
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
      rethrow;
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  /// Get current user data
  static Future<UserModel?> getCurrentUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;
      
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      return null;
    }
  }

  // ============================================
  // 2. CURRENCY RATES
  // ============================================
  
  /// Update currency rates in Firestore
  static Future<void> updateCurrencyRates(Map<String, double> rates) async {
    try {
      final batch = _firestore.batch();
      
      for (var entry in rates.entries) {
        final docRef = _firestore.collection('currencies').doc(entry.key);
        batch.set(docRef, {
          'code': entry.key,
          'rate': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      await batch.commit();
      debugPrint('✅ Currency rates updated');
    } catch (e) {
      debugPrint('❌ Error updating currency rates: $e');
      rethrow;
    }
  }

  /// Get all currency rates
  static Future<Map<String, double>> getCurrencyRates() async {
    try {
      final snapshot = await _firestore
          .collection('currencies')
          .where('isActive', isEqualTo: true)
          .get();
      
      final rates = <String, double>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        rates[data['code'] ?? ''] = (data['rate'] ?? 0.0) as double;
      }
      return rates;
    } catch (e) {
      debugPrint('❌ Error getting currency rates: $e');
      return {};
    }
  }

  // ============================================
  // 3. CONVERSION HISTORY
  // ============================================
  
  /// Get conversion history for user
  static Future<List<Map<String, dynamic>>> getConversionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('conversions')
          .where('userId', isEqualTo: userId)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'fromCurrency': data['fromCurrency'] ?? '',
          'toCurrency': data['toCurrency'] ?? '',
          'fromAmount': data['fromAmount'] ?? 0.0,
          'toAmount': data['toAmount'] ?? 0.0,
          'rate': data['rate'] ?? 0.0,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting conversion history: $e');
      return [];
    }
  }

  /// Save conversion to history
  static Future<void> saveConversion(Map<String, dynamic> data) async {
    try {
      final doc = await _firestore.collection('conversions').add({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await NotificationService().notifyGenericUserActivity(
        action: 'currency conversion',
        detail:
            '${data['fromAmount'] ?? ''} ${data['fromCurrency'] ?? ''} to ${data['toCurrency'] ?? ''}',
        relatedId: doc.id,
      );
      debugPrint('✅ Conversion saved');
    } catch (e) {
      debugPrint('❌ Error saving conversion: $e');
      rethrow;
    }
  }

  // ============================================
  // 4. ALERTS
  // ============================================
  
  /// Save alert to Firestore
  static Future<void> saveAlert(Map<String, dynamic> alertData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      await _firestore.collection('alerts').add({
        ...alertData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      await NotificationService().notifyGenericUserActivity(
        action: 'created an alert',
        detail: alertData['title']?.toString(),
      );
      debugPrint('✅ Alert saved');
    } catch (e) {
      debugPrint('❌ Error saving alert: $e');
      rethrow;
    }
  }

  /// Get user alerts
  static Future<List<Map<String, dynamic>>> getUserAlerts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('alerts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting alerts: $e');
      return [];
    }
  }

  // ============================================
  // 5. FEEDBACK
  // ============================================
  
  /// Submit user feedback
  static Future<void> submitFeedback(String feedback) async {
    try {
      final userId = _auth.currentUser?.uid;
      await _firestore.collection('feedbacks').add({
        'feedback': feedback,
        'userId': userId ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await NotificationService().notifyGenericUserActivity(
        action: 'submitted feedback',
        detail: feedback.length > 80 ? '${feedback.substring(0, 80)}...' : feedback,
      );
      debugPrint('✅ Feedback submitted');
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      rethrow;
    }
  }

  // ============================================
  // 6. FAVORITE PAIRS
  // ============================================
  
  /// Add favorite currency pair
  static Future<void> addFavoritePair(String from, String to) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      final doc = await _firestore.collection('favoritePairs').add({
        'userId': userId,
        'from': from,
        'to': to,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await NotificationService().notifyGenericUserActivity(
        action: 'added a favorite pair',
        detail: '$from to $to',
        relatedId: doc.id,
      );
      debugPrint('✅ Favorite pair added');
    } catch (e) {
      debugPrint('❌ Error adding favorite pair: $e');
      rethrow;
    }
  }

  /// Get favorite pairs
  static Future<List<Map<String, dynamic>>> getFavoritePairs() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('favoritePairs')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'from': data['from'] ?? '',
          'to': data['to'] ?? '',
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting favorite pairs: $e');
      return [];
    }
  }

  // ============================================
  // 7. DELETE DATA
  // ============================================
  
  /// Delete user data from Firestore
  static Future<void> deleteUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      debugPrint('✅ User data deleted: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      rethrow;
    }
  }

  /// Delete alert
  static Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).delete();
      debugPrint('✅ Alert deleted: $alertId');
    } catch (e) {
      debugPrint('❌ Error deleting alert: $e');
      rethrow;
    }
  }

  // ============================================
  // 8. BATCH OPERATIONS
  // ============================================
  
  /// Batch write multiple operations
  static Future<void> batchWrite(List<Future<void>> operations) async {
    try {
      await Future.wait(operations);
      debugPrint('✅ Batch write completed');
    } catch (e) {
      debugPrint('❌ Error in batch write: $e');
      rethrow;
    }
  }
}
