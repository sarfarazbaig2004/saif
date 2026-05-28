import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';
import 'package:QUIK/modules/inventory/material_master/repositories/material_master_repository.dart';
import 'package:QUIK/modules/inventory/material_master/services/weight_formula_service.dart';

class MaterialMasterScreen extends StatefulWidget {
  final String tenantId;

  const MaterialMasterScreen({super.key, required this.tenantId});

  @override
  State<MaterialMasterScreen> createState() => _MaterialMasterScreenState();
}

class _MaterialMasterScreenState extends State<MaterialMasterScreen> {
  MaterialMasterRepository get _repository =>
      MaterialMasterRepository(tenantId: widget.tenantId);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(onAdd: () => _openMaterialDialog()),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<MaterialMasterModel>>(
            stream: _repository.watchMaterials(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final materials = snapshot.data ?? const <MaterialMasterModel>[];
              if (materials.isEmpty) {
                return const Center(child: Text('No materials added yet.'));
              }
              return SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(zSurfaceSoft),
                  columns: const [
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Shape')),
                    DataColumn(label: Text('Grade')),
                    DataColumn(label: Text('Density')),
                    DataColumn(label: Text('Formula')),
                    DataColumn(label: Text('Kg/m')),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('')),
                  ],
                  rows: materials
                      .map((material) {
                        return DataRow(
                          cells: [
                            DataCell(Text(material.materialCode)),
                            DataCell(Text(material.materialName)),
                            DataCell(Text(material.materialType)),
                            DataCell(Text(material.materialShape)),
                            DataCell(Text(material.materialGrade)),
                            DataCell(Text(_num(material.density))),
                            DataCell(Text(material.formulaType)),
                            DataCell(
                              Text(_num(material.standardWeightPerMeter)),
                            ),
                            DataCell(Text(material.unit)),
                            DataCell(
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openMaterialDialog(material),
                              ),
                            ),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openMaterialDialog([MaterialMasterModel? existing]) async {
    final code = TextEditingController(text: existing?.materialCode ?? '');
    final name = TextEditingController(text: existing?.materialName ?? '');
    final shape = TextEditingController(text: existing?.materialShape ?? '');
    final grade = TextEditingController(text: existing?.materialGrade ?? 'MS');
    final density = TextEditingController(
      text: _num(existing?.density ?? MaterialMasterModel.densities['MS']!),
    );
    final standardWeight = TextEditingController(
      text: _num(existing?.standardWeightPerMeter ?? 0),
    );
    final unit = TextEditingController(text: existing?.unit ?? 'KG');
    var type = existing?.materialType ?? 'Plate';
    var formula =
        existing?.formulaType ??
        WeightFormulaService.formulaTypeForMaterial(type);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add Material' : 'Edit Material'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field(code, 'Material Code')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(name, 'Material Name')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration: _dec('Material Type'),
                            items: MaterialMasterModel.materialTypes
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                type = value;
                                formula =
                                    WeightFormulaService.formulaTypeForMaterial(
                                      value,
                                    );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _field(shape, 'Material Shape')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            grade,
                            'Material Grade',
                            onChanged: (value) {
                              final gradeDensity =
                                  WeightFormulaService.densityForGrade(value);
                              density.text = _num(gradeDensity);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _field(density, 'Density')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _field(unit, 'Unit')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(standardWeight, 'Standard Weight/Mtr'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InputDecorator(
                      decoration: _dec('Formula Type'),
                      child: Text(formula),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    final material = MaterialMasterModel(
      id: existing?.id ?? _repository.newMaterialId(),
      materialCode: code.text.trim(),
      materialName: name.text.trim(),
      materialType: type,
      materialShape: shape.text.trim(),
      materialGrade: grade.text.trim(),
      density: double.tryParse(density.text.trim()) ?? 0,
      formulaType: formula,
      standardWeightPerMeter: double.tryParse(standardWeight.text.trim()) ?? 0,
      unit: unit.text.trim().isEmpty ? 'KG' : unit.text.trim(),
    );
    await _repository.saveMaterial(material);
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: _dec(label),
      onChanged: onChanged,
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  String _num(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;

  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: zBlue),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Material Master',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Material'),
          ),
        ],
      ),
    );
  }
}
