import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';  // ✅ ADDED
import '../../widgets/glow_card.dart';    // ✅ ADDED
import '../../core/utils/animation_utils.dart';  // ✅ ADDED

class QRShareScreen extends StatefulWidget {
  const QRShareScreen({super.key}) ;

  @override
  State<QRShareScreen> createState() => _QRShareScreenState();
}

class _QRShareScreenState extends State<QRShareScreen> {
  String _qrData = 'CurrenSee: Currency Converter App';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateQRData();
  }

  void _generateQRData() {
    setState(() {
      _isGenerating = true;
      _qrData = 'CurrenSee://share?app=currensee&version=1.0.0';
      _isGenerating = false;
    });
  }

  Future<void> _shareQR() async {
    try {
      await Share.share(
        'Check out CurrenSee - Smart Currency Converter!\n\n'
        'Download now and get real-time rates!\n'
        'https://currensee.com/download',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(((0.03) * 255).round()),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'QR Share',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: AnimationUtils.fadeInSlide(  // ✅ WRAPPED WITH ANIMATION
        duration: const Duration(milliseconds: 500),
        child: Center(
          child: SingleChildScrollView(
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
                      color: const Color(0xFF00E5FF).withAlpha(((0.08) * 255).round()),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00E5FF).withAlpha(((0.2) * 255).round())),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 64,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimationUtils.fadeIn(
                  duration: const Duration(milliseconds: 400),
                  child: const Text(
                    'Share CurrenSee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimationUtils.fadeIn(
                  duration: const Duration(milliseconds: 400),
                  child: const Text(
                    'Scan the matrix code to link and download',
                    style: TextStyle(color: Color(0xFF8A99AD), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 36),
                
                GlowCard(  // ✅ GLOW CARD
                  glowColor: const Color(0xFF00E5FF),
                  padding: const EdgeInsets.all(24),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 40),
                
                GlowButton(  // ✅ GLOW BUTTON
                  onPressed: _shareQR,
                  glowColor: const Color(0xFF00E5FF),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_rounded, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        'Share Referral Link',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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

