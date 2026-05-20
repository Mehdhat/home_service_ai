import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientsDashboard extends StatefulWidget {
  const ClientsDashboard({super.key});

  @override
  State<ClientsDashboard> createState() => _ClientsDashboardState();
}

class _ClientsDashboardState extends State<ClientsDashboard> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, bookingsSnapshot) {
        if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
            ),
          );
        }

        final List<QueryDocumentSnapshot> bookings = bookingsSnapshot.data?.docs ?? [];
        
        // Group bookings by unique seekerId
        final Map<String, List<QueryDocumentSnapshot>> clientGroups = {};
        for (var booking in bookings) {
          final data = booking.data() as Map<String, dynamic>;
          final seekerId = data['seekerId'] ?? '';
          if (seekerId.isNotEmpty) {
            clientGroups.putIfAbsent(seekerId, () => []).add(booking);
          }
        }

        final int totalClientsCount = clientGroups.keys.length;
        
        // Fetch provider reviews to calculate dynamic satisfaction rate
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('providerId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, reviewsSnapshot) {
            double satisfaction = 5.0;
            if (reviewsSnapshot.hasData && reviewsSnapshot.data!.docs.isNotEmpty) {
              double sum = 0.0;
              for (var doc in reviewsSnapshot.data!.docs) {
                sum += ((doc.data() as Map<String, dynamic>)['rating'] ?? 5.0).toDouble();
              }
              satisfaction = sum / reviewsSnapshot.data!.docs.length;
            }

            // Map grouped data to a list of clients
            List<Map<String, dynamic>> clientsList = [];
            clientGroups.forEach((seekerId, bookingDocs) {
              final firstBooking = bookingDocs.first.data() as Map<String, dynamic>;
              final String name = firstBooking['seekerName'] ?? 'Client';
              final String phone = firstBooking['seekerPhone'] ?? 'N/A';
              
              // Client status: Active if any booking is Confirmed or Completed, else Pending
              bool hasActive = bookingDocs.any((b) {
                final status = (b.data() as Map<String, dynamic>)['status'] ?? '';
                return status == 'Confirmed' || status == 'Completed';
              });

              clientsList.add({
                'seekerId': seekerId,
                'name': name,
                'phone': phone,
                'bookingsCount': bookingDocs.length,
                'status': hasActive ? 'Active' : 'Pending',
              });
            });

            // Filter clients by search query
            if (_searchQuery.isNotEmpty) {
              clientsList = clientsList.where((c) {
                final name = c['name'].toString().toLowerCase();
                final phone = c['phone'].toString().toLowerCase();
                return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery.toLowerCase());
              }).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // Stats Overview cards populated dynamically
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _statCard('$totalClientsCount', 'Total Clients', Icons.people, const Color(0xFF6B46C1), isMobile),
                    _statCard('${bookings.length}', 'Total Bookings', Icons.assignment_turned_in_outlined, const Color(0xFF38A169), isMobile),
                    _statCard(satisfaction.toStringAsFixed(1), 'Average Satisfaction', Icons.star, const Color(0xFFECC94B), isMobile),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Search and Filter Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search, color: Color(0xFFA0AEC0), size: 20),
                            hintText: 'Search by name or phone...',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFFA0AEC0), fontSize: 15),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.filter_list, color: Color(0xFF4A5568), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Client List Title
                Text(
                  'Recent Contacts',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (clientsList.isEmpty)
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
                        const Icon(Icons.people_outline, size: 48, color: Color(0xFFA0AEC0)),
                        const SizedBox(height: 16),
                        Text(
                          'No Clients Found',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF4A5568)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clients will appear here once bookings are created.',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF718096)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: clientsList.map((client) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _clientCard(
                          client['name'],
                          client['phone'],
                          client['bookingsCount'],
                          satisfaction,
                          client['status'],
                          isMobile,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 40),
              ],
            );
          }
        );
      }
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, bool isMobile) {
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

  Widget _clientCard(String name, String phone, int bookings, double rating, String status, bool isMobile) {
    bool isActive = status == 'Active';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6B46C1).withOpacity(0.8), const Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name, 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1A202C)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isActive ? Colors.green : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text('Phone: $phone', style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!isMobile) ...[
             _clientDetailItem('Bookings', bookings.toString()),
             const SizedBox(width: 24),
             _clientDetailItem('Rating', rating.toStringAsFixed(1)),
             const SizedBox(width: 24),
          ],
          IconButton(
            icon: const Icon(Icons.message, color: Color(0xFF3182CE), size: 24),
            onPressed: () async {
              final String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
              final String bodyText = 'Hi $name, this is your service provider. Thank you for booking with me!';
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
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  Widget _clientDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF2D3748)),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}