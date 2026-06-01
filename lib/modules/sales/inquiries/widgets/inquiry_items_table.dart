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
        columnSpacing: 22,
        columns: const [
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Project')),
          DataColumn(label: Text('Structure Type')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Rate')),
          DataColumn(label: Text('Est. Weight')),
          DataColumn(label: Text('BOM Status')),
          DataColumn(label: Text('Quotation Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(items.length, _buildRow),
      ),
    );
  }

  DataRow _buildRow(int index) {
    final item = items[index];
    final bomStatus = _InquiryItemsTableHelpers.bomStatus(item);
    final quotationStatus = _InquiryItemsTableHelpers.quotationStatus(item);

    return DataRow(
      cells: [
        DataCell(_inquiryDescriptionCell(item)),
        DataCell(
          _inquiryShortText(
            _InquiryItemsTableHelpers.projectName(item),
            width: 130,
          ),
        ),
        DataCell(
          _inquiryShortText(
            _InquiryItemsTableHelpers.structureType(item),
            width: 130,
          ),
        ),
        DataCell(Text(InquiryItemsGrid._numberText(item['quantity']))),
        DataCell(Text(_InquiryItemsTableHelpers.dash(item['unit']))),
        DataCell(Text(InquiryItemsGrid._numberText(item['price']))),
        DataCell(Text(_InquiryItemsTableHelpers.estimatedWeight(item))),
        DataCell(
          _inquiryStatusBadge(
            bomStatus,
            _InquiryItemsTableHelpers.bomStatusColor(bomStatus),
          ),
        ),
        DataCell(
          _inquiryStatusBadge(
            quotationStatus,
            _InquiryItemsTableHelpers.quotationStatusColor(quotationStatus),
          ),
        ),
        DataCell(
          _InquiryItemActions(
            item: item,
            index: index,
            onEdit: onEdit,
            onDelete: onDelete,
            onOpenBom: onOpenBom,
            onBomAction: onBomAction,
          ),
        ),
      ],
    );
  }
}
