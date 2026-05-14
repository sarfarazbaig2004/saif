import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:QUIK/core/modules/models/tenant_module_access.dart';
import 'package:QUIK/core/modules/module_registry.dart';

class TenantModuleService {
  TenantModuleService({
    FirebaseFirestore? firestore,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheTtl = cacheTtl;

  final FirebaseFirestore _firestore;
  final Duration _cacheTtl;
  final Map<String, _TenantModuleCacheEntry> _cache = {};

  static const Set<String> _defaultEnabledModuleIds = {
    ModuleIds.dashboard,
    ModuleIds.crm,
    ModuleIds.sales,
    ModuleIds.customerPo,
    ModuleIds.projectsJobCards,
    ModuleIds.planningScheduling,
    ModuleIds.engineering,
    ModuleIds.inventoryStore,
    ModuleIds.purchase,
    ModuleIds.production,
    ModuleIds.contractorJobWork,
    ModuleIds.galvanizing,
    ModuleIds.inspectionQa,
    ModuleIds.dispatch,
    ModuleIds.hrAdmin,
    ModuleIds.finance,
    ModuleIds.reports,
    ModuleIds.administration,
    ModuleIds.settings,
  };

  static const Set<String> _requiredModuleIds = {
    ModuleIds.dashboard,
    ModuleIds.administration,
    ModuleIds.settings,
  };

  CollectionReference<Map<String, dynamic>> _modulesRef(String tenantId) {
    return _firestore
        .collection('companies')
        .doc(tenantId.trim())
        .collection('modules');
  }

  DocumentReference<Map<String, dynamic>> _tenantRef(String tenantId) {
    return _firestore.collection('companies').doc(tenantId.trim());
  }

  Future<TenantModuleSeedResult> ensureTenantModulesInitialized({
    required String tenantId,
    required String source,
  }) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) return const TenantModuleSeedResult();

    final companySnap = await _tenantRef(normalizedTenantId).get();

    if (!companySnap.exists) {
      debugPrint(
        'TenantModuleService: skipped module initialization for missing company $normalizedTenantId',
      );
      return const TenantModuleSeedResult(companyMissing: true);
    }

    final modulesRef = _modulesRef(normalizedTenantId);

    final moduleIds = ModuleRegistry.activeModules
        .map((module) => module.id)
        .toList(growable: false);

    final result = await _firestore.runTransaction((transaction) async {
      final existingModuleIds = <String>{};
      final metadataRepairModuleIds = <String>{};

      for (final moduleId in moduleIds) {
        final moduleSnap = await transaction.get(modulesRef.doc(moduleId));

        if (!moduleSnap.exists) continue;

        existingModuleIds.add(moduleId);

        final data = moduleSnap.data() ?? const <String, dynamic>{};
        final module = ModuleRegistry.findById(moduleId);

        final nameWrong = data['name'] != moduleId;
        final labelMissing = (data['label'] ?? '').toString().trim().isEmpty;
        final labelWrong = module != null && data['label'] != module.displayName;
        final requiredDisabled =
            _requiredModuleIds.contains(moduleId) && data['enabled'] != true;

        if (nameWrong || labelMissing || labelWrong || requiredDisabled) {
          metadataRepairModuleIds.add(moduleId);
        }
      }

      final missingModuleIds = moduleIds
          .where((moduleId) => !existingModuleIds.contains(moduleId))
          .toList(growable: false);

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

        transaction.set(
          modulesRef.doc(moduleId),
          {
            'name': moduleId,
            'label': module?.displayName ?? moduleId,
            if (_requiredModuleIds.contains(moduleId)) 'enabled': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      return TenantModuleSeedResult(
        modulesCreated: missingModuleIds.length,
        modulesSkipped: existingModuleIds.length,
        modulesRepaired: metadataRepairModuleIds.length,
      );
    });

    invalidateTenant(normalizedTenantId);

    debugPrint(
      'TenantModuleService: tenant=$normalizedTenantId source=$source '
      'created=${result.modulesCreated}, '
      'skipped=${result.modulesSkipped}, '
      'repaired=${result.modulesRepaired}',
    );

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
      batch.set(
        modulesRef.doc(module.id),
        {
          'name': module.id,
          'label': module.displayName,
          'enabled': safeEnabledModuleIds.contains(module.id),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    invalidateTenant(normalizedTenantId);
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
      return _withRequiredModuleIds(_defaultEnabledModuleIds);
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
    return {
      ...moduleIds,
      ..._requiredModuleIds,
    };
  }

  Stream<List<TenantModuleAccess>> watchTenantModuleAccess(String tenantId) {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) return Stream.value(const []);

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
  final int modulesCreated;
  final int modulesSkipped;
  final int modulesRepaired;
  final bool companyMissing;

  const TenantModuleSeedResult({
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

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(cachedAt) > ttl;
  }
}