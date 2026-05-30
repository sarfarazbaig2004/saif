import 'dart:convert';

import 'package:file_picker/file_picker.dart';
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
        _Header(
          onAdd: () => _openMaterialDialog(),
          onImport: _importCsv,
          onTemplate: _showTemplate,
          onSeed: _loadStandardEngineeringLibrary,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<MaterialMasterModel>>(
            stream: _repository.watchMaterials(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                  'MATERIAL_MASTER_LIST_ERROR tenantId=${widget.tenantId} '
                  'path=${_repository.collectionPath} error=${snapshot.error}',
                );
                return Center(
                  child: Text('Failed to load materials: ${snapshot.error}'),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final materials = snapshot.data ?? const <MaterialMasterModel>[];
              debugPrint(
                'MATERIAL_MASTER_LIST tenantId=${widget.tenantId} '
                'path=${_repository.collectionPath} count=${materials.length}',
              );
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
                    DataColumn(label: Text('Coating')),
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
                            DataCell(Text(material.coating)),
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
    final yieldStrength = TextEditingController(
      text: existing?.yieldStrength ?? '',
    );
    final coating = TextEditingController(
      text: existing?.coatingType.trim().isNotEmpty == true
          ? existing!.coatingType
          : existing?.coating ?? '',
    );
    final coatingSpec = TextEditingController(
      text: existing?.coatingSpec ?? '',
    );
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
                        Expanded(
                          child: _field(yieldStrength, 'Yield Strength'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _field(coating, 'Coating Type')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(coatingSpec, 'Coating Spec'),
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
      yieldStrength: yieldStrength.text.trim(),
      coating: coating.text.trim(),
      coatingType: coating.text.trim(),
      coatingSpec: coatingSpec.text.trim(),
      density: double.tryParse(density.text.trim()) ?? 0,
      formulaType: formula,
      weightFormula: formula,
      standardWeightPerMeter: double.tryParse(standardWeight.text.trim()) ?? 0,
      unit: unit.text.trim().isEmpty ? 'KG' : unit.text.trim(),
    );
    await _repository.saveMaterial(material);
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    final rows = _parseMaterialCsv(const Utf8Decoder().convert(bytes));
    var count = 0;
    for (final row in rows) {
      final code = (row['materialCode'] ?? '').trim();
      if (code.isEmpty) continue;
      await _repository.saveMaterial(_materialFromRow(row));
      count++;
    }
    _snack('Imported $count material records.');
  }

  Future<void> _loadStandardEngineeringLibrary() async {
    final created = <String>[];
    final existingByCode = <String, MaterialMasterModel>{};
    debugPrint(
      'MATERIAL_MASTER_STANDARD_LIBRARY_START tenantId=${widget.tenantId} '
      'path=${_repository.collectionPath}',
    );
    for (final row in _seedRows) {
      final code = (row['materialCode'] ?? '').trim();
      final existing = await _repository.findByMaterialCode(code);
      if (existing != null) existingByCode[code] = existing;
    }
    if (existingByCode.isNotEmpty) {
      final update = await _confirmLibraryUpdate(existingByCode.keys.toList());
      if (update != true) {
        _snack('Standard engineering material library load cancelled.');
        return;
      }
    }
    for (final row in _seedRows) {
      final code = (row['materialCode'] ?? '').trim();
      final existing = existingByCode[code];
      final material = _materialFromRow(row, existingId: existing?.id);
      await _repository.saveMaterial(material);
      created.add(material.materialCode);
    }
    debugPrint(
      'MATERIAL_MASTER_STANDARD_LIBRARY_DONE tenantId=${widget.tenantId} '
      'path=${_repository.collectionPath} documents=${created.join('|')}',
    );
    _snack('Standard engineering material library loaded.');
  }

  Future<bool?> _confirmLibraryUpdate(List<String> codes) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Existing Materials?'),
        content: Text(
          'Standard library materials already exist and will be updated: '
          '${codes.take(8).join(', ')}${codes.length > 8 ? '...' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  MaterialMasterModel _materialFromRow(
    Map<String, String> row, {
    String? existingId,
  }) {
    final category = (row['category'] ?? row['materialType'] ?? 'Plate').trim();
    final grade = (row['grade'] ?? row['materialGrade'] ?? 'MS').trim();
    final formula =
        (row['weightFormula'] ?? row['formulaType'] ?? '').trim().isEmpty
        ? WeightFormulaService.formulaTypeForMaterial(category)
        : (row['weightFormula'] ?? row['formulaType'] ?? '').trim();
    final coatingType = (row['coatingType'] ?? row['coating'] ?? '').trim();
    final yieldStrength = (row['yieldStrength'] ?? '').trim().isEmpty
        ? (grade == 'MS' ? 'YS350' : grade)
        : row['yieldStrength']!.trim();
    final coatingSpec = (row['coatingSpec'] ?? '').trim().isEmpty
        ? (coatingType.toUpperCase() == 'HDG' ? '80' : '')
        : row['coatingSpec']!.trim();
    final id = existingId?.trim().isNotEmpty == true
        ? existingId!.trim()
        : row['id']?.trim().isNotEmpty == true
        ? row['id']!.trim()
        : (row['materialCode'] ?? _repository.newMaterialId()).trim();
    return MaterialMasterModel(
      id: id,
      materialCode: (row['materialCode'] ?? '').trim(),
      materialName: (row['materialName'] ?? '').trim(),
      materialType: category,
      materialShape: (row['shape'] ?? row['materialShape'] ?? category).trim(),
      materialGrade: grade,
      yieldStrength: yieldStrength,
      coating: coatingType,
      coatingType: coatingType,
      coatingSpec: coatingSpec,
      density: MaterialMasterModel.densities[grade] ?? 7850,
      formulaType: formula,
      weightFormula: formula,
      standardWeightPerMeter:
          double.tryParse(row['standardWeightPerMeter'] ?? '') ?? 0,
      unit: (row['unit'] ?? 'KG').trim(),
      isActive: (row['isActive'] ?? 'true').trim().toLowerCase() != 'false',
    );
  }

  Future<void> _showTemplate() {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Material Master CSV Template'),
        content: SelectableText(_templateCsv),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
  final VoidCallback onImport;
  final VoidCallback onTemplate;
  final VoidCallback onSeed;

  const _Header({
    required this.onAdd,
    required this.onImport,
    required this.onTemplate,
    required this.onSeed,
  });

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
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import CSV'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onTemplate,
            icon: const Icon(Icons.description_outlined),
            label: const Text('Template'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onSeed,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Load Standard Engineering Library'),
          ),
        ],
      ),
    );
  }
}

