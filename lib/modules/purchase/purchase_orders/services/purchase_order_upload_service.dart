import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:QUIK/modules/purchase/purchase_orders/models/purchase_order_model.dart';

class PurchaseOrderUploadService {
  const PurchaseOrderUploadService._();

  static Future<PurchaseOrderAttachmentModel?> pickAndUploadVendorQuotation({
    required String companyId,
    required String purchaseOrderId,
    required String uploadedByUid,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'xlsx',
        'xls',
        'doc',
        'docx',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.bytes == null) return null;

    final safeOrderId = purchaseOrderId.trim().isEmpty
        ? 'draft'
        : purchaseOrderId.trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final storagePath =
        'companies/$companyId/purchase_orders/$safeOrderId/vendor_quotations/${timestamp}_$safeFileName';

    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putData(
      file.bytes!,
      SettableMetadata(contentType: _contentTypeFor(file.extension)),
    );

    return PurchaseOrderAttachmentModel(
      id: ref.name,
      fileName: file.name,
      fileUrl: await ref.getDownloadURL(),
      documentType: 'vendor_quotation',
      uploadedByUid: uploadedByUid,
      uploadedAt: DateTime.now(),
    );
  }

  static String _contentTypeFor(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }
}
