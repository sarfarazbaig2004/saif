import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';

class PoProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(dynamic value) formatValue;
  final Widget Function(Widget left, Widget right) row2;
  final Widget Function(String label, String value) labelValue;

  const PoProjectCard({
    super.key,
    required this.data,
    required this.formatValue,
    required this.row2,
    required this.labelValue,
  });

  @override
  Widget build(BuildContext context) {
    return PoSectionCard(
      title: 'Project Details',
      child: Column(
        children: [
          row2(
            labelValue('Project Name', formatValue(data['projectName'])),
            labelValue('Site Location', formatValue(data['siteLocation'])),
          ),
          if (formatValue(data['subject']).isNotEmpty) ...[
            const SizedBox(height: 12),
            labelValue('Subject / Scope', formatValue(data['subject'])),
          ],
        ],
      ),
    );
  }
}
