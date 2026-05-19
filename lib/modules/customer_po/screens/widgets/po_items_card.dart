import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';

class PoItemsCard extends StatelessWidget {
  final List<dynamic> items;
  final NumberFormat currency;
  final String Function(dynamic value) formatValue;
  final double Function(dynamic value) numberValue;

  const PoItemsCard({
    super.key,
    required this.items,
    required this.currency,
    required this.formatValue,
    required this.numberValue,
  });

  @override
  Widget build(BuildContext context) {
    return PoSectionCard(
      title: 'PO Items',
      child: items.isEmpty
          ? const Text(
              'No items recorded.',
              style: TextStyle(color: Colors.grey),
            )
          : Column(
              children: [
                _itemsHeader(),
                const SizedBox(height: 8),
                ...items.asMap().entries.map(
                  (entry) => _itemRow(entry.key, entry.value),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _grandTotal(),
              ],
            ),
    );
  }

  Widget _itemsHeader() {
    const style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: Color(0xFF64748B),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: const [
          Expanded(flex: 4, child: Text('Description', style: style)),
          Expanded(
            flex: 1,
            child: Text('Qty', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 1,
            child: Text('Unit', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Rate', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text('Amount', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(int index, dynamic item) {
    final m = item as Map<String, dynamic>;
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              formatValue(m['description']).isEmpty
                  ? '—'
                  : formatValue(m['description']),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              numberValue(
                m['quantity'],
              ).toStringAsFixed(numberValue(m['quantity']) % 1 == 0 ? 0 : 2),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              formatValue(m['unit']),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹ ${currency.format(numberValue(m['rate']))}',
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹ ${currency.format(numberValue(m['amount']))}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grandTotal() {
    final total = items.fold<double>(0, (acc, item) {
      final m = item as Map<String, dynamic>;
      return acc + numberValue(m['amount']);
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Grand Total',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(width: 24),
        Text(
          '₹ ${currency.format(total)}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }
}
