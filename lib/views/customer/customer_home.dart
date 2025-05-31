import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'categories.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  List<String> categories = [];
  List<DocumentSnapshot> topProviders = [];
  bool isLoadingCategories = true;
  bool isLoadingProviders = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchTopProviders();
  }

  // Fetching the categoriers of services
  Future<void> fetchCategories() async {
    final snap = await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      categories = snap.docs.map((doc) => doc['name'] as String).toList();
      isLoadingCategories = false;
    });
  }

  // Fetching the top providers based on rating
  Future<void> fetchTopProviders() async {
    final snap = await FirebaseFirestore.instance
        .collection('providers')
        .orderBy('rating', descending: true)
        .limit(5)
        .get();

    setState(() {
      topProviders = snap.docs;
      isLoadingProviders = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: Text('Find Your Service', style: textTheme.titleLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.profile_circled, color: Colors.blue[900]),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                isLoadingCategories = true;
                isLoadingProviders = true;
              });
              await fetchCategories();
              await fetchTopProviders();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 12),

                Text(
                  'Hi there 👋',
                  style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                ),

                const SizedBox(height: 6),

                Text(
                  'What service do you need today?',
                  style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),

                const SizedBox(height: 24),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for services...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {},
                ),

                const SizedBox(height: 30),

                // Categories Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Categories', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    if (!isLoadingCategories && categories.isNotEmpty)
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      )
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 50,
                  child: isLoadingCategories
                      ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
                      : categories.isEmpty
                          ? const Center(child: Text("No categories available"))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryServicesPage(category: categories[index]),
                                      ),
                                    );
                                  },
                                  child: Chip(
                                    label: Text(
                                      categories[index],
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: Colors.blue.shade50,
                                    elevation: 3,
                                    shadowColor: Colors.blue.shade100,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                );
                              },
                            ),
                ),

                const SizedBox(height: 40),

                // Top Providers Section
                Text('Top Service Providers', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),

                const SizedBox(height: 12),

                isLoadingProviders
                    ? const Center(child: CircularProgressIndicator())
                    : topProviders.isEmpty
                        ? const Center(child: Text("No top providers found"))
                        : Column(
                            children: topProviders.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final rating = (data['rating'] ?? 0).toDouble();

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.shade200,
                                    child: data['photoUrl'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(28),
                                            child: Image.network(data['photoUrl'], fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.person, color: Colors.white, size: 32),
                                  ),
                                  title: Text(
                                    data['name'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (i) => Icon(
                                          i < rating.round() ? Icons.star : Icons.star_border,
                                          color: Colors.orange.shade400,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/providerDetail', arguments: doc);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
