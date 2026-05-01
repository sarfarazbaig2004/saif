import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/dispatch/models/dispatch_model.dart';
import 'package:QUIK/modules/production/inspections/models/inspection_model.dart';

class DispatchRepository {
  DispatchRepository({FirebaseFirestore? firestore, required this.tenantId})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String tenantId;

  TenantFirestore get _tenantDb {
    return TenantFirestore(tenantId: tenantId, firestore: _firestore);
  }

  CollectionReference<Map<String, dynamic>> get _dispatchRef {
    return _tenantDb.collection('dispatches');
  }

  CollectionReference<Map<String, dynamic>> get _inspectionRef {
    return _tenantDb.collection('inspections');
  }

  Stream<List<DispatchModel>> watchDispatches() {
    return _dispatchRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(DispatchModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<InspectionModel>> watchApprovedInspections() {
    return _inspectionRef
        .where('dispatchClearanceStatus', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InspectionModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<InspectionModel?> fetchApprovedInspectionForJobCard(
    String jobCardId,
  ) async {
    final snapshot = await _inspectionRef
        .where('jobCardId', isEqualTo: jobCardId)
        .where('dispatchClearanceStatus', isEqualTo: 'approved')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return InspectionModel.fromFirestore(snapshot.docs.first);
  }

  Future<double> dispatchedQtyForJobCard(String jobCardId) async {
    final snapshot = await _dispatchRef
        .where('jobCardId', isEqualTo: jobCardId)
        .get();
    return snapshot.docs.fold<double>(0, (total, doc) {
      return total + DispatchModel.fromFirestore(doc).dispatchQty;
    });
  }

  Future<void> saveDispatch(DispatchModel dispatch) async {
    final normalizedTenantId = TenantFirestore.requireTenantId(tenantId);
    final inspection = await fetchApprovedInspectionForJobCard(
      dispatch.jobCardId,
    );
    if (inspection == null ||
        inspection.dispatchClearanceStatus != 'approved') {
      throw StateError('Dispatch clearance is not approved.');
    }

    final alreadyDispatched = await dispatchedQtyForJobCard(dispatch.jobCardId);
    if (alreadyDispatched + dispatch.dispatchQty > inspection.approvedQty) {
      throw StateError('Dispatch quantity exceeds approved inspection qty.');
    }

    await _dispatchRef.doc(dispatch.dispatchId).set({
      ...dispatch.toFirestore(),
      'tenantId': normalizedTenantId,
      'companyId': normalizedTenantId,
      'inspectionId': inspection.inspectionId,
      'approvedQty': inspection.approvedQty,
      'dispatchCommitmentDate': inspection.dispatchCommitmentDate == null
          ? null
          : Timestamp.fromDate(inspection.dispatchCommitmentDate!),
    }, SetOptions(merge: true));
  }

  String newDispatchId() => _dispatchRef.doc().id;
}
