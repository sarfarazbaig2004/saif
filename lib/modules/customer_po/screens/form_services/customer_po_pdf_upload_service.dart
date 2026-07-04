import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:QUIK/core/utils/file_upload_limits.dart';

class CustomerPoPdfUploadResult {
  final String url;
  final String fileName;
  final DateTime uploadedAt;

  const CustomerPoPdfUploadResult({
    required this.url,
    required this.fileName,
    required this.uploadedAt,
  });
}

class CustomerPoPdfUploadService {
  const CustomerPoPdfUploadService._();

  static Future<CustomerPoPdfUploadResult?> pickAndUpload({
    required String companyId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.size > maxUploadFileSizeBytes) {
      throw Exception(maxUploadFileSizeMessage);
    }

    if (file.bytes == null) return null;

    final fileName = file.name;
    final storagePath = 'companies/$companyId/customer_pos/$fileName';

    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putData(
      file.bytes!,
      SettableMetadata(contentType: 'application/pdf'),
    );

    return CustomerPoPdfUploadResult(
      url: await ref.getDownloadURL(),
      fileName: fileName,
      uploadedAt: DateTime.now(),
    );
  }
}
