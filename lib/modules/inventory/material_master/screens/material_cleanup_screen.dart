import 'package:flutter/material.dart';
import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';
import 'package:QUIK/modules/inventory/material_master/repositories/material_master_repository.dart';

/// Screen to find and clean up duplicate materials by normalized code.
class MaterialCleanupScreen extends StatefulWidget {
  final String tenantId;
  const MaterialCleanupScreen({super.key, required this.tenantId});

  @override
  State<MaterialCleanupScreen> createState() => _MaterialCleanupScreenState();
}

class _MaterialCleanupScreenState extends State<MaterialCleanupScreen> {
  late final MaterialMasterRepository _repository = MaterialMasterRepository(
    tenantId: widget.tenantId,
  );
  Map<String, List<MaterialMasterModel>> _duplicates = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  Future<void> _findDuplicates() async {
    setState(() => _loading = true);
    final all = await _repository.fetchAllMaterials(limit: 500);
    final Map<String, List<MaterialMasterModel>> dups = {};
    for (final mat in all) {
      final norm = mat.normalizedMaterialCode;
      dups.putIfAbsent(norm, () => []).add(mat);
    }
    dups.removeWhere((_, list) => list.length < 2);
    setState(() {
      _duplicates = dups;
      _loading = false;
    });
  }

  Future<void> _deactivateExceptLatest(String normCode) async {
    final list = _duplicates[normCode]!;
    // Keep the latest (by updatedAt if available, else by id)
    list.sort((a, b) => b.id.compareTo(a.id));
    final keep = list.first;
    for (final mat in list.skip(1)) {
      await _repository.saveMaterial(
        MaterialMasterModel(
          id: mat.id,
          materialCode: mat.materialCode,
          materialName: mat.materialName,
          materialType: mat.materialType,
          materialShape: mat.materialShape,
          materialGrade: mat.materialGrade,
          yieldStrength: mat.yieldStrength,
          coating: mat.coating,
          coatingType: mat.coatingType,
          coatingSpec: mat.coatingSpec,
          density: mat.density,
          formulaType: mat.formulaType,
          weightFormula: mat.weightFormula,
          standardWeightPerMeter: mat.standardWeightPerMeter,
          unit: mat.unit,
          isActive: false,
        ),
      );
    }
    await _findDuplicates();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deactivated duplicates for $normCode, kept ${keep.materialCode}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Duplicate Materials')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _duplicates.isEmpty
          ? const Center(child: Text('No duplicate materials found.'))
          : ListView(
              children: _duplicates.entries.map((entry) {
                final norm = entry.key;
                final list = entry.value;
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Normalized Code: $norm'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: list
                          .map(
                            (mat) => Text(
                              '${mat.materialCode} | ${mat.materialName} | ${mat.materialType} | Active: ${mat.isActive}',
                            ),
                          )
                          .toList(),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _deactivateExceptLatest(norm),
                      child: const Text('Keep Latest, Deactivate Old'),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
