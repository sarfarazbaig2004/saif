import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/production/material_requirements/models/material_requirement_model.dart';

class MaterialRequirementRepository {
  MaterialRequirementRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('material_requirements');
  }

  String newRequirementId() => _ref.doc().id;

  String nextRequirementNo(String jobCardNo) {
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    final source = jobCardNo.trim().isEmpty ? 'JC' : jobCardNo.trim();
    return 'MR-$source-$suffix';
  }

  Future<void> save(MaterialRequirementModel requirement) {
    return _ref.doc(requirement.requirementId).set({
      ...requirement.toFirestore(),
      'tenantId': tenantId,
      'companyId': tenantId,
    }, SetOptions(merge: true));
  }
}
