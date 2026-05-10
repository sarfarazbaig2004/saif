import 'package:cloud_firestore/cloud_firestore.dart';

class TenantFirestore {
  TenantFirestore({required String tenantId, FirebaseFirestore? firestore})
    : tenantId = tenantId.trim(),
      _firestore = firestore ?? FirebaseFirestore.instance {
    if (this.tenantId.isEmpty) {
      throw ArgumentError('tenantId is required.');
    }
  }

  final String tenantId;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get companyRef =>
      _firestore.collection('companies').doc(tenantId);

  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    final path = collectionPath.trim();
    if (path.isEmpty || path.contains('/')) {
      throw ArgumentError('Use a direct tenant subcollection name.');
    }
    return companyRef.collection(path);
  }

  DocumentReference<Map<String, dynamic>> doc(
    String collectionPath,
    String documentId,
  ) {
    final id = documentId.trim();
    if (id.isEmpty) {
      throw ArgumentError('documentId is required.');
    }
    return collection(collectionPath).doc(id);
  }

  static String requireTenantId(String? tenantId) {
    final normalized = (tenantId ?? '').trim();
    if (normalized.isEmpty) {
      throw StateError('tenantId is required.');
    }
    return normalized;
  }
}
