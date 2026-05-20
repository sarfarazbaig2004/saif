import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_pdf_upload_service.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_revision_service.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_amendment_dialog.dart';

class CustomerPoAmendmentHandler {
  const CustomerPoAmendmentHandler._();

  static Future<void> uploadAmendedPo({
    required BuildContext context,
    required String companyId,
    required String docId,
    required int currentRevisionNo,
    required String? currentPoDocumentUrl,
  }) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const PoAmendmentDialog(),
    );

    if (reason == null || reason.trim().isEmpty) return;

    final uploaded = await CustomerPoPdfUploadService.pickAndUpload(
      companyId: companyId,
    );

    if (uploaded == null) return;

    await CustomerPoRevisionService.createRevision(
      companyId: companyId,
      docId: docId,
      currentRevisionNo: currentRevisionNo,
      amendmentReason: reason.trim(),
      previousPoDocumentUrl: currentPoDocumentUrl,
      newPoDocumentUrl: uploaded.url,
      newPoFileName: uploaded.fileName,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Amended PO uploaded as new revision')),
    );
  }
}
