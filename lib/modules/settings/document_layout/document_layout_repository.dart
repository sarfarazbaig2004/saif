import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'document_layout_model.dart';

class UploadedLayoutBackground {
  final String url;
  final String storagePath;
  const UploadedLayoutBackground(this.url, this.storagePath);
}

class DocumentLayoutRepository {
  final String companyId;
  DocumentLayoutRepository(this.companyId);

  DocumentReference<Map<String, dynamic>> get _ref => FirebaseFirestore.instance
      .collection('companies').doc(companyId).collection('settings').doc('document_layout');

  Future<DocumentLayoutModel> load() async =>
      DocumentLayoutModel.fromMap((await _ref.get()).data() ?? const {});

  Future<void> save(DocumentLayoutModel layout, String? userUid) => _ref.set({
    ...layout.toMap(), 'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': userUid,
  }, SetOptions(merge: true));

  Future<UploadedLayoutBackground> upload({
    required Uint8List bytes, required String fileName, required String extension,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'companies/$companyId/settings/document_layout/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final reference = FirebaseStorage.instance.ref(path);
    await reference.putData(bytes, SettableMetadata(contentType: extension == 'png' ? 'image/png' : 'image/jpeg'));
    return UploadedLayoutBackground(await reference.getDownloadURL(), path);
  }

  Future<void> deleteStorageFile(String path) async {
    if (path.trim().isNotEmpty) await FirebaseStorage.instance.ref(path).delete();
  }
}
