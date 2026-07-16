import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = "";
  String _result = "0";
  final neonCyan = const Color(0xFF00E5FF);

  // ✅ Budget Select karne ka Dialog
  void _showSaveToBudgetDialog(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final budgets = await FirebaseFirestore.instance
        .collection('budgets')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Select Budget to Update", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: budgets.docs.length,
            itemBuilder: (ctx, index) {
              final doc = budgets.docs[index];
              return ListTile(
                title: Text(doc['name'], style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.add_circle, color: Color(0xFF00E5FF)),
                onTap: () async {
                  // Firestore mein spent value update
                  await doc.reference.update({
                    'spent': FieldValue.increment(amount)
                  });
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Added PKR $amount to ${doc['name']}"))
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _onPressed(String value) {
    setState(() {
      if (value == "AC") {
        _input = "";
        _result = "0";
      } else if (value == "=") {
        try {
          Parser p = Parser();
          Expression exp = p.parse(_input.replaceAll('x', '*'));
          _result = "${exp.evaluate(EvaluationType.REAL, ContextModel())}";
        } catch (e) {
          _result = "Error";
        }
      } else {
        _input += value;
      }
    });
  }

  Widget _buildCalcButton(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SizedBox(
          height: 65,
          child: GlowButton(
            glowColor: neonCyan.withAlpha(100),
            onPressed: () => _onPressed(text),
            child: Text(text, 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22)
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text("Calculator"),
        backgroundColor: Colors.transparent,
        actions: [
          // ✅ Save button sirf tab dikhega jab result 0 nahi hoga
          if (_result != "0" && _result != "Error")
            IconButton(
              icon: Icon(Icons.save_alt, color: neonCyan),
              onPressed: () => _showSaveToBudgetDialog(double.tryParse(_result) ?? 0.0),
            )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_input, style: const TextStyle(color: Colors.white54, fontSize: 20)),
                const SizedBox(height: 10),
                Text(_result, style: TextStyle(color: neonCyan, fontSize: 50, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Row(children: [_buildCalcButton("7"), _buildCalcButton("8"), _buildCalcButton("9"), _buildCalcButton("/")]),
                Row(children: [_buildCalcButton("4"), _buildCalcButton("5"), _buildCalcButton("6"), _buildCalcButton("x")]),
                Row(children: [_buildCalcButton("1"), _buildCalcButton("2"), _buildCalcButton("3"), _buildCalcButton("-")]),
                Row(children: [_buildCalcButton("AC"), _buildCalcButton("0"), _buildCalcButton("="), _buildCalcButton("+")]),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}