import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_items_table.dart';

class PoEngineeringTab extends StatelessWidget {
  final List<CustomerPoItemRow> items;
  final ValueChanged<List<CustomerPoItemRow>> onChanged;

  const PoEngineeringTab({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CustomerPoItemsTable(initialItems: items, onChanged: onChanged),
      ],
    );
  }
}
