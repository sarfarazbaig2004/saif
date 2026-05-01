import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/production/contractor_jobs/models/contractor_job_model.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';

class ContractorJobRepository {
  ContractorJobRepository({
    FirebaseFirestore? firestore,
    required this.tenantId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String tenantId;

  TenantFirestore get _tenantDb {
    return TenantFirestore(tenantId: tenantId, firestore: _firestore);
  }

  CollectionReference<Map<String, dynamic>> get _ref {
    return _tenantDb.collection('contractor_jobs');
  }

  Stream<List<ContractorJobModel>> watchContractorJobs() {
    return _ref
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ContractorJobModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<JobCardModel>> watchJobCards() {
    return _tenantDb
        .collection('job_cards')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(JobCardModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> saveContractorJob(ContractorJobModel job) async {
    final normalizedTenantId = TenantFirestore.requireTenantId(tenantId);
    await _ref.doc(job.jobId).set({
      ...job.toFirestore(),
      'tenantId': normalizedTenantId,
      'companyId': normalizedTenantId,
    }, SetOptions(merge: true));
  }

  String newJobId() => _ref.doc().id;
}
