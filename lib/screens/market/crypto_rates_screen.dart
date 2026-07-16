import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/glass_card.dart'; // Aapka personalized UI module wrapper

class CryptoRatesScreen extends StatefulWidget {
  const CryptoRatesScreen({super.key}) ;

  @override
  State<CryptoRatesScreen> createState() => _CryptoRatesScreenState();
}

class _CryptoRatesScreenState extends State<CryptoRatesScreen> {
  List<Map<String, dynamic>> _cryptoData = [];
  bool _isLoading = true;

  // 🔥 COINGECKO API (Free, No API Key Required)
  static const String _apiUrl = 'https://api.coingecko.com/api/v3/coins/markets';
  static const String _vsCurrency = 'usd';

  @override
  void initState() {
    super.initState();
    _fetchCryptoRates();
  }

  Future<void> _fetchCryptoRates() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          '$_apiUrl?vs_currency=$_vsCurrency&ids=bitcoin,ethereum,ripple,solana,cardano,polkadot&order=market_cap_desc&per_page=10&page=1&sparkline=false'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        
        setState(() {
          _cryptoData = data.map((item) {
            return {
              'name': item['name'] ?? 'Unknown',
              'symbol': (item['symbol'] ?? 'btc').toUpperCase(),
              'price': (item['current_price'] ?? 0.0) as double,
              'change': (item['price_change_percentage_24h'] ?? 0.0) as double,
              'icon': _getCryptoIcon(item['symbol'] ?? 'btc'),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        _loadFallbackData();
      }
    } catch (e) {
      debugPrint('Crypto API Error: $e');
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    setState(() {
      _cryptoData = [
        {'name': 'Bitcoin', 'symbol': 'BTC', 'price': 67500.0, 'change': 5.2, 'icon': Icons.currency_bitcoin},
        {'name': 'Ethereum', 'symbol': 'ETH', 'price': 3450.0, 'change': 3.1, 'icon': Icons.diamond},
        {'name': 'Ripple', 'symbol': 'XRP', 'price': 2.50, 'change': -1.5, 'icon': Icons.stacked_line_chart},
        {'name': 'Solana', 'symbol': 'SOL', 'price': 145.20, 'change': 8.7, 'icon': Icons.rocket_launch},
        {'name': 'Cardano', 'symbol': 'ADA', 'price': 0.68, 'change': -2.3, 'icon': Icons.circle},
        {'name': 'Polkadot', 'symbol': 'DOT', 'price': 7.15, 'change': 4.2, 'icon': Icons.language},
      ];
      _isLoading = false;
    });
  }

  IconData _getCryptoIcon(String symbol) {
    switch (symbol.toLowerCase()) {
      case 'btc':
        return Icons.currency_bitcoin;
      case 'eth':
        return Icons.diamond;
      case 'xrp':
        return Icons.stacked_line_chart;
      case 'sol':
        return Icons.rocket_launch;
      case 'ada':
        return Icons.circle;
      case 'dot':
        return Icons.language;
      default:
        return Icons.currency_exchange;
    }
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
          'Crypto Market',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _fetchCryptoRates,
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
                    'Loading crypto rates...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _cryptoData.length,
              itemBuilder: (context, index) {
                final crypto = _cryptoData[index];
                return _buildCryptoGlassCard(
                  crypto['name'] as String,
                  crypto['symbol'] as String,
                  crypto['price'] as double,
                  crypto['change'] as double,
                  crypto['icon'] as IconData,
                );
              },
            ),
    );
  }

  Widget _buildCryptoGlassCard(String name, String symbol, double price, double change, IconData icon) {
    final bool isPositive = change >= 0;
    final formattedPrice = price >= 1000 
        ? price.toStringAsFixed(0) 
        : price.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      // 🔥 Upgraded to standard generic GlassCard architecture
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            // Ambient Icon Glow Frame
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withAlpha(((0.08) * 255).round()),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00E5FF).withAlpha(((0.15) * 255).round()),
                ),
              ),
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 22),
            ),
            const SizedBox(width: 16),
            
            // Asset Identifiers
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    symbol,
                    style: TextStyle(
                      color: Colors.white.withAlpha(((0.4) * 255).round()),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Financial Status Analytics
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$$formattedPrice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? '+${change.toStringAsFixed(2)}%' : '${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

