import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';

class PoTermsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(dynamic value) formatValue;
  final Widget Function(String label, String value) labelValue;

  const PoTermsCard({
    super.key,
    required this.data,
    required this.formatValue,
    required this.labelValue,
  });

  @override
  Widget build(BuildContext context) {
    return PoSectionCard(
      title: 'Terms & Conditions',
      child: Column(
        children: [
          if (formatValue(data['paymentTerms']).isNotEmpty)
            labelValue('Payment Terms', formatValue(data['paymentTerms'])),
          if (formatValue(data['deliveryTerms']).isNotEmpty) ...[
            const SizedBox(height: 10),
            labelValue('Delivery Terms', formatValue(data['deliveryTerms'])),
          ],
          if (formatValue(data['inspectionRequirement']).isNotEmpty) ...[
            const SizedBox(height: 10),
            labelValue(
              'Inspection',
              formatValue(data['inspectionRequirement']),
            ),
          ],
          if (formatValue(data['warranty']).isNotEmpty) ...[
            const SizedBox(height: 10),
            labelValue('Warranty', formatValue(data['warranty'])),
          ],
          if (formatValue(data['ldClause']).isNotEmpty) ...[
            const SizedBox(height: 10),
            labelValue('LD Clause', formatValue(data['ldClause'])),
          ],
        ],
      ),
    );
  }
}
