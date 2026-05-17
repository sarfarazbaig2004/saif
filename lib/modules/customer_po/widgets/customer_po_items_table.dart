import 'package:flutter/material.dart';

import 'customer_po_item_row.dart';

class CustomerPoItemsTable extends StatefulWidget {
  final ValueChanged<List<CustomerPoItemRow>> onChanged;

  const CustomerPoItemsTable({super.key, required this.onChanged});

  @override
  State<CustomerPoItemsTable> createState() => _CustomerPoItemsTableState();
}

class _CustomerPoItemsTableState extends State<CustomerPoItemsTable> {
  final List<CustomerPoItemRow> _items = [];

  void _addItem() {
    setState(() {
      _items.add(
        const CustomerPoItemRow(
          description: '',
          quantity: 1,
          unit: 'Nos',
          rate: 0,
        ),
      );
    });

    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });

    widget.onChanged(_items);
  }

  double get _grandTotal {
    return _items.fold(0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PO Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty) const Text('No items added'),
            if (_items.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        item.description.isEmpty
                            ? 'New Item'
                            : item.description,
                      ),
                      subtitle: Text(
                        '${item.quantity} ${item.unit} × ₹${item.rate}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${item.amount.toStringAsFixed(2)}'),
                          IconButton(
                            onPressed: () => _removeItem(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Grand Total: ₹${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
