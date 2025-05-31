import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'service_detail_page.dart';

class CategoryServicesPage extends StatefulWidget {
  final String category;
  const CategoryServicesPage({super.key, required this.category});

  @override
  State<CategoryServicesPage> createState() => _CategoryServicesPageState();
}

class _CategoryServicesPageState extends State<CategoryServicesPage> {
  List<Map<String, dynamic>> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  // Fetching services
  Future<void> fetchServices() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('category', isEqualTo: widget.category)
          .get();

      List<Map<String, dynamic>> serviceList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final providerId = data['providerId'];

        final providerSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .get();

        final providerData = providerSnapshot.data();

        serviceList.add({
          ...data,
          'docId': doc.id,
          'providerName': providerData?['name'] ?? 'Unknown',
        });
      }

      setState(() {
        services = serviceList;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailPage(service: service),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.lightBlueAccent.shade200,
                child: const Icon(Icons.build, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['title'] ?? 'No Title',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${service['providerName'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${service['price']} • ${service['category']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: Text('${widget.category} Services'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
              ? const Center(
                  child: Text(
                    'No providers found for this category.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) =>
                        _buildServiceCard(services[index]),
                  ),
                ),
    );
  }
}
