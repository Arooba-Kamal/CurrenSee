import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_card.dart';
import '../../core/utils/animation_utils.dart';

class TravelEstimatorScreen extends StatefulWidget {
  const TravelEstimatorScreen({super.key});

  @override
  State<TravelEstimatorScreen> createState() => _TravelEstimatorScreenState();
}

class _TravelEstimatorScreenState extends State<TravelEstimatorScreen> {
  Future<void> _addTrip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add a trip')),
      );
      return;
    }

    final destinationController = TextEditingController();
    final durationController = TextEditingController();
    final usdController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Add Trip', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: destinationController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Destination', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: durationController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Duration (Days)', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: usdController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budget (USD)', labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              if (usdController.text.isNotEmpty) {
                final usdAmount = double.tryParse(usdController.text) ?? 0.0;
                await FirebaseFirestore.instance.collection('trips').add({
                  'userId': user.uid,
                  'destination': destinationController.text.trim(),
                  'duration': durationController.text.trim(),
                  'usd': usdAmount,
                  'pkr': usdAmount * 278.50,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        appBar: AppBar(title: const Text('Travel Estimator')),
        body: const Center(
          child: Text('Please login to view travel history', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Travel Estimator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00E5FF)),
            onPressed: _addTrip,
          ),
        ],
      ),
      // ✅ StreamBuilder ko yahan direct return karo
      body: StreamBuilder<QuerySnapshot>(
        key: UniqueKey(), // Force UI to rebuild on stream change
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No trips found", style: TextStyle(color: Colors.white54)));
          }

          final docs = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return AnimationUtils.fadeInSlide(
                duration: const Duration(milliseconds: 300),
                child: _buildTripCard(data),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlowCard(
        glowColor: const Color(0xFF00E5FF),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(trip['destination'] ?? 'Trip', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("${trip['duration'] ?? '0'} Days", style: const TextStyle(color: Color(0xFF00E5FF))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${(trip['usd'] as num).toInt()}', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 18)),
                Text('PKR ${(trip['pkr'] as num).toInt()}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
