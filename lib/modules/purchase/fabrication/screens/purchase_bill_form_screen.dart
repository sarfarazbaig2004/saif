import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_inward_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_purchase_bill_model.dart';
import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';

class PurchaseBillFormScreen extends StatefulWidget {
  final String tenantId;

  const PurchaseBillFormScreen({super.key, required this.tenantId});

  @override
  State<PurchaseBillFormScreen> createState() => _PurchaseBillFormScreenState();
}

class _PurchaseBillFormScreenState extends State<PurchaseBillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FabricationInventoryRepository _repository;

  CollectionReference<Map<String, dynamic>> get _vendorsRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(widget.tenantId)
      .collection('vendors');

  final _supplierName = TextEditingController();
  final _supplierBillNo = TextEditingController();
  final _billAmount = TextEditingController();
  final _remarks = TextEditingController();

  DateTime _billDate = DateTime.now();
  String _status = 'pending';
  String? _linkedInwardId;
  String? _selectedVendorId;
  List<RawMaterialInwardModel> _receipts = const <RawMaterialInwardModel>[];
  bool _loadingReceipts = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository = FabricationInventoryRepository(tenantId: widget.tenantId);
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    try {
      final receipts = await _repository.fetchRecentInwardEntries();
      if (!mounted) return;
      setState(() {
        _receipts = receipts;
        _loadingReceipts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReceipts = false);
    }
  }

  @override
  void dispose() {
    _supplierName.dispose();
    _supplierBillNo.dispose();
    _billAmount.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final linkedReceipt = _receipts.where(
      (item) => item.inwardId == _linkedInwardId,
    );
    final selectedReceipt = linkedReceipt.isEmpty ? null : linkedReceipt.first;

    setState(() => _saving = true);
    try {
      await _repository.savePurchaseBill(
        RawMaterialPurchaseBillModel(
          billId: _repository.newPurchaseBillId(),
          billDate: _billDate,
          supplierName: _supplierName.text.trim(),
          supplierBillNo: _supplierBillNo.text.trim(),
          linkedInwardId: selectedReceipt?.inwardId ?? '',
          linkedChallanNo: selectedReceipt?.challanNo ?? '',
          billAmount: double.tryParse(_billAmount.text.trim()) ?? 0,
          status: _status,
          remarks: _remarks.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Purchase bill saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save purchase bill: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _billDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: const Text('New Purchase Bill'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: zBorder),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dateField(),
                    _vendorPickerField(),
                    _field(_supplierBillNo, 'Supplier Bill No', required: true),
                    _field(
                      _billAmount,
                      'Bill Amount',
                      number: true,
                      required: true,
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'booked',
                            child: Text('Booked'),
                          ),
                          DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: DropdownButtonFormField<String>(
                        initialValue: _linkedInwardId,
                        decoration: InputDecoration(
                          labelText: _loadingReceipts
                              ? 'Loading linked receipt...'
                              : 'Linked GRN / Material Receipt',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Not linked yet'),
                          ),
                          ..._receipts.map((receipt) {
                            return DropdownMenuItem<String>(
                              value: receipt.inwardId,
                              child: Text(
                                '${receipt.challanNo} • ${receipt.materialDescription}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: _loadingReceipts
                            ? null
                            : (value) {
                                setState(() => _linkedInwardId = value);
                                final linked = _receipts.where(
                                  (receipt) => receipt.inwardId == value,
                                );
                                if (linked.isNotEmpty &&
                                    _supplierName.text.trim().isEmpty) {
                                  _supplierName.text =
                                      linked.first.supplierName;
                                }
                              },
                      ),
                    ),
                    _field(_remarks, 'Remarks', width: 420),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVendor() async {
    try {
      final snapshot = await _vendorsRef.orderBy('nameLower').get();

      if (!mounted) return;

      final vendors =
          snapshot.docs
              .where((doc) {
                final data = doc.data();
                return data['isDeleted'] != true && data['isActive'] != false;
              })
              .map((doc) {
                final data = doc.data();
                return _SelectedVendor(
                  id: doc.id,
                  name: (data['name'] ?? '').toString().trim(),
                );
              })
              .where((vendor) => vendor.name.isNotEmpty)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      if (vendors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active vendors found. Add a vendor first.'),
          ),
        );
        return;
      }

      final selectedVendor = await showDialog<_SelectedVendor>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Select Supplier'),
            content: SizedBox(
              width: 520,
              height: 420,
              child: ListView.separated(
                itemCount: vendors.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(vendor.name),
                    selected: vendor.id == _selectedVendorId,
                    onTap: () => Navigator.pop(dialogContext, vendor),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (!mounted || selectedVendor == null) return;

      setState(() {
        _selectedVendorId = selectedVendor.id;
        _supplierName.text = selectedVendor.name;
      });

      _formKey.currentState?.validate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load vendors: $e')));
    }
  }

  Widget _vendorPickerField() {
    return SizedBox(
      width: 240,
      child: TextFormField(
        controller: _supplierName,
        readOnly: true,
        onTap: _saving ? null : _pickVendor,
        decoration: const InputDecoration(
          labelText: 'Supplier Name *',
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        validator: (value) =>
            (value ?? '').trim().isEmpty ? 'Supplier Name is required' : null,
      ),
    );
  }

  Widget _dateField() {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Bill Date'),
          child: Text(_formatDate(_billDate)),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    double width = 240,
    bool required = false,
    bool number = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) =>
                  (value ?? '').trim().isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  String _formatDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class _SelectedVendor {
  final String id;
  final String name;

  const _SelectedVendor({required this.id, required this.name});
}
