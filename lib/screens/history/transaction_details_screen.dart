import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/glow_card.dart';  // ✅ ADDED
import '../../widgets/glow_button.dart';  // ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED

class TransactionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  const TransactionDetailsScreen({super.key, this.transaction}) ;

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  Map<String, dynamic> _transaction = {};
  bool _isLoading = true;

  Map<String, dynamic> _normalizeTransaction(Map<String, dynamic> data) {
    final from = data['from'] ?? data['fromCurrency'] ?? 'USD';
    final to = data['to'] ?? data['toCurrency'] ?? 'PKR';
    final timestamp = data['timestamp'];

    return {
      'id': data['id'],
      'from': from,
      'to': to,
      'fromAmount': (data['fromAmount'] as num?)?.toDouble() ?? 0.0,
      'toAmount': (data['toAmount'] as num?)?.toDouble() ?? 0.0,
      'rate': (data['rate'] as num?)?.toDouble() ?? 0.0,
      'timestamp': timestamp is Timestamp
          ? timestamp.toDate()
          : timestamp is DateTime
              ? timestamp
              : DateTime.now(),
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      setState(() {
        _transaction = _normalizeTransaction(widget.transaction!);
        _isLoading = false;
      });
    } else {
      _loadLatestTransaction();
    }
  }

  Future<void> _loadLatestTransaction() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _loadDemoTransaction();
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('conversions')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _transaction = _normalizeTransaction({
            'id': snapshot.docs.first.id,
            ...data,
          });
          _isLoading = false;
        });
      } else {
        _loadDemoTransaction();
      }
    } catch (e) {
      debugPrint('Error loading transaction: $e');
      _loadDemoTransaction();
    }
  }

  void _loadDemoTransaction() {
    setState(() {
      _transaction = {
        'from': 'USD',
        'to': 'PKR',
        'fromAmount': 1.0,
        'toAmount': 278.50,
        'rate': 278.50,
        'timestamp': DateTime.now(),
      };
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return NumberFormat('#,###.00').format(amount);
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Transaction Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: AnimationUtils.fadeInSlide(  // ✅ WRAPPED WITH ANIMATION
        duration: const Duration(milliseconds: 500),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlowCard(  // ✅ GLOW CARD
                      glowColor: const Color(0xFF00E5FF),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF).withAlpha(((0.1) * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz,
                                  color: Color(0xFF00E5FF),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_transaction['fromAmount']} ${_transaction['from']} → ${_transaction['to']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rate: 1 ${_transaction['from']} = ${_transaction['rate'].toStringAsFixed(4)} ${_transaction['to']}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 32),
                          
                          _detailRow('Amount', '${_transaction['fromAmount']} ${_transaction['from']}'),
                          _detailRow('Converted to', '${_formatAmount(_transaction['toAmount'])} ${_transaction['to']}'),
                          _detailRow('Exchange Rate', '${_transaction['rate'].toStringAsFixed(4)}'),
                          _detailRow('Date', _formatDate(_transaction['timestamp'])),
                          _detailRow('Time', _formatTime(_transaction['timestamp'])),
                          
                          const SizedBox(height: 12),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(((0.2) * 255).round()),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withAlpha(((0.3) * 255).round())),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Completed',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GlowButton(  // ✅ GLOW BUTTON
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            glowColor: const Color(0xFF00E5FF),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlowButton(  // ✅ GLOW BUTTON
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share feature coming soon!'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            glowColor: Colors.blue,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.share, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  'Share',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: label == 'Converted to' ? const Color(0xFF00E5FF) : Colors.white,
              fontWeight: label == 'Converted to' ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

