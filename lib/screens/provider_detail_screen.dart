import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderDetailScreen extends StatefulWidget {
  final String providerUid;
  final String providerName;
  final String providerService;
  final String providerPhone;
  final String providerRate;

  const ProviderDetailScreen({
    super.key,
    required this.providerUid,
    required this.providerName,
    required this.providerService,
    required this.providerPhone,
    required this.providerRate,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  String _seekerName = 'Seeker';
  String _seekerPhone = 'Not Provided';

  @override
  void initState() {
    super.initState();
    _loadSeekerDetails();
  }

  Future<void> _loadSeekerDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _seekerName = doc.data()?['fullName'] ?? 'Seeker';
            _seekerPhone = doc.data()?['phoneNumber'] ?? 'Not Provided';
          });
        }
      }
    } catch (_) {}
  }

  void _sendSMS(String phone, String bodyText) async {
    final String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: clean,
      queryParameters: <String, String>{'body': bodyText},
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await launchUrl(Uri.parse('sms:$clean?body=${Uri.encodeComponent(bodyText)}'));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch SMS. Phone number: $clean'),
            backgroundColor: const Color(0xFF6B46C1),
          ),
        );
      }
    }
  }

  void _showSendNotificationDialog(BuildContext context) {
    final TextEditingController msgController = TextEditingController();
    String selectedTemplate = 'Need immediate service!';
    final List<String> templates = [
      'Need immediate service!',
      'Are you available for a quick job today?',
      'Please check your direct messages.',
      'Custom Message...',
    ];

    msgController.text = selectedTemplate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Notify ${widget.providerName}',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a template and customize your message below. This will automatically initiate a booking request.',
                      style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedTemplate,
                      decoration: InputDecoration(
                        labelText: 'Notification Template',
                        labelStyle: GoogleFonts.inter(color: const Color(0xFF6B46C1)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: Colors.white,
                      items: templates.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.inter(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedTemplate = val ?? 'Need immediate service!';
                          if (selectedTemplate != 'Custom Message...') {
                            msgController.text = selectedTemplate;
                          } else {
                            msgController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: msgController,
                      maxLines: 3,
                      enabled: true,
                      decoration: InputDecoration(
                        hintText: 'Type your custom alert message here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6B46C1)),
                        ),
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                  label: Text('Send Alert', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    String finalBody = msgController.text.trim();
                    if (finalBody.isEmpty) {
                      finalBody = selectedTemplate == 'Custom Message...' ? 'Hello!' : selectedTemplate;
                    }
                    
                    try {
                      final String cleanedService = widget.providerService.replaceAll(' Specialist', '').trim();

                      // 1. Automatically perform the booking process
                      final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
                        'seekerId': FirebaseAuth.instance.currentUser?.uid ?? '',
                        'seekerName': _seekerName,
                        'seekerPhone': _seekerPhone,
                        'providerId': widget.providerUid,
                        'providerName': widget.providerName,
                        'providerPhone': widget.providerPhone,
                        'service': cleanedService,
                        'status': 'Pending',
                        'createdAt': FieldValue.serverTimestamp(),
                        'message': finalBody,
                      });

                      // 2. Create a single notification in provider's notifications collection
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.providerUid)
                          .collection('notifications')
                          .add({
                            'title': '📩 Direct Seeker Alert from $_seekerName!',
                            'body': finalBody,
                            'createdAt': FieldValue.serverTimestamp(),
                            'seekerId': FirebaseAuth.instance.currentUser?.uid ?? '',
                            'seekerName': _seekerName,
                            'seekerPhone': _seekerPhone,
                            'service': cleanedService,
                            'type': 'direct_alert',
                            'bookingId': bookingRef.id,
                            'isRead': false,
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Emergency booking request sent to ${widget.providerName}!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF38A169),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error dispatching alert: $e');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Provider Profile',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A202C),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.providerUid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
            );
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final String bio = userData['bio'] ?? 'No bio provided by the specialist.';
          final String experience = (userData['experienceYears'] ?? '3').toString();
          final String availability = userData['availability'] ?? 'Mon-Fri, 9am - 5pm';
          final String location = userData['location'] ?? 'Karachi, Pakistan';
          final double profileRating = (userData['rating'] ?? 5.0).toDouble();
          final int profileReviewsCount = userData['reviewsCount'] ?? 0;

          final String hourlyRate = userData['hourlyRate'] != null
              ? 'PKR ${userData['hourlyRate']}/hour'
              : widget.providerRate;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Card Layout
                _buildHeroCard(bio, profileRating, profileReviewsCount),
                const SizedBox(height: 24),

                // 2. Details Card Layout
                _buildBusinessDetailsCard(experience, availability, location, hourlyRate),
                const SizedBox(height: 24),

                // 3. Live Seeker Feedback List Section
                _buildSeekerFeedbackSection(isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(String bio, double rating, int reviewsCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.providerName,
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF3182CE), size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.providerService,
                      style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFECC94B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          reviewsCount == 0 ? '0.0 (No review yet...)' : '$rating ($reviewsCount reviews)',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF2D3748)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'About Specialist',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4A5568), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailsCard(String experience, String availability, String location, String hourlyRate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Details',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
          ),
          const SizedBox(height: 20),
          _detailRow(Icons.monetization_on_outlined, 'Hourly Rate', hourlyRate, const Color(0xFF38A169)),
          const SizedBox(height: 12),
          _detailRow(Icons.work_history_outlined, 'Experience', '$experience Years', const Color(0xFF3182CE)),
          const SizedBox(height: 12),
          _detailRow(Icons.calendar_month_outlined, 'Availability', availability, const Color(0xFF805AD5)),
          const SizedBox(height: 12),
          _detailRow(Icons.location_on_outlined, 'Service Address', location, const Color(0xFFE53E3E)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final String msgBody = 'Hello ${widget.providerName}, I saw your profile on the Home Service app and would like to hire you! Please let me know when you are free.';
                    _sendSMS(widget.providerPhone, msgBody);
                  },
                  icon: const Icon(Icons.message, size: 16, color: Colors.white),
                  label: Text('Send SMS', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A169),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSendNotificationDialog(context),
                  icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                  label: Text('Direct Alert', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF718096), fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1A202C), fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSeekerFeedbackSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client Feedback & Reviews',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('providerId', isEqualTo: widget.providerUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6B46C1))),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
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
                      'No reviews yet',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4A5568), fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first seeker to rate and review this provider after a session!',
                      style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Group textual reviews
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reviewData = docs[index].data() as Map<String, dynamic>;
                final double rating = (reviewData['rating'] ?? 5.0).toDouble();
                final String comment = reviewData['comment'] ?? 'Excellent service!';
                final String seekerName = reviewData['seekerName'] ?? 'Client';
                final String serviceName = reviewData['service'] ?? 'Home Service';
                
                final createdAt = reviewData['createdAt'] != null
                    ? (reviewData['createdAt'] as Timestamp).toDate()
                    : DateTime.now();
                final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

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
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFECC94B),
                                size: 16,
                              );
                            }),
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(color: const Color(0xFFA0AEC0), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"$comment"',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF2D3748),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B46C1).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              serviceName,
                              style: GoogleFonts.inter(color: const Color(0xFF6B46C1), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '- By $seekerName',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF718096),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
