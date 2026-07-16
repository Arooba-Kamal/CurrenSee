import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/glow_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double _dailyTotal = 0;
  double _weeklyTotal = 0;
  double _monthlyTotal = 0;
  int _dailyCount = 0;
  int _weeklyCount = 0;
  int _monthlyCount = 0;
  List<_ConversionPairReport> _topPairs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfWeekDate = today.subtract(Duration(days: today.weekday - 1));
      final startOfWeek = DateTime(
        startOfWeekDate.year,
        startOfWeekDate.month,
        startOfWeekDate.day,
      );
      final startOfMonth = DateTime(today.year, today.month, 1);

      final dailySnapshot = await FirebaseFirestore.instance
          .collection('conversions')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();
      _dailyCount = dailySnapshot.docs.length;
      _dailyTotal = dailySnapshot.docs.fold<double>(
        0,
        (total, doc) => total + _readConversionAmount(doc.data()),
      );

      final weeklySnapshot = await FirebaseFirestore.instance
          .collection('conversions')
          .where('timestamp', isGreaterThanOrEqualTo: startOfWeek)
          .get();
      _weeklyCount = weeklySnapshot.docs.length;
      _weeklyTotal = weeklySnapshot.docs.fold<double>(
        0,
        (total, doc) => total + _readConversionAmount(doc.data()),
      );

      final monthlySnapshot = await FirebaseFirestore.instance
          .collection('conversions')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .get();
      _monthlyCount = monthlySnapshot.docs.length;
      _monthlyTotal = monthlySnapshot.docs.fold<double>(
        0,
        (total, doc) => total + _readConversionAmount(doc.data()),
      );
      _topPairs = _buildTopPairs(monthlySnapshot.docs);
    } catch (e) {
      debugPrint('Error loading reports: $e');
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
                  'Reports & Analytics',
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
                          title: 'Daily Transactions',
                          value: _formatPkr(_dailyTotal),
                          subtitle: 'Today - $_dailyCount conversions',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlowCard(
                        glowColor: const Color(0xFF00E5FF),
                        child: _buildSummaryCard(
                          title: 'Weekly Total',
                          value: _formatPkr(_weeklyTotal),
                          subtitle: 'This Week - $_weeklyCount conversions',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlowCard(
                        glowColor: const Color(0xFF00E5FF),
                        child: _buildSummaryCard(
                          title: 'Monthly Total',
                          value: _formatPkr(_monthlyTotal),
                          subtitle: 'This Month - $_monthlyCount conversions',
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
                        'Top Conversion Pairs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_topPairs.isEmpty)
                        const Text(
                          'No conversion data found for this month',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        )
                      else
                        ..._topPairs.expand(
                          (pair) => [
                            _buildReportRow(
                              pair.title,
                              '${pair.count} conversions - ${_formatPkr(pair.totalAmount)}',
                              pair.percentage,
                            ),
                            if (pair != _topPairs.last)
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

  Widget _buildReportRow(String title, String count, double percentage) {
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
                count,
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

  double _readConversionAmount(Map<String, dynamic> data) {
    final value = data['toAmount'] ?? data['amount'] ?? data['fromAmount'] ?? 0;
    return value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
  }

  List<_ConversionPairReport> _buildTopPairs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final reportsByPair = <String, _ConversionPairReport>{};

    for (final doc in docs) {
      final data = doc.data();
      final from = (data['fromCurrency'] ?? data['from'] ?? 'N/A').toString();
      final to = (data['toCurrency'] ?? data['to'] ?? 'N/A').toString();
      final key = '$from -> $to';
      final current = reportsByPair[key] ?? _ConversionPairReport(title: key);
      reportsByPair[key] = current.copyWith(
        count: current.count + 1,
        totalAmount: current.totalAmount + _readConversionAmount(data),
      );
    }

    final reports = reportsByPair.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final topReports = reports.take(5).toList();
    final topCount = topReports.fold<int>(0, (total, item) => total + item.count);

    if (topCount == 0) return topReports;

    return topReports
        .map((item) => item.copyWith(percentage: (item.count / topCount) * 100))
        .toList();
  }

  String _formatPkr(double value) {
    if (value >= 1000000) return 'PKR ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'PKR ${(value / 1000).toStringAsFixed(1)}K';
    return 'PKR ${value.toStringAsFixed(0)}';
  }
}

class _ConversionPairReport {
  final String title;
  final int count;
  final double totalAmount;
  final double percentage;

  const _ConversionPairReport({
    required this.title,
    this.count = 0,
    this.totalAmount = 0,
    this.percentage = 0,
  });

  _ConversionPairReport copyWith({
    int? count,
    double? totalAmount,
    double? percentage,
  }) {
    return _ConversionPairReport(
      title: title,
      count: count ?? this.count,
      totalAmount: totalAmount ?? this.totalAmount,
      percentage: percentage ?? this.percentage,
    );
  }
}
