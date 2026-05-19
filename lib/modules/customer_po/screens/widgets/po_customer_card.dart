import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';

class PoCustomerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(dynamic value) formatValue;
  final Widget Function(Widget left, Widget right) row2;
  final Widget Function(String label, String value) labelValue;

  const PoCustomerCard({
    super.key,
    required this.data,
    required this.formatValue,
    required this.row2,
    required this.labelValue,
  });

  @override
  Widget build(BuildContext context) {
    return PoSectionCard(
      title: 'Customer',
      child: Column(
        children: [
          row2(
            labelValue('Company', formatValue(data['customerName'])),
            labelValue('GST Number', formatValue(data['customerGstNumber'])),
          ),
          const SizedBox(height: 12),
          row2(
            labelValue('Email', formatValue(data['customerEmail'])),
            labelValue('Mobile', formatValue(data['customerMobile'])),
          ),
          if (formatValue(data['customerAddress']).isNotEmpty) ...[
            const SizedBox(height: 12),
            labelValue('Address', formatValue(data['customerAddress'])),
          ],
        ],
      ),
    );
  }
}
