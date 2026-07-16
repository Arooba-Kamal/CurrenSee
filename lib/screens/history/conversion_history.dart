import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';
import 'transaction_details_screen.dart';

class ConversionHistoryScreen extends StatefulWidget {
  const ConversionHistoryScreen({super.key});

  @override
  State<ConversionHistoryScreen> createState() => _ConversionHistoryScreenState();
}

class _ConversionHistoryScreenState extends State<ConversionHistoryScreen> {
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) => DateFormat('hh:mm a').format(date);
  String _formatAmount(double amount) => NumberFormat('#,###.00').format(amount);

  DateTime _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return GlassScaffold(
        appBar: AppBar(
          title: const Text('History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: Colors.white24, size: 60),
              SizedBox(height: 16),
              Text('Please login to view history', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final userId = user.uid;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversions')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.withOpacity(0.5), size: 60),
                  const SizedBox(height: 16),
                  const Text('Error loading history', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.white24, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: Colors.white24, size: 60),
                  SizedBox(height: 16),
                  Text('No history found', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Start converting currencies to see history here', style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              return _readTimestamp(bData['timestamp']).compareTo(_readTimestamp(aData['timestamp']));
            });

          final grouped = <String, List<QueryDocumentSnapshot>>{};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final key = DateFormat('yyyy-MM-dd').format(_readTimestamp(data['timestamp']));
            grouped.putIfAbsent(key, () => []).add(doc);
          }

          if (grouped.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: Colors.white24, size: 60),
                  SizedBox(height: 16),
                  Text('No valid history records', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }

          final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final items = grouped[key]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(_formatDate(DateTime.parse(key))),
                  ...items.map((doc) {
                    final item = doc.data() as Map<String, dynamic>;
                    item['id'] = doc.id;
                    return _buildHistoryItem(item);
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final fromAmount = (item['fromAmount'] as num?)?.toDouble() ?? 0.0;
    final toAmount = (item['toAmount'] as num?)?.toDouble() ?? 0.0;
    final fromCurrency = item['fromCurrency'] ?? 'USD';
    final toCurrency = item['toCurrency'] ?? 'PKR';

    String timeText = 'Just now';
    if (item['timestamp'] != null) {
      final timestamp = _readTimestamp(item['timestamp']);
      timeText = timestamp.millisecondsSinceEpoch == 0 ? 'Unknown time' : _formatTime(timestamp);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransactionDetailsScreen(transaction: item)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: GlowCard(
          glowColor: const Color(0xFF00E5FF),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$fromAmount $fromCurrency → $toCurrency',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(timeText, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Text(
                '${_formatAmount(toAmount)} $toCurrency',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
