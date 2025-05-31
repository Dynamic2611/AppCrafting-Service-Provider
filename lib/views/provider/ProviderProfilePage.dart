import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController(); // New Controller

  bool _loading = true;
  bool _saving = false;
  double _rating = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  //-----------fetching Data about the provides---------------
  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    final doc = await FirebaseFirestore.instance.collection('providers').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameCtrl.text = data['name'] ?? user.displayName ?? '';
      _descriptionCtrl.text = data['description'] ?? ''; // Fetch description
    } else {
      _nameCtrl.text = user.displayName ?? '';
    }

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .collection('orders')
        .get();

    final ratings = ordersSnapshot.docs
        .map((doc) => doc.data()['customerRating'])
        .where((rating) => rating != null)
        .map((rating) => (rating as num).toDouble())
        .toList();

    if (ratings.isNotEmpty) {
      final total = ratings.reduce((a, b) => a + b);
      _rating = total / ratings.length;
      await FirebaseFirestore.instance.collection('providers').doc(uid).update({
        'rating': _rating,
      });
    } else {
      _rating = 0.0;
    }

    setState(() => _loading = false);
  }

  // ------- Save the providers details
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    await FirebaseFirestore.instance.collection('providers').doc(uid).set({
      'name': name,
      'description': description, // Save description
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayImage = FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: const Text('Provider Profile')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: displayImage != null ? NetworkImage(displayImage) : null,
                        child: displayImage == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      const Text('Rating:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < _rating.round() ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_rating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
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
