// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class APIService {
  // 🔥 EXCHANGE RATE API
  static const String _exchangeRateApiKey = 'YOUR_EXCHANGE_RATE_API_KEY';
  static const String _exchangeRateBaseUrl = 'https://api.exchangerate-api.com/v4/latest/';
  
  // 🔥 CRYPTO API (Free - No Key Required)
  static const String _cryptoBaseUrl = 'https://api.coingecko.com/api/v3';
  
  // 🔥 GOLD API (Free - No Key Required)
  static const String _goldBaseUrl = 'https://api.gold-api.com/price';
  
  // 🔥 NEWS API
  static const String _newsApiKey = 'YOUR_NEWS_API_KEY';
  static const String _newsBaseUrl = 'https://newsapi.org/v2';

  // ============================================
  // 1. EXCHANGE RATES
  // ============================================
  static Future<Map<String, dynamic>> fetchExchangeRates({String base = 'USD'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_exchangeRateBaseUrl$base'),
        headers: {
          'Authorization': 'Bearer $_exchangeRateApiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'base': data['base'] ?? base,
          'rates': data['rates'] ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch rates: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Fallback to Firestore
      return await _fetchRatesFromFirestore();
    }
  }

  static Future<Map<String, dynamic>> _fetchRatesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('isActive', isEqualTo: true)
          .get();

      final rates = <String, double>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final code = data['code'] ?? '';
        final rate = (data['rate'] ?? 0.0) as double;
        rates[code] = rate;
      }

      return {
        'success': true,
        'base': 'USD',
        'rates': rates,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'firestore',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ============================================
  // 2. CONVERT CURRENCY
  // ============================================
  static Future<double> convertCurrency(
    String from, 
    String to, 
    double amount,
  ) async {
    try {
      final result = await fetchExchangeRates(base: from);
      
      if (result['success'] == true) {
        final rates = result['rates'] as Map<String, dynamic>;
        final rate = rates[to] ?? 0.0;
        return amount * rate;
      }
      
      // Fallback: Firestore se convert karein
      return await _convertFromFirestore(from, to, amount);
    } catch (e) {
      debugPrint('Conversion Error: $e');
      return amount * 278.50; // Fallback rate
    }
  }

  static Future<double> _convertFromFirestore(
    String from, 
    String to, 
    double amount,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('code', whereIn: [from, to])
          .get();

      if (snapshot.docs.length == 2) {
        final fromData = snapshot.docs.firstWhere(
          (doc) => doc.data()['code'] == from,
        ).data();
        final toData = snapshot.docs.firstWhere(
          (doc) => doc.data()['code'] == to,
        ).data();

        final fromRate = (fromData['rate'] ?? 1.0) as double;
        final toRate = (toData['rate'] ?? 1.0) as double;
        
        return amount * (toRate / fromRate);
      }
      return amount;
    } catch (e) {
      debugPrint('Firestore Conversion Error: $e');
      return amount;
    }
  }

  // ============================================
  // 3. CRYPTO RATES
  // ============================================
  static Future<List<Map<String, dynamic>>> fetchCryptoRates() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_cryptoBaseUrl/coins/markets?vs_currency=usd'
          '&ids=bitcoin,ethereum,ripple,solana,cardano,polkadot'
          '&order=market_cap_desc&per_page=10&page=1&sparkline=false'
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return {
            'name': item['name'] ?? 'Unknown',
            'symbol': (item['symbol'] ?? '').toUpperCase(),
            'price': item['current_price'] ?? 0.0,
            'change': item['price_change_percentage_24h'] ?? 0.0,
            'marketCap': item['market_cap'] ?? 0,
            'volume': item['total_volume'] ?? 0,
            'image': item['image'] ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Crypto API Error: $e');
      return _getFallbackCryptoData();
    }
  }

  static List<Map<String, dynamic>> _getFallbackCryptoData() {
    return [
      {'name': 'Bitcoin', 'symbol': 'BTC', 'price': 67500, 'change': 5.2},
      {'name': 'Ethereum', 'symbol': 'ETH', 'price': 3450, 'change': 3.1},
      {'name': 'Ripple', 'symbol': 'XRP', 'price': 2.50, 'change': -1.5},
      {'name': 'Solana', 'symbol': 'SOL', 'price': 145.20, 'change': 8.7},
      {'name': 'Cardano', 'symbol': 'ADA', 'price': 0.68, 'change': -2.3},
      {'name': 'Polkadot', 'symbol': 'DOT', 'price': 7.15, 'change': 4.2},
    ];
  }

  // ============================================
  // 4. GOLD RATES
  // ============================================
  static Future<Map<String, dynamic>> fetchGoldRates() async {
    try {
      final response = await http.get(
        Uri.parse('$_goldBaseUrl/XAU'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'gold': data['price'] ?? 0.0,
          'change': data['change'] ?? 0.0,
          'currency': data['currency'] ?? 'USD',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return _getFallbackGoldData();
    } catch (e) {
      debugPrint('Gold API Error: $e');
      return _getFallbackGoldData();
    }
  }

  static Map<String, dynamic> _getFallbackGoldData() {
    return {
      'success': true,
      'gold': 1850.50,
      'change': 0.5,
      'currency': 'USD',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ============================================
  // 5. MARKET NEWS
  // ============================================
  static Future<List<Map<String, dynamic>>> fetchMarketNews() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_newsBaseUrl/everything?q=currency OR forex OR exchange'
          '&language=en&sortBy=publishedAt&apiKey=$_newsApiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final articles = data['articles'] as List<dynamic>? ?? [];
        
        return articles.map((item) {
          return {
            'title': item['title'] ?? '',
            'description': item['description'] ?? '',
            'source': item['source']['name'] ?? 'Unknown',
            'url': item['url'] ?? '',
            'image': item['urlToImage'] ?? '',
            'publishedAt': item['publishedAt'] ?? '',
          };
        }).toList();
      }
      return _getFallbackNews();
    } catch (e) {
      debugPrint('News API Error: $e');
      return _getFallbackNews();
    }
  }

  static List<Map<String, dynamic>> _getFallbackNews() {
    return [
      {
        'title': 'Dollar strengthens as U.S. inflation cools',
        'description': 'Market impact: Low volatility expected for global USD currency pairs.',
        'source': 'Market News',
        'publishedAt': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Euro rises against major currencies',
        'description': 'EUR shows strong performance amid positive economic data.',
        'source': 'Forex News',
        'publishedAt': DateTime.now().toIso8601String(),
      },
    ];
  }

  // ============================================
  // 6. AI PREDICTIONS
  // ============================================
  static Future<List<Map<String, dynamic>>> fetchAIPredictions() async {
    try {
      final rates = await fetchExchangeRates();
      
      if (rates['success'] == true) {
        final allRates = rates['rates'] as Map<String, dynamic>;
        final predictions = <Map<String, dynamic>>[];
        final currencies = ['PKR', 'EUR', 'GBP', 'AED', 'INR'];
        
        for (var currency in currencies) {
          if (allRates.containsKey(currency)) {
            final rate = allRates[currency] as double;
            final sentiment = _getSentiment(rate);
            final predicted = rate + (rate * 0.01 * _getRandomFactor());
            
            predictions.add({
              'pair': 'USD to $currency',
              'sentiment': sentiment,
              'prediction': predicted.toStringAsFixed(2),
              'timeframe': 'Next 24h',
              'color': _getSentimentColor(sentiment),
            });
          }
        }
        return predictions;
      }
      return _getFallbackPredictions();
    } catch (e) {
      debugPrint('AI Prediction Error: $e');
      return _getFallbackPredictions();
    }
  }

  static String _getSentiment(double rate) {
    final mod = rate % 1;
    if (mod > 0.6) return 'Bullish';
    if (mod > 0.3) return 'Neutral';
    return 'Bearish';
  }

  static Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return Colors.greenAccent;
      case 'Bearish':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  static double _getRandomFactor() {
    return DateTime.now().millisecondsSinceEpoch % 100 / 100;
  }

  static List<Map<String, dynamic>> _getFallbackPredictions() {
    return [
      {'pair': 'USD to PKR', 'sentiment': 'Bullish', 'prediction': '280.00', 'timeframe': 'Next 24h', 'color': Colors.greenAccent},
      {'pair': 'USD to EUR', 'sentiment': 'Neutral', 'prediction': '0.93', 'timeframe': 'Next 24h', 'color': Colors.grey},
      {'pair': 'USD to GBP', 'sentiment': 'Bearish', 'prediction': '0.77', 'timeframe': 'Next 24h', 'color': Colors.redAccent},
    ];
  }

  // ============================================
  // 7. USER TRANSACTIONS
  // ============================================
  static Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('conversions')
          .where('userId', isEqualTo: userId)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'from': data['fromCurrency'] ?? '',
          'to': data['toCurrency'] ?? '',
          'fromAmount': data['fromAmount'] ?? 0.0,
          'toAmount': data['toAmount'] ?? 0.0,
          'rate': data['rate'] ?? 0.0,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Transactions Error: $e');
      return [];
    }
  }

  // ============================================
  // 8. SUBMIT FEEDBACK
  // ============================================
  static Future<bool> submitFeedback(String feedback, {String? userId}) async {
    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'feedback': feedback,
        'userId': userId ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Feedback Error: $e');
      return false;
    }
  }
}
