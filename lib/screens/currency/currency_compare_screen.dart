import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';  // ✅ ADDED
// ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED

class CurrencyCompareScreen extends StatefulWidget {
  const CurrencyCompareScreen({super.key}) ;

  @override
  State<CurrencyCompareScreen> createState() => _CurrencyCompareScreenState();
}

class _CurrencyCompareScreenState extends State<CurrencyCompareScreen> {
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _selectedCurrencies = [];
  bool _isLoading = true;
  String _baseCurrency = 'USD';
  Map<String, double> _rates = {};

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

      if (mounted) {
        setState(() {
          _currencies = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'code': data['code'] ?? '',
              'name': data['name'] ?? '',
              'rate': data['rate'] ?? 0.0,
              'flag': data['flag'] ?? '🌍',
            };
          }).toList();

          _selectedCurrencies = _currencies
              .where((c) => c['code'] == 'USD' || c['code'] == 'EUR')
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading currencies: $e');
      if (mounted) {
        setState(() {
          _currencies = [
            {'code': 'USD', 'name': 'United States Dollar', 'rate': 1.0, 'flag': '🇺🇸'},
            {'code': 'EUR', 'name': 'Euro', 'rate': 0.92, 'flag': '🇪🇺'},
            {'code': 'GBP', 'name': 'British Pound', 'rate': 0.78, 'flag': '🇬🇧'},
            {'code': 'PKR', 'name': 'Pakistani Rupee', 'rate': 278.50, 'flag': '🇵🇰'},
            {'code': 'AED', 'name': 'UAE Dirham', 'rate': 3.67, 'flag': '🇦🇪'},
            {'code': 'INR', 'name': 'Indian Rupee', 'rate': 83.12, 'flag': '🇮🇳'},
          ];
          _selectedCurrencies = _currencies
              .where((c) => c['code'] == 'USD' || c['code'] == 'EUR')
              .toList();
        });
      }
    }
  }

  Future<void> _fetchRates() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl$_baseCurrency'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _rates = {};
            rates.forEach((key, value) {
              _rates[key] = (value as num).toDouble();
            });
            _isLoading = false;
          });
        }
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

      if (mounted) {
        setState(() {
          _rates = {};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final code = data['code'] ?? '';
            final rate = (data['rate'] ?? 0.0) as double;
            _rates[code] = rate;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Firestore Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addCurrencyToCompare(String code) {
    final currency = _currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'code': '', 'name': '', 'rate': 0.0, 'flag': '🌍'},
    );

    if (currency['code'] != '' && !_selectedCurrencies.any((c) => c['code'] == code)) {
      setState(() {
        _selectedCurrencies.add(currency);
      });
    }
  }

  void _removeCurrency(String code) {
    setState(() {
      _selectedCurrencies.removeWhere((c) => c['code'] == code);
      if (_baseCurrency == code && _selectedCurrencies.isNotEmpty) {
        _baseCurrency = _selectedCurrencies.first['code'];
        _fetchRates();
      }
    });
  }

  void _showAddCurrencyDialog() {
    final availableCurrencies = _currencies
        .where((c) => !_selectedCurrencies.any((s) => s['code'] == c['code']))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(((0.5) * 255).round()),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 450,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withAlpha(((0.75) * 255).round()),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withAlpha(((0.1) * 255).round())),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Currency to Compare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: availableCurrencies.isEmpty
                      ? const Center(
                          child: Text(
                            'All currencies added',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: availableCurrencies.length,
                          itemBuilder: (context, index) {
                            final currency = availableCurrencies[index];
                            final code = currency['code'] as String;
                            final name = currency['name'] as String;
                            final flag = currency['flag'] as String;

                            return AnimationUtils.fadeInSlide(  // ✅ ANIMATION
                              duration: const Duration(milliseconds: 300),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Text(flag, style: const TextStyle(fontSize: 28)),
                                title: Text(
                                  code,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  name,
                                  style: const TextStyle(color: Color(0xFF8A99AD)),
                                ),
                                trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF), size: 22),
                                onTap: () {
                                  _addCurrencyToCompare(code);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getConvertedRate(String fromCode, String toCode) {
    final fromRate = _rates[fromCode] ?? 1.0;
    final toRate = _rates[toCode] ?? 1.0;
    return toRate / fromRate;
  }

  String _formatRate(double rate) {
    return rate >= 1 ? rate.toStringAsFixed(2) : rate.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(((0.03) * 255).round()),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'Compare Currencies',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF00E5FF)),
            onPressed: _showAddCurrencyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _fetchRates,
          ),
        ],
      ),
      body: AnimationUtils.fadeInSlide(  // ✅ WRAPPED WITH ANIMATION
        duration: const Duration(milliseconds: 500),
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
                      'Loading premium rates...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
            : _selectedCurrencies.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.compare_arrows_rounded, color: Colors.white24, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Add currencies to compare',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GlowCard(  // ✅ GLOW CARD
                        glowColor: const Color(0xFF00E5FF),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.tune_rounded, color: Color(0xFF00E5FF), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Base Focus Currency:',
                                  style: TextStyle(color: Color(0xFF8A99AD), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _baseCurrency,
                                dropdownColor: const Color(0xFF0F172A).withAlpha(((0.95) * 255).round()),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00E5FF)),
                                items: _selectedCurrencies.map((c) {
                                  return DropdownMenuItem(
                                    value: c['code'] as String,
                                    child: Text('${c['flag']}  ${c['code']}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _baseCurrency = value;
                                    });
                                    _fetchRates();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Cross-Rate Matrix',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._selectedCurrencies.map((currency) {
                        final code = currency['code'] as String;
                        final name = currency['name'] as String;
                        final flag = currency['flag'] as String;
                        final isBase = code == _baseCurrency;

                        return AnimationUtils.fadeInSlide(  // ✅ ANIMATION
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: GlowCard(  // ✅ GLOW CARD
                              glowColor: isBase ? const Color(0xFF00E5FF) : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isBase ? const Color(0xFF00E5FF).withAlpha(((0.04) * 255).round()) : Colors.transparent,
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(flag, style: const TextStyle(fontSize: 30)),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      code,
                                                      style: TextStyle(
                                                        color: isBase ? const Color(0xFF00E5FF) : Colors.white,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (isBase) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF00E5FF).withAlpha(((0.15) * 255).round()),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'BASE',
                                                          style: TextStyle(
                                                            color: Color(0xFF00E5FF),
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: Color(0xFF8A99AD),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (_selectedCurrencies.length > 2)
                                          IconButton(
                                            alignment: Alignment.centerRight,
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.remove_circle_outline_rounded,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            onPressed: () => _removeCurrency(code),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(color: Colors.white10, height: 1),
                                    const SizedBox(height: 12),

                                    ..._selectedCurrencies
                                        .where((c) => c['code'] != code)
                                        .map((other) {
                                      final otherCode = other['code'] as String;
                                      final otherFlag = other['flag'] as String;
                                      final rate = _getConvertedRate(code, otherCode);

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(otherFlag, style: const TextStyle(fontSize: 18)),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '1 $code = ',
                                                  style: TextStyle(color: Colors.white.withAlpha(((0.6) * 255).round()), fontSize: 13),
                                                ),
                                                Text(
                                                  '${_formatRate(rate)} $otherCode',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: rate >= 1
                                                    ? Colors.green.withAlpha(((0.15) * 255).round())
                                                    : Colors.redAccent.withAlpha(((0.15) * 255).round()),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                rate >= 1 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                                color: rate >= 1 ? Colors.green : Colors.redAccent,
                                                size: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      if (_selectedCurrencies.length < _currencies.length)
                        Center(
                          child: TextButton.icon(
                            onPressed: _showAddCurrencyDialog,
                            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00E5FF)),
                            label: const Text(
                              'Add Asset to Matrix',
                              style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

