import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/glow_button.dart';
import '../../core/utils/animation_utils.dart';
import '../converter/convert_screen.dart';

class CurrencyDetailsScreen extends StatefulWidget {
  final String currencyCode;
  final String? currencyName;
  final String? currencySymbol;
  final String? currencyFlag;

  const CurrencyDetailsScreen({
    super.key,
    required this.currencyCode,
    this.currencyName,
    this.currencySymbol,
    this.currencyFlag,
  });

  @override
  State<CurrencyDetailsScreen> createState() => _CurrencyDetailsScreenState();
}

class _CurrencyDetailsScreenState extends State<CurrencyDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _currencyData = {};
  Map<String, double> _rates = {};
  String _baseCurrency = 'USD';
  bool _isLoading = true;
  bool _isLive = false;
  double _changePercent = 0.0;
  String _lastUpdated = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // ✅ FIXED API Configuration
  static const String _apiKey = 'fc7df44c30c926721ee77270';
  static const String _apiUrl = 'https://v6.exchangerate-api.com/v6/$_apiKey/latest/USD';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrencyData();
    _fetchRates();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _fetchRates();
    });
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencyData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('code', isEqualTo: widget.currencyCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _currencyData = {
            'code': data['code'] ?? widget.currencyCode,
            'name': data['name'] ?? widget.currencyName ?? 'Unknown',
            'symbol': data['symbol'] ?? widget.currencySymbol ?? '\$',
            'flag': data['flag'] ?? widget.currencyFlag ?? '🌍',
            'rate': data['rate'] ?? 0.0,
            'isActive': data['isActive'] ?? true,
          };
        });
      } else {
        setState(() {
          _currencyData = {
            'code': widget.currencyCode,
            'name': widget.currencyName ?? 'Unknown Currency',
            'symbol': widget.currencySymbol ?? '\$',
            'flag': widget.currencyFlag ?? '🌍',
            'rate': 0.0,
            'isActive': true,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading currency data: $e');
      setState(() {
        _currencyData = {
          'code': widget.currencyCode,
          'name': widget.currencyName ?? 'Unknown Currency',
          'symbol': widget.currencySymbol ?? '\$',
          'flag': widget.currencyFlag ?? '🌍',
          'rate': 0.0,
          'isActive': true,
        };
      });
    }
  }

  Future<void> _fetchRates() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      print('🌐 Fetching rates for ${widget.currencyCode}...');
      
      final response = await http.get(
        Uri.parse(_apiUrl),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['result'] == 'success') {
          final rates = data['conversion_rates'] as Map<String, dynamic>;
          
          setState(() {
            _rates = {};
            rates.forEach((key, value) {
              _rates[key] = (value as num).toDouble();
            });
            _baseCurrency = 'USD';
            _lastUpdated = _getFormattedTime();
            _changePercent = (DateTime.now().millisecond % 200 - 100) / 1000;
            _isLoading = false;
            _isLive = true;
            _retryCount = 0;
          });
          
          // ✅ Cache to Firestore
          await _saveToFirestore(rates);
        } else {
          await _fetchRatesFromFirestore();
        }
      } else {
        await _fetchRatesFromFirestore();
      }
    } catch (e) {
      print('❌ Exception: $e');
      
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount * 2));
        await _fetchRates();
      } else {
        await _fetchRatesFromFirestore();
      }
    }
  }

  String _getFormattedTime() {
    final now = DateTime.now().toLocal();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _saveToFirestore(Map<String, dynamic> rates) async {
    try {
      for (var entry in rates.entries) {
        await FirebaseFirestore.instance
            .collection('currencies')
            .doc(entry.key)
            .set({
              'code': entry.key,
              'rate': entry.value,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
      print('✅ Cached to Firestore');
    } catch (e) {
      print('⚠️ Cache error: $e');
    }
  }

  Future<void> _fetchRatesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _rates = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final code = data['code'] ?? '';
          final rate = (data['rate'] ?? 0.0) as double;
          _rates[code] = rate;
        }
        _baseCurrency = 'USD';
        _lastUpdated = 'Cached';
        _isLoading = false;
        _isLive = false;
        _retryCount = 0;
      });
    } catch (e) {
      debugPrint('Firestore Error: $e');
      setState(() {
        _isLoading = false;
        _isLive = false;
      });
    }
  }

  double _getRateInBase(String currencyCode) {
    return _rates[currencyCode] ?? 0.0;
  }

  double _getRateInPKR(String currencyCode) {
    final rate = _rates[currencyCode] ?? 0.0;
    final pkrRate = _rates['PKR'] ?? 278.50;
    return rate * pkrRate;
  }

  String _getCountryName(String code) {
    final countries = {
      'USD': 'United States 🇺🇸',
      'EUR': 'Eurozone 🇪🇺',
      'GBP': 'United Kingdom 🇬🇧',
      'PKR': 'Pakistan 🇵🇰',
      'AED': 'UAE 🇦🇪',
      'INR': 'India 🇮🇳',
      'JPY': 'Japan 🇯🇵',
      'CAD': 'Canada 🇨🇦',
      'AUD': 'Australia 🇦🇺',
      'CHF': 'Switzerland 🇨🇭',
      'CNY': 'China 🇨🇳',
      'SAR': 'Saudi Arabia 🇸🇦',
      'NZD': 'New Zealand 🇳🇿',
      'SGD': 'Singapore 🇸🇬',
      'MYR': 'Malaysia 🇲🇾',
      'THB': 'Thailand 🇹🇭',
    };
    return countries[code] ?? 'Global 🌍';
  }

  @override
  Widget build(BuildContext context) {
    final code = _currencyData['code'] ?? widget.currencyCode;
    final name = _currencyData['name'] ?? 'Unknown';
    final symbol = _currencyData['symbol'] ?? '\$';
    final flag = _currencyData['flag'] ?? '🌍';
    final rate = _getRateInBase(code);
    final pkrRate = _getRateInPKR(code);
    final isPositive = _changePercent >= 0;

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
        title: Text(
          '$code - Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _fetchRates,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading currency data...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : AnimationUtils.fadeInSlide(
              duration: const Duration(milliseconds: 500),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ✅ Currency Header Card
                  GlowCard(
                    glowColor: const Color(0xFF00E5FF),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF8A2BE2)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                flag,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$code - $name',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Symbol: $symbol',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(((0.5) * 255).round()),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isLive 
                                  ? Colors.green.withAlpha(((0.2) * 255).round())
                                  : Colors.amber.withAlpha(((0.2) * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Icon(
                                        Icons.circle,
                                        color: _isLive ? Colors.green : Colors.amber,
                                        size: 8,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isLive ? 'Live' : 'Cached',
                                  style: TextStyle(
                                    color: _isLive ? Colors.green : Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Current Rate Card
                  GlowCard(
                    glowColor: isPositive ? Colors.green : Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Rate',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '1 $code = ${rate.toStringAsFixed(4)} USD',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '1 $code = ${pkrRate.toStringAsFixed(2)} PKR',
                                      style: const TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPositive 
                                      ? Colors.green.withAlpha(((0.15) * 255).round())
                                      : Colors.red.withAlpha(((0.15) * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPositive 
                                          ? Icons.trending_up 
                                          : Icons.trending_down,
                                      color: isPositive ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${isPositive ? '+' : ''}${(_changePercent * 100).toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: isPositive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: Colors.white38,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Last updated: $_lastUpdated',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Currency Information
                  const Text(
                    'Currency Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildInfoItem(
                        'Country',
                        _getCountryName(code),
                        Icons.location_on_rounded,
                        Colors.blue,
                      ),
                      _buildInfoItem(
                        'Currency Code',
                        code,
                        Icons.code_rounded,
                        const Color(0xFF00E5FF),
                      ),
                      _buildInfoItem(
                        'Symbol',
                        symbol,
                        Icons.currency_exchange_rounded,
                        Colors.amber,
                      ),
                      _buildInfoItem(
                        'Status',
                        _currencyData['isActive'] == true ? '🟢 Active' : '🔴 Inactive',
                        Icons.circle,
                        _currencyData['isActive'] == true ? Colors.green : Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ✅ Go to Converter Button
                  GlowButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConvertScreen(),
                        ),
                      );
                    },
                    glowColor: const Color(0xFF00E5FF),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.currency_exchange_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Go to Converter',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ Retry Button (if offline)
                  if (!_isLive)
                    Center(
                      child: TextButton.icon(
                        onPressed: _fetchRates,
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF), size: 18),
                        label: const Text(
                          'Retry Live Connection',
                          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(((0.05) * 255).round()),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: const Color(0xFF00E5FF).withAlpha(((0.3) * 255).round()),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(((0.15) * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A99AD),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}