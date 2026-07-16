import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';  // ✅ ADDED
import '../../widgets/glow_button.dart';  // ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED
import '../../core/services/notification_service.dart';

class FavoritePairsScreen extends StatefulWidget {
  const FavoritePairsScreen({super.key}) ;

  @override
  State<FavoritePairsScreen> createState() => _FavoritePairsScreenState();
}

class _FavoritePairsScreenState extends State<FavoritePairsScreen> {
  List<Map<String, dynamic>> _favoritePairs = [];
  Map<String, double> _rates = {};
  bool _isLoading = true;
  final String _baseCurrency = 'USD';

  static const String _apiKey = 'fc7df44c30c926721ee77270';
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/';

  @override
  void initState() {
    super.initState();
    _loadFavoritePairs();
    _fetchRates();
  }

  Future<void> _loadFavoritePairs() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _favoritePairs = _getDefaultPairs();
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('favoritePairs')
          .where('userId', isEqualTo: user.uid)
          .get();

      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTs = a.data()['createdAt'] as Timestamp?;
        final bTs = b.data()['createdAt'] as Timestamp?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });

      if (docs.isNotEmpty) {
        setState(() {
          _favoritePairs = docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'from': data['from'] ?? 'USD',
              'to': data['to'] ?? 'PKR',
              'isActive': data['isActive'] ?? true,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _favoritePairs = _getDefaultPairs();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      setState(() {
        _favoritePairs = _getDefaultPairs();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getDefaultPairs() {
    return [
      {'from': 'USD', 'to': 'PKR', 'isActive': true},
      {'from': 'EUR', 'to': 'PKR', 'isActive': true},
      {'from': 'GBP', 'to': 'PKR', 'isActive': true},
      {'from': 'AED', 'to': 'PKR', 'isActive': true},
      {'from': 'INR', 'to': 'PKR', 'isActive': true},
    ];
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
          _rates = {};
          rates.forEach((key, value) {
            _rates[key] = (value as num).toDouble();
          });
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
        _rates = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final code = data['code'] ?? '';
          final rate = (data['rate'] ?? 0.0) as double;
          _rates[code] = rate;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Firestore Error: $e');
      setState(() => _isLoading = false);
    }
  }

  double _getRate(String fromCode, String toCode) {
    final fromRate = _rates[fromCode] ?? 1.0;
    final toRate = _rates[toCode] ?? 1.0;
    return toRate / fromRate;
  }

  void _addFavoritePair() async {
    final fromController = TextEditingController(text: 'USD');
    final toController = TextEditingController(text: 'PKR');

    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Add Favorite Pair',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'From Currency',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: toController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'To Currency',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          GlowButton(
            onPressed: () async {
              final from = fromController.text.trim().toUpperCase();
              final to = toController.text.trim().toUpperCase();
              
              final dialogNavigator = Navigator.of(parentContext);
              final messenger = ScaffoldMessenger.of(parentContext);
              if (from.isEmpty || to.isEmpty) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Please fill both fields')),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final doc = await FirebaseFirestore.instance.collection('favoritePairs').add({
                    'userId': user.uid,
                    'from': from,
                    'to': to,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  await NotificationService().sendUserActivityToAdmin(
                    title: 'Favorite Pair Added',
                    message: '${user.displayName ?? user.email ?? 'A user'} added $from to $to as a favorite pair.',
                    type: 'user_activity',
                    relatedId: doc.id,
                  );
                }
                
                if (!mounted) return;
                dialogNavigator.pop();
                _loadFavoritePairs();

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Favorite pair added!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!parentContext.mounted) return;

                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            glowColor: const Color(0xFF00E5FF),
            height: 45,
            child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _removeFavorite(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Remove Pair', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this favorite pair?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final doc = await FirebaseFirestore.instance
            .collection('favoritePairs')
            .doc(id)
            .get();
        final data = doc.data();
        final from = data?['from'] ?? '';
        final to = data?['to'] ?? '';

        await FirebaseFirestore.instance
            .collection('favoritePairs')
            .doc(id)
            .delete();
        await NotificationService().sendUserActivityToAdmin(
          title: 'Favorite Pair Removed',
          message: '${user?.displayName ?? user?.email ?? 'A user'} removed $from to $to from favorite pairs.',
          type: 'user_activity',
          relatedId: id,
        );
        _loadFavoritePairs();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorite pair removed'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
          'Favorite Pairs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00E5FF)),
            onPressed: _addFavoritePair,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () {
              _fetchRates();
              _loadFavoritePairs();
            },
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
                      'Loading favorite pairs...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
            : _favoritePairs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, color: Colors.white24, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No favorite pairs yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap + to add a pair',
                          style: TextStyle(color: Colors.white24),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: _favoritePairs.map((pair) {
                      final from = pair['from'] as String;
                      final to = pair['to'] as String;
                      final isActive = pair['isActive'] as bool? ?? true;
                      final rate = _getRate(from, to);
                      final change = (rate % 1) * 100;
                      final isPositive = change >= 0;

                      return AnimationUtils.fadeInSlide(  // ✅ ANIMATION
                        duration: const Duration(milliseconds: 200),
                        child: _pairCard(
                          pair['id'] as String? ?? '',
                          '$from → $to',
                          rate.toStringAsFixed(2),
                          isPositive ? '+${change.toStringAsFixed(2)}%' : '${change.toStringAsFixed(2)}%',
                          isPositive,
                          isActive,
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }

  Widget _pairCard(String id, String pair, String rate, String change, bool isPositive, bool isActive) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlowCard(  // ✅ GLOW CARD
          glowColor: isActive ? const Color(0xFF00E5FF) : Colors.red,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withAlpha(((0.1) * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.currency_exchange,
                      color: Color(0xFF00E5FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pair,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                                style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rate,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  if (id.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _removeFavorite(id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

