// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AboutScreen extends StatelessWidget {
//   const AboutScreen({super.key});

//   Future<Map<String, dynamic>> _fetchRealStats() async {
//     try {
//       final providersSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'provider').get();
//       final seekersSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'seeker').get();
//       final bookingsSnap = await FirebaseFirestore.instance.collection('bookings').where('status', isEqualTo: 'Completed').get();
//       final reviewsSnap = await FirebaseFirestore.instance.collection('reviews').get();

//       final int totalProviders = providersSnap.docs.length;
//       final int totalSeekers = seekersSnap.docs.length;
//       final int completedBookings = bookingsSnap.docs.length;

//       double averageRating = 0.0;
//       if (reviewsSnap.docs.isNotEmpty) {
//         double sum = 0.0;
//         for (var doc in reviewsSnap.docs) {
//           sum += ((doc.data())['rating'] ?? 0.0).toDouble();
//         }
//         averageRating = sum / reviewsSnap.docs.length;
//       }

//       return {
//         'totalSeekers': totalSeekers,
//         'totalProviders': totalProviders,
//         'completedBookings': completedBookings,
//         'averageRating': averageRating,
//       };
//     } catch (e) {
//       debugPrint('Error fetching about screen stats: $e');
//       return {
//         'totalSeekers': 0,
//         'totalProviders': 0,
//         'completedBookings': 0,
//         'averageRating': 0.0,
//       };
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isMobile = MediaQuery.of(context).size.width < 800;

//     return FutureBuilder<Map<String, dynamic>>(
//       future: _fetchRealStats(),
//       builder: (context, snapshot) {
//         final statsData = snapshot.data ?? {
//           'totalSeekers': 0,
//           'totalProviders': 0,
//           'completedBookings': 0,
//           'averageRating': 5.0,
//         };

//         return Scaffold(
//           backgroundColor: const Color(0xFFF8FAFC),
//           appBar: AppBar(
//             backgroundColor: Colors.white,
//             elevation: 0,
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
//               onPressed: () => Navigator.pop(context),
//             ),
//             title: Text(
//               'About Us',
//               style: GoogleFonts.inter(
//                 color: const Color(0xFF1A202C),
//                 fontWeight: FontWeight.w800,
//                 fontSize: 20,
//               ),
//             ),
//           ),
//           body: SingleChildScrollView(
//             child: Column(
//               children: [
//                 _buildHeroSection(isMobile),
//                 const SizedBox(height: 60),
//                 _buildStatsSection(isMobile, statsData),
//                 const SizedBox(height: 60),
//                 _buildMissionSection(isMobile),
//                 const SizedBox(height: 60),
//                 _buildStorySection(isMobile),
//                 const SizedBox(height: 60),
//                 _buildValuesSection(isMobile),
//                 const SizedBox(height: 60),
//                 _buildContactSection(isMobile),
//                 _buildFooter(),
//               ],
//             ),
//           ),
//         );
//       }
//     );
//   }

//   // Standardization: Matches the uploaded image style
//   Widget _buildStandardCard({
//     required IconData icon,
//     required String title,
//     required String description,
//     required Color color,
//     Color? cardBgColor,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
//       decoration: BoxDecoration(
//         color: cardBgColor ?? Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 24,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 36),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             title,
//             style: GoogleFonts.inter(
//               fontSize: 22,
//               fontWeight: FontWeight.w800,
//               color: const Color(0xFF1A202C),
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             description,
//             style: GoogleFonts.inter(
//               fontSize: 15,
//               color: const Color(0xFF718096),
//               height: 1.6,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeroSection(bool isMobile) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: 60),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: const Icon(Icons.star_rounded, color: Colors.white, size: 48),
//           ),
//           const SizedBox(height: 32),
//           Text(
//             'Home Service AI',
//             style: GoogleFonts.inter(
//               fontSize: isMobile ? 32 : 44,
//               fontWeight: FontWeight.w900,
//               color: Colors.white,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Empowering Communities, Transforming Lives',
//             style: GoogleFonts.inter(
//               fontSize: isMobile ? 18 : 22,
//               fontWeight: FontWeight.w600,
//               color: Colors.white.withOpacity(0.9),
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: isMobile ? double.infinity : 700,
//             child: Text(
//               'We are on a mission to bridge the gap between skilled service providers and those who need their services, using AI-powered technology to create meaningful connections in the informal economy.',
//               style: GoogleFonts.inter(
//                 fontSize: 16,
//                 color: Colors.white.withOpacity(0.85),
//                 height: 1.6,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsSection(bool isMobile, Map<String, dynamic> data) {
//     final int totalSeekers = data['totalSeekers'] ?? 0;
//     final int totalProviders = data['totalProviders'] ?? 0;
//     final int completedBookings = data['completedBookings'] ?? 0;
//     final double averageRating = (data['averageRating'] ?? 5.0).toDouble();

