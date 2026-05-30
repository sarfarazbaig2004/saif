import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_fastener_line_model.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_models.dart';

List<EngineeringBomLineModel> structureBomModels({
  required List<BomLineDraft> lines,
  required double projectQuantity,
  required List<BomCustomField> customFields,
}) {
  final models = <EngineeringBomLineModel>[];
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].isBlank) {
      models.add(lines[i].toModel(i + 1, projectQuantity, customFields));
    }
  }
  return models;
}

List<BomLineDraft> structureDraftsFromBom(EngineeringBomModel bom) {
  final drafts = bom.lines.map(_structureDraftFromModel).toList();
  return drafts.isEmpty ? [BomLineDraft()] : drafts;
}

List<FastenerBomLineDraft> fastenerDraftsFromBom(EngineeringBomModel bom) {
  final drafts = bom.fastenerLines.map(_fastenerDraftFromModel).toList();
  return drafts.isEmpty ? [FastenerBomLineDraft()] : drafts;
}

BomLineDraft _structureDraftFromModel(EngineeringBomLineModel line) {
  final draft = BomLineDraft(itemDescription: line.itemDescription);
  draft.materialMasterId = line.materialMasterId;
  draft.sectionCode.text = line.section;
  draft.materialCategory.text = line.materialCategory;
  draft.materialName.text = line.materialName;
  draft.qtyPerStructure.text = _number(line.qty);
  draft.lengthMm.text = _number(line.lengthMm);
  draft.widthMm.text = _number(line.widthMm);
  draft.thicknessMm.text = _number(line.thicknessMm);
  draft.odMm.text = _number(line.odMm);
  draft.idMm.text = _number(line.idMm);
  draft.heightMm.text = _number(line.heightMm);
  draft.unitWeightKgPerMeter.text = _number(line.weightPerMeter);
  draft.coatingType.text = line.coatingType.isEmpty
      ? line.material
      : line.coatingType;
  draft.coatingSpec.text = line.coatingSpec;
  draft.yieldStrength.text = line.yieldStrength;
  draft.galvanizingMicron.text = _number(line.galvanizingMicron);
  draft.grade.text = line.grade;
  draft.formulaType.text = line.formulaType;
  draft.remarks.text = line.remarks;
  for (final entry in line.customFieldValues.entries) {
    draft.customController(entry.key).text = entry.value;
  }
  return draft;
}

FastenerBomLineDraft _fastenerDraftFromModel(
  EngineeringFastenerLineModel line,
) {
  return FastenerBomLineDraft(
    location: line.location,
    description: line.description,
    boltDescription: line.boltDescription,
    boltLength: line.boltLength,
    material: line.material,
    qtyPerStructure: line.qtyPerStructure,
  );
}

String _number(double value) {
  if (value == 0) return '';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

List<EngineeringFastenerLineModel> fastenerBomModels({
  required List<FastenerBomLineDraft> lines,
  required double projectQuantity,
}) {
  final models = <EngineeringFastenerLineModel>[];
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].isBlank) {
      models.add(lines[i].toModel(i + 1, projectQuantity));
    }
  }
  return models;
}
