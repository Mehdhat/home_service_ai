import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/env_config.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Registration Logic ---

  /// Registers a user as a Seeker
  Future<UserCredential> registerAsSeeker({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String location,
  }) async {
    try {
      UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 10));

      if (credential.user != null) {
        try {
          await credential.user!.updatePhotoURL('seeker');
        } catch (_) {}
        // Save seeker data to Firestore with timeout protection
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'uid': credential.user!.uid,
            'email': email,
            'fullName': fullName,
            'phoneNumber': phoneNumber,
            'location': location,
            'role': 'seeker',
            'createdAt': FieldValue.serverTimestamp(),
            'isEmailVerified': false,
          }).timeout(const Duration(seconds: 5));
        } catch (e) {
          // Proceed anyway as the Auth account is successfully created
          print('Warning: Seeker Firestore document write timed out/failed: $e');
        }

        try {
          print('Sending verification email to: $email');
          await credential.user!.sendEmailVerification().timeout(const Duration(seconds: 10));
          print('Verification email sent successfully to: $email');
        } catch (e) {
          print('ERROR: Seeker verification email send failed: $e');
          print('Error type: ${e.runtimeType}');
          rethrow;
        }
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Registers a user as a Provider
  Future<UserCredential> registerAsProvider({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String location,
    required String serviceCategory,
    required List<String> skills,
    required double hourlyRate,
    required String availability,
    required int experienceYears,
    required String bio,
  }) async {
    try {
      UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 10));

      if (credential.user != null) {
        try {
          await credential.user!.updatePhotoURL('provider');
        } catch (_) {}
        // Save provider data to Firestore with timeout protection
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'uid': credential.user!.uid,
            'email': email,
            'fullName': fullName,
            'phoneNumber': phoneNumber,
            'location': location,
            'role': 'provider',
            'createdAt': FieldValue.serverTimestamp(),
            'isEmailVerified': false,
            // Provider-specific fields
            'serviceCategory': serviceCategory,
            'skills': skills,
            'hourlyRate': hourlyRate,
            'availability': availability,
            'experienceYears': experienceYears,
            'bio': bio,
          }).timeout(const Duration(seconds: 5));
        } catch (e) {
          // Proceed anyway as the Auth account is successfully created
          print('Warning: Provider Firestore document write timed out/failed: $e');
        }

        try {
          print('Sending verification email to: $email');
          await credential.user!.sendEmailVerification().timeout(const Duration(seconds: 10));
          print('Verification email sent successfully to: $email');
        } catch (e) {
          print('ERROR: Provider verification email send failed: $e');
          print('Error type: ${e.runtimeType}');
          rethrow;
        }
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // --- Login Logic ---

  /// Authenticates user and validates their role
  Future<User?> login({
    required String email,
    required String password,
    required String expectedRole, // 'seeker' or 'provider'
  }) async {
    try {
      UserCredential credential = await _auth
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 10));

      if (credential.user != null) {
        String actualRole = expectedRole;

        try {
          // Fetch user document to verify role with timeout protection
          DocumentSnapshot doc = await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .get()
              .timeout(const Duration(seconds: 5));

          if (doc.exists) {
            actualRole = doc['role'] ?? expectedRole;
          } else {
            // Safe Fallback: If document was missing due to register write timeout,
            // lazily initialize it in Firestore in the background.
            _firestore.collection('users').doc(credential.user!.uid).set({
              'uid': credential.user!.uid,
              'email': email,
              'fullName': email.split('@')[0],
              'phoneNumber': '',
              'location': '',
              'role': expectedRole,
              'createdAt': FieldValue.serverTimestamp(),
              'isEmailVerified': credential.user!.emailVerified,
            }).catchError((_) {});
          }
        } catch (e) {
          print('Warning: Firestore role fetch timed out/failed: $e. Falling back to expected role.');
        }

        if (actualRole != expectedRole) {
          await _auth.signOut();
          throw RoleMismatchException('This account is registered as a $actualRole. Please use the correct login portal.');
        }

        if (!credential.user!.emailVerified) {
          // Send verification email again if they try to login without being verified
          try {
            print('User email not verified. Resending verification email to: $email');
            await credential.user!.sendEmailVerification().timeout(const Duration(seconds: 10));
            print('Verification email resent successfully to: $email');
          } catch (e) {
            print('ERROR: Failed to resend verification email: $e');
            print('Error type: ${e.runtimeType}');
          }
          
          // Don't sign out - let the user stay signed in so they can verify their email
          throw EmailNotVerifiedException('Please verify your email address before logging in.');
        }

        try {
          await credential.user!.updatePhotoURL(expectedRole);
        } catch (_) {}

        return credential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on RoleMismatchException {
      rethrow;
    } on EmailNotVerifiedException {
      rethrow;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }



  // --- Utility Logic ---

  Future<void> sendPasswordReset(String email) async {
    try {
      print('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email).timeout(const Duration(seconds: 10));
      print('Password reset email sent successfully to: $email');
    } on FirebaseAuthException catch (e) {
      print('ERROR: Password reset failed for $email: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('ERROR: Password reset failed: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Password reset failed: $e');
    }
  }

  /// Checks if the current user's email has been verified
  Future<bool> checkEmailVerificationStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.reload().timeout(const Duration(seconds: 5));
        final isVerified = _auth.currentUser!.emailVerified;
        
        // Update Firestore document when email is verified
        if (isVerified) {
          try {
            await _firestore.collection('users').doc(user.uid).update({
              'isEmailVerified': true,
            }).timeout(const Duration(seconds: 5));
          } catch (e) {
            print('Warning: Failed to update isEmailVerified in Firestore: $e');
          }
        }
        
        return isVerified;
      } catch (e) {
        print('Warning: Email verification status reload failed: $e');
        return user.emailVerified;
      }
    }
    return false;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- Exception Handling ---

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

class RoleMismatchException implements Exception {
  final String message;
  RoleMismatchException(this.message);
  @override
  String toString() => message;
}

class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException(this.message);
  @override
  String toString() => message;
}
