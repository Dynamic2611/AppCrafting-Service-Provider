import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProviderDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;
  const ProviderDetailPage({super.key, required this.doc});

  // helper to fetch provider’s services
  Future<List<QueryDocumentSnapshot>> _fetchServices() async {
    final providerId = doc.id;
    final snap = await FirebaseFirestore.instance
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .get();
    return snap.docs;
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: Text(data['name'] ?? 'Provider')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ---------- provider card ----------
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: data['profileImage'] != null
                            ? NetworkImage(data['profileImage'])
                            : null,
                        child: data['profileImage'] == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(data['name'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < (data['rating'] ?? 0).round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text((data['rating'] ?? 0).toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('About Provider:',
                        style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black,fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      data['description'] ?? 'No description provided.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Services Offered',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            // ---------- services list ----------
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _fetchServices(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Text('Error loading services');
                }
                final services = snap.data!;
                if (services.isEmpty) {
                  return const Text('No services added yet.');
                }
                return Column(
                  children: services.map((s) {
                    final sd = s.data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(sd['title'] ?? 'Untitled',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(sd['category'] ?? ''),
                        trailing: Text('₹${sd['price']}'),
                        onTap: () {
                          // optional: book directly from here
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
