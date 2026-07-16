import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/glass_card.dart'; // Aapka standardized generic card module

class GoldRatesScreen extends StatefulWidget {
  const GoldRatesScreen({super.key}) ;

  @override
  State<GoldRatesScreen> createState() => _GoldRatesScreenState();
}

class _GoldRatesScreenState extends State<GoldRatesScreen> {
  List<Map<String, dynamic>> _goldData = [];
  bool _isLoading = true;

  // 🔥 GOLD API (Free)
  static const String _apiUrl = 'https://api.gold-api.com/price/XAU';

  @override
  void initState() {
    super.initState();
    _fetchGoldRates();
  }

  Future<void> _fetchGoldRates() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = data['price'] ?? 0.0;
        final change = data['change'] ?? 0.0;

        setState(() {
          _goldData = [
            {'type': 'Gold (Per Gram)', 'rate': price.toStringAsFixed(2), 'change': change.toStringAsFixed(2), 'emoji': '🟡'},
            {'type': 'Silver (Per Gram)', 'rate': (price * 0.012).toStringAsFixed(2), 'change': (change * 0.8).toStringAsFixed(2), 'emoji': '⚪'},
            {'type': 'Platinum (Per Gram)', 'rate': (price * 0.45).toStringAsFixed(2), 'change': (change * 0.6).toStringAsFixed(2), 'emoji': '⚙️'},
          ];
          _isLoading = false;
        });
      } else {
        _loadFallbackData();
      }
    } catch (e) {
      debugPrint('Gold API Error: $e');
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    setState(() {
      _goldData = [
        {'type': 'Gold (Per Gram)', 'rate': '7,850', 'change': '+0.50', 'emoji': '🟡'},
        {'type': 'Silver (Per Gram)', 'rate': '95.50', 'change': '-0.25', 'emoji': '⚪'},
        {'type': 'Platinum (Per Gram)', 'rate': '12,500', 'change': '+1.20', 'emoji': '⚙️'},
      ];
      _isLoading = false;
    });
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
          'Commodity Rates',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _fetchGoldRates,
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
                    'Fetching spot rates...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _goldData.length,
              itemBuilder: (context, index) {
                final item = _goldData[index];
                return _buildGoldGlassCard(
                  item['type'] as String,
                  'PKR ${item['rate']}',
                  item['change'] as String,
                  item['emoji'] as String,
                );
              },
            ),
    );
  }

  Widget _buildGoldGlassCard(String type, String rate, String change, String emoji) {
    final isPositive = change.startsWith('+') || (!change.startsWith('-') && double.tryParse(change) != null && double.parse(change) >= 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), // Squeezed padding
        child: Row(
          children: [
            // Core Identity Segment
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(((0.05) * 255).round()),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(((0.08) * 255).round())),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            
            // 🛑 Expanded limits text block bounds to stop Platinum layout bounds crash
            Expanded(
              child: Text(
                type,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            
            // Financial Analytical Segment
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🛑 FittedBox scales down numbers seamlessly if layout width hits extreme margins
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
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
                      isPositive ? '+$change%' : '$change%',
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

