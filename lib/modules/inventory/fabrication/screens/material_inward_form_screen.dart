import 'package:flutter/material.dart';

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

  String get _tenantId {
    final contextTenantId = context.tenant.selectedTenantId.trim();
    return contextTenantId.isNotEmpty
        ? contextTenantId
        : widget.tenantId.trim();
  }

  FabricationInventoryRepository get _repository =>
      FabricationInventoryRepository(tenantId: _tenantId);

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
                        _field(_supplierName, 'Supplier Name', required: true),
                        _field(_challanNo, 'Challan / GRN No', required: true),
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

  Widget _materialPicker(List<RawMaterialModel> materials) {
    return SizedBox(
      width: 420,
      child: DropdownButtonFormField<RawMaterialModel>(
        initialValue: _selectedMaterial,
        decoration: const InputDecoration(labelText: 'Raw Material'),
        items: materials
            .map(
              (material) => DropdownMenuItem(
                value: material,
                child: Text(
                  material.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: _applyMaterial,
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
