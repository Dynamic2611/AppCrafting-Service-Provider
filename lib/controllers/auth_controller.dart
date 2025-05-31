import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register new user 
  Future<void> register(String email, String password, String role) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    await _firestore.collection('users').doc(result.user!.uid).set({
      'uid': result.user!.uid,
      'email': email,
      'role': role,
    });
  }

  //returns the role on success, otherwise throws a FirebaseAuthException
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


  // SignOut Function
  Future<void> signOut() async => await _auth.signOut();

  // Sends a password reset email to the user.

  Future<void> sendPasswordResetEmail({
      required BuildContext context,
      required String email,
    }) async {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );

        // Delay for 2 seconds before navigating
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to login page
        Navigator.pushReplacementNamed(context, '/login');

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
}

