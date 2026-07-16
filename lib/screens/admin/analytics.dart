import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/glow_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _totalUsers = 0;
  int _totalConversions = 0;
  int _activeUsers = 0;
  List<_AnalyticsMetric> _backendMetrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      _totalUsers = await _countCollection('users');
      _totalConversions = await _countCollection('conversions');
      _activeUsers = await _countQuery(
        FirebaseFirestore.instance
            .collection('users')
            .where('lastLogin', isGreaterThanOrEqualTo: weekAgo),
      );

      final activeAlerts = await _countQuery(
        FirebaseFirestore.instance
            .collection('alerts')
            .where('isActive', isEqualTo: true),
      );
      final feedbacks = await _countCollection('feedbacks');
      final favoritePairs = await _countCollection('favoritePairs');
      final currencies = await _countCollection('currencies');
      final exchangeRates = await _countCollection('exchange_rates');

      _backendMetrics = _withPercentages([
        _AnalyticsMetric(title: 'Conversions', value: _totalConversions),
        _AnalyticsMetric(title: 'Active Alerts', value: activeAlerts),
        _AnalyticsMetric(title: 'Feedbacks', value: feedbacks),
        _AnalyticsMetric(title: 'Favorite Pairs', value: favoritePairs),
        _AnalyticsMetric(title: 'Currencies', value: currencies),
        _AnalyticsMetric(title: 'Exchange Rates', value: exchangeRates),
      ]);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GlowCard(
                        glowColor: const Color(0xFF00E5FF),
                        child: _buildSummaryCard(
                          title: 'Total Users',
                          value: _totalUsers.toString(),
                          subtitle: 'Registered Users',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlowCard(
                        glowColor: const Color(0xFF00E5FF),
                        child: _buildSummaryCard(
                          title: 'Active Users',
                          value: _activeUsers.toString(),
                          subtitle: 'Last 7 Days',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlowCard(
                        glowColor: const Color(0xFF00E5FF),
                        child: _buildSummaryCard(
                          title: 'Conversions',
                          value: _totalConversions.toString(),
                          subtitle: 'Total',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GlowCard(
                  glowColor: const Color(0xFF00E5FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backend Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_backendMetrics.isEmpty)
                        const Text(
                          'No backend data found yet',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        )
                      else
                        ..._backendMetrics.expand(
                          (metric) => [
                            _buildAnalyticsRow(
                              metric.title,
                              metric.valueText,
                              metric.percentage,
                            ),
                            if (metric != _backendMetrics.last)
                              const Divider(color: Colors.white12),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow(String title, String visitors, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                visitors,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: double.infinity,
              height: 8,
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.white.withAlpha(((0.1) * 255).round()),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00E5FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _countCollection(String collectionPath) {
    return _countQuery(FirebaseFirestore.instance.collection(collectionPath));
  }

  Future<int> _countQuery(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  List<_AnalyticsMetric> _withPercentages(List<_AnalyticsMetric> metrics) {
    final sortedMetrics = metrics.where((metric) => metric.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedMetrics.isEmpty) return [];

    final maxValue = sortedMetrics.first.value;
    return sortedMetrics
        .map(
          (metric) => metric.copyWith(
            percentage: maxValue == 0 ? 0 : (metric.value / maxValue) * 100,
          ),
        )
        .toList();
  }
}

class _AnalyticsMetric {
  final String title;
  final int value;
  final double percentage;

  const _AnalyticsMetric({
    required this.title,
    required this.value,
    this.percentage = 0,
  });

  String get valueText => '$value records';

  _AnalyticsMetric copyWith({double? percentage}) {
    return _AnalyticsMetric(
      title: title,
      value: value,
      percentage: percentage ?? this.percentage,
    );
  }
}
