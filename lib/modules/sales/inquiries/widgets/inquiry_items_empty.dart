part of 'inquiry_items_grid.dart';

class _EmptyInquiryItems extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyInquiryItems({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InquiryItemsGrid._borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.precision_manufacturing_outlined,
            size: 34,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          const Text(
            'No inquiry items added yet.',
            style: TextStyle(
              color: InquiryItemsGrid._mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create an item from a PO, BOQ, drawing, or engineering estimate.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Inquiry Item'),
          ),
        ],
      ),
    );
  }
}
