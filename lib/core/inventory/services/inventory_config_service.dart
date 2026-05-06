import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:QUIK/core/app/aman_app_config.dart';
import 'package:QUIK/core/inventory/models/inventory_profile_config.dart';

class InventoryConfigService {
  InventoryConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profileRef(String tenantId) {
    return _firestore
        .collection('companies')
        .doc(tenantId)
        .collection('inventory_config')
        .doc('profile');
  }

  Future<InventoryProfileConfig> fetchProfile(String tenantId) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) {
      return InventoryProfileConfig.general();
    }

    final snapshot = await _profileRef(normalizedTenantId).get();
    if (!snapshot.exists) {
      return InventoryProfileConfig.general();
    }

    return InventoryProfileConfig.fromFirestore(snapshot);
  }

  Future<InventoryProfileConfig> ensureDefaultProfile({
    required String tenantId,
    String source = 'system',
    Map<String, dynamic>? companyData,
    InventoryProfileConfig? profile,
  }) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) {
      return InventoryProfileConfig.general();
    }

    final ref = _profileRef(normalizedTenantId);
    final defaultProfile =
        profile ??
        _defaultProfileForTenant(normalizedTenantId, companyData ?? const {});

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        debugPrint(
          'InventoryConfigService: existing profile kept for $normalizedTenantId',
        );
        return;
      }

      transaction.set(ref, {
        ...defaultProfile.toFirestore(),
        'companyId': normalizedTenantId,
        'tenantId': normalizedTenantId,
        'createdBy': source,
        'updatedBy': source,
      });

      debugPrint(
        'InventoryConfigService: default profile created for $normalizedTenantId',
      );
    });

    return fetchProfile(normalizedTenantId);
  }

  Future<InventoryProfileConfig> ensureDefaultProfileFromCompany({
    required String tenantId,
    String source = 'system',
  }) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) {
      return InventoryProfileConfig.general();
    }

    Map<String, dynamic> companyData = const {};
    try {
      final companySnap = await _firestore
          .collection('companies')
          .doc(normalizedTenantId)
          .get();
      companyData = companySnap.data() ?? const {};
    } catch (e) {
      debugPrint(
        'InventoryConfigService: company lookup skipped for $normalizedTenantId: $e',
      );
    }

    return ensureDefaultProfile(
      tenantId: normalizedTenantId,
      source: source,
      companyData: companyData,
    );
  }

  Future<void> saveProfile({
    required String tenantId,
    required InventoryProfileConfig profile,
    String source = 'admin',
  }) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) return;

    await _profileRef(normalizedTenantId).set({
      ...profile.toFirestore(),
      'companyId': normalizedTenantId,
      'tenantId': normalizedTenantId,
      'updatedBy': source,
    }, SetOptions(merge: true));
  }

  InventoryProfileConfig _defaultProfileForTenant(
    String tenantId,
    Map<String, dynamic> companyData,
  ) {
    return tenantId.trim() == AmanAppConfig.tenantId ||
            _isFabricationCompany(companyData)
        ? InventoryProfileConfig.fabrication()
        : InventoryProfileConfig.general();
  }

  bool _isFabricationCompany(Map<String, dynamic> companyData) {
    final industryText = [
      companyData['industryType'],
      companyData['businessCategory'],
      companyData['industry'],
      companyData['subIndustry'],
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');

    return industryText.contains('fabrication');
  }
}
