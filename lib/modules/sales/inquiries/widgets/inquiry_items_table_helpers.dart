part of 'inquiry_items_grid.dart';

class _InquiryItemsTableHelpers {
  static String value(dynamic value) => value?.toString().trim() ?? '';

  static String dash(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  static bool boolValue(dynamic value) {
    if (value is bool) return value;
    return value?.toString().trim().toLowerCase() == 'true';
  }

  static String projectName(Map<String, dynamic> item) {
    return dash(
      item['projectName'] ??
          item['project'] ??
          item['siteName'] ??
          item['siteLocation'],
    );
  }

  static String structureType(Map<String, dynamic> item) {
    return dash(
      item['structureType'] ??
          item['productType'] ??
          item['category'] ??
          item['itemType'],
    );
  }

  static String bomStatus(Map<String, dynamic> item) {
    if (!boolValue(item['bomLinked'])) return 'Not Created';
    final status = value(item['bomStatus']);
    return status.isEmpty ? 'Draft' : status;
  }

  static String quotationStatus(Map<String, dynamic> item) {
    final status = value(
      item['quotationStatus'] ??
          item['quoteStatus'] ??
          item['quotationLinked'] ??
          item['quoteLinked'],
    );

    if (status.isEmpty || status == 'false') return 'Pending';
    if (status == 'true') return 'Created';
    return status;
  }

  static String estimatedWeight(Map<String, dynamic> item) {
    final value =
        item['estimatedWeightKg'] ??
        item['totalWeightKg'] ??
        item['bomWeightKg'] ??
        item['weightKg'];

    final number = double.tryParse(value?.toString() ?? '');
    if (number == null || number <= 0) return '-';

    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)} MT';
    }

    return '${number.toStringAsFixed(2)} kg';
  }

  static Color bomStatusColor(String status) {
    final text = status.toLowerCase();
    if (text.contains('approved')) return const Color(0xFF16A34A);
    if (text.contains('not')) return const Color(0xFF64748B);
    return const Color(0xFF2563EB);
  }

  static Color quotationStatusColor(String status) {
    final text = status.toLowerCase();
    if (text.contains('created') || text.contains('converted')) {
      return const Color(0xFF16A34A);
    }
    return const Color(0xFFF97316);
  }
}