const _templateCsv =
    'materialCode,materialName,category,materialShape,standardWeightPerMeter,grade,coating,isActive,yieldStrength,coatingType,coatingSpec,weightFormula\n'
    '100CS50X15X2,C Section 100CS50X15X2,C Section,C Section,3.54,YS350,HDG,true,YS350,HDG,80,Kg Per Meter\n'
    '60CS40X15X1.6,C Section 60CS40X15X1.6,C Section,C Section,1.72,YS550,Galvalume,true,YS550,Galvalume,AZ150,Kg Per Meter\n'
    '80CS40X15X2,C Section 80CS40X15X2,C Section,C Section,2.85,MS,HDG,true\n'
    '120CS50X15X2,C Section 120CS50X15X2,C Section,C Section,4.15,MS,HDG,true\n'
    'ISA40X40X4,Angle ISA40X40X4,Angle,Equal Angle,2.42,MS,HDG,true\n'
    'ISA50X50X5,Angle ISA50X50X5,Angle,Equal Angle,3.78,MS,HDG,true\n'
    'ISA65X65X6,Angle ISA65X65X6,Angle,Equal Angle,5.80,MS,HDG,true\n'
    'ISA75X75X6,Angle ISA75X75X6,Angle,Equal Angle,6.80,MS,HDG,true\n'
    'ISA90X90X8,Angle ISA90X90X8,Angle,Equal Angle,10.90,MS,HDG,true\n'
    'ISMC75,Channel ISMC75,Channel,ISMC,7.14,MS,HDG,true\n'
    'ISMC100,Channel ISMC100,Channel,ISMC,9.56,MS,HDG,true\n'
    'ISMC125,Channel ISMC125,Channel,ISMC,13.10,MS,HDG,true\n'
    'ISMC150,Channel ISMC150,Channel,ISMC,16.80,MS,HDG,true\n'
    'ISMC200,Channel ISMC200,Channel,ISMC,22.30,MS,HDG,true\n'
    'FLAT25X3,Flat 25X3,Flat,Flat,0.59,MS,HDG,true\n'
    'FLAT40X5,Flat 40X5,Flat,Flat,1.57,MS,HDG,true\n'
    'FLAT50X6,Flat 50X6,Flat,Flat,2.36,MS,HDG,true\n'
    'FLAT75X8,Flat 75X8,Flat,Flat,4.71,MS,HDG,true\n'
    'PLATE50X5,Plate 50X5,Plate,Plate,0,YS550,HDG,true,YS550,HDG,80,Plate Volume\n'
    'PLATE75X6,Plate 75X6,Plate,Plate,0,MS,,true\n'
    'PLATE100X8,Plate 100X8,Plate,Plate,0,MS,,true\n'
    'PLATE150X10,Plate 150X10,Plate,Plate,0,MS,,true\n'
    'PIPE25NB,Pipe 25NB,Pipe,NB Pipe,2.44,MS,HDG,true\n'
    'PIPE32NB,Pipe 32NB,Pipe,NB Pipe,3.14,MS,HDG,true\n'
    'PIPE40NB,Pipe 40NB,Pipe,NB Pipe,3.61,MS,HDG,true\n'
    'PIPE50NB,Pipe 50NB,Pipe,NB Pipe,5.10,MS,HDG,true\n'
    'PIPE80NB,Pipe 80NB,Pipe,NB Pipe,8.47,MS,HDG,true\n'
    'SHS50X50X3,Hollow Section SHS50X50X3,Hollow Section,SHS,4.31,MS,HDG,true\n'
    'SHS75X75X4,Hollow Section SHS75X75X4,Hollow Section,SHS,8.86,MS,HDG,true\n'
    'RHS100X50X3,Hollow Section RHS100X50X3,Hollow Section,RHS,6.67,MS,HDG,true\n'
    '1280X1063X0.5,Roofing Sheet 1280X1063X0.5,Roofing Sheet,Roofing Sheet,0,YS550,Galvalume,true,YS550,Galvalume,AZ150,Sheet Area';

final _seedRows = _parseMaterialCsv(_templateCsv);

List<Map<String, String>> _parseMaterialCsv(String csv) {
  final lines = const LineSplitter()
      .convert(csv)
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.length < 2) return const [];
  final headers = _splitCsvLine(lines.first);
  return lines.skip(1).map((line) {
    final values = _splitCsvLine(line);
    return {
      for (var i = 0; i < headers.length; i++)
        headers[i]: i < values.length ? values[i] : '',
    };
  }).toList();
}

List<String> _splitCsvLine(String line) {
  return line.split(',').map((value) => value.trim()).toList();
}
