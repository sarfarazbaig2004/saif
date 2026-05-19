import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/providers/customer_po_provider.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_duplicate_service.dart';

class CustomerPoFormOrchestrator {
  const CustomerPoFormOrchestrator._();

  static Future<void> save({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required bool mounted,
    required bool isEditMode,
    required CustomerPoProvider provider,
    required String companyId,
    required String customerId,
    required String poNumber,
    required String? currentDocId,
    required VoidCallback showCustomerError,
    required CustomerPoModel Function() buildPo,
  }) async {
    if (customerId.isEmpty) {
      showCustomerError();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    if (!formKey.currentState!.validate()) return;

    final duplicateId = await CustomerPoDuplicateService.findDuplicatePoId(
      companyId: companyId,
      customerId: customerId,
      poNumber: poNumber,
      currentDocId: currentDocId,
    );

    if (duplicateId != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This customer PO already exists. Open existing or create a revision.',
          ),
        ),
      );
      return;
    }

    try {
      final po = buildPo();

      if (isEditMode) {
        await provider.updateCustomerPo(po);
      } else {
        await provider.createCustomerPo(po);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Customer PO ${isEditMode ? 'updated' : 'saved'} successfully',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${isEditMode ? 'update' : 'save'} Customer PO: $e',
          ),
        ),
      );
    }
  }
}
