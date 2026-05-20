import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../main.dart';
import '../repositories/auth_repository.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final Widget destination;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.destination,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _canResend = true;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    // Start polling to automatically proceed once they verify
    _startAutoCheck();
  }

  void _startAutoCheck() {
    print('Starting auto-check for email verification...');
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        print('Checking email verification status...');
        final isVerified = await _authRepository.checkEmailVerificationStatus();
        print('Email verification status: $isVerified');
        if (isVerified) {
          print('Email verified! Navigating to destination...');
          timer.cancel();
          _onVerified();
        }
      } catch (e) {
        print("Verification status polling check failed/timed out: $e");
      }
    });
  }

  void _onVerified() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email successfully verified!',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF38A169),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.destination),
      );
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      print('Manual check for email verification status...');
      final isVerified = await _authRepository.checkEmailVerificationStatus();
      print('Manual check result: $isVerified');
      if (isVerified) {
        _onVerified();
      } else {
        print('Email not verified yet');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email is not verified yet. Please check your inbox and click the verification link.',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFE53E3E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('ERROR: Manual check failed: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking status: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    try {
      print('Resending verification email to: ${widget.email}');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('ERROR: No current user found when trying to resend verification email');
        throw Exception('No user logged in');
      }
      print('Current user email: ${user.email}');
      print('Current user emailVerified: ${user.emailVerified}');
      await user.sendEmailVerification();
      print('Verification email resent successfully to: ${widget.email}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification email resent!',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF38A169),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _canResend = false;
        _resendCooldown = 60;
      });

      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_resendCooldown > 1) {
              _resendCooldown--;
            } else {
              _canResend = true;
              timer.cancel();
            }
          });
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print('ERROR: Failed to resend verification email: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error resending email: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancel() async {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
          onPressed: _cancel,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.all(64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Verify Your Identity',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We need to verify your email address to ensure the security of your account and the platform.',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: const Color(0xFFE9D8FD),
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white,
                    height: double.infinity,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: _buildFormContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildFormContent(),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 48,
              color: Color(0xFF6B46C1),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A202C),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a verification link to your email address:\n${widget.email}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF718096),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6B46C1), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'The app will automatically advance once you verify by clicking the link in your email.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4A5568),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _checkStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B46C1),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'I Have Verified',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _canResend ? _resendEmail : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
          ),
          child: Text(
            _canResend ? 'Resend Email' : 'Resend in ${_resendCooldown}s',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _canResend ? const Color(0xFF6B46C1) : const Color(0xFFA0AEC0),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _cancel,
          child: Text(
            'Cancel & Back to Login',
            style: GoogleFonts.inter(
              color: const Color(0xFFE53E3E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
