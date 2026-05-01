import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/production/masters/models/work_center_model.dart';

class WorkCenterRepository {
  WorkCenterRepository({FirebaseFirestore? firestore, required this.tenantId})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String tenantId;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('work_centers');
  }

  Stream<List<WorkCenterModel>> watchWorkCenters() {
    return _ref
        .orderBy('workCenterCode')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkCenterModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> saveWorkCenter(WorkCenterModel workCenter) {
    return _ref.doc(workCenter.workCenterId).set({
      ...workCenter.toFirestore(),
      'companyId': tenantId,
      'tenantId': tenantId,
    }, SetOptions(merge: true));
  }

  String newWorkCenterId() => _ref.doc().id;
}
