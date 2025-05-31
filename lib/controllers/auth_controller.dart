import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ──────────────────────────────────────────────
  /// REGISTER  ➜  delay 1 s ➜  sign-out ➜  go to login
  /// ──────────────────────────────────────────────
  Future<void> register({
    required BuildContext context,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'role': role,
      });

      // Feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Account created successfully! Please log in.',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );


      // Wait a moment so user can read the message
      await Future.delayed(const Duration(seconds: 2));


      // Navigate to login page
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException {
      rethrow; // let UI show friendly error
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Unexpected error, please try again.',
      );
    }
  }

  /// ──────────────────────────────────────────────
  /// LOGIN  (returns role or throws)
  /// ──────────────────────────────────────────────
  Future<String> login({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final snap =
          await _firestore.collection('users').doc(cred.user!.uid).get();
      final role = (snap.data()?['role'] ?? 'Customer') as String;

      if (role != selectedRole) {
        await _auth.signOut(); // keep auth state clean
        throw FirebaseAuthException(
          code: 'role-mismatch',
          message: 'This account is registered as $role. Please switch the toggle.',
        );
      }
      return role;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Unexpected error, please try again later.',
      );
    }
  }

  /// ──────────────────────────────────────────────
  /// SIGN-OUT
  /// ──────────────────────────────────────────────
  Future<void> signOut() async => _auth.signOut();

  /// ──────────────────────────────────────────────
  /// PASSWORD RESET EMAIL
  /// ──────────────────────────────────────────────
  Future<void> sendPasswordResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
