import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';

enum AccessSelectionMode {
  single,
  multiple;

  String get storageValue => name;

  static AccessSelectionMode fromStorage(
    dynamic value, {
    AccessSelectionMode fallback = AccessSelectionMode.multiple,
  }) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'single' => AccessSelectionMode.single,
      'multiple' => AccessSelectionMode.multiple,
      _ => fallback,
    };
  }
}

Set<String> readSelectionIds(dynamic value) {
  if (value is! Iterable || value is String) return <String>{};
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet();
}

Set<String> normalizeSelectionIds(
  Iterable<String> ids,
  AccessSelectionMode mode,
) {
  final normalized =
      ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList()
        ..sort();
  if (mode == AccessSelectionMode.single && normalized.length > 1) {
    return <String>{normalized.first};
  }
  return normalized.toSet();
}

Set<String> factoryIdsForVerticals({
  required Iterable<VerticalModel> verticals,
  required Set<String> selectedVerticalIds,
}) {
  return verticals
      .where((vertical) => selectedVerticalIds.contains(vertical.id))
      .expand((vertical) => vertical.factoryIds)
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
}
