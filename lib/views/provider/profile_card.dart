import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatefulWidget {
  final Map<String, dynamic> data;          
  const ProfileCard({super.key, required this.data});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late String _name;
  String? _imgUrl;
  double _rating = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _name    = widget.data['name'] ?? '';
    _imgUrl  = widget.data['profileImage'] as String?;
    _rating  = (widget.data['rating'] ?? 0).toDouble();
    _refreshRating();         
  }


  // ----------------Refreshing the rating ---------------
  Future<void> _refreshRating() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('rating')) {
        setState(() {
          _rating = (data['rating'] as num).toDouble();
        });
      }
    }
  } catch (e) {
    debugPrint('Error fetching provider rating: $e');
  }

  if (mounted) {
    setState(() {
      _loading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 32,
          backgroundImage: _imgUrl != null ? NetworkImage(_imgUrl!) : null,
          child: _imgUrl == null ? const Icon(Icons.person, size: 32) : null,
        ),
        title: Text(
          _name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                children: [
                  const Text(
                    'Rating:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < _rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => Navigator.pushNamed(context, '/providerProfile'),
        ),
      ),
    );

  }
}
