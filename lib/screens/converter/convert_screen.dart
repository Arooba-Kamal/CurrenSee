import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/services/firestore_service.dart';
import '../../core/utils/animation_utils.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/glow_card.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  // API Configuration
  String _apiKey = '36141dbe41d8328fd4bf1088'; // Your API key
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6/';
  
  // State
  Map<String, dynamic> _rates = {};
  bool _isLoading = false;
  bool _isConverting = false;
  String _error = '';
  String _connectionStatus = 'Checking...';
  bool _isApiConnected = false;
  List<String> _currencies = [];
  
  // Currency selection
  final TextEditingController _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'USD';
  String _toCurrency = 'PKR';
  double? _convertedAmount;
  double? _rate;

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Fetch exchange rates from API
  Future<void> _fetchExchangeRates() async {
    if (_apiKey.isEmpty) {
      setState(() {
        _error = 'Please add your API key';
        _isLoading = false;
        _isApiConnected = false;
        _connectionStatus = '❌ No API Key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _isApiConnected = false;
      _connectionStatus = '🔄 Connecting...';
    });

    try {
      final url = Uri.parse('$_baseUrl$_apiKey/latest/USD');
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['result'] == 'success') {
          setState(() {
            _rates = Map<String, dynamic>.from(data['conversion_rates']);
            _currencies = _rates.keys.toList()..sort();
            _error = '';
            _isApiConnected = true;
            _connectionStatus = '✅ API Connected';
          });
        } else {
          setState(() {
            _error = data['error-type'] ?? 'API returned an error';
            _isApiConnected = false;
            _connectionStatus = '❌ API Error';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load data. Status: ${response.statusCode}';
          _isApiConnected = false;
          _connectionStatus = '❌ Connection Failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isApiConnected = false;
        _connectionStatus = '❌ Error';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Convert currency using fetched rates
  double _convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (_rates.isEmpty || !_rates.containsKey(fromCurrency) || !_rates.containsKey(toCurrency)) {
      return 0.0;
    }
    
    final fromRate = _rates[fromCurrency];
    final toRate = _rates[toCurrency];
    
    if (fromRate == null || toRate == null) {
      return 0.0;
    }
    
    final inBase = amount / fromRate;
    return inBase * toRate;
  }

  // Convert and save to history
  Future<void> _convertAndSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login before saving conversions');
      return;
    }

    if (_rates.isEmpty) {
      _showMessage('Exchange rates not loaded. Please try again.');
      await _fetchExchangeRates();
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount');
      return;
    }

    setState(() => _isConverting = true);

    try {
      // Convert using the fetched rates
      final converted = _convertCurrency(amount, _fromCurrency, _toCurrency);
      final rate = amount == 0 ? 0.0 : converted / amount;

      // Save to Firestore
      await FirestoreService.saveConversion({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'fromCurrency': _fromCurrency,
        'toCurrency': _toCurrency,
        'fromAmount': amount,
        'toAmount': converted,
        'rate': rate,
      });

      if (!mounted) return;
      setState(() {
        _convertedAmount = converted;
        _rate = rate;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Conversion failed: $e');
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  void _swapCurrencies() {
    setState(() {
      final oldFrom = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = oldFrom;
      _convertedAmount = null;
      _rate = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Currency Converter', style: TextStyle(color: Colors.white)),
        actions: [
          // Refresh button
          IconButton(
            tooltip: 'Refresh Rates',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
            onPressed: _isLoading ? null : _fetchExchangeRates,
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded, color: Color(0xFF00E5FF)),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
      body: AnimationUtils.fadeInSlide(
        duration: const Duration(milliseconds: 400),
        child: _isLoading && _rates.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading exchange rates...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isApiConnected 
                          ? Colors.green.withAlpha((0.15 * 255).round())
                          : Colors.red.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isApiConnected ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isApiConnected ? Icons.check_circle : Icons.error,
                          color: _isApiConnected ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _connectionStatus,
                          style: TextStyle(
                            color: _isApiConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_currencies.length} currencies',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Converter Card
                  GlowCard(
                    glowColor: const Color(0xFF00E5FF),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(color: Color(0xFF8A99AD), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha((0.05 * 255).round()),
                            hintText: '0.00',
                            hintStyle: const TextStyle(color: Colors.white24),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).round())),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).round())),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: _currencyPicker('From', _fromCurrency, (value) {
                              setState(() {
                                _fromCurrency = value;
                                _convertedAmount = null;
                                _rate = null;
                              });
                            })),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: IconButton(
                                tooltip: 'Swap',
                                onPressed: _swapCurrencies,
                                icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00E5FF), size: 30),
                              ),
                            ),
                            Expanded(child: _currencyPicker('To', _toCurrency, (value) {
                              setState(() {
                                _toCurrency = value;
                                _convertedAmount = null;
                                _rate = null;
                              });
                            })),
                          ],
                        ),
                        const SizedBox(height: 22),
                        GlowButton(
                          onPressed: (_isLoading || _isConverting) ? null : _convertAndSave,
                          glowColor: const Color(0xFF00E5FF),
                          child: _isConverting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.currency_exchange_rounded, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text('Convert & Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Result Card
                  if (_convertedAmount != null)
                    GlowCard(
                      glowColor: Colors.greenAccent,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Result', style: TextStyle(color: Color(0xFF8A99AD))),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_convertedAmount!.toStringAsFixed(2)} $_toCurrency',
                              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1 $_fromCurrency = ${(_rate ?? 0).toStringAsFixed(4)} $_toCurrency',
                            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Saved to your account history',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 18),
                  
                  // Exchange Rates List (optional)
                  if (_currencies.isNotEmpty)
                    GlowCard(
                      glowColor: const Color(0xFF00E5FF),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exchange Rates',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Base: USD',
                            style: TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _currencies.length > 10 ? 10 : _currencies.length,
                              itemBuilder: (context, index) {
                                final currency = _currencies[index];
                                final rate = _rates[currency];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        currency,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                      ),
                                      const Spacer(),
                                      Text(
                                        rate != null ? rate.toStringAsFixed(4) : 'N/A',
                                        style: const TextStyle(color: Color(0xFF00E5FF)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _currencyPicker(String label, String value, ValueChanged<String> onChanged) {
    // Use fetched currencies if available, otherwise fallback to default list
    final availableCurrencies = _currencies.isNotEmpty ? _currencies : const ['USD', 'PKR', 'EUR', 'GBP', 'AED', 'INR'];
    
    // Ensure the current value exists in the list
    String selectedValue = value;
    if (!availableCurrencies.contains(value) && availableCurrencies.isNotEmpty) {
      selectedValue = availableCurrencies.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(selectedValue);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha((0.1 * 255).round())),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00E5FF)),
              items: availableCurrencies
                  .map((currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}