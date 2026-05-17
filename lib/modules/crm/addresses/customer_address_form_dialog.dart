import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer_address_model.dart';

class CustomerAddressFormDialog extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final DocumentSnapshot<Map<String, dynamic>>? addressDoc;

  const CustomerAddressFormDialog({
    super.key,
    required this.customerRef,
    this.addressDoc,
  });

  static Future<void> show(
    BuildContext context, {
    required DocumentReference<Map<String, dynamic>> customerRef,
    DocumentSnapshot<Map<String, dynamic>>? addressDoc,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CustomerAddressFormDialog(
        customerRef: customerRef,
        addressDoc: addressDoc,
      ),
    );
  }

  @override
  State<CustomerAddressFormDialog> createState() =>
      _CustomerAddressFormDialogState();
}

class _CustomerAddressFormDialogState extends State<CustomerAddressFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String _addressType = CustomerAddressModel.addressTypes.first;
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _pincode = TextEditingController();
  final _gstNumber = TextEditingController();
  final _contactPerson = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  bool _isPrimary = false;
  bool _saving = false;

  bool get _isEdit => widget.addressDoc != null;

  CollectionReference<Map<String, dynamic>> get _addressesRef =>
      widget.customerRef.collection('addresses');

  @override
  void initState() {
    super.initState();
    final doc = widget.addressDoc;
    if (doc != null) {
      final d = doc.data() ?? {};
      _addressType =
          (d['addressType'] ?? CustomerAddressModel.addressTypes.first)
              .toString();
      _line1.text = (d['addressLine1'] ?? '').toString();
      _line2.text = (d['addressLine2'] ?? '').toString();
      _city.text = (d['city'] ?? '').toString();
      _state.text = (d['state'] ?? '').toString();
      _country.text = (d['country'] ?? 'India').toString();
      _pincode.text = (d['pincode'] ?? '').toString();
      _gstNumber.text = (d['gstNumber'] ?? '').toString();
      _contactPerson.text = (d['contactPerson'] ?? '').toString();
      _mobile.text = (d['mobile'] ?? '').toString();
      _email.text = (d['email'] ?? '').toString();
      _isPrimary = d['isPrimary'] == true;
    }
  }

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _pincode.dispose();
    _gstNumber.dispose();
    _contactPerson.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _unsetOtherPrimary() async {
    final snapshot = await _addressesRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snapshot.docs) {
      if (_isEdit && d.id == widget.addressDoc!.id) continue;
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      if (_isPrimary) await _unsetOtherPrimary();

      final address = CustomerAddressModel(
        id: widget.addressDoc?.id ?? '',
        addressType: _addressType,
        addressLine1: _line1.text.trim(),
        addressLine2: _line2.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        country: _country.text.trim(),
        pincode: _pincode.text.trim(),
        gstNumber: _gstNumber.text.trim(),
        contactPerson: _contactPerson.text.trim(),
        mobile: _mobile.text.trim(),
        email: _email.text.trim(),
        isPrimary: _isPrimary,
      );

      if (_isEdit) {
        await widget.addressDoc!.reference.update({
          ...address.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': uid,
        });
      } else {
        await _addressesRef.add({
          ...address.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'createdByUid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': uid,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Address updated' : 'Address added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save address: $e'),
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenHeight - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Icon(
                      Icons.location_on_outlined,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Address' : 'Add Address',
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
            ),
            const Divider(height: 1),

            // ── Scrollable form ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ADDRESS TYPE'),
                      DropdownButtonFormField<String>(
                        initialValue: _addressType,
                        items: CustomerAddressModel.addressTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _addressType = v!),
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      _sectionLabel('LOCATION'),
                      _field(
                        'Address Line 1 *',
                        _line1,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Address line 1 is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _field('Address Line 2', _line2),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _field(
                              'City *',
                              _city,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'City is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(flex: 3, child: _field('State', _state)),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _field(
                              'Pincode',
                              _pincode,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field('Country', _country),
                      const SizedBox(height: 16),

                      _sectionLabel('GST & CONTACT'),
                      _field('GST Number', _gstNumber),
                      const SizedBox(height: 12),
                      _field('Contact Person', _contactPerson),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'Mobile',
                              _mobile,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              'Email',
                              _email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final text = (v ?? '').trim();
                                if (text.isEmpty) return null;
                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(text)) {
                                  return 'Invalid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
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
                            'Primary address',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _isPrimary
                                ? 'This is the main address for this customer'
                                : 'Mark as the main address',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
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
                        : Text(_isEdit ? 'Update' : 'Add Address'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
