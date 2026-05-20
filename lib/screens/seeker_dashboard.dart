import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bookings_dashboard.dart';
import 'rating_dashboard.dart';
import 'ai_messaging_screen.dart';
import 'provider_detail_screen.dart';
import '../main.dart';

class SeekerDashboard extends StatefulWidget {
  const SeekerDashboard({super.key});

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard> {
  // 0: Explore, 1: Bookings, 2: Messages, 3: Ratings, 4: Profile
  int _currentViewIndex = 0;
  bool _isCheckingAuth = true;
  bool _isSavingSettings = false;
  String _seekerName = 'Seeker';
  String _seekerEmail = '';
  String? _selectedSearchCategory;
  String _seekerPhone = '';
  String _seekerLocation = '';
  String _searchText = '';
  dynamic _bookingSubscription;
  bool _isBookingSubscriptionInitialized = false;

  final TextEditingController _seekerNameController = TextEditingController();
  final TextEditingController _seekerEmailController = TextEditingController();
  final TextEditingController _seekerPhoneController = TextEditingController();
  final TextEditingController _seekerLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _listenToLiveBookingUpdates();
  }

  @override
  void dispose() {
    if (_bookingSubscription != null) {
      _bookingSubscription.cancel();
    }
    _seekerNameController.dispose();
    _seekerEmailController.dispose();
    _seekerPhoneController.dispose();
    _seekerLocationController.dispose();
    super.dispose();
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
          _seekerName = doc.data()?['fullName'] ?? user.displayName ?? 'Seeker';
          _seekerEmail = doc.data()?['email'] ?? user.email ?? '';
          _seekerPhone = doc.data()?['phoneNumber'] ?? '';
          _seekerLocation = doc.data()?['location'] ?? '';

          _seekerNameController.text = _seekerName;
          _seekerEmailController.text = _seekerEmail;
          _seekerPhoneController.text = _seekerPhone;
          _seekerLocationController.text = _seekerLocation;
        });
      }
    } catch (e) {
      print('Warning: Seeker background profile load failed (offline): $e');
    }
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _redirectToLanding('Please log in to access the Seeker Dashboard.');
      return;
    }

    // Fast-path: If role is cached in photoURL, immediately populate fields & load details in background
    if (user.photoURL == 'seeker') {
      if (mounted) {
        setState(() {
          _seekerName = user.displayName ?? 'Seeker';
          _seekerEmail = user.email ?? '';
          _seekerPhone = '';
          _seekerLocation = '';

          _seekerNameController.text = _seekerName;
          _seekerEmailController.text = _seekerEmail;
          _seekerPhoneController.text = '';
          _seekerLocationController.text = '';
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
      if (role != 'seeker') {
        await FirebaseAuth.instance.signOut();
        _redirectToLanding('Access denied. This account is registered as a $role.');
        return;
      }

      if (mounted) {
        setState(() {
          _seekerName = doc.data()?['fullName'] ?? 'Seeker';
          _seekerEmail = doc.data()?['email'] ?? user.email ?? '';
          _seekerPhone = doc.data()?['phoneNumber'] ?? '';
          _seekerLocation = doc.data()?['location'] ?? '';

          _seekerNameController.text = _seekerName;
          _seekerEmailController.text = _seekerEmail;
          _seekerPhoneController.text = _seekerPhone;
          _seekerLocationController.text = _seekerLocation;

          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      // Graceful offline fallback: allow dashboard access using cached FirebaseAuth information
      print('Warning: Seeker auth check failed: $e. Falling back to offline dashboard mode.');
      if (mounted) {
        setState(() {
          _seekerName = user.displayName ?? 'Seeker';
          _seekerEmail = user.email ?? '';
          _seekerPhone = '';
          _seekerLocation = '';

          _seekerNameController.text = _seekerName;
          _seekerEmailController.text = _seekerEmail;
          _seekerPhoneController.text = _seekerPhone;
          _seekerLocationController.text = _seekerLocation;

          _isCheckingAuth = false;
        });
      }
    }
  }

  void _listenToLiveBookingUpdates() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _bookingSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .snapshots()
          .listen((snapshot) {
            if (!_isBookingSubscriptionInitialized) {
              _isBookingSubscriptionInitialized = true;
              return;
            }
            
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>?;
                if (data == null) continue;
                
                final String type = data['type'] ?? '';
                if (type == 'provider_accepted') {
                  _showProviderAcceptedAlert(data);
                }
              }
            }
          });
    }
  }

  void _showProviderAcceptedAlert(Map<String, dynamic> data) {
    final String providerName = data['providerName'] ?? 'Expert';
    final String providerId = data['providerId'] ?? '';
    final String bookingId = data['bookingId'] ?? '';
    final String service = data['service'] ?? 'Home service';
    final String seekerName = data['seekerName'] ?? _seekerName;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 25),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2C7A7B), // Beautiful rich teal
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF319795),
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
                      '🚨 PROVIDER CHOSEN & READY!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE6FFFA),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$providerName accepted your $service request!',
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
          action: SnackBarAction(
            label: 'CONFIRM BOOKING',
            textColor: const Color(0xFFB2F5EA),
            onPressed: () async {
              try {
                // 1. Update global booking to Confirmed
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({'status': 'Confirmed'});
                
                // 2. Notify the provider
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(providerId)
                    .collection('notifications')
                    .doc('${FirebaseAuth.instance.currentUser?.uid ?? ''}_seeker_confirmed')
                    .set({
                      'type': 'seeker_confirmed',
                      'seekerName': seekerName,
                      'service': service,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isRead': false,
                    });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Reservation officially secured! provider is notified.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFF38A169),
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                }
              } catch (e) {
                print('Error confirming booking: $e');
              }
            },
          ),
        ),
      );
    });
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

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
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

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: isMobile
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  _getAppBarTitle(),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A202C),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              )
            : null,
        body: isMobile 
            ? _buildMobileLayout(isMobile) 
            : _buildDesktopLayout(isMobile),
        bottomNavigationBar: isMobile
            ? _buildMobileNav()
            : null,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentViewIndex) {
      case 1: return 'My Bookings';
      case 2: return 'AI Assistant & Messages';
      case 3: return 'My Reviews';
      case 4: return 'Account Settings';
      default: return 'Find Services';
    }
  }

  Widget _buildActiveContentSection(bool isMobile) {
    switch (_currentViewIndex) {
      case 1:
        return const BookingsDashboard(role: 'Seeker');
      case 2:
        return const AIMessagingScreen();
      case 3:
        return const RatingDashboard(role: 'Seeker');
      case 4:
        return _buildSettingsSection(isMobile);
      default:
        return _buildFindServicesSection(isMobile);
    }
  }

  Widget _buildMobileNav() {
    int mobileIndex = _currentViewIndex;
    if (mobileIndex > 4) mobileIndex = 4; // Safely cap
    return BottomNavigationBar(
      currentIndex: mobileIndex,
      onTap: (index) {
        if (index == 5) {
          _handleLogout();
        } else {
          setState(() => _currentViewIndex = index);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF6B46C1),
      unselectedItemColor: const Color(0xFFA0AEC0),
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Match'),
        BottomNavigationBarItem(icon: Icon(Icons.star_border), label: 'Reviews'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.logout, color: Colors.redAccent), label: 'Log Out'),
      ],
    );
  }

  Widget _buildMobileLayout(bool isMobile) {
    if (_currentViewIndex == 2) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: AIMessagingScreen(),
      );
    }
    // Apply horizontal 20px padding and 20px top padding for a clean look on mobile
    // for Bookings, Reviews, and Profile tabs. Explore tab has its own custom spacing.
    final bool applyPadding = _currentViewIndex != 0;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: applyPadding ? 20 : 0,
        right: applyPadding ? 20 : 0,
        top: applyPadding ? 20 : 0,
        bottom: 40,
      ),
      child: _buildActiveContentSection(isMobile),
    );
  }

  Widget _buildDesktopLayout(bool isMobile) {
    return Row(
      children: [
        Container(
          width: 280,
          color: const Color(0xFF1A202C),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HomeService AI',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 40),
              _buildSidebarItem(Icons.search, 'Find Services', index: 0),
              _buildSidebarItem(Icons.bookmark_border, 'My Bookings', index: 1),
              _buildSidebarItem(Icons.auto_awesome, 'AI Match', index: 2),
              _buildSidebarItem(Icons.star_border, 'My Reviews', index: 3),
              _buildSidebarItem(Icons.person_outline, 'Account Settings', index: 4),
              const Spacer(),
              _buildSidebarItem(Icons.logout, 'Log Out', isLogoutAction: true, color: Colors.redAccent),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF7FAFC),
            height: double.infinity,
            child: _currentViewIndex == 2
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getAppBarTitle(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A202C),
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                              ),
                            ),
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFF6B46C1),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const Expanded(child: AIMessagingScreen()),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getAppBarTitle(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A202C),
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                              ),
                            ),
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFF6B46C1),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildActiveContentSection(isMobile),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {int index = 0, bool isLogoutAction = false, Color? color}) {
    final bool isActive = !isLogoutAction && _currentViewIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          if (isLogoutAction) {
            _handleLogout();
          } else {
            setState(() => _currentViewIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6B46C1).withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? (isActive ? const Color(0xFF9F7AEA) : const Color(0xFFA0AEC0))),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: color ?? (isActive ? Colors.white : const Color(0xFFA0AEC0)),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFindServicesSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) const SizedBox(height: 20),
        _buildActiveAlerts(isMobile),
        _buildSearchBar(isMobile),
        const SizedBox(height: 30),
        _buildCategories(isMobile),
        const SizedBox(height: 30),
        _buildRecommendedProviders(isMobile),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildActiveAlerts(bool isMobile) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('seekerId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'ProviderAccepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String bookingId = doc.id;
              final String providerName = data['providerName'] ?? 'Expert';
              final String providerId = data['providerId'] ?? '';
              final String service = data['service'] ?? 'Home service';

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF319795), Color(0xFF2C7A7B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF319795).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_on, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '🎉 PROVIDER ACCEPTED REQUEST!',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$providerName has accepted your emergency request for $service and is ready to start! Please confirm the booking to lock it in.',
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFECC94B), // Gold
                            foregroundColor: const Color(0xFF744210),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            try {
                              // 1. Confirm the booking
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(bookingId)
                                  .update({'status': 'Confirmed'});

                              // 2. Notify the provider
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(providerId)
                                  .collection('notifications')
                                  .doc('${FirebaseAuth.instance.currentUser?.uid ?? ''}_booking_confirmed')
                                  .set({
                                    'type': 'booking_confirmed',
                                    'bookingId': bookingId,
                                    'seekerName': data['seekerName'] ?? 'Seeker',
                                    'service': service,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'isRead': false,
                                  });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 Booking Confirmed! Provider has been dispatched.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    backgroundColor: const Color(0xFF38A169),
                                    behavior: SnackBarBehavior.floating,
                                  )
                                );
                              }
                            } catch (e) {
                              print('Error confirming booking: $e');
                            }
                          },
                          child: Text(
                            'CONFIRM BOOKING',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isMobile ? const Color(0xFFF7FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: isMobile ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFFA0AEC0)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchText = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search for services, providers, or locations...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFFA0AEC0),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(bool isMobile) {
    final List<String> dropItems = [
      'Show All Categories',
      'Electrician',
      'Plumber',
      'AC Technician',
      'Carpenter',
      'Home Appliances Repair',
      'Deep Cleaning',
      'Water Tank Cleaning',
      'Pest Control',
      'Gardener',
      'Laundry & Dry Cleaning',
      'Home Tutor',
      'Generator Mechanic',
      'Painter',
      'Solar Panel Cleaning',
      'Home Maid',
      'Home beauticians',
      'Others',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Service Category',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSearchCategory ?? 'Show All Categories',
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B46C1)),
                dropdownColor: Colors.white,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A202C),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                items: dropItems.map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Row(
                      children: [
                        Icon(
                          val == 'Show All Categories' ? Icons.all_inclusive : Icons.category_outlined,
                          color: const Color(0xFF6B46C1),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(val),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newVal) {
                  setState(() {
                    if (newVal == 'Show All Categories') {
                      _selectedSearchCategory = null;
                    } else {
                      _selectedSearchCategory = newVal;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedProviders(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Providers',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _selectedSearchCategory == null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'provider')
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'provider')
                    .where('serviceCategory', isEqualTo: _selectedSearchCategory)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Text(
                  'Error loading providers: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              
              // Apply real-time in-memory keyword matching!
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['fullName'] ?? '').toString().toLowerCase();
                final category = (data['serviceCategory'] ?? '').toString().toLowerCase();
                final bio = (data['bio'] ?? '').toString().toLowerCase();
                final city = (data['city'] ?? '').toString().toLowerCase();
                final skills = (data['skills'] ?? '').toString().toLowerCase();
                
                if (_searchText.isEmpty) return true;
                
                return name.contains(_searchText) || 
                       category.contains(_searchText) || 
                       bio.contains(_searchText) || 
                       city.contains(_searchText) || 
                       skills.contains(_searchText);
              }).toList();

              if (filteredDocs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      _searchText.isEmpty
                          ? 'No active local providers registered yet.'
                          : 'No providers match your search query.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF718096),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              final List<Widget> cards = filteredDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['fullName'] ?? 'Provider';
                final service = data['serviceCategory'] ?? 'Specialist';
                final rate = data['hourlyRate'] ?? '1,000';
                final experience = data['experienceYears'] ?? '3';
                final phone = data['phoneNumber'] ?? '03001234567';
                
                // Get actual rating and review count from database
                final double rating = (data['rating'] ?? 0.0).toDouble();
                final int reviews = data['reviewsCount'] ?? 0;
                
                final String providerUid = doc.id;
                
                return _providerCard(
                  name: name,
                  service: '$service Specialist',
                  rating: rating,
                  reviews: reviews,
                  price: 'PKR $rate/hour',
                  phone: phone,
                  isMobile: isMobile,
                  providerUid: providerUid,
                );
              }).toList();

              return isMobile
                  ? Column(
                      children: cards.map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: card,
                          )).toList(),
                    )
                  : Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: cards.map((card) => SizedBox(width: 440, child: card)).toList(),
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _providerCard({
    required String name,
    required String service,
    required double rating,
    required int reviews,
    required String price,
    required String phone,
    required bool isMobile,
    required String providerUid,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDetailScreen(
                providerUid: providerUid,
                providerName: name,
                providerService: service,
                providerPhone: phone,
                providerRate: price,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('reviews').where('providerId', isEqualTo: providerUid).snapshots(),
                    builder: (context, snapshot) {
                      double dynamicRating = 0.0;
                      int dynamicReviews = 0;
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        dynamicReviews = snapshot.data!.docs.length;
                        double sum = 0;
                        for (var doc in snapshot.data!.docs) {
                          sum += ((doc.data() as Map<String, dynamic>)['rating'] ?? 0.0).toDouble();
                        }
                        dynamicRating = sum / dynamicReviews;
                      }
                      
                      return Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFECC94B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            dynamicReviews == 0 ? '0.0' : dynamicRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A202C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($dynamicReviews reviews)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFA0AEC0),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3182CE),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.message_outlined, color: Color(0xFF38A169), size: 24),
              tooltip: 'Send SMS',
              onPressed: () {
                final String msgBody = 'Hello $name, I saw your $service profile on the Home Service app and would like to hire you! Please let me know when you are free.';
                _sendSMS(phone, msgBody);
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFF6B46C1), size: 24),
              tooltip: 'Send Manual Alert',
              onPressed: () {
                _showSendNotificationDialog(context, providerUid, name, service, phone);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showSendNotificationDialog(BuildContext context, String providerId, String providerName, String providerService, String providerPhone) {
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
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Notify $providerName',
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
                  icon: isSending ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                  label: Text(isSending ? 'Sending...' : 'Send Alert', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: isSending ? null : () async {
                    setState(() { isSending = true; });
                    String finalBody = msgController.text.trim();
                    if (finalBody.isEmpty) {
                      finalBody = selectedTemplate == 'Custom Message...' ? 'Hello!' : selectedTemplate;
                    }
                    
                    try {
                      final String cleanedService = providerService.replaceAll(' Specialist', '').trim();

                      // Duplicate alert check to prevent multiple direct alerts
                      final duplicateCheck = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(providerId)
                          .collection('notifications')
                          .where('seekerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                          .where('service', isEqualTo: cleanedService)
                          .where('type', isEqualTo: 'direct_alert')
                          .limit(1)
                          .get();

                      if (duplicateCheck.docs.isNotEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Duplicate alert detected, request not sent.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFFE53E3E),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }


                      // 1. Automatically perform the booking process
                      final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
                        'seekerId': FirebaseAuth.instance.currentUser?.uid ?? '',
                        'seekerName': _seekerName,
                        'seekerPhone': _seekerPhone,
                        'providerId': providerId,
                        'providerName': providerName,
                        'providerPhone': providerPhone,
                        'service': cleanedService,
                        'status': 'Pending',
                        'createdAt': FieldValue.serverTimestamp(),
                        'message': finalBody,
                      });

                      // 2. Create a SINGLE notification in provider's notifications collection
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(providerId)
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
                            content: Text(
                              '🎉 Alert sent and booking request initialized with $providerName!',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: const Color(0xFF38A169),
                            behavior: SnackBarBehavior.floating,
                          )
                        );
                      }
                    } catch (e) {
                      print('Error sending alert: $e');
                      if (context.mounted) {
                        setState(() { isSending = false; });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error sending alert: $e', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            behavior: SnackBarBehavior.floating,
                          )
                        );
                      }
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

  Future<void> _sendSMS(String phoneNumber, String messageBody) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': messageBody,
      },
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await launchUrl(Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(messageBody)}'));
      }
    } catch (e) {
      print('Error launching SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch SMS. Provider phone: $cleanPhone'),
            backgroundColor: const Color(0xFF6B46C1),
          ),
        );
      }
    }
  }

  Widget _buildSettingsSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
            _settingsInputStub(label: 'Full Name', controller: _seekerNameController),
            const SizedBox(height: 16),
            _settingsInputStub(label: 'Phone Number', controller: _seekerPhoneController),
            const SizedBox(height: 16),
            _settingsInputStub(label: 'Primary Service Address', controller: _seekerLocationController),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSavingSettings ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSavingSettings
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Save Changes', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          ],
        ),
      );
  }

  Future<void> _saveSettings() async {
    if (_seekerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Name cannot be empty',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSavingSettings = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fullName': _seekerNameController.text.trim(),
          'phoneNumber': _seekerPhoneController.text.trim(),
          'location': _seekerLocationController.text.trim(),
        }).timeout(const Duration(seconds: 5));

        setState(() {
          _seekerName = _seekerNameController.text.trim();
          _seekerPhone = _seekerPhoneController.text.trim();
          _seekerLocation = _seekerLocationController.text.trim();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings saved successfully!',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF38A169),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save settings: ${e.toString()}',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingSettings = false);
      }
    }
  }

  Widget _settingsInputStub({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF4A5568), fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFEDF2F7) : const Color(0xFFF7FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6B46C1))),
          ),
        ),
      ],
    );
  }
}