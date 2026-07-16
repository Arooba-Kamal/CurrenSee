import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';

class SpendingTrackerScreen extends StatefulWidget {
  const SpendingTrackerScreen({super.key});

  @override
  State<SpendingTrackerScreen> createState() => _SpendingTrackerScreenState();
}

class _SpendingTrackerScreenState extends State<SpendingTrackerScreen> {
  Future<void> _addSpending() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add spending')),
      );
      return;
    }

    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Add Spending', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: categoryController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: amountController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (PKR)', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: locationController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Location', labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('spendings').add({
                  'userId': user.uid,
                  'category': categoryController.text.trim(),
                  'pkr': double.tryParse(amountController.text) ?? 0.0,
                  'usd': (double.tryParse(amountController.text) ?? 0.0) / 278.50,
                  'location': locationController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.pop(dialogContext);
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return GlassScaffold(
        appBar: AppBar(title: const Text('Spending Tracker')),
        body: const Center(
          child: Text('Please login to view spending history', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Spending Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Color(0xFF00E5FF)), onPressed: _addSpending),
        ],
      ),
      // ✅ StreamBuilder use kiya hai, screen automatic update hogi
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('spendings')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No records found", style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var s = snapshot.data!.docs[index];
              return _spendingCard(s['category'], 'PKR ${(s['pkr'] as num).toInt()}', '\$${(s['usd'] as num).toStringAsFixed(2)}', s['location']);
            },
          );
        },
      ),
    );
  }

  Widget _spendingCard(String cat, String pkr, String usd, String loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowCard(
        glowColor: const Color(0xFF00E5FF),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(pkr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(usd, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }
}
