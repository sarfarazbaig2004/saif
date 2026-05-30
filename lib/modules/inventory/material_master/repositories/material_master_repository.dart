import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';

class MaterialMasterRepository {
  /// Returns all materials (for cleanup/maintenance screens)
  Future<List<MaterialMasterModel>> fetchAllMaterials({int limit = 500}) async {
    final snapshot = await _ref.limit(limit).get();
    return snapshot.docs.map(MaterialMasterModel.fromFirestore).toList();
  }

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

  String get collectionPath => 'companies/${tenantId.trim()}/material_master';

  String newMaterialId() => _ref.doc().id;

  Stream<List<MaterialMasterModel>> watchMaterials() {
    return _ref
        .orderBy('materialName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MaterialMasterModel.fromFirestore)
              .where((material) => material.isActive)
              .toList(growable: false),
        );
  }

  Future<List<MaterialMasterModel>> searchMaterials(String query) async {
    final normalized = query.trim().toLowerCase();
    final snapshot = await _ref.limit(200).get();
    final materials = snapshot.docs
        .map(MaterialMasterModel.fromFirestore)
        .where((material) {
          if (!material.isActive) return false;
          if (normalized.isEmpty) return true;
          final haystack =
              '${material.materialCode} ${material.materialName} ${material.materialType} ${material.materialGrade}'
                  .toLowerCase();
          return haystack.contains(normalized);
        })
        .toList(growable: false);
    return materials;
  }

  Future<MaterialMasterModel?> findByMaterialCode(String materialCode) async {
    final code = materialCode.trim();
    if (code.isEmpty) return null;
    final snapshot = await _ref
        .where('materialCode', isEqualTo: code)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return MaterialMasterModel.fromFirestore(snapshot.docs.first);
  }

  /// Finds a material by normalized material code (deduplication logic)
  Future<MaterialMasterModel?> findByNormalizedMaterialCode(String code) async {
    final normalized = MaterialMasterModel.normalizeMaterialCode(code);
    final snapshot = await _ref.limit(200).get();
    for (final doc in snapshot.docs) {
      final mat = MaterialMasterModel.fromFirestore(doc);
      if (mat.normalizedMaterialCode == normalized) {
        return mat;
      }
    }
    return null;
  }

  /// Enforces uniqueness by normalized material code. Updates existing if duplicate found.
  Future<void> saveMaterial(MaterialMasterModel material) async {
    final normalized = material.normalizedMaterialCode;
    final snapshot = await _ref.limit(200).get();
    MaterialMasterModel? duplicate;
    for (final doc in snapshot.docs) {
      final mat = MaterialMasterModel.fromFirestore(doc);
      if (mat.normalizedMaterialCode == normalized && mat.id != material.id) {
        duplicate = mat;
        break;
      }
    }
    final docId = duplicate?.id ?? material.id;
    await _ref.doc(docId).set({
      ...material.toFirestore(),
      'tenantId': tenantId,
      'companyId': tenantId,
    }, SetOptions(merge: true));
  }
}
