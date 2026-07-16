import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/glow_card.dart';
import '../../core/services/notification_service.dart';

class ManageCurrenciesScreen extends StatefulWidget {
  const ManageCurrenciesScreen({super.key});

  @override
  State<ManageCurrenciesScreen> createState() => _ManageCurrenciesScreenState();
}

class _ManageCurrenciesScreenState extends State<ManageCurrenciesScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addCurrency() async {
    if (_codeController.text.isEmpty || _nameController.text.isEmpty || _rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim().toUpperCase();
      final name = _nameController.text.trim();
      final rate = double.parse(_rateController.text.trim());

      await FirebaseFirestore.instance.collection('currencies').add({
        'code': code,
        'name': name,
        'rate': rate,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ NOTIFICATION: Send to all users
      await NotificationService().sendToAllUsers(
        title: 'New Currency Added 💰',
        message: '$name ($code) has been added to the system.',
        type: 'info',
      );

      _codeController.clear();
      _nameController.clear();
      _rateController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Currency added successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleCurrency(String docId, bool currentStatus) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('currencies').doc(docId).get();
      final data = doc.data();
      final code = data?['code'] ?? 'Currency';
      final name = data?['name'] ?? code;
      final newStatus = currentStatus ? 'disabled' : 'enabled';

      await FirebaseFirestore.instance.collection('currencies').doc(docId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService().sendToAllUsers(
        title: 'Currency $newStatus',
        message: '$name ($code) has been $newStatus by admin.',
        type: 'info',
        relatedId: docId,
      );
    } catch (e) {
      debugPrint('Error toggling currency: $e');
    }
  }

  void _showEditDialog(String docId, String code, String name, double rate) {
    final codeController = TextEditingController(text: code);
    final nameController = TextEditingController(text: name);
    final rateController = TextEditingController(text: rate.toString());
    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1120),
        title: const Text('Edit Currency', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Currency Code',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Currency Name',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Exchange Rate',
                labelStyle: TextStyle(color: Colors.white54),
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
              final dialogNavigator = Navigator.of(parentContext);
              final messenger = ScaffoldMessenger.of(parentContext);
              try {
                final newCode = codeController.text.trim().toUpperCase();
                final newName = nameController.text.trim();
                final newRate = double.parse(rateController.text.trim());

                await FirebaseFirestore.instance.collection('currencies').doc(docId).update({
                  'code': newCode,
                  'name': newName,
                  'rate': newRate,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                // ✅ NOTIFICATION: Send to all users
                await NotificationService().sendToAllUsers(
                  title: 'Currency Updated 📝',
                  message: '$newName ($newCode) has been updated.',
                  type: 'info',
                );

                if (!mounted) return;

                dialogNavigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Currency updated'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;

                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            glowColor: const Color(0xFF00E5FF),
            height: 45,
            child: const Text('Update', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Currencies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          GlowCard(
            glowColor: const Color(0xFF00E5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Currency', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _codeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Code (USD)',
                          labelStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rateController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rate',
                          labelStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GlowButton(
                      onPressed: _isLoading ? () {} : _addCurrency,
                      glowColor: const Color(0xFF00E5FF),
                      height: 50,
                      width: 100,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          GlowCard(
            glowColor: const Color(0xFF00E5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Currencies', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('currencies')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            '${snapshot.data!.docs.length} currencies',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('currencies')
                      .orderBy('code')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                      );
                    }

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

                    final currencies = snapshot.data!.docs;
                    
                    if (currencies.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No currencies added yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: currencies.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final code = data['code'] ?? '';
                        final name = data['name'] ?? '';
                        final rate = data['rate'] ?? 0.0;
                        final isActive = data['isActive'] ?? true;
                        
                        return Column(
                          children: [
                            _currencyRow(
                              doc.id,
                              code,
                              name,
                              rate.toStringAsFixed(2),
                              isActive,
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
          ),
        ],
      ),
    );
  }

  Widget _currencyRow(String docId, String code, String name, String rate, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rate: $rate', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
              Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                onPressed: () => _showEditDialog(docId, code, name, double.parse(rate)),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: Icon(
                  isActive ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () => _toggleCurrency(docId, isActive),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
