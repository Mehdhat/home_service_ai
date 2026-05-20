import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingDashboard extends StatelessWidget {
  final String role; // 'Seeker' or 'Provider'

  const RatingDashboard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final bool isSeeker = role == 'Seeker';
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Setup real-time reviews stream query
    Query reviewsQuery = FirebaseFirestore.instance.collection('reviews');
    if (isSeeker) {
      reviewsQuery = reviewsQuery.where('seekerId', isEqualTo: currentUserId);
    } else {
      reviewsQuery = reviewsQuery.where('providerId', isEqualTo: currentUserId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: reviewsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
            ),
          );
        }

        final List<QueryDocumentSnapshot> allDocs = List.from(snapshot.data?.docs ?? []);
        
        // Sort in-memory descending by createdAt
        allDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;
          final aTime = aData?['createdAt'] != null
              ? (aData!['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = bData?['createdAt'] != null
              ? (bData!['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        // Real-Time Aggregate Calculations
        double averageRating = 0.0;
        if (allDocs.isNotEmpty) {
          double sum = allDocs.fold(0.0, (prev, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return prev + (data['rating'] ?? 5.0).toDouble();
          });
          averageRating = sum / allDocs.length;
        }

        final int totalReviews = allDocs.length;
        final int fiveStarCount = allDocs.where((doc) {
          final r = (doc.data() as Map<String, dynamic>)['rating'] ?? 5.0;
          return r >= 5.0;
        }).length;
        final int fourStarCount = allDocs.where((doc) {
          final r = (doc.data() as Map<String, dynamic>)['rating'] ?? 5.0;
          return r >= 4.0 && r < 5.0;
        }).length;
        final int threeStarOrLessCount = allDocs.where((doc) {
          final r = (doc.data() as Map<String, dynamic>)['rating'] ?? 5.0;
          return r < 4.0;
        }).length;

        // Visual presentation percentages
        double fiveStarPct = totalReviews > 0 ? fiveStarCount / totalReviews : 0.0;
        double fourStarPct = totalReviews > 0 ? fourStarCount / totalReviews : 0.0;
        double threeStarPct = totalReviews > 0 ? threeStarOrLessCount / totalReviews : 0.0;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              if (!isSeeker) ...[
                _buildOverallRatingCard(isMobile, averageRating, totalReviews),
                const SizedBox(height: 25),
              ],
              
              _buildStatsSection(isMobile, isSeeker, totalReviews, averageRating, fiveStarCount),
              const SizedBox(height: 30),
              
              if (!isSeeker && totalReviews > 0) ...[
                _buildRatingDistribution(isMobile, fiveStarCount, fourStarCount, threeStarOrLessCount, fiveStarPct, fourStarPct, threeStarPct),
                const SizedBox(height: 30),
              ],
              
              _buildReviewsList(isMobile, isSeeker, allDocs),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallRatingCard(bool isMobile, double averageRating, int totalReviews) {
    final String ratingText = totalReviews == 0 ? '0.0 (No review yet...)' : '${averageRating.toStringAsFixed(1)} / 5.0';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECC94B), Color(0xFFD69E2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFECC94B).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Professional Reputation',
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalReviews == 0 ? '0.0' : averageRating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 4),
                    child: Text(
                      totalReviews == 0 ? ' (No review yet...)' : '/ 5.0',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isMobile)
            Row(
              children: List.generate(5, (index) {
                final double starDiff = averageRating - index;
                if (starDiff >= 0.8) {
                  return const Icon(Icons.star, color: Colors.white, size: 32);
                } else if (starDiff >= 0.3) {
                  return const Icon(Icons.star_half, color: Colors.white, size: 32);
                } else {
                  return const Icon(Icons.star_border, color: Colors.white, size: 32);
                }
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isMobile, bool isSeeker, int totalReviews, double averageRating, int fiveStarCount) {
    if (isSeeker) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _statCard('$totalReviews', 'Reviews Written', Icons.edit_note, const Color(0xFF6B46C1), isMobile),
          _statCard(averageRating.toStringAsFixed(1), 'Average Given', Icons.star, const Color(0xFFECC94B), isMobile),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statCard('$totalReviews', 'Total Reviews', Icons.reviews_outlined, const Color(0xFFECC94B), isMobile),
        _statCard('$fiveStarCount', '5-Star Ratings', Icons.star_rate, const Color(0xFF38A169), isMobile),
        _statCard((totalReviews - fiveStarCount).toString(), 'Other Ratings', Icons.star_half_outlined, const Color(0xFF3182CE), isMobile),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(bool isMobile, int fiveStar, int fourStar, int threeStar, double fivePct, double fourPct, double threePct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Sentiment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _ratingBar(5, fiveStar, fivePct),
          const SizedBox(height: 12),
          _ratingBar(4, fourStar, fourPct),
          const SizedBox(height: 12),
          _ratingBar(3, threeStar, threePct),
        ],
      ),
    );
  }

  Widget _ratingBar(int stars, int count, double percentage) {
    return Row(
      children: [
        SizedBox(width: 15, child: Text('$stars', style: const TextStyle(fontWeight: FontWeight.bold))),
        const Icon(Icons.star, color: Color(0xFFECC94B), size: 14),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFFECC94B),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text('$count', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildReviewsList(bool isMobile, bool isSeeker, List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSeeker ? 'Past Reviews You Wrote' : 'Detailed Feedback',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        if (docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_outlined, color: Color(0xFFA0AEC0), size: 40),
                const SizedBox(height: 12),
                Text(
                  'No reviews matching this account.',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF718096)),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final double rating = (d['rating'] ?? 5.0).toDouble();
              final String comment = d['comment'] ?? 'Excellent service!';
              final String service = d['service'] ?? 'Home service';
              
              final createdAt = d['createdAt'] != null
                  ? (d['createdAt'] as Timestamp).toDate()
                  : DateTime.now();
              final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

              // Display other party name
              final String displayName = isSeeker
                  ? 'Provider: ${d['providerName'] ?? 'Expert'}'
                  : 'Client: ${d['seekerName'] ?? 'Seeker'}';

              return _reviewCard(displayName, rating.toInt(), comment, dateStr, service);
            },
          ),
      ],
    );
  }

  Widget _reviewCard(String name, int rating, String comment, String date, String tag) {
    final String initial = name.contains(':') ? name.split(':')[1].trim()[0] : name[0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFECC94B).withOpacity(0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(color: Color(0xFFD69E2E), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(8)),
                child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => Icon(Icons.star, color: i < rating ? const Color(0xFFECC94B) : Colors.grey[300], size: 16)),
          ),
          const SizedBox(height: 8),
          Text(comment, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}