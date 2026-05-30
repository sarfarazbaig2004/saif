part of 'inquiry_items_grid.dart';

class _InquiryItemsTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final InquiryBomAction? onOpenBom;
  final InquiryBomGridActionCallback? onBomAction;

  const _InquiryItemsTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    this.onOpenBom,
    this.onBomAction,
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
          final bomLinked = _bool(item['bomLinked']);
          final normalizedStatus = bomStatus.toLowerCase();
          final approved = normalizedStatus == 'approved';
          final state = !bomLinked
              ? 'Create BOM'
              : approved
              ? 'View BOM + Create Revision'
              : 'Edit BOM + View BOM + Delete';
          debugPrint(
            'BOM_BUTTON_STATE index=$index '
            'inquiryItemId=${_value(item['inquiryItemId'])} '
            'bomLinked=$bomLinked bomId=$bomId '
            'bomNumber=${_value(item['bomNumber'])} '
            'bomStatus=$bomStatus state=$state',
          );
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
                !bomLinked
                    ? OutlinedButton.icon(
                        onPressed: !_hasAction
                            ? null
                            : () => _handleAction(
                                item,
                                InquiryBomGridAction.edit,
                              ),
                        icon: const Icon(Icons.account_tree_outlined, size: 16),
                        label: const Text('Create BOM'),
                      )
                    : Wrap(
                        spacing: 8,
                        children: [
                          if (approved) ...[
                            OutlinedButton(
                              onPressed: !_hasAction
                                  ? null
                                  : () => _handleAction(
                                      item,
                                      InquiryBomGridAction.view,
                                    ),
                              child: const Text('View BOM'),
                            ),
                            OutlinedButton(
                              onPressed: !_hasAction
                                  ? null
                                  : () => _handleAction(
                                      item,
                                      InquiryBomGridAction.createRevision,
                                    ),
                              child: const Text('Create Revision'),
                            ),
                          ] else ...[
                            OutlinedButton(
                              onPressed: !_hasAction
                                  ? null
                                  : () => _handleAction(
                                      item,
                                      InquiryBomGridAction.edit,
                                    ),
                              child: const Text('Edit'),
                            ),
                            OutlinedButton(
                              onPressed: !_hasAction
                                  ? null
                                  : () => _handleAction(
                                      item,
                                      InquiryBomGridAction.view,
                                    ),
                              child: const Text('View'),
                            ),
                            OutlinedButton(
                              onPressed: !_hasAction
                                  ? null
                                  : () => _handleAction(
                                      item,
                                      InquiryBomGridAction.delete,
                                    ),
                              child: const Text('Delete'),
                            ),
                          ],
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

  bool get _hasAction => onBomAction != null || onOpenBom != null;

  void _handleAction(Map<String, dynamic> item, InquiryBomGridAction action) {
    if (onBomAction != null) {
      onBomAction!(item, action);
      return;
    }
    switch (action) {
      case InquiryBomGridAction.edit:
      case InquiryBomGridAction.createRevision:
        onOpenBom?.call(item, readOnly: false);
        break;
      case InquiryBomGridAction.view:
        onOpenBom?.call(item, readOnly: true);
        break;
      case InquiryBomGridAction.delete:
        break;
    }
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().trim().toLowerCase() == 'true';
  }
}
