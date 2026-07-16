import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'currency_details_screen.dart';  // ✅ FIXED IMPORT
import '../../widgets/glow_card.dart';
import '../../core/utils/animation_utils.dart';

class CurrencyListScreen extends StatefulWidget {
  const CurrencyListScreen({super.key});

  @override
  State<CurrencyListScreen> createState() => _CurrencyListScreenState();
}

class _CurrencyListScreenState extends State<CurrencyListScreen> {
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = true;
  final String _baseCurrency = 'USD';
  String _lastUpdated = '';

  static const String _apiKey = 'fc7df44c30c926721ee77270';
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/';

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    _fetchRates();
  }

  Future<void> _loadCurrencies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('isActive', isEqualTo: true)
          .orderBy('code')
          .get();

      setState(() {
        _currencies = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'code': data['code'] ?? '',
            'name': data['name'] ?? '',
            'rate': (data['rate'] ?? 0.0).toString(),
            'symbol': data['symbol'] ?? '\$',
            'flag': data['flag'] ?? '🌍',
            'isActive': data['isActive'] ?? true,
            'id': doc.id,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading currencies: $e');
      setState(() {
        _currencies = [
          {'code': 'USD', 'name': 'United States Dollar', 'rate': '1.00', 'symbol': '\$', 'flag': '🇺🇸', 'isActive': true},
          {'code': 'EUR', 'name': 'Euro', 'rate': '0.92', 'symbol': '€', 'flag': '🇪🇺', 'isActive': true},
          {'code': 'GBP', 'name': 'British Pound', 'rate': '0.78', 'symbol': '£', 'flag': '🇬🇧', 'isActive': true},
          {'code': 'PKR', 'name': 'Pakistani Rupee', 'rate': '278.50', 'symbol': '₨', 'flag': '🇵🇰', 'isActive': true},
          {'code': 'INR', 'name': 'Indian Rupee', 'rate': '83.50', 'symbol': '₹', 'flag': '🇮🇳', 'isActive': true},
          {'code': 'AED', 'name': 'UAE Dirham', 'rate': '3.67', 'symbol': 'د.إ', 'flag': '🇦🇪', 'isActive': true},
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRates() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl$_baseCurrency'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        setState(() {
          _currencies = _currencies.map((currency) {
            final code = currency['code'] as String;
            final rate = rates[code];
            return {
              ...currency,
              'rate': rate != null ? rate.toString() : currency['rate'],
            };
          }).toList();
          
          _lastUpdated = DateTime.now().toString().substring(0, 19);
          _isLoading = false;
        });
      } else {
        await _fetchRatesFromFirestore();
      }
    } catch (e) {
      debugPrint('API Error: $e');
      await _fetchRatesFromFirestore();
    }
  }

  Future<void> _fetchRatesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        final rates = <String, double>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final code = data['code'] ?? '';
          final rate = (data['rate'] ?? 0.0) as double;
          rates[code] = rate;
        }

        _currencies = _currencies.map((currency) {
          final code = currency['code'] as String;
          final rate = rates[code];
          return {
            ...currency,
            'rate': rate != null ? rate.toString() : currency['rate'],
          };
        }).toList();

        _lastUpdated = 'Cached: ${DateTime.now().toString().substring(0, 19)}';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Firestore Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _searchCurrency(String query) {
    setState(() {
      if (query.isEmpty) {
        _loadCurrencies();
      } else {
        final searchTerm = query.toLowerCase();
        _currencies = _currencies.where((currency) {
          final code = (currency['code'] ?? '').toLowerCase();
          final name = (currency['name'] ?? '').toLowerCase();
          return code.contains(searchTerm) || name.contains(searchTerm);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      // backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Exchange Rates (Base 1 USD)',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _fetchRates,
          ),
        ],
      ),
      body: AnimationUtils.fadeInSlide(
        duration: const Duration(milliseconds: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search currency...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withAlpha(((0.05) * 255).round()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _searchCurrency,
              ),
            ),
            
            if (_lastUpdated.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated: $_lastUpdated',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading currencies...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  : _currencies.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.currency_exchange, color: Colors.white24, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'No currencies found',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _currencies.length,
                          itemBuilder: (context, index) {
                            final currency = _currencies[index];
                            return AnimationUtils.fadeInSlide(
                              duration: const Duration(milliseconds: 200),
                              child: _buildCurrencyCard(currency),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(Map<String, dynamic> currency) {
    final code = currency['code'] as String? ?? 'N/A';
    final name = currency['name'] as String? ?? 'Unknown';
    final rate = currency['rate'] as String? ?? '0.00';
    final symbol = currency['symbol'] as String? ?? '\$';
    final flag = currency['flag'] as String? ?? '🌍';
    final isActive = currency['isActive'] as bool? ?? true;

    final rateValue = double.tryParse(rate) ?? 0.0;
    final isUSD = code == 'USD';
    final changePercent = isUSD ? 0.0 : ((rateValue % 1) * 100).roundToDouble();
    final isPositive = changePercent >= 0;

    return GlowCard(
      glowColor: isActive ? const Color(0xFF00E5FF) : Colors.red,
      padding: const EdgeInsets.all(12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F172A),
          child: Text(
            flag,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Row(
          children: [
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            if (!isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(((0.2) * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(color: Colors.red, fontSize: 8),
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isUSD ? '1.00' : '$symbol$rate',
              style: TextStyle(
                color: isUSD ? const Color(0xFF00E5FF) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (!isUSD) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isPositive ? '+$changePercent%' : '$changePercent%',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CurrencyDetailsScreen(
                currencyCode: currency['code'] as String,
                currencyName: currency['name'] as String,
                currencySymbol: currency['symbol'] as String,
                currencyFlag: currency['flag'] as String,
              ),
            ),
          );
        },
      ),
    );
  }
}

