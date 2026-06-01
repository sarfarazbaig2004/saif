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
      width: 300,
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _bomButtons(),
      ),
    );
  }

  List<Widget> _bomButtons() {
    final bomLinked = _InquiryItemsTableHelpers.boolValue(item['bomLinked']);
    final bomStatus = _InquiryItemsTableHelpers.value(
      item['bomStatus'],
    ).toLowerCase();

    if (!bomLinked) {
      return [
        _smallActionButton(
          'Create BOM',
          !_hasAction ? null : () => _handleAction(InquiryBomGridAction.edit),
        ),
      ];
    }

    if (bomStatus == 'approved') {
      return [
        _smallActionButton(
          'View BOM',
          !_hasAction ? null : () => _handleAction(InquiryBomGridAction.view),
        ),
        const SizedBox(width: 8),
        _smallActionButton(
          'Revision',
          !_hasAction
              ? null
              : () => _handleAction(InquiryBomGridAction.createRevision),
        ),
      ];
    }

    return [
      _smallActionButton(
        'Edit BOM',
        !_hasAction ? null : () => _handleAction(InquiryBomGridAction.edit),
      ),
      const SizedBox(width: 8),
      _smallActionButton(
        'View',
        !_hasAction ? null : () => _handleAction(InquiryBomGridAction.view),
      ),
      const SizedBox(width: 8),
      _smallActionButton(
        'Delete',
        !_hasAction ? null : () => _handleAction(InquiryBomGridAction.delete),
      ),
    ];
  }

  Widget _smallActionButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
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
