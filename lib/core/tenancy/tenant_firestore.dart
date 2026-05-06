import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/app/aman_app_config.dart';

class TenantFirestore {
  TenantFirestore({required String tenantId, FirebaseFirestore? firestore})
    : tenantId = AmanAppConfig.tenantId,
      _firestore = firestore ?? FirebaseFirestore.instance {
    final requestedTenantId = tenantId.trim();
    if (requestedTenantId.isNotEmpty &&
        requestedTenantId != AmanAppConfig.tenantId) {
      throw ArgumentError('AMAN Infra ERP only supports the AMAN tenant.');
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
    final requestedTenantId = (tenantId ?? '').trim();
    if (requestedTenantId.isNotEmpty &&
        requestedTenantId != AmanAppConfig.tenantId) {
      throw StateError('AMAN Infra ERP only supports the AMAN tenant.');
    }
    return AmanAppConfig.tenantId;
  }
}
