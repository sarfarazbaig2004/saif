part of 'inquiry_items_grid.dart';

class _InquiryItemsTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final InquiryBomAction? onOpenBom;

  const _InquiryItemsTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    this.onOpenBom,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('HSN')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Rate')),
          DataColumn(label: Text('BOM')),
          DataColumn(label: Text('')),
        ],
        rows: List.generate(items.length, (index) {
          final item = items[index];
          final bomId = _value(item['bomId']);
          final bomStatus = _value(item['bomStatus']);
          final approved = bomStatus.toLowerCase() == 'approved';
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 240,
                  child: Text(_value(item['name'] ?? item['description'])),
                ),
              ),
              DataCell(Text(_value(item['hsn']))),
              DataCell(Text(InquiryItemsGrid._numberText(item['quantity']))),
              DataCell(Text(_value(item['unit']))),
              DataCell(Text(InquiryItemsGrid._numberText(item['price']))),
              DataCell(
                bomId.isEmpty
                    ? OutlinedButton.icon(
                        onPressed: onOpenBom == null
                            ? null
                            : () => onOpenBom!(item, readOnly: false),
                        icon: const Icon(Icons.account_tree_outlined, size: 16),
                        label: const Text('Create BOM'),
                      )
                    : Wrap(
                        spacing: 8,
                        children: [
                          if (!approved)
                            OutlinedButton(
                              onPressed: onOpenBom == null
                                  ? null
                                  : () => onOpenBom!(item, readOnly: false),
                              child: const Text('Edit BOM'),
                            ),
                          OutlinedButton(
                            onPressed: onOpenBom == null
                                ? null
                                : () => onOpenBom!(item, readOnly: true),
                            child: const Text('View BOM'),
                          ),
                        ],
                      ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => onEdit(index),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => onDelete(index),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  static String _value(dynamic value) => value?.toString().trim() ?? '';
}
