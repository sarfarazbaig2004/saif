part of 'customer_po_model.dart';

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDate(dynamic value) {
  if (value is DateTime) return value;
  return null;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  return {};
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is List) return value.whereType<Map<String, dynamic>>().toList();
  return [];
}
