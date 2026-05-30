import 'package:flutter/material.dart';

class EngineeringBomAppBarActions extends StatelessWidget {
  final bool saving;
  final bool readOnly;
  final ValueChanged<String> onGenerateQuotation;
  final VoidCallback onRefreshMaterials;
  final VoidCallback onCreateRevision;
  final VoidCallback onSaveDraft;
  final VoidCallback onSave;

  const EngineeringBomAppBarActions({
    super.key,
    required this.saving,
    required this.readOnly,
    required this.onGenerateQuotation,
    required this.onRefreshMaterials,
    required this.onCreateRevision,
    required this.onSaveDraft,
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
          onPressed: saving || readOnly ? null : onRefreshMaterials,
          icon: const Icon(Icons.sync_outlined),
          label: const Text('Refresh Material Values'),
        ),
        TextButton.icon(
          onPressed: saving ? null : onCreateRevision,
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('Create Revision'),
        ),
        TextButton.icon(
          onPressed: saving || readOnly ? null : onSaveDraft,
          icon: const Icon(Icons.drafts_outlined),
          label: const Text('Save Draft'),
        ),
        TextButton.icon(
          onPressed: saving || readOnly ? null : onSave,
          icon: const Icon(Icons.save_outlined),
          label: Text(saving ? 'Saving' : 'Save BOM'),
        ),
      ],
    );
  }
}
