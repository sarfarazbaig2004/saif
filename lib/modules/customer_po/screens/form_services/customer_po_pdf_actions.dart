import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_amendment_handler.dart';

class CustomerPoPdfActions {
  const CustomerPoPdfActions._();

  static VoidCallback? amendedUpload({
    required BuildContext context,
    required bool isEditMode,
    required String companyId,
    required String docId,
    required String? currentPoDocumentUrl,
  }) {
    if (!isEditMode) return null;

    return () => CustomerPoAmendmentHandler.uploadAmendedPo(
      context: context,
      companyId: companyId,
      docId: docId,
      currentRevisionNo: 0,
      currentPoDocumentUrl: currentPoDocumentUrl,
    );
  }
}
