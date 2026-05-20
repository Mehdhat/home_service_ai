import 'dart:io';

void main() {
  final file = File('lib/screens/provider_dashboard.dart');
  var content = file.readAsStringSync();

  // Define the exact string to be replaced
  final target = '''        
        // Real-Time Emergency Alerts (Zero Overflow Header)
        const SizedBox(height: 30),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('notifications')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            final List<QueryDocumentSnapshot> docs = List.from(snapshot.data?.docs ?? []);
            
            // Sort in-memory descending by createdAt
            docs.sort((a, b) {
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

            // Mark all active notifications as read after a 2-second premium delay
            if (docs.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(seconds: 2), () {
                  _markAllNotificationsAsRead(docs);
                });
              });
            }

            if (docs.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53E3E), size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Real-Time Emergency Alerts',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE53E3E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String bookingId = data['bookingId'] ?? '';
                  final String type = data['type'] ?? '';

                  if (bookingId.isEmpty || type == 'direct_alert') {
                    if (type == 'new_review') {
                      final seekerName = data['seekerName'] ?? 'Client';
                      final double rating = (data['rating'] ?? 5.0).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(12),
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
                                      const Icon(Icons.star, color: Color(0xFFECC94B), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'New Review Received!',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D3748)),
                                      ),
                                      if (data['isRead'] != true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE53E3E),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('NEW', style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF718096)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Dismiss Notification',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(FirebaseAuth.instance.currentUser?.uid)
                                          .collection('notifications')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$seekerName rated you \$rating stars! Check it out in the Reviews tab.',
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A5568)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Direct Seeker Message/Alert
                    final seekerName = data['seekerName'] ?? 'Client';
                    final seekerPhone = data['seekerPhone'] ?? 'N/A';
                    final body = data['body'] ?? 'No text';
                    final service = data['service'] ?? 'Home service';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF2F7), // Elegant gray/blue
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6B46C1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.mail, color: Colors.white, size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Message from \$seekerName (\$service)',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2D3748)),
                                    ),
                                    if (data['isRead'] != true) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53E3E),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('NEW', style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF718096)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Dismiss Notification',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser?.uid)
                                        .collection('notifications')
                                        .doc(doc.id)
                                        .delete();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              body,
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A5568), height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Phone: \$seekerPhone',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF718096)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B46C1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Direct Alert',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6B46C1)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .snapshots(),
                    builder: (context, bookingSnapshot) {
                      if (!bookingSnapshot.hasData || !bookingSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final bData = bookingSnapshot.data!.data() as Map<String, dynamic>;
                      final String currentStatus = bData['status'] ?? 'Pending';
                      final seekerName = bData['seekerName'] ?? 'A Seeker';
                      final seekerPhone = bData['seekerPhone'] ?? '03001234567';
                      final service = bData['service'] ?? 'Home service';
                      final createdAtTimestamp = bData['createdAt'] as Timestamp?;
                      final DateTime createdAt = createdAtTimestamp != null
                          ? createdAtTimestamp.toDate()
                          : DateTime.now();
                      final String timeString = '\${createdAt.hour}:\${createdAt.minute.toString().padLeft(2, "0")}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: currentStatus == 'Confirmed'
                                ? const Color(0xFFF0FFF4) // Soft green for confirmed!
                                : currentStatus == 'ProviderAccepted'
                                    ? const Color(0xFFFFFFF0) // Soft gold for pending seeker
                                    : const Color(0xFFFFF5F5), // Soft red for pending provider
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentStatus == 'Confirmed'
                                  ? const Color(0xFFC6F6D5)
                                  : currentStatus == 'ProviderAccepted'
                                      ? const Color(0xFFFEFCBF)
                                      : const Color(0xFFFEB2B2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: currentStatus == 'Confirmed'
                                          ? const Color(0xFFC6F6D5)
                                          : currentStatus == 'ProviderAccepted'
                                              ? const Color(0xFFFEFCBF)
                                              : const Color(0xFFFED7D7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      currentStatus == 'Confirmed' ? Icons.check_circle_rounded : Icons.flash_on,
                                      color: currentStatus == 'Confirmed'
                                          ? const Color(0xFF38A169)
                                          : currentStatus == 'ProviderAccepted'
                                              ? const Color(0xFFD69E2E)
                                              : const Color(0xFFE53E3E),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      currentStatus == 'Confirmed'
                                                          ? '🎉 BOOKING CONFIRMED'
                                                          : currentStatus == 'ProviderAccepted'
                                                              ? '⌛ PENDING CLIENT CONFIRM'
                                                              : '🚨 EMERGENCY DISPATCH',
                                                      style: GoogleFonts.inter(
                                                        color: currentStatus == 'Confirmed'
                                                            ? const Color(0xFF38A169)
                                                            : currentStatus == 'ProviderAccepted'
                                                                ? const Color(0xFFD69E2E)
                                                                : const Color(0xFFE53E3E),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (data['isRead'] != true) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFE53E3E),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text('NEW', style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  timeString,
                                                  style: GoogleFonts.inter(
                                                    color: const Color(0xFF718096),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF718096)),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  tooltip: 'Dismiss Notification',
                                                  onPressed: () async {
                                                    await FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(FirebaseAuth.instance.currentUser?.uid)
                                                        .collection('notifications')
                                                        .doc(doc.id)
                                                        .delete();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentStatus == 'Confirmed'
                                              ? 'Your session with \$seekerName is active!'
                                              : '\$seekerName needs a \$service immediately!',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF2D3748),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Phone: \$seekerPhone',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF4A5568),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.message, color: Color(0xFF3182CE), size: 28),
                                    onPressed: () async {
                                      final String clean = seekerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
                                      final String bodyText = 'Hi \$seekerName, this is \$_providerName. I saw your emergency request for \$service!';
                                      final Uri smsUri = Uri(
                                        scheme: 'sms',
                                        path: clean,
                                        queryParameters: <String, String>{'body': bodyText},
                                      );
                                      try {
                                        if (await canLaunchUrl(smsUri)) {
                                          await launchUrl(smsUri);
                                        } else {
                                          await launchUrl(Uri.parse('sms:\$clean?body=\${Uri.encodeComponent(bodyText)}'));
                                        }
                                      } catch (_) {}
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  if (currentStatus == 'Pending')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE53E3E),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: Text('Accept Request', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                      onPressed: () async {
                                        try {
                                          // 1. Update global booking status to ProviderAccepted
                                          await FirebaseFirestore.instance
                                              .collection('bookings')
                                              .doc(bookingId)
                                              .update({'status': 'ProviderAccepted'});

                                          // 2. Write notification to Seeker's notifications subcollection
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(bData['seekerId'])
                                              .collection('notifications')
                                              .add({
                                                'type': 'provider_accepted',
                                                'providerId': FirebaseAuth.instance.currentUser?.uid ?? '',
                                                'providerName': _providerName,
                                                'bookingId': bookingId,
                                                'service': service,
                                                'seekerName': seekerName,
                                                'createdAt': FieldValue.serverTimestamp(),
                                              });

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Accepted! Seeker has been notified in real time.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                                backgroundColor: const Color(0xFF319795),
                                                behavior: SnackBarBehavior.floating,
                                              )
                                            );
                                          }
                                        } catch (e) {
                                          print('Error accepting booking: \$e');
                                        }
                                      },
                                    ),
                                  if (currentStatus == 'ProviderAccepted')
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFD69E2E),
                                        side: const BorderSide(color: Color(0xFFD69E2E)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(color: Color(0xFFD69E2E), strokeWidth: 2),
                                      ),
                                      label: Text('Pending Seeker...', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                      onPressed: null,
                                    ),
                                  if (currentStatus == 'Confirmed')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF38A169),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: Text('Complete Session', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('bookings')
                                            .doc(bookingId)
                                            .update({'status': 'Completed'});
                                        
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth.instance.currentUser?.uid)
                                            .collection('notifications')
                                            .doc(doc.id)
                                            .delete();
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('🎉 Service completed!'),
                                            backgroundColor: const Color(0xFF38A169),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ],
    );
  }''';

  final replacement = '''      ],
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53E3E), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Real-Time Emergency Alerts',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE53E3E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Review direct seeker messages, system dispatches, and incoming reviews below.',
            style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildNotificationsList(),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final List<QueryDocumentSnapshot> docs = List.from(snapshot.data?.docs ?? []);
        
        // Sort in-memory descending by createdAt
        docs.sort((a, b) {
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

        // Mark all active notifications as read after a 2-second premium delay
        if (docs.isNotEmpty && _currentTabIndex == 6) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(seconds: 2), () {
              _markAllNotificationsAsRead(docs);
            });
          });
        }

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 64, color: Color(0xFFA0AEC0)),
                  const SizedBox(height: 16),
                  Text(
                    'All Clear!',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No new emergency alerts at the moment.',
                    style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String bookingId = data['bookingId'] ?? '';
              final String type = data['type'] ?? '';

              if (bookingId.isEmpty || type == 'direct_alert') {
                if (type == 'new_review') {
                  final seekerName = data['seekerName'] ?? 'Client';
                  final double rating = (data['rating'] ?? 5.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
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
                                  const Icon(Icons.star, color: Color(0xFFECC94B), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'New Review Received!',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D3748)),
                                  ),
                                  if (data['isRead'] != true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53E3E),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('NEW', style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF718096)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Dismiss Notification',
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth.instance.currentUser?.uid)
                                      .collection('notifications')
                                      .doc(doc.id)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$seekerName rated you \$rating stars! Check it out in the Reviews tab.',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A5568)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Direct Seeker Message/Alert (OVERFLOW IMMUNE)
                final seekerName = data['seekerName'] ?? 'Client';
                final seekerPhone = data['seekerPhone'] ?? 'N/A';
                final body = data['body'] ?? 'No text';
                final service = data['service'] ?? 'Home service';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F7), // Elegant gray/blue
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6B46C1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.mail, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Message from \$seekerName (\$service)',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2D3748)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (data['isRead'] != true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53E3E),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('NEW', style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF718096)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Dismiss Notification',
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser?.uid)
                                    .collection('notifications')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          body,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A5568), height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Phone: \$seekerPhone',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF718096)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B46C1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Direct Alert',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6B46C1)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .snapshots(),
                builder: (context, bookingSnapshot) {
                  if (!bookingSnapshot.hasData || !bookingSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final bData = bookingSnapshot.data!.data() as Map<String, dynamic>;
                  final String currentStatus = bData['status'] ?? 'Pending';
                  final seekerName = bData['seekerName'] ?? 'A Seeker';
                  final seekerPhone = bData['seekerPhone'] ?? '03001234567';
                  final service = bData['service'] ?? 'Home service';
                  final createdAtTimestamp = bData['createdAt'] as Timestamp?;
                  final DateTime createdAt = createdAtTimestamp != null
                      ? createdAtTimestamp.toDate()
                      : DateTime.now();
                  final String timeString = '\${createdAt.hour}:\${createdAt.minute.toString().padLeft(2, "0")}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: currentStatus == 'Confirmed'
                            ? const Color(0xFFF0FFF4) // Soft green for confirmed!
                            : currentStatus == 'ProviderAccepted'
                                ? const Color(0xFFFFFFF0) // Soft gold for pending seeker
                                : const Color(0xFFFFF5F5), // Soft red for pending provider
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentStatus == 'Confirmed'
                              ? const Color(0xFFC6F6D5)
                              : currentStatus == 'ProviderAccepted'
                                  ? const Color(0xFFFEFCBF)
                                  : const Color(0xFFFEB2B2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: currentStatus == 'Confirmed'
                                      ? const Color(0xFFC6F6D5)
                                      : currentStatus == 'ProviderAccepted'
                                          ? const Color(0xFFFEFCBF)
                                          : const Color(0xFFFED7D7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  currentStatus == 'Confirmed' ? Icons.check_circle_rounded : Icons.flash_on,
                                  color: currentStatus == 'Confirmed'
                                      ? const Color(0xFF38A169)
                                      : currentStatus == 'ProviderAccepted'
                                          ? const Color(0xFFD69E2E)
                                          : const Color(0xFFE53E3E),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  currentStatus == 'Confirmed'
                                                      ? '🎉 BOOKING CONFIRMED'
                                                      : currentStatus == 'ProviderAccepted'
                                                          ? '⌛ PENDING CLIENT CONFIRM'
                                                          : '🚨 EMERGENCY DISPATCH',
                                                  style: GoogleFonts.inter(
                                                    color: currentStatus == 'Confirmed'
                                                        ? const Color(0xFF38A169)
                                                        : currentStatus == 'ProviderAccepted'
                                                            ? const Color(0xFFD69E2E)
                                                            : const Color(0xFFE53E3E),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (data['isRead'] != true) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE53E3E),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('NEW', style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              timeString,
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF718096),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF718096)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'Dismiss Notification',
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(FirebaseAuth.instance.currentUser?.uid)
                                                    .collection('notifications')
                                                    .doc(doc.id)
                                                    .delete();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentStatus == 'Confirmed'
                                          ? 'Your session with \$seekerName is active!'
                                          : '\$seekerName needs a \$service immediately!',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF2D3748),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Phone: \$seekerPhone',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF4A5568),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.message, color: Color(0xFF3182CE), size: 28),
                                onPressed: () async {
                                  final String clean = seekerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
                                  final String bodyText = 'Hi \$seekerName, this is \$_providerName. I saw your emergency request for \$service!';
                                  final Uri smsUri = Uri(
                                    scheme: 'sms',
                                    path: clean,
                                    queryParameters: <String, String>{'body': bodyText},
                                  );
                                  try {
                                    if (await canLaunchUrl(smsUri)) {
                                      await launchUrl(smsUri);
                                    } else {
                                      await launchUrl(Uri.parse('sms:\$clean?body=\${Uri.encodeComponent(bodyText)}'));
                                    }
                                  } catch (_) {}
                                },
                              ),
                              const SizedBox(width: 12),
                              if (currentStatus == 'Pending')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53E3E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text('Accept Request', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                  onPressed: () async {
                                    try {
                                      // 1. Update global booking status to ProviderAccepted
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(bookingId)
                                          .update({'status': 'ProviderAccepted'});

                                      // 2. Write notification to Seeker's notifications subcollection
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(bData['seekerId'])
                                          .collection('notifications')
                                          .add({
                                            'type': 'provider_accepted',
                                            'providerId': FirebaseAuth.instance.currentUser?.uid ?? '',
                                            'providerName': _providerName,
                                            'bookingId': bookingId,
                                            'service': service,
                                            'seekerName': seekerName,
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Accepted! Seeker has been notified in real time.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                            backgroundColor: const Color(0xFF319795),
                                            behavior: SnackBarBehavior.floating,
                                          )
                                        );
                                      }
                                    } catch (e) {
                                      print('Error accepting booking: \$e');
                                    }
                                  },
                                ),
                              if (currentStatus == 'ProviderAccepted')
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFD69E2E),
                                    side: const BorderSide(color: Color(0xFFD69E2E)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Color(0xFFD69E2E), strokeWidth: 2),
                                  ),
                                  label: Text('Pending Seeker...', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                  onPressed: null,
                                ),
                              if (currentStatus == 'Confirmed')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF38A169),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text('Complete Session', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('bookings')
                                        .doc(bookingId)
                                        .update({'status': 'Completed'});
                                    
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser?.uid)
                                        .collection('notifications')
                                        .doc(doc.id)
                                        .delete();
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('🎉 Service completed!'),
                                        backgroundColor: const Color(0xFF38A169),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }''';

  // Normalize Windows CRLF to standard LF for precise string matching
  final normalizedContent = content.replaceAll('\\r\\n', '\\n');
  final normalizedTarget = target.replaceAll('\\r\\n', '\\n');

  if (normalizedContent.contains(normalizedTarget)) {
    final newContent = normalizedContent.replaceFirst(normalizedTarget, replacement);
    file.writeAsStringSync(newContent);
    print('SUCCESS: Provider Dashboard successfully updated!');
  } else {
    print('ERROR: Target content not found in file!');
  }
}
