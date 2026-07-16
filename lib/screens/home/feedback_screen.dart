import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/notification_service.dart';
// Niche diye gaye widgets LoginScreen se liye gaye hain consistency ke liye
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/glow_input.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  int _rating = 0;

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final feedbackText = _feedbackController.text.trim();
      final userName = user?.displayName ?? 'User';
      final userEmail = user?.email ?? 'anonymous@email.com';
      final userId = user?.uid ?? 'anonymous';
      
      // ✅ Save feedback with complete user info
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'feedback': feedbackText,
        'rating': _rating.toDouble(),
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // ✅ Preview text for notification
      final previewText = feedbackText.length > 50
          ? '${feedbackText.substring(0, 50)}...'
          : feedbackText;

      // ✅ Send notification to admin with complete user info
      await NotificationService().sendToAdmin(
        title: 'New Feedback Received 📝',
        message:
            'From: $userName ($userEmail)\nRating: $_rating/5\nFeedback: "$previewText"',
        type: 'feedback',
        relatedId: userId,
      );

      if (!mounted) return;
      _feedbackController.clear();
      setState(() => _rating = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Feedback submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00E5FF);

    // LoginScreen ki tarah GlassScaffold use kiya hai
    return GlassScaffold(
      // AppBar ko bhi transparent aur minimalistic banaya hai
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Feedback',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: neonCyan),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us what you think',
                style: TextStyle(
                  fontSize: 28, // Login Screen ke title size se match
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your feedback helps us improve the app and fix issues faster.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54, // Login Screen ke subtitle color se match
                ),
              ),
              const SizedBox(height: 40),
              
              // Login Screen ke container jaisa decoration
              Container(
                height: 150,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(((0.05) * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(((0.1) * 255).round()),
                  ),
                ),
                child: GlowInput(
                  controller: _feedbackController,
                  labelText: "Your Feedback",
                  hintText: 'Write your feedback here...',
                  prefixIcon: Icons.feedback_outlined,
                  glowColor: neonCyan,
                  // maxLines: 8, // Feedback ke liye badi input field
                  // GlowInput multi-line text handle karne ke liye adaptable hona chahiye
                ),
              ),
              
              const SizedBox(height: 30),

              _ratingSelector(neonCyan),
              
              const SizedBox(height: 30),
              
              // Login Screen ke GlowButton jaisa button
              GlowButton(
                onPressed: _isSubmitting ? () {} : _submitFeedback,
                glowColor: neonCyan,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF0B1329)),
                        ),
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          color: Color(0xFF0B1329),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingSelector(Color glowColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(((0.05) * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(((0.1) * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate your experience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = value <= _rating;

              return IconButton(
                tooltip: '$value star${value == 1 ? '' : 's'}',
                onPressed:
                    _isSubmitting ? null : () => setState(() => _rating = value),
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isSelected ? const Color(0xFFFFB800) : Colors.white38,
                  size: 34,
                ),
                splashRadius: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 42,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _rating == 0 ? 'Tap a star to add rating' : '$_rating out of 5',
            style: TextStyle(
              color: _rating == 0 ? Colors.white38 : glowColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
