import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/env_config.dart';
import 'screens/seeker_dashboard.dart';
import 'screens/provider_dashboard.dart';
import 'screens/auth_screen.dart';
import 'screens/about_screen.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Securely load environment variables
  await EnvConfig.initialize();

  try {
    // Initialize Firebase with platform-specific options from .env
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: kIsWeb
          ? FirebaseOptions(
              apiKey: EnvConfig.webApiKey,
              appId: EnvConfig.webAppId,
              messagingSenderId: EnvConfig.webMessagingSenderId,
              projectId: EnvConfig.webProjectId,
              authDomain: EnvConfig.webAuthDomain,
              storageBucket: EnvConfig.webStorageBucket,
              measurementId: EnvConfig.webMeasurementId,
            )
          : Platform.isAndroid
              ? FirebaseOptions(
                  apiKey: EnvConfig.androidApiKey,
                  appId: EnvConfig.androidAppId,
                  messagingSenderId: EnvConfig.androidMessagingSenderId,
                  projectId: EnvConfig.androidProjectId,
                )
              : FirebaseOptions(
                  apiKey: EnvConfig.iosApiKey,
                  appId: EnvConfig.iosAppId,
                  messagingSenderId: EnvConfig.iosMessagingSenderId,
                  projectId: EnvConfig.iosProjectId,
                  iosBundleId: EnvConfig.iosBundleId,
                ),
    );
    print('Firebase initialized successfully');
    print('Project ID: ${Firebase.app().options.projectId}');
  } catch (e) {
    print('ERROR: Firebase initialization failed: $e');
    print('Error type: ${e.runtimeType}');
  }

  runApp(const ServiceHubApp());
}

class ServiceHubApp extends StatelessWidget {
  const ServiceHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Service AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashLoadingScreen();
          }

          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            final cachedRole = user.photoURL;
            if (cachedRole == 'seeker') {
              return const SeekerDashboard();
            } else if (cachedRole == 'provider') {
              return const ProviderDashboard();
            }

            // Fallback: If no cached role in user.photoURL (e.g. legacy accounts),
            // dynamically retrieve from Firestore role check.
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const SplashLoadingScreen();
                }

                if (userSnapshot.hasError) {
                  print("Warning: main.dart Firestore role fetch failed/offline: ${userSnapshot.error}");
                  return const SeekerDashboard();
                }

                if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                  final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final role = data?['role'];
                  if (role == 'seeker' || role == 'provider') {
                    // Update user photoURL cache in the background for next relaunch
                    user.updatePhotoURL(role).catchError((_) {});
                    if (role == 'seeker') {
                      return const SeekerDashboard();
                    } else {
                      return const ProviderDashboard();
                    }
                  }
                }

                // If user doesn't exist or doesn't have a role, sign out and show landing
                FirebaseAuth.instance.signOut();
                return const LandingPage();
              },
            );
          }

          return const LandingPage();
        },
      ),
    );
  }
}

class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Home Service AI',
              style: GoogleFonts.inter(
                color: const Color(0xFF1A202C),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildHeader(context, isMobile),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildHeroSection(isMobile),
            const SizedBox(height: 60),
            _buildMainCards(context, isMobile),
            const SizedBox(height: 80),
            _buildFeaturesSection(isMobile),
            const SizedBox(height: 60),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context, bool isMobile) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        padding: EdgeInsets.only(
          top: isMobile ? 10 : 30,
          left: isMobile ? 20 : 80,
          right: isMobile ? 20 : 80,
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Home Service AI',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A202C),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
              child: Text(
                'About',
                style: GoogleFonts.inter(
                  color: const Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _buildRoleTab(context, 'Seeker', 'Service Seeker', Icons.person_outline, isMobile),
                  Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                  _buildRoleTab(context, 'Provider', 'Service Provider', Icons.business_center_outlined, isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab(BuildContext context, String role, String label, IconData icon, bool isMobile) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthScreen(
              role: role,
              destination: role == 'Seeker' ? const SeekerDashboard() : const ProviderDashboard(),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B46C1)),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A202C),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: isMobile ? 36 : 56,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1.1,
              ),
              children: const [
                TextSpan(
                  text: 'Connecting Communities,\n',
                  style: TextStyle(color: Color(0xFF1A202C)),
                ),
                TextSpan(
                  text: 'Empowering Livelihoods',
                  style: TextStyle(
                    color: Color(0xFF6B46C1), // Updated to use the solid theme purple directly
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 700,
            child: Text(
              'AI-powered platform bridging service providers and seekers in the informal economy. We build trust through technology.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF718096),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCards(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      child: Wrap(
        spacing: 30,
        runSpacing: 30,
        alignment: WrapAlignment.center,
        children: [
          HoverCard(
            isMobile: isMobile,
            icon: Icons.person_outline_rounded,
            title: "I'm Looking for Services",
            subtitle: "Find trusted local professionals for home repairs, cleaning, and tutoring instantly.",
            bullets: const [
              "Browse verified service providers.",
              "AI-powered matching algorithms.",
              "Secure booking and payments."
            ],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen(role: 'Seeker', destination: SeekerDashboard()))),
          ),
          HoverCard(
            isMobile: isMobile,
            icon: Icons.business_center_outlined,
            title: "I Offer Services",
            subtitle: "Grow your business by connecting with local customers who need your specific skills.",
            bullets: const [
              "Create your professional profile.",
              "Manage bookings and earnings.",
              "Build reputation with verified reviews."
            ],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen(role: 'Provider', destination: ProviderDashboard()))),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isMobile) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Why Choose Home Service AI?",
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(children: _featureList())
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _featureList().map((w) => Expanded(child: w)).toList(),
                ),
        ],
      ),
    );
  }

  List<Widget> _featureList() {
    return [
      _featureItem(Icons.verified_user_outlined, "Verified Providers", "Every professional is verified for your peace of mind.", Colors.green),
      _featureItem(Icons.auto_awesome_outlined, "AI Matching", "Smart technology finds the perfect pro for your job.", Colors.blue),
      _featureItem(Icons.trending_up_rounded, "Fair Pricing", "Transparent costs with absolutely no hidden fees.", Colors.purple),
    ];
  }

  Widget _featureItem(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF718096), height: 1.5, fontWeight: FontWeight.w500),
          ),
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

class HoverCard extends StatefulWidget {
  final bool isMobile;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final VoidCallback onTap;

  const HoverCard({super.key, required this.isMobile, required this.icon, required this.title, required this.subtitle, required this.bullets, required this.onTap});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool isHovered = false;
  final Color brandPurple = const Color(0xFF6B46C1);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isMobile ? double.infinity : 450,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isHovered ? brandPurple : const Color(0xFFE2E8F0), width: 2),
            boxShadow: [
              BoxShadow(
                color: isHovered ? brandPurple.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: brandPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: brandPurple, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A202C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.bullets.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: brandPurple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}