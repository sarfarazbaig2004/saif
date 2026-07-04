import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_transaction_model.dart';
import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';

class MaterialInwardFormScreen extends StatefulWidget {
  final String tenantId;
  final bool purchaseView;

  const MaterialInwardFormScreen({
    super.key,
    required this.tenantId,
    this.purchaseView = false,
  });

  @override
  State<MaterialInwardFormScreen> createState() =>
      _MaterialInwardFormScreenState();
}

class _MaterialInwardFormScreenState extends State<MaterialInwardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _supplierName = TextEditingController();
  final _challanNo = TextEditingController();
  final _plantName = TextEditingController(text: 'Plant 1');
  final _warehouseName = TextEditingController(text: 'Main Store');
  final _materialDescription = TextEditingController();
  final _grade = TextEditingController();
  final _lengthMm = TextEditingController();
  final _unitWeightKgPerM = TextEditingController();
  final _quantityKg = TextEditingController();
  final _quantityNos = TextEditingController();
  final _remarks = TextEditingController();

  DateTime _inwardDate = DateTime.now();
  bool _saving = false;
  RawMaterialModel? _selectedMaterial;
  String? _selectedVendorId;

  String get _tenantId {
    final contextTenantId = context.tenant.selectedTenantId.trim();
    return contextTenantId.isNotEmpty
        ? contextTenantId
        : widget.tenantId.trim();
  }

  FabricationInventoryRepository get _repository =>
      FabricationInventoryRepository(tenantId: _tenantId);

  CollectionReference<Map<String, dynamic>> get _vendorsRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(_tenantId)
          .collection('vendors');

  @override
  void initState() {
    super.initState();
    _quantityNos.addListener(_autoCalculateKg);
    _lengthMm.addListener(_autoCalculateKg);
    _unitWeightKgPerM.addListener(_autoCalculateKg);
  }

  @override
  void dispose() {
    _supplierName.dispose();
    _challanNo.dispose();
    _plantName.dispose();
    _warehouseName.dispose();
    _materialDescription.dispose();
    _grade.dispose();
    _lengthMm.dispose();
    _unitWeightKgPerM.dispose();
    _quantityKg.dispose();
    _quantityNos.dispose();
    _remarks.dispose();
    super.dispose();
  }

  void _autoCalculateKg() {
    final qtyKg = double.tryParse(_quantityKg.text.trim()) ?? 0;
    if (qtyKg > 0) return;
    final nos = double.tryParse(_quantityNos.text.trim()) ?? 0;
    final length = double.tryParse(_lengthMm.text.trim()) ?? 0;
    final unitWeight = double.tryParse(_unitWeightKgPerM.text.trim()) ?? 0;
    if (nos <= 0 || length <= 0 || unitWeight <= 0) return;
    final kg = nos * (length / 1000) * unitWeight;
    _quantityKg.text = kg.toStringAsFixed(3);
  }

  void _applyMaterial(RawMaterialModel? material) {
    if (material == null) return;
    setState(() => _selectedMaterial = material);
    _materialDescription.text = material.descriptionThickness;
    _grade.text = material.gradeIs;
    _lengthMm.text = _formatNumber(material.length);
    _unitWeightKgPerM.text = _formatNumber(material.unitWeight);
    _autoCalculateKg();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing company workspace. Material inward was not saved.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final material = _selectedMaterial;
      await _repository.saveInventoryTransaction(
        RawMaterialTransactionModel(
          transactionId: _repository.newTransactionId(),
          transactionType: RawMaterialTransactionType.inward,
          transactionDate: _inwardDate,
          materialId: material?.materialId ?? '',
          materialCode: material?.materialCode ?? '',
          materialDescription: _materialDescription.text.trim(),
          grade: _grade.text.trim(),
          length: double.tryParse(_lengthMm.text.trim()) ?? 0,
          unitWeight: double.tryParse(_unitWeightKgPerM.text.trim()) ?? 0,
          uom: material?.uom ?? 'Kg',
          category: material?.category ?? '',
          productFamily: material?.productFamily ?? '',
          plantName: _plantName.text.trim(),
          warehouseName: _warehouseName.text.trim(),
          quantityNos: double.tryParse(_quantityNos.text.trim()) ?? 0,
          quantityKg: double.tryParse(_quantityKg.text.trim()) ?? 0,
          referenceNo: _challanNo.text.trim(),
          partyOrProcess: _supplierName.text.trim(),
          workOrderId: '',
          heatNumber: '',
          batchNo: '',
          millCertificateUrl: '',
          qaReferenceId: '',
          remarks: _remarks.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.purchaseView
                ? 'GRN saved and stock updated'
                : 'Material inward saved and stock updated',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save receipt: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inwardDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _inwardDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.purchaseView
        ? 'New GRN / Material Receipt'
        : 'New Raw Material Inward';

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: Text(title),
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
          child: StreamBuilder<List<RawMaterialModel>>(
            stream: _repository.watchRawMaterials(activeOnly: true),
            builder: (context, snapshot) {
              final materials = snapshot.data ?? const <RawMaterialModel>[];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: zBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _dateField(),
                        _vendorDropdown(),
                        _field(_challanNo, 'Challan / GRN No', required: true),
                        _field(_plantName, 'Plant', required: true),
                        _field(_warehouseName, 'Warehouse', required: true),
                        _materialPicker(materials),
                        _field(
                          _materialDescription,
                          'Description / Thickness',
                          width: 420,
                          required: true,
                        ),
                        _field(_grade, 'Grade / IS', required: true),
                        _field(_lengthMm, 'Length', number: true),
                        _field(_unitWeightKgPerM, 'Unit Weight', number: true),
                        _field(
                          _quantityNos,
                          'Received Qty (nos)',
                          number: true,
                        ),
                        _field(
                          _quantityKg,
                          'Received Qty (kg)',
                          number: true,
                          required: true,
                        ),
                        _field(_remarks, 'Remarks', width: 420),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  Future<void> _pickVendor() async {
    if (_tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing company workspace.')),
      );
      return;
    }

    try {
      final snapshot = await _vendorsRef.get();

      if (!mounted) return;

      final vendors = snapshot.docs
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

  Widget _vendorDropdown() {
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


  Widget _materialPicker(List<RawMaterialModel> materials) {
    final materialMap = <String, RawMaterialModel>{};

    for (final material in materials) {
      final materialId = material.materialId.trim();
      if (materialId.isEmpty) continue;
      materialMap.putIfAbsent(materialId, () => material);
    }

    final uniqueMaterials = materialMap.values.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

    final selectedId = _selectedMaterial?.materialId.trim() ?? '';
    final selectedValue =
        uniqueMaterials.any((material) => material.materialId == selectedId)
            ? selectedId
            : null;

    return SizedBox(
      width: 420,
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Raw Material'),
        selectedItemBuilder: (context) => uniqueMaterials
            .map(
              (material) => Text(
                material.displayName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
            .toList(growable: false),
        items: uniqueMaterials
            .map(
              (material) => DropdownMenuItem<String>(
                value: material.materialId,
                child: Text(
                  material.displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: (materialId) {
          final material = materialMap[materialId];
          _applyMaterial(material);
        },
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
          decoration: const InputDecoration(labelText: 'Receipt Date'),
          child: Text(_formatDate(_inwardDate)),
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

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(3);
  }
}

class _SelectedVendor {
  final String id;
  final String name;

  const _SelectedVendor({
    required this.id,
    required this.name,
  });
}

