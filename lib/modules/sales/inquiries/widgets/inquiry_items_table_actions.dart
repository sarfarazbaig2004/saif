part of 'inquiry_items_grid.dart';

class _InquiryItemActions extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final InquiryBomAction? onOpenBom;
  final InquiryBomGridActionCallback? onBomAction;

  const _InquiryItemActions({
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    this.onOpenBom,
    this.onBomAction,
  });

  bool get _hasAction => onBomAction != null || onOpenBom != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ..._bomButtons(),
          IconButton(
            tooltip: 'Edit Item',
            onPressed: () => onEdit(index),
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Delete Item',
            onPressed: () => onDelete(index),
            icon: const Icon(
              Icons.delete_outline,
              size: 19,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bomButtons() {
    final bomLinked = _InquiryItemsTableHelpers.boolValue(item['bomLinked']);
    final bomStatus = _InquiryItemsTableHelpers.value(
      item['bomStatus'],
    ).toLowerCase();
    final approved = bomStatus == 'approved';

    if (!bomLinked) {
      return [
        OutlinedButton.icon(
          onPressed: !_hasAction
              ? null
              : () => _handleAction(InquiryBomGridAction.edit),
          icon: const Icon(Icons.account_tree_outlined, size: 15),
          label: const Text('Create BOM'),
        ),
      ];
    }

    if (approved) {
      return [
        OutlinedButton(
          onPressed: !_hasAction
              ? null
              : () => _handleAction(InquiryBomGridAction.view),
          child: const Text('View BOM'),
        ),
        OutlinedButton(
          onPressed: !_hasAction
              ? null
              : () => _handleAction(InquiryBomGridAction.createRevision),
          child: const Text('Revision'),
        ),
      ];
    }

    return [
      OutlinedButton(
        onPressed: !_hasAction
            ? null
            : () => _handleAction(InquiryBomGridAction.edit),
        child: const Text('Edit BOM'),
      ),
      OutlinedButton(
        onPressed: !_hasAction
            ? null
            : () => _handleAction(InquiryBomGridAction.view),
        child: const Text('View'),
      ),
      OutlinedButton(
        onPressed: !_hasAction
            ? null
            : () => _handleAction(InquiryBomGridAction.delete),
        child: const Text('Delete'),
      ),
    ];
  }

  void _handleAction(InquiryBomGridAction action) {
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
}
