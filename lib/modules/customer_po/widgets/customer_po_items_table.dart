import 'package:flutter/material.dart';

import 'customer_po_item_row.dart';

class CustomerPoItemsTable extends StatefulWidget {
  final ValueChanged<List<CustomerPoItemRow>> onChanged;

  const CustomerPoItemsTable({super.key, required this.onChanged});

  @override
  State<CustomerPoItemsTable> createState() => _CustomerPoItemsTableState();
}

class _RowControllers {
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController rate;

  _RowControllers({
    String desc = '',
    double qty = 1,
    String u = 'Nos',
    double r = 0,
  }) : description = TextEditingController(text: desc),
       quantity = TextEditingController(text: qty.toString()),
       unit = TextEditingController(text: u),
       rate = TextEditingController(text: r == 0 ? '' : r.toString());

  void dispose() {
    description.dispose();
    quantity.dispose();
    unit.dispose();
    rate.dispose();
  }
}

class _CustomerPoItemsTableState extends State<CustomerPoItemsTable> {
  final List<CustomerPoItemRow> _items = [];
  final List<_RowControllers> _controllers = [];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    final ctrls = _RowControllers();
    setState(() {
      _items.add(
        const CustomerPoItemRow(
          description: '',
          quantity: 1,
          unit: 'Nos',
          rate: 0,
        ),
      );
      _controllers.add(ctrls);
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    _controllers[index].dispose();
    setState(() {
      _items.removeAt(index);
      _controllers.removeAt(index);
    });
    widget.onChanged(_items);
  }

  void _updateItem(int index) {
    final c = _controllers[index];
    final qty = double.tryParse(c.quantity.text) ?? 0;
    final r = double.tryParse(c.rate.text) ?? 0;
    setState(() {
      _items[index] = CustomerPoItemRow(
        description: c.description.text,
        quantity: qty,
        unit: c.unit.text,
        rate: r,
      );
    });
    widget.onChanged(_items);
  }

  double get _grandTotal => _items.fold(0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  final c = _controllers[index];
                  final amount = _items[index].amount;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: c.description,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => _updateItem(index),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _removeItem(index),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: c.quantity,
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => _updateItem(index),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: c.unit,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => _updateItem(index),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: c.rate,
                                  decoration: const InputDecoration(
                                    labelText: 'Rate (₹)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => _updateItem(index),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '₹${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
