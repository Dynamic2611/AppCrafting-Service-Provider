import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersList extends StatelessWidget {
  const OrdersList({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ordersCol = FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: ordersCol.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Error loading orders'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data!.docs;
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final doc = orders[i];
            final d = doc.data() as Map<String, dynamic>;
            final status = (d['status'] ?? 'Pending') as String;
            final statusColor = _getStatusColor(status.toLowerCase());
            final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
            final dateString =
                createdAt != null ? DateFormat('yyyy-MM-dd – hh:mm a').format(createdAt) : '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: const Icon(Icons.shopping_bag, color: Colors.indigo),
                title: Text(d['serviceTitle'] ?? 'Service Title', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Created: $dateString'),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(status.toUpperCase()),
                      backgroundColor: statusColor.withOpacity(0.2),
                      labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => OrderDetailDialog(
                    orderId: doc.id,
                    data: d,
                    providerId: uid,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}




class OrderDetailDialog extends StatefulWidget {
  final String orderId;
  final String providerId;
  final Map<String, dynamic> data;

  const OrderDetailDialog({
    super.key,
    required this.orderId,
    required this.data,
    required this.providerId,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  final List<String> _statusOptions = ['pending', 'confirmed', 'in progress', 'completed', 'cancelled'];
  late String _selectedStatus;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.data['status'] ?? 'pending';
  }

  Future<void> _updateStatus() async {
    setState(() => _updating = true);
    await FirebaseFirestore.instance
        .collection('providers')
        .doc(widget.providerId)
        .collection('orders')
        .doc(widget.orderId)
        .update({'status': _selectedStatus});
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $_selectedStatus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat('yyyy-MM-dd – hh:mm a').format(createdAt)
        : 'Unknown';

    return AlertDialog(
      title: const Text('Order Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Service', data['serviceTitle']),
            _infoRow('Customer', data['customerName']),
            _infoRow('Phone', data['customerPhone']),
            _infoRow('Created At', formattedDate),
            const SizedBox(height: 12),
            const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              onChanged: (val) => setState(() => _selectedStatus = val!),
              items: _statusOptions.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _updating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _updating ? null : _updateStatus,
          icon: _updating
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
          label: Text(_updating ? 'Updating...' : 'Update'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }
}
