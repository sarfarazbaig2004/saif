import 'package:flutter/material.dart';

class EngineeringBomAppBarActions extends StatelessWidget {
  final bool saving;
  final ValueChanged<String> onGenerateQuotation;
  final VoidCallback onSave;

  const EngineeringBomAppBarActions({
    super.key,
    required this.saving,
    required this.onGenerateQuotation,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopupMenuButton<String>(
          tooltip: 'Generate Quotation',
          onSelected: onGenerateQuotation,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'commercial',
              child: Text('Commercial Quotation'),
            ),
            PopupMenuItem(
              value: 'bomDetailed',
              child: Text('BOM Detailed Quotation'),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.request_quote_outlined),
                SizedBox(width: 6),
                Text('Generate Quotation'),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: saving ? null : onSave,
          icon: const Icon(Icons.save_outlined),
          label: Text(saving ? 'Saving' : 'Save BOM'),
        ),
      ],
    );
  }
}
