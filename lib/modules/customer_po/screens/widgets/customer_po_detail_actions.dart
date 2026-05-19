import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_record_status_service.dart';

class CustomerPoDetailActions extends StatelessWidget {
  final String companyId;
  final String docId;

  const CustomerPoDetailActions({
    super.key,
    required this.companyId,
    required this.docId,
  });

  Future<void> _markDuplicate(BuildContext context) async {
    await CustomerPoRecordStatusService.markAsDuplicate(
      companyId: companyId,
      docId: docId,
      reason: 'Created twice by mistake',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate Customer PO deleted from active list'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit PO',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerPoFormScreen(
                companyId: companyId,
                existingDocId: docId,
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'duplicate') _markDuplicate(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'duplicate',
              child: Text('Delete Duplicate Entry'),
            ),
          ],
        ),
      ],
    );
  }
}
