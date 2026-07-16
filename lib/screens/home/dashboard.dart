import 'package:currensee/screens/converter/convert_screen.dart';
import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/glow_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/notification_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String _liveRate = '1 USD = 278.50 PKR';
  String _change = '+0.45 (0.16%)';
  String _lastUpdated = 'Loading...';
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  static const String _apiKey = '36141dbe41d8328fd4bf1088';
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';

  @override
  void initState() {
    super.initState();
    _fetchLiveRate();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveRate() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        // headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final pkrRate = rates['PKR'] ?? 278.50;
        
        setState(() {
          _liveRate = '1 USD = ${pkrRate.toStringAsFixed(2)} PKR';
          _change = '+${(pkrRate % 1).toStringAsFixed(2)} (${((pkrRate % 1) * 100).toStringAsFixed(2)}%)';
          _lastUpdated = DateTime.now().toString().substring(11, 19);
          _isLoading = false;
        });
      } else {
        await _fetchFromFirestore();
      }
    } catch (e) {
      await _fetchFromFirestore();
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('code', whereIn: ['USD', 'PKR'])
          .get();

      if (snapshot.docs.length == 2) {
        final pkrData = snapshot.docs.firstWhere(
          (doc) => doc.data()['code'] == 'PKR',
        ).data();
        final pkrRate = (pkrData['rate'] ?? 278.50) as double;

        setState(() {
          _liveRate = '1 USD = ${pkrRate.toStringAsFixed(2)} PKR';
          _change = '+${(pkrRate % 1).toStringAsFixed(2)}%';
          _lastUpdated = 'Cached';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _liveRate = '1 USD = 278.50 PKR';
        _change = '+0.45 (0.16%)';
        _lastUpdated = 'Offline';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00E5FF);

    return GlassScaffold(
      // backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.sort, color: Colors.white70),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text(
          'CurrenSee',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const NotificationBadge(
              child: Icon(
                Icons.notifications_none_outlined,
                size: 26,
                color: Colors.white,
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, '/alerts/notifications'),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            
            // Live Rate Card with Glow
            GlowCard(
              glowColor: neonCyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Rate',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLoading ? 'Loading...' : _liveRate,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: const Icon(
                              Icons.trending_up,
                              color: Color(0xFF00E5FF),
                              size: 26,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _isLoading ? 'Updating...' : _change,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Last updated: $_lastUpdated',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 28),
            const Text(
              'Quick Convert',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            
            // Quick Convert Card
            GlowCard(
              glowColor: neonCyan,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      _buildBlockInput("From", "USD", "United States Dollar", "1.00"),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Divider(
                          color: Colors.white.withAlpha(((0.06) * 255).round()),
                          height: 1,
                        ),
                      ),
                      _buildBlockInput("To", "PKR", "Pakistan Rupee", "278.50"),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1527).withAlpha(((0.8) * 255).round()),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(((0.15) * 255).round()),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonCyan.withAlpha(((0.2) * 255).round()),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                    child: const Icon(
                      Icons.swap_vert,
                      color: Color(0xFF00E5FF),
                      size: 22,
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Convert Button with Glow
            GlowButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConvertScreen())
              ),
              glowColor: neonCyan,
              child: const Text(
                'Convert',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Quick Icons - Rate Alerts REMOVED
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickIcon(
                  Icons.star_border_rounded,
                  "Favorites",
                  () => Navigator.pushNamed(context, '/currency/favorites'),
                  neonCyan,
                ),
                _buildQuickIcon(
                  Icons.history_rounded,
                  "History",
                  () => Navigator.pushNamed(context, '/history'),
                  neonCyan,
                ),
                // ✅ Rate Alerts REMOVED - Show nahi hoga
                // _buildQuickIcon(
                //   Icons.notifications_active_outlined,
                //   "Rate Alerts",
                //   () => Navigator.pushNamed(context, '/alerts/rate_alerts'),
                //   neonCyan,
                // ),
                _buildQuickIcon(
                  Icons.grid_view_rounded,
                  "Calculator",
                  () => Navigator.pushNamed(context, '/calculator/calculator_screen'),
                  neonCyan,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockInput(String tag, String iso, String full, String rateValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tag,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  iso,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              full,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Text(
          rateValue,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickIcon(IconData icon, String title, VoidCallback onTap, Color glowColor) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            GlowCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 16,
              glowColor: glowColor,
              hasGlow: true,
              child: Icon(
                icon,
                color: glowColor.withAlpha(((0.85) * 255).round()),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
