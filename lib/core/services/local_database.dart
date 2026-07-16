// lib/core/services/local_database.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocalDatabaseService {
  static late SharedPreferences _prefs;

  // ============================================
  // INIT
  // ============================================
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Local database initialized');
  }

  // ============================================
  // 1. SAVE & GET DATA
  // ============================================
  
  /// Save any data to local storage
  static Future<void> saveLocalData(String key, dynamic value) async {
    try {
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is List || value is Map) {
        await _prefs.setString(key, jsonEncode(value));
      }
      debugPrint('✅ Data saved: $key');
    } catch (e) {
      debugPrint('❌ Error saving data: $e');
      rethrow;
    }
  }

  /// Get data from local storage
  static Future<dynamic> getLocalData(String key) async {
    try {
      final value = _prefs.get(key);
      if (value == null) return null;
      
      // Try to parse JSON if it's a string that looks like JSON
      if (value is String && (value.startsWith('{') || value.startsWith('['))) {
        try {
          return jsonDecode(value);
        } catch (_) {
          return value;
        }
      }
      return value;
    } catch (e) {
      debugPrint('❌ Error getting data: $e');
      return null;
    }
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Remove data
  static Future<void> removeData(String key) async {
    try {
      await _prefs.remove(key);
      debugPrint('✅ Data removed: $key');
    } catch (e) {
      debugPrint('❌ Error removing data: $e');
      rethrow;
    }
  }

  // ============================================
  // 2. CURRENCY RATES (Offline Cache)
  // ============================================
  
  /// Cache conversion rates for offline use
  static Future<void> cacheConversionRates(Map<String, double> rates) async {
    try {
      final jsonString = jsonEncode(rates);
      await _prefs.setString('cachedRates', jsonString);
      await _prefs.setString('cachedRatesTimestamp', DateTime.now().toIso8601String());
      debugPrint('✅ Rates cached: ${rates.length} currencies');
    } catch (e) {
      debugPrint('❌ Error caching rates: $e');
      rethrow;
    }
  }

  /// Get cached rates
  static Future<Map<String, double>> getCachedRates() async {
    try {
      final jsonString = _prefs.getString('cachedRates');
      if (jsonString == null) return {};
      
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      debugPrint('❌ Error getting cached rates: $e');
      return {};
    }
  }

  /// Get cached rates timestamp
  static DateTime? getCachedRatesTimestamp() {
    final timestamp = _prefs.getString('cachedRatesTimestamp');
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Check if cache is valid (not older than 1 hour)
  static bool isCacheValid() {
    final timestamp = getCachedRatesTimestamp();
    if (timestamp == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes < 60; // 1 hour valid
  }

  // ============================================
  // 3. CONVERSION HISTORY (Local)
  // ============================================
  
  /// Save conversion transaction locally
  static Future<void> saveConversionHistory(Map<String, dynamic> transaction) async {
    try {
      final history = await getLocalHistory();
      history.insert(0, {
        ...transaction,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 100 transactions
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }
      
      await _prefs.setString('localHistory', jsonEncode(history));
      debugPrint('✅ Transaction saved locally');
    } catch (e) {
      debugPrint('❌ Error saving transaction: $e');
      rethrow;
    }
  }

  /// Get local transaction history
  static Future<List<Map<String, dynamic>>> getLocalHistory() async {
    try {
      final jsonString = _prefs.getString('localHistory');
      if (jsonString == null) return [];
      
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('❌ Error getting local history: $e');
      return [];
    }
  }

  /// Clear local history
  static Future<void> clearLocalHistory() async {
    try {
      await _prefs.remove('localHistory');
      debugPrint('✅ Local history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing history: $e');
      rethrow;
    }
  }

  // ============================================
  // 4. USER PREFERENCES
  // ============================================
  
  /// Save user preferences
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final jsonString = jsonEncode(preferences);
      await _prefs.setString('userPreferences', jsonString);
      debugPrint('✅ User preferences saved');
    } catch (e) {
      debugPrint('❌ Error saving preferences: $e');
      rethrow;
    }
  }

  /// Get user preferences
  static Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final jsonString = _prefs.getString('userPreferences');
      if (jsonString == null) return {};
      
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('❌ Error getting preferences: $e');
      return {};
    }
  }

  // ============================================
  // 5. CLEAR ALL DATA
  // ============================================
  
  /// Clear all local data
  static Future<void> clearLocalData() async {
    try {
      await _prefs.clear();
      debugPrint('✅ All local data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      rethrow;
    }
  }

  /// Clear specific section
  static Future<void> clearSection(String section) async {
    try {
      final keys = _prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith(section)) {
          await _prefs.remove(key);
        }
      }
      debugPrint('✅ Section cleared: $section');
    } catch (e) {
      debugPrint('❌ Error clearing section: $e');
      rethrow;
    }
  }

  // ============================================
  // 6. UTILITY
  // ============================================
  
  /// Get all keys
  static Set<String> getAllKeys() {
    return _prefs.getKeys();
  }

  /// Get storage size estimate
  static int getStorageSize() {
    return _prefs.getKeys().length;
  }
}
