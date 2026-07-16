import 'package:currensee/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../widgets/glow_button.dart';  // ✅ ADDED
// ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED

class PDFExportScreen extends StatefulWidget {
  const PDFExportScreen({super.key}) ;

  @override
  State<PDFExportScreen> createState() => _PDFExportScreenState();
}

class _PDFExportScreenState extends State<PDFExportScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _loadDemoData();
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('conversions')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _history = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'from': data['fromCurrency'] ?? 'USD',
              'to': data['toCurrency'] ?? 'PKR',
              'fromAmount': data['fromAmount'] ?? 0.0,
              'toAmount': data['toAmount'] ?? 0.0,
              'rate': data['rate'] ?? 0.0,
              'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            };
          }).toList();
          _calculateTotal();
          _isLoading = false;
        });
      } else {
        _loadDemoData();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    setState(() {
      _history = [
        {'from': 'USD', 'to': 'PKR', 'fromAmount': 1.0, 'toAmount': 278.50, 'rate': 278.50, 'timestamp': DateTime.now().subtract(const Duration(hours: 2))},
        {'from': 'EUR', 'to': 'PKR', 'fromAmount': 50.0, 'toAmount': 15225.00, 'rate': 304.50, 'timestamp': DateTime.now().subtract(const Duration(hours: 5))},
        {'from': 'AED', 'to': 'PKR', 'fromAmount': 100.0, 'toAmount': 7580.00, 'rate': 75.80, 'timestamp': DateTime.now().subtract(const Duration(days: 1))},
      ];
      _calculateTotal();
      _isLoading = false;
    });
  }

  void _calculateTotal() {
    _totalAmount = _history.fold(0.0, (total, item) => total + (item['toAmount'] as double));
  }

  Future<void> _generatePDF() async {
    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'CurrenSee - Conversion History',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated on: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 16),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Transactions', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                          pw.Text('${_history.length}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Total Amount', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                          pw.Text('${_totalAmount.toStringAsFixed(2)} PKR', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('From', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('To', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('Converted', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('Rate', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                ),

                ..._history.map((item) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text(item['from'] ?? '')),
                        pw.Expanded(child: pw.Text(item['to'] ?? '')),
                        pw.Expanded(child: pw.Text('${item['fromAmount']}')),
                        pw.Expanded(child: pw.Text('${item['toAmount']}')),
                        pw.Expanded(child: pw.Text('${item['rate'].toStringAsFixed(4)}')),
                        pw.Expanded(child: pw.Text(DateFormat('MMM dd, yyyy').format(item['timestamp']))),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 20),
                pw.Divider(),

                pw.Center(
                  child: pw.Text(
                    'Generated by CurrenSee App',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Export PDF',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: AnimationUtils.fadeInSlide(  // ✅ WRAPPED WITH ANIMATION
        duration: const Duration(milliseconds: 500),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading data...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimationUtils.scaleIn(  // ✅ SCALE ANIMATION
                        duration: const Duration(milliseconds: 500),
                        begin: 0.8,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withAlpha(((0.1) * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            size: 80,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimationUtils.fadeIn(
                        duration: const Duration(milliseconds: 400),
                        child: const Text(
                          'Export History as PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_history.length} transactions found',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${_totalAmount.toStringAsFixed(2)} PKR',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      GlowButton(  // ✅ GLOW BUTTON
                        onPressed: _history.isEmpty ? () {} : _generatePDF,
                        glowColor: const Color(0xFF00E5FF),
                        child: Text(
                          _history.isEmpty ? 'No data to export' : 'Generate PDF',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

