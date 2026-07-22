import 'package:QUIK/core/permissions/permission_evaluator.dart';

class VerticalPermissionAssignments {
  static const int schemaVersion = 1;

  const VerticalPermissionAssignments._();

  static Map<String, Set<String>> parse(dynamic raw) {
    if (raw is! Map) return <String, Set<String>>{};
    final result = <String, Set<String>>{};
    for (final entry in raw.entries) {
      final verticalId = entry.key.toString().trim();
      if (verticalId.isEmpty) continue;
      final assignment = entry.value;
      final permissions = assignment is Map
          ? assignment['permissions']
          : assignment;
      result[verticalId] = PermissionEvaluator.parsePermissions(
        permissions,
      ).keys;
    }
    return result;
  }

  static Set<String> unionForVerticals({
    required Map<String, Set<String>> assignments,
    required Iterable<String> selectedVerticalIds,
  }) {
    return PermissionEvaluator.normalizeDependencies({
      for (final verticalId in selectedVerticalIds) ...?assignments[verticalId],
    });
  }

  static Map<String, dynamic> toStorageMap({
    required Map<String, Set<String>> assignments,
    required Iterable<String> selectedVerticalIds,
  }) {
    final result = <String, dynamic>{};
    final verticalIds =
        selectedVerticalIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    for (final verticalId in verticalIds) {
      final selection = PermissionEvaluator.normalizeDependencies(
        assignments[verticalId] ?? const <String>{},
      );
      result[verticalId] = <String, dynamic>{
        'permissions': PermissionEvaluator.toStorageMap(selection),
        'allowedModuleIds': PermissionEvaluator.deriveAllowedModuleIds(
          selection,
        ),
        'permissionSchemaVersion': PermissionEvaluator.schemaVersion,
      };
    }
    return result;
  }
}
