import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add_edit_services_page.dart'; // <- ServiceFormPage

class MyServicesPage extends StatelessWidget {
  const MyServicesPage({super.key});

  // price formatter
  String _fmtPrice(num? p) =>
      p == null ? '—' : '₹${NumberFormat('#,##0.00', 'en_IN').format(p)}';

  // ───────────────────────── helpers ─────────────────────────
  Future<bool?> _confirmDelete(
      BuildContext context, DocumentReference docRef, Map<String, dynamic>? data) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete service?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await docRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Service deleted'),
          action: (data == null)
              ? null
              : SnackBarAction(
                  label: 'UNDO',
                  onPressed: () async => docRef.set(data),
                ),
        ),
      );
    }
    return ok;
  }

  void _openForm(BuildContext ctx, {DocumentSnapshot? doc}) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => ServiceFormPage(serviceDoc: doc)),
    );
  }

  // status chip color based on category hash (simple)
  Color _chipColor(String category) {
    final hash = category.codeUnits.fold(0, (p, c) => p + c);
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final query = FirebaseFirestore.instance
        .collection('services')
        .where('providerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: const Text('My Services')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        onPressed: () => _openForm(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // just wait; StreamBuilder auto refreshes
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.build_circle,
                        size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No services yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first service'),
                      onPressed: () => _openForm(context),
                    )
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final doc = docs[i];
                final d = doc.data() as Map<String, dynamic>;
                final cat = d['category'] ?? '—';

                return Dismissible(
                  key: ValueKey(doc.id),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context, doc.reference, d),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      title: Text(
                        d['title'] ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Chip(
                            label: Text(cat),
                            backgroundColor: _chipColor(cat),
                          ),
                          const SizedBox(width: 8),
                          Text(_fmtPrice(d['price'])),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _openForm(context, doc: doc);
                          if (value == 'delete') {
                            _confirmDelete(context, doc.reference, d);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () => _openForm(context, doc: doc),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
