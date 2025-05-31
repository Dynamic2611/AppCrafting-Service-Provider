import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import 'orders_list.dart';
import 'profile_card.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final providerDoc =
        FirebaseFirestore.instance.collection('providers').doc(uid);
        final auth = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: const Text('Provider Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                      if (shouldLogout == true) {
                        await auth.signOut();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: providerDoc.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exists = snap.data!.exists;
          final data   = snap.data!.data() as Map<String, dynamic>?;

          return RefreshIndicator(
            onRefresh: () async {
              // Pull-to-refresh simply re-triggers the stream rebuild.
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1️⃣ PROFILE section
                exists
                    ? ProfileCard(data: data!)
                    : _setupBanner(context),
                const SizedBox(height: 20),

                // 2️⃣ ORDERS section
                Text('My Orders',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const SizedBox(
                  height: 450, // fixed height for orders list
                  child: OrdersList(),
                ),
                const SizedBox(height: 10),

                // 3️⃣ ACTION BUTTONS
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dashboardButton(
                      context,
                      icon: Icons.add_circle_outline,
                      label: 'Add Service',
                      onTap: () => Navigator.pushNamed(context, '/addService'),
                    ),
                    _dashboardButton(
                      context,
                      icon: Icons.list_alt,
                      label: 'My Services',
                      onTap: () => Navigator.pushNamed(context, '/myServices'),
                    ),
                    
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── Helpers ─────────────────────────

  Widget _setupBanner(BuildContext ctx) => Card(
        color: Colors.amber.shade100,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.warning_amber, color: Colors.black87),
          title: const Text('Complete your provider profile'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Navigator.pushNamed(ctx, '/providerProfile'),
        ),
      );

  Widget _dashboardButton(BuildContext ctx,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: 140,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
