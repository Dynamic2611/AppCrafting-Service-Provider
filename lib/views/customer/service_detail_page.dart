import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_profile_page.dart';

class ServiceDetailPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  bool _isBooking = false;

  // Booking the services and fetching it 
  Future<void> _bookService(BuildContext context) async {
    setState(() => _isBooking = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final service = widget.service;

      if (!userSnap.exists ||
          userSnap['name'] == null ||
          userSnap['name'].toString().isEmpty ||
          userSnap['phone'] == null ||
          userSnap['phone'].toString().isEmpty) {
        // force user to fill profile
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Profile required'),
            content: const Text('Please complete your profile before booking.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Go to Profile')),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserProfilePage()),
          );
        }
        return;
      }

      // Confirm booking before proceeding
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm Booking'),
          content: Text(
            'Do you want to book "${service['title'] ?? 'this service'}"?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm')),
          ],
        ),
      );

      if (confirm != true) return;

      final userData = userSnap.data()!;
      final providerId = service['providerId']; // passed in earlier

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .collection('orders')
          .add({
        'serviceId': service['docId'],
        'serviceTitle': service['title'],
        'customerId': uid,
        'customerName': userData['name'],
        'customerPhone': userData['phone'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context); // back to service list
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: const Text('Service Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              service['title'] ?? 'No Title',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(service['category'] ?? 'Unknown',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Text('Price',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('₹${service['price'] ?? 'N/A'}',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      service['description'] ?? 'No description provided.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Provider: ${service['providerName'] ?? 'Unknown'}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isBooking ? null : () => _bookService(context),
                icon: _isBooking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shopping_cart_checkout),
                label: Text(_isBooking ? 'Booking...' : 'Book Service'),
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
