import 'package:flutter/material.dart';

import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';
import 'package:QUIK/modules/inventory/material_master/repositories/material_master_repository.dart';

class MaterialPickerDialog extends StatefulWidget {
  final String tenantId;

  const MaterialPickerDialog({super.key, required this.tenantId});

  @override
  State<MaterialPickerDialog> createState() => _MaterialPickerDialogState();
}

class _MaterialPickerDialogState extends State<MaterialPickerDialog> {
  final _search = TextEditingController();
  List<MaterialMasterModel> _materials = const [];
  bool _loading = true;

  MaterialMasterRepository get _repository =>
      MaterialMasterRepository(tenantId: widget.tenantId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String query = '']) async {
    setState(() => _loading = true);
    try {
      final materials = await _repository.searchMaterials(query);
      // Deduplicate by normalized code, prefer active/latest
      final Map<String, MaterialMasterModel> deduped = {};
      final Map<String, List<MaterialMasterModel>> duplicates = {};
      for (final mat in materials) {
        final norm = mat.normalizedMaterialCode;
        if (!deduped.containsKey(norm)) {
          deduped[norm] = mat;
          duplicates[norm] = [mat];
        } else {
          // Prefer active, latest (by updatedAt if available)
          final existing = deduped[norm]!;
          // If mat is more recently updated or more complete, prefer it
          // (Assume order from Firestore is not guaranteed, so just keep first active)
          if (!existing.isActive && mat.isActive) {
            deduped[norm] = mat;
          }
          duplicates[norm]!.add(mat);
        }
      }
      final dedupedList = deduped.values.toList();
      final hasDuplicates = duplicates.values.any((list) => list.length > 1);
      debugPrint(
        'MATERIAL_PICKER_SOURCE tenantId=${widget.tenantId} '
        'path=${_repository.collectionPath} count=${materials.length} deduped=${dedupedList.length}',
      );
      if (!mounted) return;
      setState(() {
        _materials = dedupedList;
        _loading = false;
      });
      if (hasDuplicates) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Warning: Duplicate materials with same code exist!',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint(
        'MATERIAL_PICKER_SOURCE_ERROR tenantId=${widget.tenantId} '
        'path=${_repository.collectionPath} error=$e',
      );
      if (!mounted) return;
      setState(() {
        _materials = const [];
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Material'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search material',
              ),
              onChanged: _load,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _materials.isEmpty
                  ? const Center(child: Text('No materials found.'))
                  : ListView.separated(
                      itemCount: _materials.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final material = _materials[index];
                        return ListTile(
                          title: Text(material.displayName),
                          subtitle: Text(
                            '${material.materialType} • ${material.materialGrade} • ${material.formulaType}',
                          ),
                          trailing: material.standardWeightPerMeter > 0
                              ? Text('${material.standardWeightPerMeter} kg/m')
                              : null,
                          onTap: () => Navigator.pop(context, material),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
