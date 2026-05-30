import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/engineering/bom/models/engineering_bom_model.dart';

class EngineeringBomAuditHelper {
  const EngineeringBomAuditHelper._();

  static Map<String, dynamic> entry({
    required String action,
    required String changedBy,
    required String changedByName,
    required List<String> changes,
  }) {
    return {
      'action': action,
      'changedAt': Timestamp.now(),
      'changedBy': changedBy,
      'changedByName': changedByName,
      'changes': changes,
    };
  }

  static Map<String, dynamic> field({
    required String fieldChanged,
    required Object? oldValue,
    required Object? newValue,
    required String changedBy,
  }) {
    return {
      'fieldChanged': fieldChanged,
      'oldValue': oldValue?.toString() ?? '',
      'newValue': newValue?.toString() ?? '',
      'changedBy': changedBy,
      'changedOn': Timestamp.now(),
    };
  }

  static List<Map<String, dynamic>> fieldEntries(
    Map<String, dynamic> before,
    EngineeringBomModel after,
    String changedBy,
  ) {
    final entries = <Map<String, dynamic>>[];
    void compare(String fieldName, Object? oldValue, Object? newValue) {
      if ((oldValue ?? '').toString() == (newValue ?? '').toString()) return;
      entries.add(
        field(
          fieldChanged: fieldName,
          oldValue: oldValue,
          newValue: newValue,
          changedBy: changedBy,
        ),
      );
    }

    compare('status', before['status'], after.status);
    compare('revision', before['revision'], after.revision);
    compare('revisionReason', before['revisionReason'], after.revisionReason);
    compare(
      'projectQuantity',
      before['projectQuantity'],
      after.projectQuantity,
    );
    compare(
      'structureLineCount',
      (before['lines'] as List?)?.length ?? 0,
      after.lines.length,
    );
    compare(
      'fastenerLineCount',
      (before['fastenerLines'] as List?)?.length ?? 0,
      after.fastenerLines.length,
    );
    compare(
      'totalCalculatedWeight',
      before['totalCalculatedWeight'],
      after.totalCalculatedWeight,
    );
    return entries;
  }

  static List<String> summary(
    Map<String, dynamic> before,
    EngineeringBomModel after,
  ) {
    final changes = <String>[];
    void compare(String label, Object? oldValue, Object? newValue) {
      if ((oldValue ?? '').toString() != (newValue ?? '').toString()) {
        changes.add('$label: ${oldValue ?? ''} -> ${newValue ?? ''}');
      }
    }

    compare('Status', before['status'], after.status);
    compare('Revision', before['revision'], after.revision);
    compare(
      'Project quantity',
      before['projectQuantity'],
      after.projectQuantity,
    );
    compare(
      'Structure line count',
      (before['lines'] as List?)?.length ?? 0,
      after.lines.length,
    );
    compare(
      'Fastener line count',
      (before['fastenerLines'] as List?)?.length ?? 0,
      after.fastenerLines.length,
    );
    compare(
      'Total weight',
      before['totalCalculatedWeight'],
      after.totalCalculatedWeight,
    );
    return changes.isEmpty
        ? ['No field-level summary change detected']
        : changes;
  }
}
