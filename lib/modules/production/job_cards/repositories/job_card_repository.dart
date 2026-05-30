import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';

class JobCardRepository {
  JobCardRepository({FirebaseFirestore? firestore, required this.tenantId})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String tenantId;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('job_cards');
  }

  Stream<List<JobCardModel>> watchJobCards() {
    return _ref
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(JobCardModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<JobCardModel?> fetchJobCard(String jobCardId) async {
    final snapshot = await _ref.doc(jobCardId).get();
    if (!snapshot.exists) return null;
    return JobCardModel.fromFirestore(snapshot);
  }

  Future<bool> isJobCardNoAvailable({
    required String jobCardNo,
    String? excludingJobCardId,
  }) async {
    final normalizedNo = jobCardNo.trim();
    if (normalizedNo.isEmpty) return false;

    final snapshot = await _ref
        .where('jobCardNo', isEqualTo: normalizedNo)
        .limit(2)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id != excludingJobCardId) return false;
    }
    return true;
  }

  Future<void> saveJobCard(JobCardModel jobCard) async {
    final normalizedTenantId = TenantFirestore.requireTenantId(tenantId);
    await _validateApprovedBomRevision(jobCard.bomId);
    final isAvailable = await isJobCardNoAvailable(
      jobCardNo: jobCard.jobCardNo,
      excludingJobCardId: jobCard.jobCardId,
    );
    if (!isAvailable) {
      throw StateError('Job card number already exists in this company.');
    }

    await _ref.doc(jobCard.jobCardId).set({
      ...jobCard.toFirestore(),
      'tenantId': normalizedTenantId,
      'companyId': normalizedTenantId,
    }, SetOptions(merge: true));
  }

  String newJobCardId() => _ref.doc().id;

  Future<void> _validateApprovedBomRevision(String bomId) async {
    final id = bomId.trim();
    if (id.isEmpty) return;
    final snapshot = await _firestore
        .collection('companies')
        .doc(TenantFirestore.requireTenantId(tenantId))
        .collection('engineering_boms')
        .doc(id)
        .get();
    final status = (snapshot.data()?['status'] ?? '').toString().toLowerCase();
    if (!snapshot.exists || status != 'approved') {
      throw StateError(
        'Production Job Card requires an approved BOM revision.',
      );
    }
  }
}
