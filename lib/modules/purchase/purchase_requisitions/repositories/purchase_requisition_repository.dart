import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/purchase/purchase_requisitions/models/purchase_requisition_model.dart';

class PurchaseRequisitionRepository {
  PurchaseRequisitionRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('purchase_requisitions');
  }

  String newRequisitionId() => _ref.doc().id;

  String nextRequisitionNo() {
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'PR-$suffix';
  }

  Stream<List<PurchaseRequisitionModel>> watchRequisitions() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PurchaseRequisitionModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> save(PurchaseRequisitionModel requisition) {
    return _ref.doc(requisition.requisitionId).set({
      ...requisition.toFirestore(),
      'tenantId': tenantId,
      'companyId': tenantId,
    }, SetOptions(merge: true));
  }
}
