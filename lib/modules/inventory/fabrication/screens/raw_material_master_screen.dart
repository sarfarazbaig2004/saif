import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';

class RawMaterialMasterScreen extends StatefulWidget {
  final String tenantId;

  const RawMaterialMasterScreen({super.key, required this.tenantId});

  @override
  State<RawMaterialMasterScreen> createState() =>
      _RawMaterialMasterScreenState();
}

class _RawMaterialMasterScreenState extends State<RawMaterialMasterScreen> {
  final _search = TextEditingController();
  String _query = '';

  String get _tenantId {
    final selectedTenantId = context.tenant.selectedTenantId.trim();
    return selectedTenantId.isNotEmpty ? selectedTenantId : widget.tenantId;
  }

  FabricationInventoryRepository get _repository =>
      FabricationInventoryRepository(tenantId: _tenantId);

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tenantId.trim().isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    return StreamBuilder<List<RawMaterialModel>>(
      stream: _repository.watchRawMaterials(),
      builder: (context, snapshot) {
        final materials = (snapshot.data ?? const <RawMaterialModel>[])
            .where(_matches)
            .toList(growable: false);

        return Column(
          children: [
            _Header(
              search: _search,
              count: materials.length,
              onAdd: () => _openForm(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData
                  ? const Center(child: CircularProgressIndicator(color: zBlue))
                  : materials.isEmpty
                  ? _EmptyState(onAdd: () => _openForm())
                  : _RawMaterialTable(
                      materials: materials,
                      onEdit: (material) => _openForm(material: material),
                    ),
            ),
          ],
        );
      },
    );
  }

  bool _matches(RawMaterialModel material) {
    if (_query.isEmpty) return true;
    final fields = [
      material.materialCode,
      material.descriptionThickness,
      material.gradeIs,
      material.length.toString(),
      material.category,
      material.productFamily,
    ];
    return fields.any((field) => field.toLowerCase().contains(_query));
  }

  Future<void> _openForm({RawMaterialModel? material}) async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          _RawMaterialFormDialog(repository: _repository, material: material),
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController search;
  final int count;
  final VoidCallback onAdd;

  const _Header({
    required this.search,
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, color: zBlue),
          const SizedBox(
            width: 260,
            child: Text(
              'Raw Materials',
              style: TextStyle(
                color: zText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 360,
            child: TextField(
              controller: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search material, grade, length, category',
              ),
            ),
          ),
          Chip(label: Text('$count materials')),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('New Raw Material'),
          ),
        ],
      ),
    );
  }
}

class _RawMaterialTable extends StatelessWidget {
  final List<RawMaterialModel> materials;
  final ValueChanged<RawMaterialModel> onEdit;

  const _RawMaterialTable({required this.materials, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Material Code')),
              DataColumn(label: Text('Description / Thickness')),
              DataColumn(label: Text('Grade / IS')),
              DataColumn(label: Text('Length')),
              DataColumn(label: Text('Unit Weight')),
              DataColumn(label: Text('UOM')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Product Family')),
              DataColumn(label: Text('Reorder Level')),
              DataColumn(label: Text('Remarks')),
              DataColumn(label: Text('')),
            ],
            rows: materials
                .map(
                  (material) => DataRow(
                    cells: [
                      DataCell(Text(material.materialCode)),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Text(
                            material.descriptionThickness,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(material.gradeIs)),
                      DataCell(Text(_number(material.length))),
                      DataCell(Text(_number(material.unitWeight))),
                      DataCell(Text(material.uom)),
                      DataCell(Text(material.category)),
                      DataCell(Text(material.productFamily)),
                      DataCell(Text(_number(material.reorderLevel))),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            material.remarks,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => onEdit(material),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  String _number(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _RawMaterialFormDialog extends StatefulWidget {
  final FabricationInventoryRepository repository;
  final RawMaterialModel? material;

  const _RawMaterialFormDialog({required this.repository, this.material});

  @override
  State<_RawMaterialFormDialog> createState() => _RawMaterialFormDialogState();
}

class _RawMaterialFormDialogState extends State<_RawMaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _grade;
  late final TextEditingController _length;
  late final TextEditingController _unitWeight;
  late final TextEditingController _uom;
  late final TextEditingController _category;
  late final TextEditingController _productFamily;
  late final TextEditingController _reorderLevel;
  late final TextEditingController _remarks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final material = widget.material;
    _code = TextEditingController(text: material?.materialCode ?? '');
    _description = TextEditingController(
      text: material?.descriptionThickness ?? '',
    );
    _grade = TextEditingController(text: material?.gradeIs ?? '');
    _length = TextEditingController(
      text: material == null ? '' : _number(material.length),
    );
    _unitWeight = TextEditingController(
      text: material == null ? '' : _number(material.unitWeight),
    );
    _uom = TextEditingController(text: material?.uom ?? 'Nos');
    _category = TextEditingController(text: material?.category ?? '');
    _productFamily = TextEditingController(text: material?.productFamily ?? '');
    _reorderLevel = TextEditingController(
      text: material == null ? '0' : _number(material.reorderLevel),
    );
    _remarks = TextEditingController(text: material?.remarks ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    _grade.dispose();
    _length.dispose();
    _unitWeight.dispose();
    _uom.dispose();
    _category.dispose();
    _productFamily.dispose();
    _reorderLevel.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.material == null ? 'New Raw Material' : 'Edit Raw Material',
      ),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field(_code, 'Material Code', required: true),
                _field(
                  _description,
                  'Description / Thickness',
                  width: 488,
                  required: true,
                ),
                _field(_grade, 'Grade / IS'),
                _field(_length, 'Length', number: true),
                _field(_unitWeight, 'Unit Weight', number: true),
                _field(_uom, 'UOM', required: true),
                _field(_category, 'Category'),
                _field(_productFamily, 'Product Family'),
                _field(_reorderLevel, 'Reorder Level', number: true),
                _field(_remarks, 'Remarks', width: 488),
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
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving' : 'Save'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    double width = 238,
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
        validator: (value) {
          final text = (value ?? '').trim();
          if (required && text.isEmpty) return 'Required';
          if (number && text.isNotEmpty && double.tryParse(text) == null) {
            return 'Enter valid number';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await widget.repository.saveRawMaterial(
        RawMaterialModel(
          materialId:
              widget.material?.materialId ?? widget.repository.newMaterialId(),
          materialCode: _code.text.trim(),
          descriptionThickness: _description.text.trim(),
          gradeIs: _grade.text.trim(),
          length: double.tryParse(_length.text.trim()) ?? 0,
          unitWeight: double.tryParse(_unitWeight.text.trim()) ?? 0,
          uom: _uom.text.trim().isEmpty ? 'Nos' : _uom.text.trim(),
          category: _category.text.trim(),
          productFamily: _productFamily.text.trim(),
          reorderLevel: double.tryParse(_reorderLevel.text.trim()) ?? 0,
          remarks: _remarks.text.trim(),
          isActive: true,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Raw material saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save raw material: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _number(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 42, color: zMuted),
          const SizedBox(height: 10),
          const Text(
            'No raw materials yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('New Raw Material'),
          ),
        ],
      ),
    );
  }
}