//     final List<Widget> stats = [
//       _buildStandardCard(icon: Icons.people_outline, title: '$totalSeekers', description: 'Active Seekers', color: const Color(0xFF3182CE)),
//       _buildStandardCard(icon: Icons.business_center_outlined, title: '$totalProviders', description: 'Active Providers', color: const Color(0xFF38A169)),
//       _buildStandardCard(icon: Icons.check_circle_outline, title: '$completedBookings', description: 'Bookings Completed', color: const Color(0xFF9F7AEA)),
//       _buildStandardCard(icon: Icons.star_outline, title: averageRating.toStringAsFixed(1), description: 'Average Rating', color: const Color(0xFFECC94B)),
//     ];

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
//       child: isMobile
//           ? Column(children: stats.expand((w) => [w, const SizedBox(height: 20)]).toList()..removeLast())
//           : Row(children: stats.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: w))).toList()),
//     );
//   }

//   Widget _buildMissionSection(bool isMobile) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF6B46C1).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(Icons.rocket_launch_outlined, color: Color(0xFF6B46C1), size: 32),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 'Our Mission',
//                 style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(40),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15)),
//               ],
//             ),
//             child: Text(
//               'To democratize access to quality services by creating a trusted platform that empowers skilled professionals to grow their livelihoods while providing communities with reliable, affordable services.',
//               style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF4A5568), height: 1.7),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStorySection(bool isMobile) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF3182CE).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(Icons.auto_stories_outlined, color: Color(0xFF3182CE), size: 32),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 'Our Story',
//                 style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           Container(
//             padding: const EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: const Color(0xFFE2E8F0)),
//             ),
//             child: Column(
//               children: [
//                 _storyItem('The Problem', 'Millions of skilled professionals struggle to find steady work...', Icons.warning_amber_outlined, Colors.orange),
//                 const SizedBox(height: 24),
//                 _storyItem('Our Solution', 'We leverage cutting-edge AI technology to match providers...', Icons.lightbulb_outline, Colors.green),
//                 const SizedBox(height: 24),
//                 _storyItem('The Impact', 'Creating meaningful connections in the informal economy...', Icons.trending_up_outlined, Colors.blue),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _storyItem(String title, String description, IconData icon, Color color) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
//           child: Icon(icon, color: color, size: 24),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A202C))),
//               const SizedBox(height: 8),
//               Text(description, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF4A5568), height: 1.6)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildValuesSection(bool isMobile) {
//     final List<Widget> values = [
//       _buildStandardCard(icon: Icons.verified_user_outlined, title: 'Trust & Safety', description: 'Every provider is verified, every booking is secure', color: Colors.green),
//       _buildStandardCard(icon: Icons.balance_outlined, title: 'Fairness', description: 'Transparent pricing, no hidden fees, fair earnings', color: Colors.blue),
//       _buildStandardCard(icon: Icons.diversity_3_outlined, title: 'Community', description: 'Building bridges between people and connections', color: Colors.purple),
//       _buildStandardCard(icon: Icons.psychology_outlined, title: 'Innovation', description: 'Using AI to solve real-world problems in the informal economy', color: Colors.orange),
//     ];

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(color: const Color(0xFF9F7AEA).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//                 child: const Icon(Icons.diamond_outlined, color: Color(0xFF9F7AEA), size: 32),
//               ),
//               const SizedBox(width: 16),
//               Text('Our Core Values', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C))),
//             ],
//           ),
//           const SizedBox(height: 32),
//           isMobile
//               ? Column(children: values.expand((w) => [w, const SizedBox(height: 20)]).toList()..removeLast())
//               : Row(children: values.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: w))).toList()),
//         ],
//       ),
//     );
//   }

//   Widget _buildContactSection(bool isMobile) {
//     final List<Widget> contacts = [
//       _buildStandardCard(icon: Icons.email_outlined, title: 'Email', description: 'mehdhathafeez@gmail.com', color: const Color(0xFF3182CE), cardBgColor: const Color(0xFFF8FAFC)),
//       _buildStandardCard(icon: Icons.location_on_outlined, title: 'Location', description: 'Karachi, Pakistan', color: const Color(0xFFE53E3E), cardBgColor: const Color(0xFFF8FAFC)),
//     ];

//     return Container(
//       width: double.infinity,
//       color: Colors.white,
//       padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: 60),
//       child: Column(
//         children: [
//           Text('Get in Touch', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C))),
//           const SizedBox(height: 16),
//           Text('Have questions? We\'d love to hear from you.', style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF718096), fontWeight: FontWeight.w500)),
//           const SizedBox(height: 40),
//           isMobile
//               ? Column(children: contacts.expand((w) => [w, const SizedBox(height: 20)]).toList()..removeLast())
//               : Row(children: contacts.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: w))).toList()),
//         ],
//       ),
//     );
//   }

//   Widget _buildFooter() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 32),
//       color: const Color(0xFFF8FAFC),
//       child: Center(
//         child: Text(
//           '© ${DateTime.now().year} Home Service AI. All rights reserved.',
//           style: GoogleFonts.inter(
//             fontSize: 14,
//             color: const Color(0xFF718096),
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Us',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A202C),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(isMobile),
            const SizedBox(height: 60),
            _buildEcosystemSection(isMobile),
            const SizedBox(height: 60),
            _buildMissionSection(isMobile),
            const SizedBox(height: 60),
            _buildStorySection(isMobile),
            const SizedBox(height: 60),
            _buildValuesSection(isMobile),
            const SizedBox(height: 60),
            _buildContactSection(isMobile),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // Standardization: Matches the clean design card layout
  Widget _buildStandardCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    Color? cardBgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A202C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF718096),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 32),
          Text(
            'Home Service AI',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 32 : 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Empowering Communities, Transforming Lives',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: isMobile ? double.infinity : 700,
            child: Text(
              'We are on a mission to bridge the gap between skilled service providers and those who need their services, using AI-powered technology to create meaningful connections in the informal economy.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.85),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Refactored from Stats to Ecosystem Information Cards
  Widget _buildEcosystemSection(bool isMobile) {
    final List<Widget> cards = [
      _buildStandardCard(
        icon: Icons.people_outline,
        title: 'Service Seekers',
        description: 'Everyday users looking for reliable, verified, and safe home assistance. Our AI engine instantly matches their explicit requirements with vetted professionals nearby.',
        color: const Color(0xFF3182CE),
      ),
      _buildStandardCard(
        icon: Icons.business_center_outlined,
        title: 'Service Providers',
        description: 'Skilled local professionals looking to scale their income. We equip them with digital identity tools, transparent work discovery, and AI smart-scheduling.',
        color: const Color(0xFF38A169),
      ),
      _buildStandardCard(
        icon: Icons.check_circle_outline,
        title: 'Smart Bookings',
        description: 'A seamless scheduling system with integrated escrow security. Designed to handle upfront parameters automatically, tracking progress dynamically from request to completion.',
        color: const Color(0xFF9F7AEA),
      ),
      _buildStandardCard(
        icon: Icons.star_outline,
        title: 'Quality & Trust',
        description: 'Backed by decentralized peer review algorithms. Every interaction establishes a reputation graph ensuring exceptional service benchmarks across our entire network.',
        color: const Color(0xFFECC94B),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182CE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub_outlined, color: Color(0xFF3182CE), size: 32),
              ),
              const SizedBox(width: 16),
              Text(
                'Our Ecosystem',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          isMobile
              ? Column(children: cards.expand((w) => [w, const SizedBox(height: 20)]).toList()..removeLast())
              : Row(children: cards.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: w))).toList()),
        ],
      ),
    );
  }

  Widget _buildMissionSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rocket_launch_outlined, color: Color(0xFF6B46C1), size: 32),
              ),
              const SizedBox(width: 16),
              Text(
                'Our Mission',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15)),
              ],
            ),
            child: Text(
              'To democratize access to quality services by creating a trusted platform that empowers skilled professionals to grow their livelihoods while providing communities with reliable, affordable services.',
              style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF4A5568), height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorySection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182CE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories_outlined, color: Color(0xFF3182CE), size: 32),
              ),
              const SizedBox(width: 16),
              Text(
                'Our Story',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _storyItem('The Problem', 'Millions of skilled professionals struggle to find steady work...', Icons.warning_amber_outlined, Colors.orange),
                const SizedBox(height: 24),
                _storyItem('Our Solution', 'We leverage cutting-edge AI technology to match providers...', Icons.lightbulb_outline, Colors.green),
                const SizedBox(height: 24),
                _storyItem('The Impact', 'Creating meaningful connections in the informal economy...', Icons.trending_up_outlined, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storyItem(String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A202C))),
              const SizedBox(height: 8),
              Text(description, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF4A5568), height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValuesSection(bool isMobile) {
    final List<Widget> values = [
      _buildStandardCard(icon: Icons.verified_user_outlined, title: 'Trust & Safety', description: 'Every provider is verified, every booking is secure', color: Colors.green),
      _buildStandardCard(icon: Icons.balance_outlined, title: 'Fairness', description: 'Transparent pricing, no hidden fees, fair earnings', color: Colors.blue),
      _buildStandardCard(icon: Icons.diversity_3_outlined, title: 'Community', description: 'Building bridges between people and connections', color: Colors.purple),
      _buildStandardCard(icon: Icons.psychology_outlined, title: 'Innovation', description: 'Using AI to solve real-world problems in the informal economy', color: Colors.orange),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF9F7AEA).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.diamond_outlined, color: Color(0xFF9F7AEA), size: 32),
              ),
              const SizedBox(width: 16),
              Text('Our Core Values', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C))),
            ],
          ),
          const SizedBox(height: 32),
          isMobile
              ? Column(children: values.expand((w) => [w, const SizedBox(height: 20)]).toList()..removeLast())
              : Row(children: values.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: w))).toList()),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isMobile) {
    final List<Widget> contacts = [
      _buildStandardCard(icon: Icons.email_outlined, title: 'Email', description: 'mehdhathafeez@gmail.com', color: const Color(0xFF3182CE), cardBgColor: const Color(0xFFF8FAFC)),
      _buildStandardCard(icon: Icons.location_on_outlined, title: 'Location', description: 'Karachi, Pakistan', color: const Color(0xFFE53E3E), cardBgColor: const Color(0xFFF8FAFC)),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: 60),
      child: Column(
        children: [
          Text('Get in Touch', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C))),
          const SizedBox(height: 16),
          Text('Have questions? We\'d love to hear from you.', style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF718096), fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          isMobile
              ? Column(children: contacts.expand((w) => [w, const SizedBox(height: 20)]).toList()..removeLast())
              : Row(children: contacts.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: w))).toList()),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Text(
          '© ${DateTime.now().year} Home Service AI. All rights reserved.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}