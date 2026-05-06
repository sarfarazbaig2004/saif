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
    required List<ComplianceAccessCategory> allowedCategories,
  }) {
    final Query<Map<String, dynamic>> query =
        allowedCategories.length == ComplianceAccessCategory.values.length
        ? _ref
        : _ref.where(
            'accessCategories',
            arrayContainsAny: allowedCategories
                .map((category) => category.key)
                .toList(),
          );

    final fallbackQuery =
        allowedCategories.length == ComplianceAccessCategory.values.length
        ? null
        : _ref.where(
            'category',
            whereIn: allowedCategories.map((category) => category.key).toList(),
          );

    return query.snapshots().asyncMap((snapshot) async {
      final documents = snapshot.docs
          .map(ComplianceDocumentModel.fromFirestore)
          .toList();

      if (documents.isEmpty && fallbackQuery != null) {
        final fallbackSnapshot = await fallbackQuery.get();
        documents.addAll(
          fallbackSnapshot.docs.map(ComplianceDocumentModel.fromFirestore),
        );
      }

      documents.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(1900);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });

      final byId = <String, ComplianceDocumentModel>{
        for (final document in documents) document.id: document,
      };
      return byId.values.toList(growable: false);
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
      contentType: _contentTypeForFile(safeFileName),
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

  Future<String> resolveDownloadUrl(ComplianceDocumentModel document) async {
    final currentUrl = document.fileUrl.trim();
    if (currentUrl.isNotEmpty) return currentUrl;

    final storagePath = document.storagePath.trim();
    if (storagePath.isEmpty) return '';

    return _storage.ref().child(storagePath).getDownloadURL();
  }

  Future<void> deleteNormalComplianceDocument(
    ComplianceDocumentModel document,
  ) async {
    if (document.isQmsDocument) {
      throw StateError('QMS revision history cannot be deleted.');
    }

    final normalizedTenantId = TenantFirestore.requireTenantId(tenantId);
    final path = document.storagePath.trim();
    if (path.startsWith(
      'companies/$normalizedTenantId/compliance_documents/',
    )) {
      try {
        await _storage.ref().child(path).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
    }

    await _ref.doc(document.id).delete();
  }

  Future<void> approveDocument({
    required ComplianceDocumentModel document,
    required String approvedBy,
    required DateTime approvalDate,
  }) async {
    await saveDocument(
      document.copyWith(
        approvedBy: approvedBy,
        approvalDate: approvalDate,
        isObsolete: false,
        qmsApprovalStatus: QmsApprovalStatus.approved,
      ),
    );
  }

  Future<void> archiveDocument(ComplianceDocumentModel document) async {
    await saveDocument(
      document.copyWith(
        isObsolete: true,
        qmsApprovalStatus: document.qmsApprovalStatus,
      ),
    );
  }

  String _contentTypeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
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
