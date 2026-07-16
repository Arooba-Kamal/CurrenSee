import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/glass_card.dart';

class MarketNewsScreen extends StatefulWidget {
  const MarketNewsScreen({super.key}) ;

  @override
  State<MarketNewsScreen> createState() => _MarketNewsScreenState();
}

class _MarketNewsScreenState extends State<MarketNewsScreen> {
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  String _selectedCategory = 'all'; // 'all', 'analysis'

  // 🔥 NEWS API KEY - YAHAN APNI KEY DAALEIN
  static const String _newsApiKey = '37162bed227145049f21be9fdd35f939'; // ✅ YOUR API KEY
  static const String _newsBaseUrl = 'https://newsapi.org/v2';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String query = 'currency OR forex OR exchange OR dollar OR euro';
      if (_selectedCategory == 'analysis') {
        query = 'currency analysis OR forex analysis OR market analysis';
      }

      final response = await http.get(
        Uri.parse(
          '$_newsBaseUrl/everything?q=$query'
          '&language=en'
          '&sortBy=publishedAt'
          '&pageSize=20'
          '&apiKey=$_newsApiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final articles = data['articles'] as List<dynamic>? ?? [];

        setState(() {
          _news = articles.map((item) {
            return {
              'title': item['title'] ?? 'No title',
              'description': item['description'] ?? 'No description',
              'source': item['source']['name'] ?? 'Unknown',
              'url': item['url'] ?? '',
              'image': item['urlToImage'] ?? '',
              'publishedAt': item['publishedAt'] ?? DateTime.now().toIso8601String(),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        // Agar API fail ho toh demo news show karein
        _loadDemoNews();
      }
    } catch (e) {
      debugPrint('❌ News API Error: $e');
      _loadDemoNews();
    }
  }

  void _loadDemoNews() {
    setState(() {
      _news = [
        {
          'title': 'Dollar strengthens as U.S. inflation cools down significantly',
          'description': 'Market impact: Low volatility expected for global USD currency pairs over the fiscal week.',
          'source': 'Market News',
          'publishedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'title': 'Euro rises against major currencies amid positive economic data',
          'description': 'EUR shows strong performance against USD and GBP following ECB policy announcement.',
          'source': 'Forex News',
          'publishedAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'title': 'Bitcoin reaches new high as institutional adoption grows',
          'description': 'Cryptocurrency market sees surge in trading volume and institutional investment.',
          'source': 'Crypto News',
          'publishedAt': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        },
        {
          'title': 'Gold prices steady as investors await Fed decision',
          'description': 'Precious metals market remains stable with gold holding above \$1,850 per ounce.',
          'source': 'Commodity News',
          'publishedAt': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String(),
        },
      ];
      _isLoading = false;
    });
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  IconData _getIconForTitle(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('dollar') || lowerTitle.contains('usd')) {
      return Icons.attach_money;
    } else if (lowerTitle.contains('euro') || lowerTitle.contains('eur')) {
      return Icons.euro_symbol;
    } else if (lowerTitle.contains('bitcoin') || lowerTitle.contains('crypto')) {
      return Icons.currency_bitcoin;
    } else if (lowerTitle.contains('gold') || lowerTitle.contains('silver')) {
      return Icons.brightness_high;
    } else if (lowerTitle.contains('analysis')) {
      return Icons.analytics;
    } else {
      return Icons.trending_up;
    }
  }

  Color _getColorForTitle(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('dollar') || lowerTitle.contains('usd')) {
      return const Color(0xFF00E5FF);
    } else if (lowerTitle.contains('euro') || lowerTitle.contains('eur')) {
      return const Color(0xFF8A2BE2);
    } else if (lowerTitle.contains('bitcoin') || lowerTitle.contains('crypto')) {
      return Colors.orange;
    } else if (lowerTitle.contains('gold') || lowerTitle.contains('silver')) {
      return Colors.amber;
    } else {
      return const Color(0xFF00E5FF);
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
          'Market News',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _fetchNews,
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
                    'Loading news...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : _news.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper, color: Colors.white24, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'No news available',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Categories
                    Row(
                      children: [
                        _buildCategoryTab('All News', _selectedCategory == 'all'),
                        const SizedBox(width: 10),
                        _buildCategoryTab('Analysis', _selectedCategory == 'analysis'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // News Count
                    Text(
                      '${_news.length} articles found',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    // News List
                    ..._news.map((item) {
                      final title = item['title'] as String;
                      final description = item['description'] as String;
                      final time = _getTimeAgo(item['publishedAt'] as String);
                      final icon = _getIconForTitle(title);
                      final color = _getColorForTitle(title);

                      return _buildNewsCard(
                        title,
                        description,
                        time,
                        icon,
                        color,
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildCategoryTab(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title == 'All News' ? 'all' : 'analysis';
        });
        _fetchNews();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8A2BE2) : Colors.white.withAlpha(((0.04) * 255).round()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.white.withAlpha(((0.1) * 255).round()),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF8A99AD),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(String title, String desc, String time, IconData icon, Color highlightColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF8A99AD),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    time,
                    style: TextStyle(
                      color: highlightColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: highlightColor.withAlpha(((0.1) * 255).round()),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: highlightColor.withAlpha(((0.2) * 255).round())),
              ),
              child: Icon(icon, color: highlightColor, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

