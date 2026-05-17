import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer_contact_model.dart';

class CustomerContactFormDialog extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final DocumentSnapshot<Map<String, dynamic>>? contactDoc;

  const CustomerContactFormDialog({
    super.key,
    required this.customerRef,
    this.contactDoc,
  });

  static Future<void> show(
    BuildContext context, {
    required DocumentReference<Map<String, dynamic>> customerRef,
    DocumentSnapshot<Map<String, dynamic>>? contactDoc,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CustomerContactFormDialog(
        customerRef: customerRef,
        contactDoc: contactDoc,
      ),
    );
  }

  @override
  State<CustomerContactFormDialog> createState() =>
      _CustomerContactFormDialogState();
}

class _CustomerContactFormDialogState extends State<CustomerContactFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _designation = TextEditingController();
  final _department = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();

  bool _isPrimary = false;
  bool _saving = false;

  bool get _isEdit => widget.contactDoc != null;

  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      widget.customerRef.collection('contacts');

  @override
  void initState() {
    super.initState();
    final doc = widget.contactDoc;
    if (doc != null) {
      final d = doc.data() ?? {};
      _name.text = (d['name'] ?? '').toString();
      _designation.text = (d['designation'] ?? '').toString();
      _department.text = (d['department'] ?? '').toString();
      _mobile.text = (d['mobile'] ?? d['phone'] ?? '').toString();
      _email.text = (d['email'] ?? '').toString();
      _isPrimary = d['isPrimary'] == true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    _department.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _unsetOtherPrimary() async {
    final snapshot = await _contactsRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snapshot.docs) {
      if (_isEdit && d.id == widget.contactDoc!.id) continue;
      if (d.data()['isPrimary'] == true) {
        batch.update(d.reference, {
          'isPrimary': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobile.text.trim();
    final email = _email.text.trim();
    if (mobile.isEmpty && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a mobile number or email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      if (_isPrimary) await _unsetOtherPrimary();

      final contact = CustomerContactModel(
        id: widget.contactDoc?.id ?? '',
        name: _name.text.trim(),
        designation: _designation.text.trim(),
        department: _department.text.trim(),
        mobile: mobile,
        email: email,
        isPrimary: _isPrimary,
      );

      if (_isEdit) {
        await widget.contactDoc!.reference.update({
          ...contact.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': uid,
        });
      } else {
        await _contactsRef.add({
          ...contact.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'createdByUid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': uid,
          'isActive': true,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Contact updated' : 'Contact added'),
          backgroundColor: Colors.green,
        ),
      );
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

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit Contact' : 'Add Contact',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 16),
                _field(
                  'Name *',
                  _name,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field('Designation', _designation)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Department', _department)),
                  ],
                ),
                const SizedBox(height: 12),
                _field('Mobile', _mobile, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _field(
                  'Email',
                  _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return null;
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _isPrimary
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPrimary
                          ? Colors.green.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: SwitchListTile(
                    dense: true,
                    value: _isPrimary,
                    onChanged: (v) => setState(() => _isPrimary = v),
                    title: const Text(
                      'Primary contact',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _isPrimary
                          ? 'Main point of contact for this customer'
                          : 'Mark as the main point of contact',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'Update' : 'Add Contact'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
