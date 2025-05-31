import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../customer/customer_home.dart';
import '../provider/dashboard.dart';
import 'login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getHomePage(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = doc.data()?['role'];

    if (role == 'Provider') {
      return const ProviderDashboardPage(); // Provider Home Page
    } else {
      return const CustomerHome(); // Default to Customer
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // User is logged in, fetch their role and navigate accordingly
          return FutureBuilder<Widget>(
            future: _getHomePage(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnapshot.hasData) {
                return roleSnapshot.data!;
              } else {
                return const Scaffold(
                  body: Center(child: Text("Role not found. Contact support.")),
                );
              }
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
