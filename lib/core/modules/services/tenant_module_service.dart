import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/core/modules/models/tenant_module_access.dart';
import 'package:QUIK/core/modules/module_registry.dart';

class TenantModuleService {
  TenantModuleService({
    FirebaseFirestore? firestore,
    Duration cacheTtl = const Duration(minutes: 5),
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheTtl = cacheTtl;

  final FirebaseFirestore _firestore;
  final Duration _cacheTtl;
  final Map<String, _TenantModuleCacheEntry> _cache = {};

  static const Set<String> _defaultEnabledModuleIds = {
    ModuleIds.administration,
    ModuleIds.crm,
    ModuleIds.sales,
    ModuleIds.service,
    ModuleIds.inventory,
    ModuleIds.dispatch,
    ModuleIds.finance,
    ModuleIds.production,
    ModuleIds.reports,
    ModuleIds.settings,
  };

  CollectionReference<Map<String, dynamic>> _modulesRef(String tenantId) {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('modules');
  }

  DocumentReference<Map<String, dynamic>> _tenantRef(String tenantId) {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).companyRef;
  }

  Future<TenantModuleSeedResult> ensureTenantModulesInitialized({
    required String tenantId,
    required String source,
  }) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) {
      return const TenantModuleSeedResult();
    }

    final companySnap = await _firestore
        .collection('companies')
        .doc(normalizedTenantId)
        .get();

    if (!companySnap.exists) {
      debugPrint(
        'TenantModuleService: skipped module initialization for missing company $normalizedTenantId',
      );
      return const TenantModuleSeedResult(companyMissing: true);
    }

    final tenantRef = _tenantRef(normalizedTenantId);
    final modulesRef = _modulesRef(normalizedTenantId);
    final moduleIds = ModuleRegistry.activeModules
        .map((module) => module.id)
        .toList(growable: false);

