// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/modules/purchase/miraj/screens/vendor_contact_screen.dart';

class MirajVendorMasterScreen extends StatefulWidget {
  final String tenantId;
  final String currentUserUid;

  const MirajVendorMasterScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
  });

  @override
  State<MirajVendorMasterScreen> createState() =>
      _MirajVendorMasterScreenState();
}

class _MirajVendorMasterScreenState extends State<MirajVendorMasterScreen> {
  final _searchController = TextEditingController();

  CollectionReference<Map<String, dynamic>> get _vendorsRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(widget.tenantId)
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
          tenantId: widget.tenantId,
          currentUserUid: widget.currentUserUid,
          vendorId: vendorId,
          initialData: data,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          final searchText = _searchController.text.trim().toLowerCase();

          final vendors = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data();

            if (data['isDeleted'] == true) return false;

            if (searchText.isEmpty) return true;

            final searchableText = [
              data['name'],
              data['contactPerson'],
              data['phone'],
              data['email'],
              data['gstNo'],
            ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

            return searchableText.contains(searchText);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _VendorHeader(),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search vendors...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

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
                            vendorRef: doc.reference,
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
  final _panController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankBranchController = TextEditingController();
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
    _panController.text = (data['panNo'] ?? '').toString();
    _bankNameController.text = (data['bankName'] ?? '').toString();
    _accountHolderController.text = (data['accountHolderName'] ?? '')
        .toString();
    _accountNoController.text = (data['bankAccountNo'] ?? '').toString();
    _ifscController.text = (data['ifscCode'] ?? '').toString();
    _bankBranchController.text = (data['bankBranch'] ?? '').toString();
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
    _panController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _bankBranchController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) return 'Vendor name is required';
    if (name.length < 3) return 'Vendor name must be at least 3 characters';
    if (name.length > 100) return 'Vendor name cannot exceed 100 characters';

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null;

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return 'Enter valid 10 digit phone number';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;

    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      return 'Enter valid email address';
    }

    return null;
  }

  String? _validateGst(String? value) {
    final gst = value?.trim().toUpperCase() ?? '';
    if (gst.isEmpty) return null;

    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][A-Z0-9]{3}$').hasMatch(gst)) {
      return 'Enter valid 15 character GST number';
    }

    return null;
  }

  String? _validatePan(String? value) {
    final pan = value?.trim().toUpperCase() ?? '';
    if (pan.isEmpty) return null;

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
      return 'Enter valid PAN number';
    }

    return null;
  }

  String? _validateAccountNo(String? value) {
    final accountNo = value?.trim() ?? '';
    if (accountNo.isEmpty) return null;

    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(accountNo)) {
      return 'Enter valid account number';
    }

    return null;
  }

  String? _validateIfsc(String? value) {
    final ifsc = value?.trim().toUpperCase() ?? '';
    if (ifsc.isEmpty) return null;

    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      return 'Enter valid IFSC code';
    }

    return null;
  }

  Future<bool> _vendorFieldExists(String field, String value) async {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) return false;

    final snapshot = await _vendorsRef
        .where(field, isEqualTo: normalizedValue)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    if (_isEdit && snapshot.docs.first.id == widget.vendorId) {
      return false;
    }

    return true;
  }

  Future<String?> _findDuplicateVendorField({
    required String name,
    required String phone,
    required String email,
    required String gstNo,
    required String panNo,
    required String bankAccountNo,
  }) async {
    final checks = <String, String>{
      'nameLower': name.trim().toLowerCase(),
      'phone': phone.trim(),
      'email': email.trim().toLowerCase(),
      'gstNo': gstNo.trim().toUpperCase(),
      'panNo': panNo.trim().toUpperCase(),
      'bankAccountNo': bankAccountNo.trim(),
    };

    final labels = <String, String>{
      'nameLower': 'Vendor name already exists',
      'phone': 'Phone number already exists',
      'email': 'Email already exists',
      'gstNo': 'GST number already exists',
      'panNo': 'PAN number already exists',
      'bankAccountNo': 'Bank account number already exists',
    };

    for (final entry in checks.entries) {
      if (entry.value.isEmpty) continue;

      if (await _vendorFieldExists(entry.key, entry.value)) {
        return labels[entry.key];
      }
    }

    return null;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor?'),
        content: const Text(
          'This vendor will be hidden from the system. Existing purchase records will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _vendorsRef.doc(widget.vendorId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': widget.currentUserUid,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vendor deleted')));

    Navigator.pop(context);
  }

  Future<void> _save() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final duplicateMessage = await _findDuplicateVendorField(
        name: name,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        gstNo: _gstController.text.trim().toUpperCase(),
        panNo: _panController.text.trim().toUpperCase(),
        bankAccountNo: _accountNoController.text.trim(),
      );

      if (duplicateMessage != null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(duplicateMessage),
            backgroundColor: Colors.orange,
          ),
        );

        setState(() => _isSaving = false);
        return;
      }
      final data = {
        'tenantId': widget.tenantId,
        'name': name,
        'nameLower': name.toLowerCase(),
        'contactPerson': _contactController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gstNo': _gstController.text.trim().toUpperCase(),
        'panNo': _panController.text.trim().toUpperCase(),
        'bankName': _bankNameController.text.trim(),
        'accountHolderName': _accountHolderController.text.trim(),
        'bankAccountNo': _accountNoController.text.trim(),
        'ifscCode': _ifscController.text.trim().toUpperCase(),
        'bankBranch': _bankBranchController.text.trim(),
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
                    validator: _validateName,
                    maxLength: 100,
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
                    validator: _validatePhone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.call_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstController,
                    validator: _validateGst,
                    maxLength: 15,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'GST No.',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _panController,
                    validator: _validatePan,
                    maxLength: 10,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'PAN No.',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _accountHolderController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      prefixIcon: Icon(Icons.person_pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _accountNoController,
                    keyboardType: TextInputType.number,
                    validator: _validateAccountNo,
                    decoration: const InputDecoration(
                      labelText: 'Account No.',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ifscController,
                    validator: _validateIfsc,
                    maxLength: 11,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankBranchController,
                    decoration: const InputDecoration(
                      labelText: 'Branch Name',
                      prefixIcon: Icon(Icons.account_tree_outlined),
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

            const SizedBox(height: 12),

            if (_isEdit)
              OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Vendor'),
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
  final DocumentReference<Map<String, dynamic>> vendorRef;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _VendorCard({
    required this.vendorRef,
    required this.data,
    required this.onTap,
  });

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
        trailing: Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorContactScreen(
                      vendorRef: vendorRef,
                      vendorName: (data['name'] ?? 'Vendor').toString(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.contacts_outlined, size: 18),
              label: const Text('Contacts'),
            ),
            IconButton(onPressed: onTap, icon: const Icon(Icons.edit_outlined)),
          ],
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
