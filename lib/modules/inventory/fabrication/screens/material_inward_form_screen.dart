import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_transaction_model.dart';
import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';
import 'package:QUIK/modules/inventory/fabrication/services/material_inward_weight_calculator.dart';

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
    final nos = double.tryParse(_quantityNos.text.trim()) ?? 0;
    final length = double.tryParse(_lengthMm.text.trim()) ?? 0;
    final unitWeight = double.tryParse(_unitWeightKgPerM.text.trim()) ?? 0;
    final kg = calculateMaterialInwardWeightKg(
      unitWeightKgPerMeter: unitWeight,
      lengthMeter: length,
      receivedQuantityNos: nos,
    );
    _quantityKg.text = formatMaterialInwardWeightKg(kg);
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
          quantityKg: calculateMaterialInwardWeightKg(
            unitWeightKgPerMeter:
                double.tryParse(_unitWeightKgPerM.text.trim()) ?? 0,
            lengthMeter: double.tryParse(_lengthMm.text.trim()) ?? 0,
            receivedQuantityNos: double.tryParse(_quantityNos.text.trim()) ?? 0,
          ),
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
                          rejectNegative: true,
                        ),
                        _field(
                          _quantityKg,
                          'Received Qty (kg)',
                          number: true,
                          required: true,
                          readOnly: true,
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
      child: Autocomplete<RawMaterialModel>(
        initialValue: TextEditingValue(
          text: _selectedMaterial?.displayName ?? '',
        ),
        displayStringForOption: (material) => material.displayName,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) return materials;
          return materials.where((material) {
            return material.displayName.toLowerCase().contains(query) ||
                material.materialCode.toLowerCase().contains(query) ||
                material.descriptionThickness.toLowerCase().contains(query) ||
                material.gradeIs.toLowerCase().contains(query);
          });
        },
        onSelected: _applyMaterial,
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Raw Material',
                  suffixIcon: Icon(Icons.search),
                ),
                onFieldSubmitted: (_) => onFieldSubmitted(),
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          final matches = options.toList(growable: false);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 300,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final material = matches[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        material.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: material.gradeIs.isEmpty
                          ? null
                          : Text(
                              material.gradeIs,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => onSelected(material),
                    );
                  },
                ),
              ),
            ),
          );
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
    bool readOnly = false,
    bool rejectNegative = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (required && (value ?? '').trim().isEmpty) {
            return '$label is required';
          }
          if (rejectNegative &&
              (double.tryParse((value ?? '').trim()) ?? 0) < 0) {
            return '$label cannot be negative';
          }
          return null;
        },
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
