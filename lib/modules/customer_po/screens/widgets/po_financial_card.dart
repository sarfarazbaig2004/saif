import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';

class PoFinancialCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final double Function(dynamic value) numberValue;

  const PoFinancialCard({
    super.key,
    required this.data,
    required this.currency,
    required this.numberValue,
  });

  @override
  Widget build(BuildContext context) {
    return PoSectionCard(
      title: 'Financial Summary',
      child: Column(
        children: [
          _finRow(
            'Basic Value',
            '₹ ${currency.format(numberValue(data['basicValue']))}',
          ),
          const SizedBox(height: 8),
          _finRow(
            'GST (${numberValue(data['gstPercent']).toStringAsFixed(0)}%)',
            '₹ ${currency.format(numberValue(data['gstAmount']))}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          _finRow(
            'Total Value',
            '₹ ${currency.format(numberValue(data['totalValue']))}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _finRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
      color: bold ? const Color(0xFF0F172A) : const Color(0xFF334155),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
