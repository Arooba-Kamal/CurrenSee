// lib/widgets/live_rate_card.dart
import 'package:currensee/core/theme/currensee_theme.dart' show CurrenSeeTheme;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveRateCard extends StatefulWidget {
  final String fromCurrency;
  final String toCurrency;
  final double? initialRate;
  final double? initialChange;

  const LiveRateCard({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    this.initialRate,
    this.initialChange,
  });

  @override
  State<LiveRateCard> createState() => _LiveRateCardState();
}

class _LiveRateCardState extends State<LiveRateCard> {
  double _rate = 0.0;
  double _change = 0.0;
  double _changePercent = 0.0;
  bool _isPositive = true;
  bool _isLoading = true;
  String _lastUpdated = 'Loading...';

  // 🔥 EXCHANGE RATE API KEY
  static const String _apiKey = 'YOUR_EXCHANGE_RATE_API_KEY';
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/';

  @override
  void initState() {
    super.initState();
    if (widget.initialRate != null) {
      _rate = widget.initialRate!;
      _change = widget.initialChange ?? 0.0;
      _isLoading = false;
    } else {
      _fetchLiveRate();
    }
  }

  Future<void> _fetchLiveRate() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl${widget.fromCurrency}'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final rate = rates[widget.toCurrency] ?? 0.0;
        final change = data['change'] ?? 0.0;

        setState(() {
          _rate = rate;
          _change = change;
          _changePercent = (change / _rate) * 100;
          _isPositive = change >= 0;
          _lastUpdated = DateTime.now().toString().substring(11, 19);
          _isLoading = false;
        });
      } else {
        await _fetchFromFirestore();
      }
    } catch (e) {
      debugPrint('API Error: $e');
      await _fetchFromFirestore();
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('currencies')
          .where('code', whereIn: [widget.fromCurrency, widget.toCurrency])
          .get();

      if (snapshot.docs.length == 2) {
        final fromData = snapshot.docs.firstWhere(
          (doc) => doc.data()['code'] == widget.fromCurrency,
        ).data();
        final toData = snapshot.docs.firstWhere(
          (doc) => doc.data()['code'] == widget.toCurrency,
        ).data();

        final fromRate = (fromData['rate'] ?? 1.0) as double;
        final toRate = (toData['rate'] ?? 1.0) as double;
        final rate = toRate / fromRate;

        setState(() {
          _rate = rate;
          _change = 0.0;
          _changePercent = 0.0;
          _isPositive = true;
          _lastUpdated = 'Cached';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Firestore Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E2640),
                  const Color(0xFF141A2B),
                ]
              : [
                  CurrenSeeTheme.primaryBlue.withAlpha(((0.05) * 255).round()),
                  CurrenSeeTheme.primaryIndigo.withAlpha(((0.05) * 255).round()),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(((0.1) * 255).round())
              : CurrenSeeTheme.primaryBlue.withAlpha(((0.1) * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.fromCurrency} → ${widget.toCurrency}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: CurrenSeeTheme.accentGreen.withAlpha(((0.1) * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isLoading ? 'Loading...' : 'Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isLoading ? Colors.orange : CurrenSeeTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                ),
              ),
            )
          else
            Text(
              _rate.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isPositive ? Icons.trending_up : Icons.trending_down,
                color: _isPositive
                    ? CurrenSeeTheme.accentGreen
                    : CurrenSeeTheme.accentRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_isPositive ? '+' : ''}${_change.toStringAsFixed(2)} (${_isPositive ? '+' : ''}${_changePercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isPositive
                      ? CurrenSeeTheme.accentGreen
                      : CurrenSeeTheme.accentRed,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Last updated: $_lastUpdated',
                style: const TextStyle(
                  fontSize: 12,
                  color: CurrenSeeTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

