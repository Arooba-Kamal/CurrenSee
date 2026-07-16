import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/glow_button.dart'; // Add button ke liye zaroori

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  List<Map<String, dynamic>> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _budgets = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Budget',
            'limit': (data['limit'] as num?)?.toDouble() ?? 0.0,
            'spent': (data['spent'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();
        _isLoading = false;
      });
    }
  }

  // ✅ Add Budget Dialog function (Wapas add kar diya)
  Future<void> _addBudget() async {
    final nameController = TextEditingController();
    final limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Add New Budget', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: limitController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Limit (PKR)', labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          GlowButton(
            glowColor: const Color(0xFF00E5FF),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('budgets').add({
                  'userId': user.uid,
                  'name': nameController.text.trim(),
                  'limit': double.tryParse(limitController.text) ?? 0.0,
                  'spent': 0.0,
                });
                Navigator.pop(context);
                _loadBudgets(); // Refresh
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF)), onPressed: _addBudget), // ✅ Add button
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBudgets),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty 
              ? const Center(child: Text("No budgets yet. Click '+' to add", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _budgets.length,
                  itemBuilder: (context, index) {
                    final b = _budgets[index];
                    double p = (b['limit'] > 0) ? (b['spent'] / b['limit']) * 100 : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlowCard(
                        glowColor: const Color(0xFF00E5FF),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(b['name'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                              Text('${p.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF00E5FF)))
                            ]),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: (b['spent'] / (b['limit'] == 0 ? 1 : b['limit'])).clamp(0, 1)),
                            const SizedBox(height: 10),
                            Text('Spent: PKR ${b['spent'].toInt()} / Limit: PKR ${b['limit'].toInt()}', 
                                 style: const TextStyle(color: Colors.white70))
                          ],
                        ),
                      ),
                    );
                  }),
    );
  }
}