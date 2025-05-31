import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Fetching the profile details
  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snap.exists) {
      _nameCtrl.text = snap['name'] ?? '';
      _phoneCtrl.text = snap['phone'] ?? '';
    }
    setState(() => _loading = false);
  }

  // Saving the profile details
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


// Showing the rating 
  Future<void> _showRatingDialog(
      DocumentReference orderRef, Map<String, dynamic> data) async {
    double rating = (data['customerRating'] ?? 0).toDouble();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rate this service'),
        content: StatefulBuilder(
          builder: (_, setStateSB) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 32,
                ),
                onPressed: () => setStateSB(() => rating = i + 1.0),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await orderRef.update({'customerRating': rating});
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your rating!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = FirebaseAuth.instance.currentUser;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ordersStream = FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('customerId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: const Text('My Profile')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadProfile();
              setState(() {}); 
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Profile section
                Text('Profile Information',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v!.isEmpty || v.length < 10 ? 'Enter a valid number' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: user.email ?? '',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Orders section
                Text('My Orders', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: ordersStream.snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Error loading orders'),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No orders placed yet'),
                      );
                    }
                    return ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data() as Map<String, dynamic>;

                        Color statusColor;
                        switch (data['status']?.toString().toLowerCase()) {
                          case 'completed':
                            statusColor = Colors.green;
                            break;
                          case 'pending':
                            statusColor = Colors.orange;
                            break;
                          case 'cancelled':
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return ListTile(
                          title: Text(data['serviceTitle'] ?? 'Service'),
                          subtitle: Row(
                            children: [
                              Chip(
                                label: Text(
                                  data['status'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: statusColor,
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < (data['customerRating'] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _showRatingDialog(doc.reference, data),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Sign-out button with confirmation dialog
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
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
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_saving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
