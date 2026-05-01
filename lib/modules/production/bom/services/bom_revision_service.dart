import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';

class BomRevisionService {
  BomRevisionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String> copyRevision({
    required String tenantId,
    required String sourceBomId,
  }) async {
    final bomRef = TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('bom_headers');
    final sourceRef = bomRef.doc(sourceBomId);
    final sourceSnap = await sourceRef.get();

    if (!sourceSnap.exists) {
      throw StateError('Source BOM not found');
    }

    final sourceData = sourceSnap.data() ?? <String, dynamic>{};
    final nextRevision =
        ((sourceData['revisionNo'] is num)
                ? sourceData['revisionNo'] as num
                : 0)
            .toInt() +
        1;
    final nextRef = bomRef.doc();
    final linesSnap = await sourceRef.collection('bom_lines').get();
    final batch = _firestore.batch();

    batch.set(nextRef, {
      ...sourceData,
      'bomId': nextRef.id,
      'revisionNo': nextRevision,
      'status': 'draft',
      'companyId': tenantId,
      'tenantId': tenantId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final line in linesSnap.docs) {
      batch.set(nextRef.collection('bom_lines').doc(line.id), {
        ...line.data(),
        'companyId': tenantId,
        'tenantId': tenantId,
      });
    }

    await batch.commit();
    return nextRef.id;
  }
}
