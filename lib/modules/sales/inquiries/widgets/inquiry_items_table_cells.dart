part of 'inquiry_items_grid.dart';

const double _inquiryRowHeight = 72;

Widget _inquiryDescriptionCell(Map<String, dynamic> item) {
  final description = _InquiryItemsTableHelpers.dash(
    item['name'] ?? item['description'],
  );
  final hsn = _InquiryItemsTableHelpers.value(item['hsn']);

  return SizedBox(
    width: 250,
    height: _inquiryRowHeight,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (hsn.isNotEmpty && hsn != '-') ...[
          const SizedBox(height: 3),
          Text(
            'HSN: $hsn',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ],
    ),
  );
}

Widget _inquiryShortText(String value, {required double width}) {
  return SizedBox(
    width: width,
    height: _inquiryRowHeight,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

Widget _inquiryStatusBadge(String value, Color color) {
  return SizedBox(
    height: _inquiryRowHeight,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}