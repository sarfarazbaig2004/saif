import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorContactScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> vendorRef;
  final String vendorName;

  const VendorContactScreen({
    super.key,
    required this.vendorRef,
    required this.vendorName,
  });

  @override
  State<VendorContactScreen> createState() => _VendorContactScreenState();
}

class _VendorContactScreenState extends State<VendorContactScreen> {
  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      widget.vendorRef.collection('contacts');

  Future<void> _openForm({
    String? contactId,
    Map<String, dynamic>? data,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _VendorContactForm(
        contactsRef: _contactsRef,
        contactId: contactId,
        initialData: data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Contacts - ${widget.vendorName}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101828),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _contactsRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = snapshot.data?.docs ?? [];

          if (contacts.isEmpty) {
            return const Center(child: Text('No vendor contacts yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = contacts[index];
              final data = doc.data();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      data['isPrimary'] == true
                          ? Icons.verified_user_outlined
                          : Icons.person_outline,
                    ),
                  ),
                  title: Text((data['name'] ?? 'Contact').toString()),
                  subtitle: Text(
                    [
                          data['designation'],
                          data['department'],
                          data['phone'],
                          data['email'],
                          data['isPrimary'] == true ? 'Primary' : '',
                        ]
                        .map((e) => (e ?? '').toString())
                        .where((e) => e.trim().isNotEmpty)
                        .join(' | '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openForm(contactId: doc.id, data: data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _VendorContactForm extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> contactsRef;
  final String? contactId;
  final Map<String, dynamic>? initialData;

  const _VendorContactForm({
    required this.contactsRef,
    this.contactId,
    this.initialData,
  });

  @override
  State<_VendorContactForm> createState() => _VendorContactFormState();
}

class _VendorContactFormState extends State<_VendorContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _designation = TextEditingController();
  final _department = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _isPrimary = false;
  bool _saving = false;

  bool get _isEdit => widget.contactId != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;

    _name.text = (data['name'] ?? '').toString();
    _designation.text = (data['designation'] ?? '').toString();
    _department.text = (data['department'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    _phone.text = (data['phone'] ?? '').toString();
    _isPrimary = data['isPrimary'] == true;
  }

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    _department.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _unsetOtherPrimary() async {
    final snapshot = await widget.contactsRef.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      if (_isEdit && doc.id == widget.contactId) continue;

      if (doc.data()['isPrimary'] == true) {
        batch.update(doc.reference, {
          'isPrimary': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_isPrimary) {
        await _unsetOtherPrimary();
      }

      final data = {
        'name': _name.text.trim(),
        'designation': _designation.text.trim(),
        'department': _department.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'isPrimary': _isPrimary,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit) {
        await widget.contactsRef.doc(widget.contactId).update(data);
      } else {
        await widget.contactsRef.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Contact' : 'Add Contact'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _field(_name, 'Contact Name *', Icons.person_outline, true),
                _field(
                  _designation,
                  'Designation',
                  Icons.badge_outlined,
                  false,
                ),
                _field(
                  _department,
                  'Department',
                  Icons.account_tree_outlined,
                  false,
                ),
                _field(_email, 'Email', Icons.email_outlined, false),
                _field(_phone, 'Phone', Icons.phone_outlined, false),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPrimary,
                  title: const Text('Primary contact'),
                  onChanged: (value) {
                    setState(() => _isPrimary = value ?? false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
