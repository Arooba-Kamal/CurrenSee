import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';  // ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED

class OfflineConversionScreen extends StatefulWidget {
  const OfflineConversionScreen({super.key}) ;

  @override
  State<OfflineConversionScreen> createState() => _OfflineConversionScreenState();
}

class _OfflineConversionScreenState extends State<OfflineConversionScreen> {
  String _rate = 'Loading...';
  String _cachedDate = 'Never';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedRate();
  }

  Future<void> _loadCachedRate() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cachedRates');
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        final usdRate = (data['USD'] ?? 1.0) as double;
        final pkrRate = (data['PKR'] ?? 278.20) as double;
        final timestamp = data['timestamp'] ?? '';
        
        setState(() {
          _rate = '1 USD = ${(pkrRate / usdRate).toStringAsFixed(2)} PKR';
          _cachedDate = timestamp.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _rate = '1 USD = 278.20 PKR';
          _cachedDate = 'No cache found';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Cache Error: $e');
      setState(() {
        _rate = '1 USD = 278.20 PKR';
        _cachedDate = 'Error loading cache';
        _isLoading = false;
      });
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
          'Offline Conversion',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _loadCachedRate,
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
                      'Loading cached insights...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  GlowCard(  // ✅ GLOW CARD
                    glowColor: Colors.orange,
                    child: Column(
                      children: [
                        const Text(
                          'Last Known Exchange Rate',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _rate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(((0.15) * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Offline Mode',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(((0.05) * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(((0.1) * 255).round())),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange.withAlpha(((0.06) * 255).round()),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storage_rounded, color: Color(0xFF00E5FF), size: 44),
                            const SizedBox(height: 10),
                            const Text(
                              'Local Data Engine Active',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Displaying data optimized from storage',
                              style: TextStyle(color: Colors.white.withAlpha(((0.4) * 255).round()), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Feed Specifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildSyncStatItem('System Architecture', 'Shared Prefs'),
                      _buildSyncStatItem('Base Currency', 'USD 🇺🇸'),
                      _buildSyncStatItem('Target Feed', 'PKR 🇵🇰'),
                      _buildSyncStatItem('Cached On', _cachedDate),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSyncStatItem(String label, String value) {
    return GlowCard(  // ✅ GLOW CARD
      glowColor: Colors.orange,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 13),
          ),
          const SizedBox(height: 4),
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

