import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingsDashboard extends StatefulWidget {
  final String role; // 'Seeker' or 'Provider'

  const BookingsDashboard({super.key, required this.role});

  @override
  State<BookingsDashboard> createState() => _BookingsDashboardState();
}

class _BookingsDashboardState extends State<BookingsDashboard> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final bool isSeeker = widget.role == 'Seeker';
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    Query bookingsQuery = FirebaseFirestore.instance.collection('bookings');
    if (isSeeker) {
      bookingsQuery = bookingsQuery.where('seekerId', isEqualTo: currentUserId);
    } else {
      bookingsQuery = bookingsQuery.where('providerId', isEqualTo: currentUserId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: bookingsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
          ));
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
        
        // Calculate counts dynamically!
        int totalCount = allDocs.length;
        int pendingCount = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Pending').length;
        int acceptedCount = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'ProviderAccepted').length;
        int confirmedCount = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Confirmed').length;
        int completedCount = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Completed').length;

        // Apply visual filtering
        List<QueryDocumentSnapshot> filteredDocs = allDocs;
        if (_selectedFilter != 'All') {
          final String filterStatus = _selectedFilter == 'Accepted' ? 'ProviderAccepted' : _selectedFilter;
          filteredDocs = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == filterStatus).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Dynamic Stats Section (No Mock Data!)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _statCard(context, '$totalCount', 'Total', Icons.calendar_today, const Color(0xFF3182CE), isMobile),
                _statCard(context, '$pendingCount', 'Pending', Icons.pending, const Color(0xFFDD6B20), isMobile),
                _statCard(context, '$acceptedCount', 'Accepted', Icons.thumb_up_alt_outlined, const Color(0xFFD69E2E), isMobile),
                _statCard(context, '$confirmedCount', 'Confirmed', Icons.check_circle, const Color(0xFF38A169), isMobile),
                _statCard(context, '$completedCount', 'Completed', Icons.done_all, const Color(0xFF6B46C1), isMobile),
              ],
            ),
            const SizedBox(height: 30),
            
            // Premium Status Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B46C1)),
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A202C),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                      });
                    }
                  },
                  items: <String>['All', 'Pending', 'Accepted', 'Confirmed', 'Completed']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            value == 'All'
                                ? Icons.all_inclusive
                                : value == 'Pending'
                                    ? Icons.pending_actions
                                    : value == 'Accepted'
                                        ? Icons.thumb_up_alt_outlined
                                        : value == 'Confirmed'
                                            ? Icons.check_circle_outline
                                            : Icons.done_all,
                            size: 18,
                            color: value == 'All'
                                ? const Color(0xFF3182CE)
                                : value == 'Pending'
                                    ? const Color(0xFFDD6B20)
                                    : value == 'Accepted'
                                        ? const Color(0xFFD69E2E)
                                        : value == 'Confirmed'
                                            ? const Color(0xFF38A169)
                                            : const Color(0xFF6B46C1),
                          ),
                          const SizedBox(width: 10),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Bookings List (No Mock Data!)
            if (filteredDocs.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFA0AEC0), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings found',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Matching alerts will appear here in real-time.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                  final docId = filteredDocs[index].id;
                  final service = data['service'] ?? 'Home service';
                  final otherPartyName = isSeeker 
                      ? 'Provider: ${data['providerName'] ?? 'Expert'}' 
                      : 'Client: ${data['seekerName'] ?? 'User'}';
                  final rate = data['providerRate'] ?? 'PKR 1,500/hr';
                  final status = data['status'] ?? 'Confirmed';
                  
                  final createdAt = data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now();
                  final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
                  final timeStr = '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, "0")}';

                  Color statusColor = const Color(0xFF38A169); // Confirmed (Green)
                  String displayStatus = status;
                  if (status == 'Pending') {
                    statusColor = const Color(0xFFDD6B20); // Orange
                  } else if (status == 'ProviderAccepted') {
                    statusColor = const Color(0xFFD69E2E); // Gold/Yellow
                    displayStatus = 'Accepted';
                  } else if (status == 'Completed') {
                    statusColor = const Color(0xFF6B46C1); // Purple
                  }

                  final bool alreadyReviewed = data['reviewed'] ?? false;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    otherPartyName,
                                    style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$dateStr • $timeStr',
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  rate,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900, 
                                    color: const Color(0xFF3182CE),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (status == 'Completed')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      displayStatus,
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  PopupMenuButton<String>(
                                    onSelected: (newStatus) async {
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(docId)
                                          .update({'status': newStatus});
                                    },
                                    itemBuilder: (context) => [
                                      if (status != 'Pending')
                                        const PopupMenuItem(value: 'Pending', child: Text('Mark Pending')),
                                      if (status != 'ProviderAccepted')
                                        const PopupMenuItem(value: 'ProviderAccepted', child: Text('Mark Accepted')),
                                      if (status != 'Confirmed')
                                        const PopupMenuItem(value: 'Confirmed', child: Text('Mark Confirmed')),
                                      const PopupMenuItem(value: 'Completed', child: Text('Mark Completed')),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            displayStatus,
                                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_drop_down, size: 12, color: statusColor),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                        if (status == 'Confirmed' || (status == 'Completed' && isSeeker && !alreadyReviewed)) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (status == 'Confirmed')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B46C1), // Premium purple
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.done_all, size: 16),
                                  label: Text('Complete Service', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('bookings')
                                        .doc(docId)
                                        .update({'status': 'Completed'});
                                  },
                                ),
                              if (status == 'Completed' && isSeeker && !alreadyReviewed)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFECC94B), // Gold
                                    foregroundColor: const Color(0xFF744210),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.star, size: 16),
                                  label: Text('Rate & Review', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                  onPressed: () {
                                    _showRatingDialog(
                                      context,
                                      docId,
                                      data['providerId'] ?? '',
                                      data['providerName'] ?? 'Expert',
                                      service,
                                      data['seekerName'] ?? 'A Seeker',
                                      data['seekerId'] ?? '',
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        );
      }
    );
  }

  Widget _statCard(BuildContext context, String value, String label, IconData icon, Color color, bool isMobile) {
    double cardWidth = isMobile 
        ? (MediaQuery.of(context).size.width - 60) / 2 
        : 180; 

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A202C),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3182CE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3182CE) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String bookingId, String providerId, String providerName, String service, String seekerName, String seekerId) {
    double selectedStars = 5.0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Rate your $service session!',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'How was your experience with $providerName?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF4A5568), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedStars ? Icons.star : Icons.star_border,
                            color: const Color(0xFFECC94B),
                            size: 36,
                          ),
                          onPressed: () {
                            if (!isSubmitting) {
                              setState(() {
                                selectedStars = index + 1.0;
                              });
                            }
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      enabled: !isSubmitting,
                      style: GoogleFonts.inter(color: const Color(0xFF2D3748)),
                      decoration: InputDecoration(
                        hintText: 'Share your detailed feedback...',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFFA0AEC0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6B46C1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting ? null : () async {
                    setState(() {
                      isSubmitting = true;
                    });

                    final String comment = commentController.text.trim();
                    final String activeUid = FirebaseAuth.instance.currentUser?.uid ?? seekerId;
                    final String activeName = seekerName.isEmpty || seekerName == 'A Seeker'
                        ? (FirebaseAuth.instance.currentUser?.displayName ?? 'Seeker')
                        : seekerName;

                    try {
                      // 1. Write review to global collection
                      await FirebaseFirestore.instance.collection('reviews').add({
                        'bookingId': bookingId,
                        'seekerId': activeUid,
                        'seekerName': activeName,
                        'providerId': providerId,
                        'providerName': providerName,
                        'rating': selectedStars,
                        'comment': comment.isEmpty ? 'Excellent service!' : comment,
                        'service': service,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // 2. Mark booking as reviewed
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(bookingId)
                          .update({'reviewed': true});

                      try {
                        // Recalculate average rating & review count and save directly to the provider user document
                        final reviewsQuerySnapshot = await FirebaseFirestore.instance
                            .collection('reviews')
                            .where('providerId', isEqualTo: providerId)
                            .get();
                        
                        double sum = 0.0;
                        int reviewsCount = reviewsQuerySnapshot.docs.length;
                        for (var doc in reviewsQuerySnapshot.docs) {
                          sum += (doc.data()['rating'] ?? 0.0).toDouble();
                        }
                        double averageRating = reviewsCount > 0 ? (sum / reviewsCount) : 5.0;

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(providerId)
                            .update({
                              'rating': double.parse(averageRating.toStringAsFixed(1)),
                              'reviewsCount': reviewsCount,
                            });

                        // 3. Notify the provider
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(providerId)
                            .collection('notifications')
                            .add({
                              'type': 'new_review',
                              'seekerName': activeName,
                              'rating': selectedStars,
                              'createdAt': FieldValue.serverTimestamp(),
                              'isRead': false,
                            });
                      } catch (innerErr) {
                        print('Non-critical error updating provider stats: $innerErr');
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      if (context.mounted) {
                        Navigator.pop(context);
                        // Show success SnackBar instead of dialog to avoid context issues
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '🎉 Review submitted successfully! Thank you for your feedback.',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: const Color(0xFF38A169),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error submitting review: $e');
                      if (context.mounted) {
                        setState(() {
                          isSubmitting = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit review. Please try again.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFFE53E3E),
                            behavior: SnackBarBehavior.floating,
                          )
                        );
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Submit Review', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}