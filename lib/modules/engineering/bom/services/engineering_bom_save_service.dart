import 'package:firebase_auth/firebase_auth.dart';

import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_fastener_line_model.dart';
import 'package:QUIK/modules/engineering/bom/repositories/engineering_bom_repository.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_draft_mapper.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_models.dart';

Future<EngineeringBomSaveResult> saveEngineeringBom({
  required EngineeringBomRepository repository,
  required String bomId,
  required String bomNo,
  required String inquiryId,
  required String inquiryItemId,
  required String customer,
  required String project,
  required String revision,
  required String status,
  required String revisionReason,
  required double projectQuantity,
  required List<String> visibleColumns,
  required List<BomCustomField> customFields,
  required List<EngineeringBomLineModel> lines,
  required List<EngineeringFastenerLineModel> fastenerLines,
  required double totalCalculatedWeight,
}) {
  final user = FirebaseAuth.instance.currentUser;
  return repository.saveBom(
    EngineeringBomModel(
      id: bomId,
      bomNo: bomNo,
      inquiryId: inquiryId,
      inquiryItemId: inquiryItemId,
      customer: customer,
      project: project,
      revision: revision.trim().isEmpty ? 'A' : revision.trim(),
      status: status,
      revisionReason: revisionReason,
      projectQuantity: projectQuantity,
      visibleColumns: visibleColumns,
      customFields: customFields,
      lines: lines,
      fastenerLines: fastenerLines,
      totalCalculatedWeight: totalCalculatedWeight,
    ),
    changedBy: user?.uid ?? '',
    changedByName: (user?.displayName ?? user?.email ?? '').trim(),
  );
}

Future<EngineeringBomSaveResult> saveEngineeringBomDraft({
  required EngineeringBomRepository repository,
  required String bomId,
  required String bomNo,
  required String inquiryId,
  required String inquiryItemId,
  required String customer,
  required String project,
  required String revision,
  required String status,
  required String revisionReason,
  required double projectQuantity,
  required List<String> visibleColumns,
  required List<BomCustomField> customFields,
  required List<BomLineDraft> structureLines,
  required List<FastenerBomLineDraft> fastenerDrafts,
  required double totalCalculatedWeight,
}) {
  final lines = structureBomModels(
    lines: structureLines,
    projectQuantity: projectQuantity,
    customFields: customFields,
  );
  if (lines.isEmpty) {
    throw StateError('Add at least one BOM line before saving.');
  }
  return saveEngineeringBom(
    repository: repository,
    bomId: bomId,
    bomNo: bomNo,
    inquiryId: inquiryId,
    inquiryItemId: inquiryItemId,
    customer: customer,
    project: project,
    revision: revision,
    status: status,
    revisionReason: revisionReason,
    projectQuantity: projectQuantity,
    visibleColumns: visibleColumns,
    customFields: customFields,
    lines: lines,
    fastenerLines: fastenerBomModels(
      lines: fastenerDrafts,
      projectQuantity: projectQuantity,
    ),
    totalCalculatedWeight: totalCalculatedWeight,
  );
}
