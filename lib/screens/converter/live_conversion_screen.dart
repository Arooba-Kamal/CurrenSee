import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';
import '../../core/utils/animation_utils.dart';

class LiveConversionScreen extends StatefulWidget {
  const LiveConversionScreen({super.key});

  @override
  State<LiveConversionScreen> createState() => _LiveConversionScreenState();
}

class _LiveConversionScreenState extends State<LiveConversionScreen>
    with SingleTickerProviderStateMixin {
  String _rate = 'Loading...';
  String _lastUpdated = 'Just now';
  bool _isLoading = true;
  bool _isLive = false;
  String _source = 'Initializing...';

  // ✅ API Configuration
  static const String _apiKey = 'fc7df44c30c926721ee77270';
  static const String _apiUrl = 'https://v6.exchangerate-api.com/v6/$_apiKey/latest/USD';
  
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _fetchLiveRate();
    
    // ✅ Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _fetchLiveRate();
    });
    
    // ✅ Pulse animation for live indicator
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

  Future<void> _fetchLiveRate() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      print('🌐 Fetching from: $_apiUrl');
      
      final response = await http.get(
        Uri.parse(_apiUrl),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Request timeout');
          throw Exception('Connection timeout');
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Response received successfully');
        
        // ✅ Check if API returned success
        if (data['result'] == 'success') {
          final rates = data['conversion_rates'] as Map<String, dynamic>;
          final pkrRate = rates['PKR'] as double? ?? 278.50;
          final baseCode = data['base_code'] ?? 'USD';
          
          if (mounted) {
            setState(() {
              _rate = '1 $baseCode = ${pkrRate.toStringAsFixed(2)} PKR';
              _lastUpdated = _getFormattedTime();
              _isLoading = false;
              _isLive = true;
              _source = 'Live API';
              _retryCount = 0;
            });
          }
          
          // ✅ Cache to Firestore
          await _saveToFirestore(pkrRate);
        } else {
          // API returned error
          final errorType = data['error-type'] ?? 'Unknown error';
          print('❌ API Error: $errorType');
          await _fetchFromFirestore();
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        await _fetchFromFirestore();
      }
    } catch (e) {
      print('❌ Exception: $e');
      
      // ✅ Retry logic
      if (_retryCount < _maxRetries) {
        _retryCount++;
        print('🔄 Retry $_retryCount/$_maxRetries');
        await Future.delayed(Duration(seconds: _retryCount * 2));
        await _fetchLiveRate();
      } else {
        await _fetchFromFirestore();
      }
    }
  }

  String _getFormattedTime() {
    final now = DateTime.now().toLocal();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _saveToFirestore(double rate) async {
    try {
      await FirebaseFirestore.instance
          .collection('currencies')
          .doc('PKR')
          .set({
            'code': 'PKR',
            'rate': rate,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      print('✅ Cached to Firestore: $rate');
    } catch (e) {
      print('⚠️ Firestore cache error: $e');
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      print('📂 Fetching from Firestore...');
      final doc = await FirebaseFirestore.instance
          .collection('currencies')
          .doc('PKR')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final pkrRate = (data['rate'] ?? 278.50).toDouble();
        
        if (mounted) {
          setState(() {
            _rate = '1 USD = ${pkrRate.toStringAsFixed(2)} PKR';
            _lastUpdated = 'Cached';
            _isLoading = false;
            _isLive = false;
            _source = 'Cached Data';
            _retryCount = 0;
          });
        }
        print('✅ Loaded from Firestore: $pkrRate');
      } else {
        _setDefaultRates();
      }
    } catch (e) {
      print('❌ Firestore Error: $e');
      _setDefaultRates();
    }
  }

  void _setDefaultRates() {
    if (mounted) {
      setState(() {
        _rate = '1 USD = 278.50 PKR';
        _lastUpdated = 'Offline';
        _isLoading = false;
        _isLive = false;
        _source = 'Offline Data';
        _retryCount = 0;
      });
    }
    print('📌 Using default rates');
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
          'Live Conversion',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _fetchLiveRate,
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
                    'Fetching live insights...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : AnimationUtils.fadeInSlide(
              duration: const Duration(milliseconds: 500),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // ✅ Main Rate Card with Live Status
                  GlowCard(
                    glowColor: _isLive ? const Color(0xFF00E5FF) : Colors.amber,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Live Exchange Rate',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
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
                                  Icon(
                                    _isLive ? Icons.online_prediction_rounded : Icons.history_rounded, 
                                    color: _isLive ? Colors.green : Colors.amber, 
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isLive ? 'Live' : 'Cached',
                                    style: TextStyle(
                                      color: _isLive ? Colors.green : Colors.amberAccent, 
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _rate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Updated: $_lastUpdated',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Source: $_source',
                              style: TextStyle(
                                color: _isLive ? Colors.green : Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // ✅ Live Stream Status Card
                  GlowCard(
                    glowColor: _isLive ? const Color(0xFF00E5FF) : Colors.grey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isLive ? Colors.green : Colors.grey,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isLive ? Colors.green : Colors.grey).withAlpha(((0.5) * 255).round()),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isLive ? '🟢 Live Stream Active' : '⏸️ Stream Paused',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    _isLive 
                                        ? 'Auto-refresh every 30 seconds' 
                                        : 'Using cached data (Offline mode)',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(((0.4) * 255).round()),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.analytics_outlined,
                              color: const Color(0xFF00E5FF).withAlpha(((0.6) * 255).round()),
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _isLive ? 1.0 : 0.5,
                          backgroundColor: Colors.white.withAlpha(((0.1) * 255).round()),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'System Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ✅ Grid Stats
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildStatItem(
                        'Engine Version',
                        'v6 (Latest)',
                        Icons.code_rounded,
                      ),
                      _buildStatItem(
                        'Base Currency',
                        'USD 🇺🇸',
                        Icons.attach_money_rounded,
                      ),
                      _buildStatItem(
                        'Target Feed',
                        'PKR 🇵🇰',
                        Icons.currency_exchange_rounded,
                      ),
                      _buildStatItem(
                        'Sync Status',
                        _isLive ? 'Active' : 'Cached',
                        _isLive ? Icons.wifi_rounded : Icons.signal_cellular_off_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ✅ Retry Button (if offline)
                  if (!_isLive)
                    Center(
                      child: TextButton.icon(
                        onPressed: _fetchLiveRate,
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
                        label: const Text(
                          'Retry Live Connection',
                          style: TextStyle(color: Color(0xFF00E5FF)),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(((0.05) * 255).round()),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return GlowCard(
      glowColor: const Color(0xFF00E5FF),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}