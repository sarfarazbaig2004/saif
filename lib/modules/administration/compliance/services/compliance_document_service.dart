import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/administration/compliance/models/compliance_document_model.dart';

class ComplianceDocumentService {
  ComplianceDocumentService({
    required this.tenantId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  TenantFirestore get _tenantDb {
    return TenantFirestore(tenantId: tenantId, firestore: _firestore);
  }

  CollectionReference<Map<String, dynamic>> get _ref {
    return _tenantDb.collection('compliance_documents');
  }

  Stream<List<ComplianceDocumentModel>> watchDocuments({
    required List<ComplianceDocumentCategory> allowedCategories,
  }) {
    final Query<Map<String, dynamic>> query =
        allowedCategories.length == ComplianceDocumentCategory.values.length
        ? _ref
        : _ref.where(
            'category',
            whereIn: allowedCategories.map((category) => category.key).toList(),
          );

    return query.snapshots().map((snapshot) {
      final documents = snapshot.docs
          .map(ComplianceDocumentModel.fromFirestore)
          .toList(growable: false);
      documents.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(1900);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });
      return documents;
    });
  }

  String newDocumentId() => _ref.doc().id;

  Future<UploadedComplianceFile> uploadFile({
    required String documentId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final normalizedTenantId = TenantFirestore.requireTenantId(tenantId);
    final safeFileName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final storagePath =
        'companies/$normalizedTenantId/compliance_documents/$documentId/$safeFileName';
    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(
      contentDisposition: 'inline; filename="$safeFileName"',
    );

    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    return UploadedComplianceFile(
      fileName: safeFileName,
      fileUrl: url,
      storagePath: storagePath,
    );
  }

  Future<void> saveDocument(ComplianceDocumentModel document) async {
    final normalizedTenantId = TenantFirestore.requireTenantId(tenantId);
    await _ref.doc(document.id).set({
      ...document.toFirestore(),
      'tenantId': normalizedTenantId,
      'companyId': normalizedTenantId,
    }, SetOptions(merge: true));
  }
}

class UploadedComplianceFile {
  const UploadedComplianceFile({
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
  });

  final String fileName;
  final String fileUrl;
  final String storagePath;
}