    final result = await _firestore.runTransaction((transaction) async {
      final tenantSnap = await transaction.get(tenantRef);
      final existingModuleIds = <String>{};
      final metadataRepairModuleIds = <String>{};

      for (final moduleId in moduleIds) {
        final moduleSnap = await transaction.get(modulesRef.doc(moduleId));
        if (moduleSnap.exists) {
          existingModuleIds.add(moduleId);
          final data = moduleSnap.data() ?? const <String, dynamic>{};
          if (data['name'] != moduleId ||
              (data['label'] ?? '').toString().trim().isEmpty ||
              (_defaultEnabledModuleIds.contains(moduleId) &&
                  data['enabled'] != true)) {
            metadataRepairModuleIds.add(moduleId);
          }
        }
      }

      final missingModuleIds = moduleIds
          .where((moduleId) => !existingModuleIds.contains(moduleId))
          .toList(growable: false);

      if (!tenantSnap.exists) {
        transaction.set(tenantRef, {
          'tenantId': normalizedTenantId,
          'companyId': normalizedTenantId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'moduleSeedSource': source,
        });
      }

      for (final moduleId in missingModuleIds) {
        final module = ModuleRegistry.findById(moduleId);
        transaction.set(modulesRef.doc(moduleId), {
          'name': moduleId,
          'label': module?.displayName ?? moduleId,
          'enabled': _defaultEnabledModuleIds.contains(moduleId),
          'features': const <String, dynamic>{},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (final moduleId in metadataRepairModuleIds) {
        final module = ModuleRegistry.findById(moduleId);
        transaction.set(modulesRef.doc(moduleId), {
          'name': moduleId,
          'label': module?.displayName ?? moduleId,
          if (_defaultEnabledModuleIds.contains(moduleId)) 'enabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return TenantModuleSeedResult(
        tenantCreated: !tenantSnap.exists,
        modulesCreated: missingModuleIds.length,
        modulesSkipped: existingModuleIds.length,
        modulesRepaired: metadataRepairModuleIds.length,
      );
    });

    invalidateTenant(normalizedTenantId);
    if (result.tenantCreated) {
      debugPrint(
        'TenantModuleService: seeded tenant $normalizedTenantId from $source with ${result.modulesCreated} module docs',
      );
    } else if (result.modulesCreated > 0) {
      debugPrint(
        'TenantModuleService: backfilled tenant $normalizedTenantId from $source with ${result.modulesCreated} missing module docs',
      );
    } else if (result.modulesRepaired > 0) {
      debugPrint(
        'TenantModuleService: repaired tenant $normalizedTenantId from $source with ${result.modulesRepaired} module metadata updates',
      );
    } else {
      debugPrint(
        'TenantModuleService: skipped existing module docs for tenant $normalizedTenantId',
      );
    }
    return result;
  }

  Future<void> saveEnabledModuleIds({
    required String tenantId,
    required Set<String> enabledModuleIds,
  }) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) return;

    final batch = _firestore.batch();
    final modulesRef = _modulesRef(normalizedTenantId);
    final safeEnabledModuleIds = _withRequiredModuleIds(enabledModuleIds);

    for (final module in ModuleRegistry.activeModules) {
      batch.set(modulesRef.doc(module.id), {
        'name': module.id,
        'label': module.displayName,
        'enabled': safeEnabledModuleIds.contains(module.id),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    invalidateTenant(normalizedTenantId);
    debugPrint(
      'TenantModuleService: saved ${ModuleRegistry.activeModules.length} module access docs for tenant $normalizedTenantId',
    );
  }

  Future<void> configureNewWorkspaceModules({
    required String tenantId,
    required Set<String> enabledModuleIds,
    required String source,
  }) async {
    final seedResult = await ensureTenantModulesInitialized(
      tenantId: tenantId,
      source: source,
    );

    if (seedResult.companyMissing) return;

    await saveEnabledModuleIds(
      tenantId: tenantId,
      enabledModuleIds: enabledModuleIds,
    );

    debugPrint(
      'TenantModuleService: configured new workspace $tenantId module selection from $source',
    );
  }

  Future<List<TenantModuleAccess>> fetchTenantModuleAccess(
    String tenantId, {
    bool forceRefresh = false,
  }) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) return const [];

    final cached = _cache[normalizedTenantId];
    if (!forceRefresh && cached != null && !cached.isExpired(_cacheTtl)) {
      return cached.modules;
    }

    final snapshot = await _modulesRef(normalizedTenantId).get();
    final modules = snapshot.docs
        .map(
          (doc) => TenantModuleAccess.fromFirestore(
            tenantId: normalizedTenantId,
            snapshot: doc,
          ),
        )
        .toList(growable: false);

    _cache[normalizedTenantId] = _TenantModuleCacheEntry(modules);
    debugPrint(
      'TenantModuleService: loaded ${modules.length} module access docs for tenant $normalizedTenantId',
    );

    return modules;
  }

  Future<Set<String>> fetchEnabledModuleIds(
    String tenantId, {
    bool forceRefresh = false,
    bool fallbackToActiveRegistryWhenUnconfigured = true,
  }) async {
    final access = await fetchTenantModuleAccess(
      tenantId,
      forceRefresh: forceRefresh,
    );

    if (access.isEmpty && fallbackToActiveRegistryWhenUnconfigured) {
      return _withRequiredModuleIds(
        ModuleRegistry.activeModules.map((module) => module.id).toSet(),
      );
    }

    final enabledModuleIds = access
        .where((moduleAccess) {
          final module = ModuleRegistry.findById(moduleAccess.moduleId);
          return moduleAccess.enabled && module != null && module.isActive;
        })
        .map((moduleAccess) => moduleAccess.moduleId)
        .toSet();

    return _withRequiredModuleIds(enabledModuleIds);
  }

  Set<String> _withRequiredModuleIds(Set<String> moduleIds) {
    return {...moduleIds, ModuleIds.administration, ModuleIds.settings};
  }

  Stream<List<TenantModuleAccess>> watchTenantModuleAccess(String tenantId) {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) {
      return Stream.value(const []);
    }

    return _modulesRef(normalizedTenantId).snapshots().map((snapshot) {
      final modules = snapshot.docs
          .map(
            (doc) => TenantModuleAccess.fromFirestore(
              tenantId: normalizedTenantId,
              snapshot: doc,
            ),
          )
          .toList(growable: false);

      _cache[normalizedTenantId] = _TenantModuleCacheEntry(modules);
      return modules;
    });
  }

  void invalidateTenant(String tenantId) {
    _cache.remove(tenantId.trim());
  }

  void clearCache() {
    _cache.clear();
  }
}

class TenantModuleSeedResult {
  final bool tenantCreated;
  final int modulesCreated;
  final int modulesSkipped;
  final int modulesRepaired;
  final bool companyMissing;

  const TenantModuleSeedResult({
    this.tenantCreated = false,
    this.modulesCreated = 0,
    this.modulesSkipped = 0,
    this.modulesRepaired = 0,
    this.companyMissing = false,
  });
}

class _TenantModuleCacheEntry {
  final List<TenantModuleAccess> modules;
  final DateTime cachedAt;

  _TenantModuleCacheEntry(this.modules) : cachedAt = DateTime.now();

  bool isExpired(Duration ttl) => DateTime.now().difference(cachedAt) > ttl;
}
