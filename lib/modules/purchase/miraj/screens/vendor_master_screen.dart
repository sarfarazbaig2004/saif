// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MirajVendorMasterScreen extends StatelessWidget {
  final String tenantId;
  final String currentUserUid;

  const MirajVendorMasterScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
  });

  CollectionReference<Map<String, dynamic>> get _vendorsRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(tenantId)
      .collection('vendors');

  void _openForm(
    BuildContext context, {
    String? vendorId,
    Map<String, dynamic>? data,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MirajVendorFormScreen(
          tenantId: tenantId,
          currentUserUid: currentUserUid,
          vendorId: vendorId,
          initialData: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('New Vendor'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _vendorsRef.orderBy('nameLower').snapshots(),
        builder: (context, snapshot) {
          final vendors = (snapshot.data?.docs ?? [])
              .where((doc) => doc.data()['isDeleted'] != true)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _VendorHeader(),
              const SizedBox(height: 14),
              Expanded(
                child:
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : vendors.isEmpty
                    ? const _EmptyVendorState()
                    : ListView.separated(
                        itemCount: vendors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = vendors[index];
                          return _VendorCard(
                            data: doc.data(),
                            onTap: () => _openForm(
                              context,
                              vendorId: doc.id,
                              data: doc.data(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MirajVendorFormScreen extends StatefulWidget {
  final String tenantId;
  final String currentUserUid;
  final String? vendorId;
  final Map<String, dynamic>? initialData;

  const MirajVendorFormScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
    this.vendorId,
    this.initialData,
  });

  @override
  State<MirajVendorFormScreen> createState() => _MirajVendorFormScreenState();
}

class _MirajVendorFormScreenState extends State<MirajVendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEdit => widget.vendorId != null;

  CollectionReference<Map<String, dynamic>> get _vendorsRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(widget.tenantId)
      .collection('vendors');

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;

    _nameController.text = (data['name'] ?? '').toString();
    _contactController.text = (data['contactPerson'] ?? '').toString();
    _phoneController.text = (data['phone'] ?? '').toString();
    _emailController.text = (data['email'] ?? '').toString();
    _gstController.text = (data['gstNo'] ?? '').toString();
    _addressController.text = (data['address'] ?? '').toString();
    _notesController.text = (data['notes'] ?? '').toString();
    _isActive = data['isActive'] != false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _save() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final data = {
        'tenantId': widget.tenantId,
        'name': name,
        'nameLower': name.toLowerCase(),
        'contactPerson': _contactController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gstNo': _gstController.text.trim(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
        'isActive': _isActive,
        'isDeleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.currentUserUid,
      };

      if (_isEdit) {
        await _vendorsRef.doc(widget.vendorId).update(data);
      } else {
        await _vendorsRef.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': widget.currentUserUid,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Vendor updated' : 'Vendor saved')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save vendor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Vendor' : 'New Vendor'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101828),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _Card(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name *',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Person',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.call_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstController,
                    decoration: const InputDecoration(
                      labelText: 'GST No.',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    title: const Text('Active Vendor'),
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving...' : 'Save Vendor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorHeader extends StatelessWidget {
  const _VendorHeader();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendors',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Maintain supplier master records before creating offers and purchase orders.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _VendorCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = data['isActive'] != false;
    return _Card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: active
              ? const Color(0xFFEAF2FF)
              : const Color(0xFFF2F4F7),
          child: Icon(
            Icons.business_outlined,
            color: active ? const Color(0xFF2563EB) : const Color(0xFF667085),
          ),
        ),
        title: Text(
          (data['name'] ?? 'Vendor').toString(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            (data['contactPerson'] ?? '').toString(),
            (data['phone'] ?? '').toString(),
            (data['gstNo'] ?? '').toString(),
          ].where((value) => value.trim().isNotEmpty).join(' • '),
        ),
        trailing: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.edit_outlined),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyVendorState extends StatelessWidget {
  const _EmptyVendorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4E7EC)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 42, color: Color(0xFF667085)),
            SizedBox(height: 12),
            Text(
              'No vendors yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Create vendor master records here, then use those suppliers for offers and purchase orders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667085), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
