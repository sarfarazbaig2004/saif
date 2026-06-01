part of 'inquiry_items_grid.dart';

Widget _inquiryDescriptionCell(Map<String, dynamic> item) {
  final description = _InquiryItemsTableHelpers.dash(
    item['name'] ?? item['description'],
  );
  final hsn = _InquiryItemsTableHelpers.value(item['hsn']);

  return SizedBox(
    width: 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (hsn.isNotEmpty)
          Text(
            'HSN: $hsn',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    ),
  );
}

Widget _inquiryShortText(String value, {required double width}) {
  return SizedBox(
    width: width,
    child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}

Widget _inquiryStatusBadge(String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.20)),
    ),
    child: Text(
      value,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}
