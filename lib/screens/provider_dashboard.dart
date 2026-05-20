import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bookings_dashboard.dart';
import 'rating_dashboard.dart';
import 'clients_dashboard.dart';
import 'provider_profile_dashboard.dart';
import '../main.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  // 0: Overview, 1: Bookings, 2: Profile, 3: Clients, 4: Ratings, 5: Services, 6: Notifications
  int _currentTabIndex = 0;
  bool _isCheckingAuth = true;
  String _providerName = 'Provider';
  String _hourlyRate = '1,500';
  String _serviceCategory = 'Electrician';
  String _experienceYears = '5';
  
  dynamic _notificationSubscription;
  bool _isNotificationListenerInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _listenToLiveEmergencyAlerts();
  }

  @override
  void dispose() {
    if (_notificationSubscription != null) {
      _notificationSubscription.cancel();
    }
    super.dispose();
  }

  void _listenToLiveEmergencyAlerts() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .snapshots()
          .listen((snapshot) {
            // First snapshot load retrieves all existing documents as 'added'.
            // We set the initialized flag to true so we only pop SnackBars for newly created alerts during active sessions.
            if (!_isNotificationListenerInitialized) {
              _isNotificationListenerInitialized = true;
              return;
            }
            
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>?;
                if (data == null) continue;
                
                final String type = data['type'] ?? '';
                if (type == 'seeker_confirmed') {
                  _showConfirmationCelebration(data);
                } else {
                  _showBottomScaffoldNotification(data);
                }
              }
            }
          });
    }
  }

  void _showConfirmationCelebration(Map<String, dynamic> data) {
    final seekerName = data['seekerName'] ?? 'A Seeker';
    final service = data['service'] ?? 'Home service';
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2B6CB0), // Elegant deep blue
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF4299E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 BOOKING OFFICIALLY CONFIRMED!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFBEE3F8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$seekerName has confirmed your $service booking!',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showBottomScaffoldNotification(Map<String, dynamic> data) {
    final seekerName = data['seekerName'] ?? 'A Seeker';
    final seekerPhone = data['seekerPhone'] ?? 'N/A';
    final service = data['service'] ?? 'Home service';
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 15),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A202C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53E3E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 LIVE EMERGENCY MATCH REQUEST!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFEB2B2),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$seekerName needs a $service immediately!',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Phone: $seekerPhone',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA0AEC0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'SMS NOW',
            textColor: const Color(0xFF3182CE),
            onPressed: () async {
              final String clean = seekerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
              final String bodyText = 'Hi $seekerName, this is $_providerName from Home Service AI. I saw your emergency request for $service and can help you immediately! Let me know if you are ready.';
              final Uri smsUri = Uri(
                scheme: 'sms',
                path: clean,
                queryParameters: <String, String>{
                  'body': bodyText,
                },
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
        ),
      );
    });
  }

  Future<void> _loadProfileDetailsInBackground(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists && mounted) {
        setState(() {
          _providerName = doc.data()?['fullName'] ?? user.displayName ?? 'Provider';
          _hourlyRate = (doc.data()?['hourlyRate'] ?? '1,500').toString();
          _serviceCategory = doc.data()?['serviceCategory'] ?? 'Electrician';
          _experienceYears = (doc.data()?['experienceYears'] ?? '5').toString();
        });
      }
    } catch (e) {
      print('Warning: Provider background profile load failed (offline): $e');
    }
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _redirectToLanding('Please log in to access the Provider Dashboard.');
      return;
    }

    // Fast-path: If role is cached in photoURL, immediately populate fields & load details in background
    if (user.photoURL == 'provider') {
      if (mounted) {
        setState(() {
          _providerName = user.displayName ?? 'Provider';
          _isCheckingAuth = false;
        });
      }
      _loadProfileDetailsInBackground(user);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        _redirectToLanding('User record not found. Please register.');
        return;
      }

      final role = doc.data()?['role'];
      if (role != 'provider') {
        await FirebaseAuth.instance.signOut();
        _redirectToLanding('Access denied. This account is registered as a $role.');
        return;
      }

      if (mounted) {
        setState(() {
          _providerName = doc.data()?['fullName'] ?? 'Provider';
          _hourlyRate = (doc.data()?['hourlyRate'] ?? '1,500').toString();
          _serviceCategory = doc.data()?['serviceCategory'] ?? 'Electrician';
          _experienceYears = (doc.data()?['experienceYears'] ?? '5').toString();
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      // Graceful offline fallback: allow dashboard access using cached FirebaseAuth information
      print('Warning: Provider auth check failed: $e. Falling back to offline dashboard mode.');
      if (mounted) {
        setState(() {
          _providerName = user.displayName ?? 'Provider';
          _isCheckingAuth = false;
        });
      }
    }
  }

  void _redirectToLanding(String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (route) => false,
        );
      }
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
  }

  Widget _getBodyContent() {
    switch (_currentTabIndex) {
      case 1: return const BookingsDashboard(role: 'Provider');
      case 2: return const ClientsDashboard();
      case 3: return const RatingDashboard(role: 'Provider');
      case 4: return const ProviderProfileDashboard();
      case 5: return _buildNotificationsTab();
      default: return _buildOverviewHub();
    }
  }

  String _getAppBarTitle() {
    switch (_currentTabIndex) {
      case 1: return 'Bookings';
      case 2: return 'Clients';
      case 3: return 'Ratings';
      case 4: return 'Profile';
      case 5: return 'Alerts';
      default: return 'Overview Hub';
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF1A202C),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Text('HomeService AI', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
          const SizedBox(height: 20),
          _sidebarItem(Icons.dashboard_outlined, 'Overview Hub', 0),
          _sidebarItem(Icons.notifications_active_outlined, 'Alerts', 5),
          _sidebarItem(Icons.calendar_today, 'Bookings', 1),
          _sidebarItem(Icons.people_outline, 'Clients', 2),
          _sidebarItem(Icons.star_border, 'Ratings', 3),
          _sidebarItem(Icons.person_outline, 'Profile', 4),
          const Spacer(),
          _sidebarItem(Icons.logout, 'Log Out', -1, isLogout: true, color: Colors.redAccent),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int index, {bool isLogout = false, Color? color}) {
    final bool isActive = _currentTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () {
          if (isLogout) {
            _logout();
          } else {
            setState(() => _currentTabIndex = index);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isActive ? const Color(0xFF6B46C1).withOpacity(0.2) : Colors.transparent,
        leading: Icon(icon, color: color ?? (isActive ? const Color(0xFF9F7AEA) : const Color(0xFFA0AEC0))),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: color ?? (isActive ? Colors.white : const Color(0xFFA0AEC0)),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTabIcon() {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: currentUserId.isEmpty 
          ? const Stream.empty() 
          : FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('notifications')
              .snapshots(),
      builder: (context, snapshot) {
        final int alertCount = snapshot.hasData
            ? snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isRead'] != true;
              }).length
            : 0;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_active_outlined),
            if (alertCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53E3E), // Alert Red
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      '$alertCount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _markAllNotificationsAsRead(List<QueryDocumentSnapshot> docs) async {
    if (!mounted) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      bool hasUnread = false;
      
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isRead'] != true) {
          batch.update(doc.reference, {'isRead': true});
          hasUnread = true;
        }
      }
      
      if (hasUnread) {
        await batch.commit();
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Widget _buildMobileNavFixed() {
    int mobileIndex = 0;
    if (_currentTabIndex == 0) mobileIndex = 0;
    else if (_currentTabIndex == 5) mobileIndex = 1;
    else if (_currentTabIndex == 1) mobileIndex = 2;
    else if (_currentTabIndex == 2) mobileIndex = 3;
    else if (_currentTabIndex == 4) mobileIndex = 4;

    return BottomNavigationBar(
      currentIndex: mobileIndex,
      onTap: (i) {
        if (i == 5) {
          _logout();
        } else if (i == 0) {
          setState(() => _currentTabIndex = 0);
        } else if (i == 1) {
          setState(() => _currentTabIndex = 5);
        } else if (i == 2) {
          setState(() => _currentTabIndex = 1);
        } else if (i == 3) {
          setState(() => _currentTabIndex = 2);
        } else if (i == 4) {
          setState(() => _currentTabIndex = 4);
        }
      },
      selectedItemColor: const Color(0xFF6B46C1),
      unselectedItemColor: const Color(0xFFA0AEC0),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: _buildNotificationsTabIcon(), label: 'Alerts'),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
        const BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Clients'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        const BottomNavigationBarItem(icon: Icon(Icons.logout, color: Colors.redAccent), label: 'Log Out'),
      ],
    );
  }

  Widget _buildOverviewHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back, $_providerName', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        // Live Quick Action Grid (No Mock Data!)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseAuth.instance.currentUser?.uid == null 
              ? const Stream.empty() 
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('notifications')
                  .snapshots(),
          builder: (context, snapshot) {
            final int alertsCount = snapshot.data?.docs.length ?? 0;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _quickActionCard('Hourly Rate', 'PKR $_hourlyRate/hr', Icons.attach_money, const Color(0xFF38A169), 5),
                _quickActionCard('Experience', '$_experienceYears Years', Icons.star, const Color(0xFFECC94B), 5),
                _quickActionCard('Category', _serviceCategory, Icons.work_outlined, const Color(0xFF3182CE), 5),
                _quickActionCard('Total Dispatches', '$alertsCount Alerts', Icons.notifications_active, const Color(0xFF6B46C1), 6),
              ],
            );
          }
        ),
        const SizedBox(height: 30),
        _buildReviewsSection(),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFECC94B), size: 28),
            const SizedBox(width: 12),
            Text(
              'Recent Reviews',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: currentUserId.isEmpty 
              ? const Stream.empty() 
              : FirebaseFirestore.instance
                  .collection('reviews')
                  .where('providerId', isEqualTo: currentUserId)
                  .snapshots(),
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

            if (allDocs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined, color: Color(0xFFA0AEC0), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reviews from clients will appear here.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allDocs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = allDocs[index].data() as Map<String, dynamic>;
                final double rating = (d['rating'] ?? 5.0).toDouble();
                final String comment = d['comment'] ?? 'Excellent service!';
                final String service = d['service'] ?? 'Home service';
                final String seekerName = d['seekerName'] ?? 'Client';
                
                final createdAt = d['createdAt'] != null
                    ? (d['createdAt'] as Timestamp).toDate()
                    : DateTime.now();
                final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

                return _reviewCard(seekerName, rating.toInt(), comment, dateStr, service);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _reviewCard(String name, int rating, String comment, String date, String tag) {
    final String initial = name[0];

    return Container(
      padding: const EdgeInsets.all(16),
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

  Widget _buildNotificationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53E3E), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alerts',
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
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseAuth.instance.currentUser?.uid == null 
          ? const Stream.empty() 
          : FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
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
        if (docs.isNotEmpty && _currentTabIndex == 5) {
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
                    'No new alerts at the moment.',
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

              if (bookingId.isEmpty) {
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
                            '$seekerName rated you $rating stars! Check it out in the Reviews tab.',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A5568)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Direct Seeker Message/Alert is now handled by the Booking UI below since it has a bookingId!
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
                  final String timeString = '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, "0")}';

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
                                                          : type == 'direct_alert' ? '📩 DIRECT BOOKING REQUEST' : '🚨 EMERGENCY DISPATCH',
                                                  style: GoogleFonts.inter(
                                                    color: currentStatus == 'Confirmed'
                                                        ? const Color(0xFF38A169)
                                                        : currentStatus == 'ProviderAccepted'
                                                            ? const Color(0xFFD69E2E)
                                                            : type == 'direct_alert' ? const Color(0xFF6B46C1) : const Color(0xFFE53E3E),
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
                                    if (type == 'direct_alert') ...[
                                      Text(
                                        data['body'] ?? 'No custom message',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF4A5568),
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    Text(
                                      currentStatus == 'Confirmed'
                                          ? 'Your session with $seekerName is active!'
                                          : '$seekerName needs a $service immediately!',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF2D3748),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Phone: $seekerPhone',
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
                                  final String bodyText = 'Hi $seekerName, this is $_providerName. I saw your emergency request for $service!';
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
                                      print('Error accepting booking: $e');
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
  }

  Widget _quickActionCard(String title, String value, IconData icon, Color color, int targetIndex) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    // On mobile: two cards per row. Outer padding is 20, grid spacing is 16.
    // Card width = (screenWidth - 40 - 16) / 2 = (screenWidth - 56) / 2
    final double cardWidth = isMobile ? (screenWidth - 56) / 2 : 160;

    return InkWell(
      onTap: () => setState(() => _currentTabIndex = targetIndex),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            // Auto-scale value text so long categories never wrap or overflow
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value, 
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            // Auto-scale title label for bulletproof alignment
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title, 
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem(String text, String time, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(time, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Color(0xFF6B46C1),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Securing your session...',
                style: GoogleFonts.inter(
                  color: const Color(0xFF718096),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: isMobile ? AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          title: Text(_getAppBarTitle(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black)),
        ) : null,
        body: Row(
          children: [
            if (!isMobile) _buildSidebar(),
            Expanded(
              child: Container(
                color: const Color(0xFFF7FAFC),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 20 : 40),
                  child: _getBodyContent(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isMobile ? _buildMobileNavFixed() : null,
      ),
    );
  }
}