import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class ParsedSmartAlert {
  final String fromCurrency;
  final String toCurrency;
  final String operator;
  final double targetRate;

  const ParsedSmartAlert({
    required this.fromCurrency,
    required this.toCurrency,
    required this.operator,
    required this.targetRate,
  });

  bool matchesRate({
    required String fromCurrency,
    required String toCurrency,
    required double rate,
  }) {
    if (this.fromCurrency != fromCurrency.toUpperCase()) return false;
    if (this.toCurrency != toCurrency.toUpperCase()) return false;

    switch (operator) {
      case '<=':
      case '<':
        return rate <= targetRate;
      case '=':
      case '==':
        return (rate - targetRate).abs() < 0.0001 || rate >= targetRate;
      case '>=':
      case '>':
      default:
        return rate >= targetRate;
    }
  }
}

class SmartAlertService {
  SmartAlertService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  Future<int> notifyMatchingRateAlerts({
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    String? relatedId,
  }) async {
    final normalizedFrom = fromCurrency.trim().toUpperCase();
    final normalizedTo = toCurrency.trim().toUpperCase();
    var sentCount = 0;

    try {
      final snapshot = await _firestore
          .collection('smartAlerts')
          .where('isEnabled', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId']?.toString() ?? '';
        if (userId.isEmpty) continue;

        final parsed = _parseAlert(data);
        if (parsed == null) continue;
        if (!parsed.matchesRate(
          fromCurrency: normalizedFrom,
          toCurrency: normalizedTo,
          rate: rate,
        )) {
          continue;
        }

        final lastTriggeredRate = _readDouble(data['lastTriggeredRate']);
        if (lastTriggeredRate != null &&
            (lastTriggeredRate - rate).abs() < 0.0001) {
          continue;
        }

        final title = data['title']?.toString().trim();
        await _notificationService.sendNotification(
          userId: userId,
          title: title?.isNotEmpty == true ? title! : 'Smart Rate Alert',
          message:
              '1 $normalizedFrom is now $rate $normalizedTo. Your target was ${parsed.operator} ${parsed.targetRate}.',
          type: 'alert',
          relatedId: relatedId ?? doc.id,
        );

        await doc.reference.update({
          'lastTriggeredAt': FieldValue.serverTimestamp(),
          'lastTriggeredRate': rate,
          'triggerCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        sentCount++;
      }
    } catch (e) {
      debugPrint('Error checking smart rate alerts: $e');
    }

    return sentCount;
  }

  Future<void> notifyNewAlertIfCurrentRateMatches({
    required DocumentReference alertRef,
    required ParsedSmartAlert parsedAlert,
    required String userId,
    required String title,
  }) async {
    if (userId.isEmpty) return;

    try {
      final rateSnapshot = await _firestore
          .collection('exchange_rates')
          .where('fromCurrency', isEqualTo: parsedAlert.fromCurrency)
          .where('toCurrency', isEqualTo: parsedAlert.toCurrency)
          .limit(1)
          .get();

      if (rateSnapshot.docs.isEmpty) return;

      final rate = _readDouble(rateSnapshot.docs.first.data()['rate']);
      if (rate == null) return;

      if (!parsedAlert.matchesRate(
        fromCurrency: parsedAlert.fromCurrency,
        toCurrency: parsedAlert.toCurrency,
        rate: rate,
      )) {
        return;
      }

      await _notificationService.sendNotification(
        userId: userId,
        title: title.trim().isNotEmpty ? title.trim() : 'Smart Rate Alert',
        message:
            '1 ${parsedAlert.fromCurrency} is now $rate ${parsedAlert.toCurrency}. Your target was ${parsedAlert.operator} ${parsedAlert.targetRate}.',
        type: 'alert',
        relatedId: alertRef.id,
      );

      await alertRef.update({
        'lastTriggeredAt': FieldValue.serverTimestamp(),
        'lastTriggeredRate': rate,
        'triggerCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error checking new smart alert current rate: $e');
    }
  }

  ParsedSmartAlert? parseConditionForSave(String title, String condition) {
    return _parseText('$condition $title');
  }

  ParsedSmartAlert? _parseAlert(Map<String, dynamic> data) {
    final fromCurrency = data['fromCurrency']?.toString().toUpperCase();
    final toCurrency = data['toCurrency']?.toString().toUpperCase();
    final targetRate = _readDouble(data['targetRate']);
    final operator = data['operator']?.toString();

    if (fromCurrency != null &&
        fromCurrency.length == 3 &&
        toCurrency != null &&
        toCurrency.length == 3 &&
        targetRate != null) {
      return ParsedSmartAlert(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        operator: operator ?? '>=',
        targetRate: targetRate,
      );
    }

    return _parseText(
      '${data['condition'] ?? ''} ${data['title'] ?? ''}',
    );
  }

  ParsedSmartAlert? _parseText(String value) {
    final text = value.trim().toUpperCase();
    if (text.isEmpty) return null;

    final rateMatches = RegExp(r'\d+(?:\.\d+)?').allMatches(text).toList();
    final rateMatch = rateMatches.isEmpty ? null : rateMatches.last;
    if (rateMatch == null) return null;

    final currencies = RegExp(r'\b[A-Z]{3}\b')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    if (currencies.isEmpty) return null;

    final operatorMatch = RegExp(r'(>=|<=|==|>|<|=)').firstMatch(text);

    return ParsedSmartAlert(
      fromCurrency: currencies.first,
      toCurrency: currencies.length > 1 ? currencies[1] : 'PKR',
      operator: operatorMatch?.group(1) ?? '>=',
      targetRate: double.parse(rateMatch.group(0)!),
    );
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
