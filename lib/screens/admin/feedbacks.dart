import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/glow_card.dart';

class FeedbacksScreen extends StatefulWidget {
  const FeedbacksScreen({super.key});

  @override
  State<FeedbacksScreen> createState() => _FeedbacksScreenState();
}

class _FeedbacksScreenState extends State<FeedbacksScreen> {
  int _totalFeedbacks = 0;
  int _newFeedbacks = 0;
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFeedbackStats();
  }

  Future<void> _loadFeedbackStats() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('feedbacks').get();

      _totalFeedbacks = snapshot.docs.length;

      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final newSnapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('createdAt', isGreaterThanOrEqualTo: yesterday)
          .get();
      _newFeedbacks = newSnapshot.docs.length;

      final ratedFeedbacks = snapshot.docs.where((doc) {
        final data = doc.data();
        return _readRating(data['rating']) > 0;
      }).toList();

      if (ratedFeedbacks.isNotEmpty) {
        double totalRating = 0;
        for (var doc in ratedFeedbacks) {
          final data = doc.data();
          totalRating += _readRating(data['rating']);
        }
        _avgRating = totalRating / ratedFeedbacks.length;
      } else {
        _avgRating = 0.0;
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('Error loading feedbacks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Feedbacks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _newFeedbacks > 0
                      ? Colors.green.withAlpha(((0.2) * 255).round())
                      : Colors.grey.withAlpha(((0.2) * 255).round()),
                  border: Border.all(
                    color: _newFeedbacks > 0 ? Colors.green : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _newFeedbacks > 0 ? '$_newFeedbacks New' : 'No New',
                  style: TextStyle(
                    color: _newFeedbacks > 0 ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          GlowCard(
            glowColor: const Color(0xFF00E5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Feedbacks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feedbacks')
                      .orderBy('createdAt', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
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

                    final feedbacks = snapshot.data!.docs;
                    
                    if (feedbacks.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No feedbacks yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: feedbacks.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final feedback = data['feedback'] ?? '';
                        final author =
                            (data['userName'] ??
                                    data['author'] ??
                                    data['userEmail'] ??
                                    'Anonymous')
                                .toString();
                        final rating = _readRating(data['rating']);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _feedbackCard(feedback, author, rating),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: GlowCard(
                  glowColor: const Color(0xFF00E5FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avg Rating',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'out of 5.0',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlowCard(
                  glowColor: const Color(0xFF00E5FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Reviews',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _totalFeedbacks.toString(),
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'from users',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackCard(String feedback, String author, double rating) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(((0.05) * 255).round()),
        border: Border.all(color: Colors.white.withAlpha(((0.1) * 255).round())),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feedback,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                author,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Row(
                children: [
                  ..._ratingStars(rating),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFFFB800),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _readRating(dynamic value) {
    if (value is num) return value.toDouble().clamp(0.0, 5.0).toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) return 0.0;
    return parsed.clamp(0.0, 5.0).toDouble();
  }

  List<Widget> _ratingStars(double rating) {
    return List.generate(5, (index) {
      final starValue = index + 1;
      return Icon(
        rating >= starValue ? Icons.star_rounded : Icons.star_border_rounded,
        color: const Color(0xFFFFB800),
        size: 14,
      );
    });
  }

  // ignore: unused_element
  String _getStars(double rating) {
    final fullStars = rating.floor();
    final halfStar = rating - fullStars >= 0.5;
    
    String stars = '';
    for (int i = 0; i < fullStars; i++) {
      stars += '★';
    }
    if (halfStar) {
      stars += '★';
    }
    final remaining = 5 - stars.length;
    for (int i = 0; i < remaining; i++) {
      stars += '☆';
    }
    return stars;
  }
}

