import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';
import '../../core/utils/animation_utils.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isApiWorking = true;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  // ✅ GEMINI API Configuration - USING LATEST MODELS
  // 🔑 Get your key: https://aistudio.google.com/apikey
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE'; // ⚠️ Replace with your key
  
  // ✅ Using Gemini 2.5 Flash (Fast & Efficient)
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=';
  
  // Alternative models (comment/uncomment to switch):
  // static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=';
  
  // ✅ Exchange Rate API - Already Working
  static const String _exchangeApiKey = 'f3fa7d18b8d0d04766403bb7';
  static const String _exchangeApiUrl = 'https://v6.exchangerate-api.com/v6/';
  
  Map<String, dynamic> _rates = {};
  List<String> _currencies = [];
  bool _isRatesLoading = false;
  String _baseCurrency = 'USD';
  bool _ratesLoaded = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController);
    
    _fetchExchangeRates();
    
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      _messages.add({
        'role': 'assistant',
        'content': '🔑 **Gemini API Key Required!**\n\n'
            'Get your FREE key at:\n'
            'https://aistudio.google.com/apikey\n\n'
            '💡 Then replace it in the code.',
      });
      _isApiWorking = false;
    }
  }

  Future<void> _fetchExchangeRates() async {
    setState(() => _isRatesLoading = true);

    try {
      final url = Uri.parse('$_exchangeApiUrl$_exchangeApiKey/latest/$_baseCurrency');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            _rates = Map<String, dynamic>.from(data['conversion_rates']);
            _currencies = _rates.keys.toList()..sort();
            _isRatesLoading = false;
            _ratesLoaded = true;
          });
          
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': '✅ **${_currencies.length} Currencies Loaded!**\n\n'
                  '💱 Now you can ask about any currency!',
            });
          });
        }
      }
    } catch (e) {
      setState(() => _isRatesLoading = false);
      print('❌ Rate error: $e');
    }
  }

  String _convertCurrency(double amount, String from, String to) {
    if (_rates.isEmpty || !_rates.containsKey(from) || !_rates.containsKey(to)) {
      return '0.00';
    }
    final fromRate = _rates[from];
    final toRate = _rates[to];
    if (fromRate == null || toRate == null) return '0.00';
    final result = (amount / fromRate) * toRate;
    return result.toStringAsFixed(2);
  }

  String _getRate(String from, String to) {
    if (_rates.isEmpty || !_rates.containsKey(from) || !_rates.containsKey(to)) {
      return 'N/A';
    }
    final fromRate = _rates[from];
    final toRate = _rates[to];
    if (fromRate == null || toRate == null) return 'N/A';
    return (toRate / fromRate).toStringAsFixed(4);
  }

  String _getAllRates() {
    if (_rates.isEmpty) return '⚠️ Rates not available';
    final major = ['USD', 'PKR', 'EUR', 'GBP', 'AED', 'INR', 'CAD', 'AUD'];
    final sb = StringBuffer();
    sb.writeln('📊 **Live Rates (Base: USD)**\n');
    for (var c in major) {
      if (_rates.containsKey(c)) {
        sb.writeln('1 USD = ${_rates[c].toStringAsFixed(4)} $c');
      }
    }
    return sb.toString();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'role': 'assistant',
      'content': '👋 **Welcome to CurrenSee AI!**\n\n'
          '🤖 Powered by **Gemini 2.5 Flash**\n'
          '💱 **What I can do:**\n'
          '• Live currency rates 📊\n'
          '• Instant conversions 🔄\n'
          '• Smart insights 🧠\n\n'
          '📌 **Try:**\n'
          '• "USD to PKR rate"\n'
          '• "Convert 100 USD to EUR"\n'
          '• "Show all rates"\n\n'
          '⚡ *Latest Gemini 2.5 AI*',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String? _processCurrencyQuery(String message) {
    final lowerMsg = message.toLowerCase().trim();
    
    if (lowerMsg.contains('all') && (lowerMsg.contains('rate') || lowerMsg.contains('currency') || lowerMsg.contains('show'))) {
      return _getAllRates();
    }
    
    final convertPattern = RegExp(r'(\d+(?:\.\d+)?)\s*([A-Za-z]{3})\s*(?:to|in|->)?\s*([A-Za-z]{3})');
    final match = convertPattern.firstMatch(message);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!);
      final from = match.group(2)!.toUpperCase();
      final to = match.group(3)!.toUpperCase();
      if (amount != null && amount > 0 && _rates.containsKey(from) && _rates.containsKey(to)) {
        final result = _convertCurrency(amount, from, to);
        final rate = _getRate(from, to);
        return '💱 **Conversion Result**\n\n'
            '$amount $from = **$result $to**\n\n'
            '📊 1 $from = $rate $to';
      }
    }
    
    final ratePattern = RegExp(r'([A-Za-z]{3})\s*(?:to|in|->)?\s*([A-Za-z]{3})');
    final rateMatch = ratePattern.firstMatch(message);
    if (rateMatch != null && (lowerMsg.contains('rate') || lowerMsg.contains('what') || lowerMsg.contains('show'))) {
      final from = rateMatch.group(1)!.toUpperCase();
      final to = rateMatch.group(2)!.toUpperCase();
      if (_rates.containsKey(from) && _rates.containsKey(to)) {
        final rate = _getRate(from, to);
        return '📊 **Exchange Rate**\n\n'
            '1 $from = **$rate $to**';
      }
    }
    return null;
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '🔑 **Get Your Gemini API Key**\n\n'
              '1. Go to: https://aistudio.google.com/apikey\n'
              '2. Click "Create API Key"\n'
              '3. Copy the key\n'
              '4. Replace in code\n\n'
              '💡 It\'s **FREE**!',
        });
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final currencyResponse = _processCurrencyQuery(message);
      if (currencyResponse != null) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': currencyResponse});
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      print('📤 Sending to Gemini 2.5 Flash...');

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': 'You are a helpful currency assistant. Answer concisely: $message'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 500,
          'topP': 0.95,
          'topK': 64,
        }
      };

      final response = await http.post(
        Uri.parse('$_apiUrl$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout'),
      );

      print('📡 Gemini Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;
        
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '$aiResponse\n\n✨ *Powered by Gemini 2.5*',
          });
          _isLoading = false;
          _isApiWorking = true;
          _retryCount = 0;
        });
        _scrollToBottom();
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '⚠️ **API Error ${response.statusCode}**\n\n'
                'Check your API key at:\n'
                'https://aistudio.google.com/apikey\n\n'
                'Make sure:\n'
                '✅ Key is valid\n'
                '✅ Gemini API is enabled',
          });
          _isLoading = false;
          _isApiWorking = false;
        });
        _scrollToBottom();
      } else if (response.statusCode == 429) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '⏳ **Rate Limit Reached!**\n\n'
                'Please wait a moment and try again.\n'
                '💡 Free tier: 60 requests/minute',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '⚠️ **Error ${response.statusCode}**\n\n'
                'Please try again.',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error: $e');
      
      if (_retryCount < _maxRetries) {
        _retryCount++;
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '🔄 Retrying... ($_retryCount/$_maxRetries)',
          });
          _isLoading = false;
        });
        _scrollToBottom();
        await Future.delayed(Duration(seconds: _retryCount * 2));
        if (mounted) _sendMessage();
        return;
      }

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '⚠️ **Connection Error!**\n\n'
              'Please check:\n'
              '🔑 Your API key\n'
              '🌐 Internet connection\n'
              '🔄 Try again',
        });
        _isLoading = false;
        _isApiWorking = false;
      });
      _scrollToBottom();
    }
  }

  void _sendQuickResponse(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.03),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF8A2BE2)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'CurrenSee AI',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _ratesLoaded ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _ratesLoaded ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _ratesLoaded ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isRatesLoading ? '...' : '${_currencies.length}',
                    style: TextStyle(
                      color: _ratesLoaded ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF), size: 20),
              onPressed: _isRatesLoading ? null : _fetchExchangeRates,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
      body: AnimationUtils.fadeInSlide(
        duration: const Duration(milliseconds: 500),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMe = message['role'] == 'user';
                  return _buildChatBubble(message['content']!, isMe);
                },
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Gemini 2.5 is thinking...',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickChip('💱 USD to PKR', () => _sendQuickResponse('USD to PKR rate')),
                      const SizedBox(width: 8),
                      _buildQuickChip('📊 All rates', () => _sendQuickResponse('Show all exchange rates')),
                      const SizedBox(width: 8),
                      _buildQuickChip('🔄 100 USD to EUR', () => _sendQuickResponse('Convert 100 USD to EUR')),
                      const SizedBox(width: 8),
                      _buildQuickChip('🤖 Ask AI', () => _sendQuickResponse('Explain cryptocurrency in simple terms')),
                    ],
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: _ratesLoaded ? "Ask Gemini 2.5..." : "Loading rates...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlowButton(
                    onPressed: (_isLoading || _isRatesLoading) ? null : _sendMessage,
                    glowColor: const Color(0xFF00E5FF),
                    height: 45,
                    width: 50,
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.send,
                      color: Colors.black,
                      size: 20,
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

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    final isCurrency = text.contains('💱') || text.contains('📊');
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF6C2BD9), Color(0xFF8A2BE2)])
              : LinearGradient(
                  colors: isCurrency
                      ? [Colors.green.shade900.withOpacity(0.2), Colors.green.shade800.withOpacity(0.1)]
                      : [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe 
                ? const Color(0xFF8A2BE2).withOpacity(0.3)
                : (isCurrency ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.08)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
            if (!isMe) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: isCurrency
                          ? const LinearGradient(colors: [Colors.green, Color(0xFF00E5FF)])
                          : const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF8A2BE2)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCurrency ? 'Live Rates' : 'Gemini 2.5',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    isCurrency ? 'Real-time' : 'Latest AI',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}