import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/inventory/item_master/screens_add_item_master.dart';

class EngineeringBomMaterialRefreshResult {
  final int refreshed;
  final int missing;

  const EngineeringBomMaterialRefreshResult({
    required this.refreshed,
    required this.missing,
  });
}

Future<EngineeringBomMaterialRefreshResult> refreshEngineeringBomMaterials({
  required MaterialMasterRepository repository,
  required List<BomLineDraft> lines,
}) async {
  var refreshed = 0;
  var missing = 0;
  for (final line in lines) {
    final code = line.sectionCode.text.trim();
    if (code.isEmpty) continue;
    final material = await repository.findByMaterialCode(code);
    if (material == null) {
      missing++;
      continue;
    }
    line.applyMaterial(material);
    refreshed++;
  }
  return EngineeringBomMaterialRefreshResult(
    refreshed: refreshed,
    missing: missing,
  );
}
