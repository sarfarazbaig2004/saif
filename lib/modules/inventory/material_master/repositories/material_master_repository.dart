import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';

class MaterialMasterRepository {
  MaterialMasterRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('material_master');
  }

  String newMaterialId() => _ref.doc().id;

  Stream<List<MaterialMasterModel>> watchMaterials() {
    return _ref
        .where('isActive', isEqualTo: true)
        .orderBy('materialName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MaterialMasterModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<List<MaterialMasterModel>> searchMaterials(String query) async {
    final normalized = query.trim().toLowerCase();
    final snapshot = await _ref
        .where('isActive', isEqualTo: true)
        .limit(100)
        .get();
    final materials = snapshot.docs
        .map(MaterialMasterModel.fromFirestore)
        .where((material) {
          if (normalized.isEmpty) return true;
          final haystack =
              '${material.materialCode} ${material.materialName} ${material.materialType} ${material.materialGrade}'
                  .toLowerCase();
          return haystack.contains(normalized);
        })
        .toList(growable: false);
    return materials;
  }

  Future<void> saveMaterial(MaterialMasterModel material) {
    return _ref.doc(material.id).set({
      ...material.toFirestore(),
      'tenantId': tenantId,
      'companyId': tenantId,
    }, SetOptions(merge: true));
  }
}
