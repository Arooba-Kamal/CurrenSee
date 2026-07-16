import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/smart_alert_service.dart';

class ManageRatesScreen extends StatefulWidget {
  const ManageRatesScreen({super.key});

  @override
  State<ManageRatesScreen> createState() => _ManageRatesScreenState();
}

class _ManageRatesScreenState extends State<ManageRatesScreen> {
  bool _isRefreshing = false;
  String _lastUpdated = '';
  String _errorMessage = '';

  final TextEditingController _fromCurrencyController = TextEditingController();
  final TextEditingController _toCurrencyController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _updateLastUpdated();
  }

  void _updateLastUpdated() {
    final now = DateTime.now();
    setState(() {
      _lastUpdated = DateFormat('HH:mm dd/MM/yyyy').format(now);
    });
  }

  Future<void> _refreshRates() async {
    setState(() => _isRefreshing = true);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      _updateLastUpdated();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Rates refreshed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _addRate() async {
    if (_fromCurrencyController.text.isEmpty ||
        _toCurrencyController.text.isEmpty ||
        _rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = '';
    });

    try {
      final fromCurrency = _fromCurrencyController.text.trim().toUpperCase();
      final toCurrency = _toCurrencyController.text.trim().toUpperCase();
      final rate = double.parse(_rateController.text.trim());

      final existingRates = await FirebaseFirestore.instance
          .collection('exchange_rates')
          .where('fromCurrency', isEqualTo: fromCurrency)
          .where('toCurrency', isEqualTo: toCurrency)
          .get();

      if (existingRates.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('exchange_rates')
            .doc(existingRates.docs.first.id)
            .update({
          'rate': rate,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('exchange_rates').add({
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'rate': rate,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      }

      // ✅ NOTIFICATION: Send to all users
      await NotificationService().sendToAllUsers(
        title: 'Exchange Rate Updated 📈',
        message: 'New rate: 1 $fromCurrency = $rate $toCurrency',
        type: 'rate_updated',
      );

      await SmartAlertService().notifyMatchingRateAlerts(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        rate: rate,
        relatedId: '$fromCurrency-$toCurrency',
      );

      _fromCurrencyController.clear();
      _toCurrencyController.clear();
      _rateController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Rate added/updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isAdding = false);
  }

  Future<void> _deleteRate(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('exchange_rates')
          .doc(docId)
          .get();
      final data = doc.data();
      final fromCurrency = data?['fromCurrency'] ?? 'N/A';
      final toCurrency = data?['toCurrency'] ?? 'N/A';

      await FirebaseFirestore.instance
          .collection('exchange_rates')
          .doc(docId)
          .delete();

      await NotificationService().sendToAllUsers(
        title: 'Exchange Rate Removed',
        message: '$fromCurrency/$toCurrency exchange rate has been removed.',
        type: 'rate_updated',
        relatedId: docId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Rate deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Exchange Rates',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildAddRateForm(),
          const SizedBox(height: 20),
          _buildRatesList(),
          const SizedBox(height: 20),
          _buildRefreshSection(),
        ],
      ),
    );
  }

  Widget _buildAddRateForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Exchange Rate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // ✅ FIXED: Wrapped in Column to prevent overflow
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromCurrencyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'From (e.g., USD)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF00E5FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _toCurrencyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'To (e.g., PKR)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _rateController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Exchange Rate',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isAdding ? null : _addRate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isAdding
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Add Rate',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Exchange Rates',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('exchange_rates')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No exchange rates available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fromCurrency = data['fromCurrency'] ?? 'N/A';
                  final toCurrency = data['toCurrency'] ?? 'N/A';
                  final rate = data['rate'] ?? 0.0;
                  final docId = doc.id;

                  return Column(
                    children: [
                      _buildRateRow(
                        fromCurrency: fromCurrency,
                        toCurrency: toCurrency,
                        rate: rate,
                        docId: docId,
                      ),
                      const Divider(color: Colors.white12),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Better layout for rate rows to prevent overflow
  Widget _buildRateRow({
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    required String docId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Currency Pair Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$fromCurrency/$toCurrency',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Rate Info - Expanded to take available space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Updated: ${DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now())}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Delete Button - Fixed width
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0A1628),
                    title: const Text(
                      'Delete Rate',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Delete $fromCurrency/$toCurrency exchange rate?',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteRate(docId);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last Updated',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                _lastUpdated,
                style: TextStyle(
                  color: Colors.green.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isRefreshing ? null : _refreshRates,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Refresh Rates',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fromCurrencyController.dispose();
    _toCurrencyController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}
