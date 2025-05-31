import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceFormPage extends StatefulWidget {
  ///  `serviceDoc` == null → Add-mode, otherwise Edit-mode.
  final DocumentSnapshot? serviceDoc;
  const ServiceFormPage({super.key, this.serviceDoc});

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl  = TextEditingController();
  final _priceCtl = TextEditingController();

  List<String> _categories = [];
  String? _selectedCat;
  bool _loadingCats = true;
  bool _saving      = false;

  bool get _isEdit => widget.serviceDoc != null;

  @override
  void initState() {
    super.initState();
    _preFillIfEdit();
    _fetchCategories();
  }

  void _preFillIfEdit() {
    if (_isEdit) {
      final d = widget.serviceDoc!.data() as Map<String, dynamic>;
      _titleCtl.text = d['title'] ?? '';
      _descCtl.text  = d['description'] ?? '';
      _priceCtl.text = d['price']?.toString() ?? '';
      _selectedCat   = d['category'];
    }
  }

  Future<void> _fetchCategories() async {
    final snap =
        await FirebaseFirestore.instance.collection('categories').get();
    _categories = snap.docs.map((d) => d['name'] as String).toList();

    // Ensuring current category is in the list
    if (_selectedCat != null && !_categories.contains(_selectedCat)) {
      _categories.insert(0, _selectedCat!);
    }
    if (_categories.isNotEmpty && _selectedCat == null) {
      _selectedCat = _categories.first;
    }
    setState(() => _loadingCats = false);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _priceCtl.dispose();
    super.dispose();
  }

  // ───────────────────────── Category helper ─────────────────────────
  Future<void> _addNewCategory() async {
    final ctrl = TextEditingController();
    final newCat = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Appliance Repair'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );

    if (newCat != null && newCat.isNotEmpty && !_categories.contains(newCat)) {
      await FirebaseFirestore.instance.collection('categories').add({'name': newCat});
      setState(() {
        _categories.add(newCat);
        _selectedCat = newCat;
      });
    }
  }

  // ───────────────────────── Submit ─────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'title'      : _titleCtl.text.trim(),
      'description': _descCtl.text.trim(),
      'price'      : double.parse(_priceCtl.text),
      'category'   : _selectedCat,
    };

    try {
      if (_isEdit) {
        await widget.serviceDoc!.reference.update(data);
      } else {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('services').add({
          ...data,
          'providerId': uid,
          'createdAt' : FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Service updated' : 'Service added')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ───────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loadingCats) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.1,
        title: Text(_isEdit ? 'Edit Service' : 'Add Service')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Title
                  TextFormField(
                    controller: _titleCtl,
                    decoration: const InputDecoration(
                      labelText: 'Service Title',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descCtl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  TextFormField(
                    controller: _priceCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Price (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final parsed = double.tryParse(v);
                      if (parsed == null) return 'Invalid number';
                      if (parsed < 0) return 'Must be positive';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCat,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ..._categories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c))),
                      const DropdownMenuItem(
                          value: '__add__', child: Text('➕ Add new category')),
                    ],
                    onChanged: (val) {
                      if (val == '__add__') {
                        _addNewCategory();
                      } else {
                        setState(() => _selectedCat = val);
                      }
                    },
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(_isEdit ? Icons.save : Icons.add),
                      label: Text(_saving
                          ? (_isEdit ? 'Saving...' : 'Adding...')
                          : (_isEdit ? 'Update Service' : 'Add Service')),
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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
