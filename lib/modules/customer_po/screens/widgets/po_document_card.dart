import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';

class PoDocumentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(dynamic value) formatValue;
  final String Function(dynamic value) formatDate;
  final void Function(BuildContext context, String url) openUrl;

  const PoDocumentCard({
    super.key,
    required this.data,
    required this.formatValue,
    required this.formatDate,
    required this.openUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = formatValue(data['poDocumentUrl']);
    final fileName = formatValue(data['poFileName']);
    final uploadedAt = formatDate(data['uploadedAt']);

    return PoSectionCard(
      title: 'PO Document',
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName.isEmpty ? 'Attached Document' : fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (uploadedAt != '—')
                  Text(
                    'Uploaded: $uploadedAt',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (url.isNotEmpty)
            FilledButton.icon(
              onPressed: () => openUrl(context, url),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open'),
            )
          else
            Text(
              'No URL',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }
}
