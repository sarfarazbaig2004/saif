import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_model.dart';

class EngineeringBomRepository {
  EngineeringBomRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('engineering_boms');
  }

  String newBomId() => _ref.doc().id;

  String nextBomNo() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 100000}';
    return 'EBOM-$stamp';
  }

  Future<void> saveBom(EngineeringBomModel bom) {
    return _ref.doc(bom.id).set({
      ...bom.toFirestore(),
      'companyId': tenantId,
      'tenantId': tenantId,
    }, SetOptions(merge: true));
  }
}
