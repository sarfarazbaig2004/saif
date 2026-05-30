import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
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
