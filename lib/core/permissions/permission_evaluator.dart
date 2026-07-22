import 'package:QUIK/core/modules/module_registry.dart';
import 'package:QUIK/core/permissions/permission_catalogue.dart';

class PermissionSelection {
  final Set<String> keys;
  final Set<String> unknownKeys;

  const PermissionSelection({required this.keys, required this.unknownKeys});
}

/// Canonical parser, dependency normalizer, serializer, and runtime evaluator.
class PermissionEvaluator {
  static const int schemaVersion = 1;
  static const Set<String> fullAccessRoles = {
    'software_super_admin',
    'company_super_admin',
  };

  final Set<String> permissions;
  final Set<String> unknownPermissions;
  final bool hasExplicitPermissions;
  final Set<String> legacyAllowedModuleIds;
  final String role;

  PermissionEvaluator({
    required Iterable<String> permissions,
    this.unknownPermissions = const {},
    this.hasExplicitPermissions = true,
    this.legacyAllowedModuleIds = const {},
    this.role = '',
  }) : permissions = normalizeDependencies(permissions);

  factory PermissionEvaluator.fromUserData(Map<String, dynamic> data) {
    final parsed = parsePermissions(data['permissions']);
    final allowedModuleIds = _stringSet(data['allowedModuleIds']);
    final storedSchemaVersion = switch (data['permissionSchemaVersion']) {
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    // Before schema v1, several records contained an empty `permissions` map
    // next to the real level-one module selection. Treat only that legacy
    // shape as a module fallback. A v1 empty map is an intentional no-access
    // selection and must never silently regain access.
    final hasExplicitPermissions =
        data.containsKey('permissions') &&
        (storedSchemaVersion >= schemaVersion ||
            parsed.keys.isNotEmpty ||
            parsed.unknownKeys.isNotEmpty);
    return PermissionEvaluator(
      permissions: hasExplicitPermissions
          ? parsed.keys
          : expandLegacyModuleIds(allowedModuleIds),
      unknownPermissions: parsed.unknownKeys,
      hasExplicitPermissions: hasExplicitPermissions,
      legacyAllowedModuleIds: allowedModuleIds,
      role: (data['role'] ?? '').toString(),
    );
  }

  /// Future vertical-aware runtime entry point. Until modules are switched to
  /// a vertical context, callers continue using [fromUserData], whose stored
  /// permissions are the compatibility union of all selected verticals.
  factory PermissionEvaluator.fromUserDataForVertical(
    Map<String, dynamic> data, {
    required String verticalId,
  }) {
    final assignments = data['verticalPermissions'];
    final assignment = assignments is Map ? assignments[verticalId] : null;
    if (assignment is Map && assignment.containsKey('permissions')) {
      return PermissionEvaluator.fromExplicit(
        permissions: assignment['permissions'],
        allowedModuleIds: _stringSet(assignment['allowedModuleIds']),
        role: (data['role'] ?? '').toString(),
      );
    }
    return PermissionEvaluator.fromUserData(data);
  }

  factory PermissionEvaluator.fromExplicit({
    required dynamic permissions,
    String role = '',
    Iterable<String> allowedModuleIds = const [],
    bool hasExplicitPermissions = true,
  }) {
    final parsed = parsePermissions(permissions);
    final legacyIds = allowedModuleIds.toSet();
    return PermissionEvaluator(
      permissions: hasExplicitPermissions
          ? parsed.keys
          : expandLegacyModuleIds(legacyIds),
      unknownPermissions: parsed.unknownKeys,
      hasExplicitPermissions: hasExplicitPermissions,
      legacyAllowedModuleIds: legacyIds,
      role: role,
    );
  }

  bool get isFullAccess => fullAccessRoles.contains(role.trim().toLowerCase());

  bool hasPermission(String key) => isFullAccess || permissions.contains(key);

  bool hasAnyPermission(Iterable<String> keys) =>
      isFullAccess || keys.any(permissions.contains);

  bool hasAllPermissions(Iterable<String> keys) =>
      isFullAccess || keys.every(permissions.contains);

  bool canViewModule(String moduleId) =>
      isFullAccess || permissions.any((key) => key.startsWith('$moduleId.'));

  bool canViewSubmodule(String moduleId, String submoduleId) =>
      hasPermission('$moduleId.$submoduleId.${PermissionActionIds.view}');

  static PermissionSelection parsePermissions(dynamic raw) {
    final selected = <String>{};
    final unknown = <String>{};

    void addKey(String rawKey) {
      final key = _canonicalizeLegacyKey(rawKey);
      if (key == null) return;
      if (AmanPermissionCatalogue.knownKeys.contains(key)) {
        selected.add(key);
      } else {
        unknown.add(rawKey);
      }
    }

    if (raw is Iterable && raw is! String) {
      for (final value in raw) {
        addKey(value.toString().trim());
      }
    } else if (raw is Map) {
      for (final moduleEntry in raw.entries) {
        final module = _canonicalModuleId(moduleEntry.key.toString());
        final moduleValue = moduleEntry.value;
        if (moduleEntry.key.toString().contains('.') && moduleValue == true) {
          addKey(moduleEntry.key.toString());
          continue;
        }
        if (moduleValue is! Map) continue;

        for (final submoduleEntry in moduleValue.entries) {
          final submodule = _canonicalSubmoduleId(
            module,
            submoduleEntry.key.toString(),
          );
          final submoduleValue = submoduleEntry.value;
          if (submoduleValue == true) {
            addKey('$module.$submodule.view');
            continue;
          }
          if (submoduleValue is! Map) {
            if (module == ModuleIds.dashboard && submoduleValue == true) {
              addKey(PermissionKeys.dashboardView);
            }
            continue;
          }
          for (final actionEntry in submoduleValue.entries) {
            if (actionEntry.value == true) {
              addKey('$module.$submodule.${actionEntry.key}');
            }
          }
        }

        // Legacy dashboard was shaped as {dashboard: {view: true}} or
        // {dashboard: {dashboard: true}} instead of a normal submodule.
        if (module == ModuleIds.dashboard &&
            (moduleValue['view'] == true || moduleValue['dashboard'] == true)) {
          addKey(PermissionKeys.dashboardView);
        }
      }
    }

    return PermissionSelection(
      keys: normalizeDependencies(selected),
      unknownKeys: unknown,
    );
  }

  static Set<String> normalizeDependencies(Iterable<String> input) {
    final result = input
        .where(AmanPermissionCatalogue.knownKeys.contains)
        .toSet();
    for (final key in result.toList(growable: false)) {
      final viewKey = AmanPermissionCatalogue.viewKeyFor(key);
      if (viewKey != null) result.add(viewKey);
    }
    return result;
  }

  static Set<String> withoutViewAndDependents(
    Iterable<String> input,
    String viewKey,
  ) {
    final submodule = AmanPermissionCatalogue.submoduleForKey(viewKey);
    if (submodule == null) return input.toSet()..remove(viewKey);
    final prefix = '${submodule.moduleId}.${submodule.id}.';
    return input.where((key) => !key.startsWith(prefix)).toSet();
  }

  static Set<String> expandLegacyModuleIds(Iterable<String> moduleIds) {
    final normalizedIds = moduleIds.map(_canonicalModuleId).toSet();
    return {
      for (final key in AmanPermissionCatalogue.orderedKeys)
        if (normalizedIds.contains(key.split('.').first)) key,
    };
  }

  static List<String> ordered(Iterable<String> keys) {
    final values = normalizeDependencies(keys);
    return AmanPermissionCatalogue.orderedKeys
        .where(values.contains)
        .toList(growable: false);
  }

  /// Stores only selected leaves. Map insertion order follows the catalogue.
  static Map<String, dynamic> toStorageMap(Iterable<String> keys) {
    final result = <String, dynamic>{};
    for (final key in ordered(keys)) {
      final parts = key.split('.');
      final module =
          result.putIfAbsent(parts[0], () => <String, dynamic>{})
              as Map<String, dynamic>;
      final submodule =
          module.putIfAbsent(parts[1], () => <String, bool>{})
              as Map<String, bool>;
      submodule[parts[2]] = true;
    }
    return result;
  }

  static List<String> deriveAllowedModuleIds(Iterable<String> keys) {
    final selected = normalizeDependencies(keys);
    return AmanPermissionCatalogue.modules
        .where(
          (module) => selected.any((key) => key.startsWith('${module.id}.')),
        )
        .map((module) => module.id)
        .toList(growable: false);
  }

  static Set<String> _stringSet(dynamic raw) {
    if (raw is! Iterable || raw is String) return <String>{};
    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static String _canonicalModuleId(String raw) {
    switch (raw.trim()) {
      case 'inventory':
        return ModuleIds.inventoryStore;
      case 'hr':
        return ModuleIds.hrAdmin;
      case 'customerPo':
        return ModuleIds.customerPo;
      case 'projectsJobCards':
        return ModuleIds.projectsJobCards;
      case 'planningScheduling':
        return ModuleIds.planningScheduling;
      default:
        return raw.trim();
    }
  }

  static String _canonicalSubmoduleId(String module, String raw) {
    const aliases = {
      'dashboard.dashboard': 'overview',
      'crm.customerVisits': 'follow_ups',
      'crm.communicationHistory': 'follow_ups',
      'sales.salesOrder': 'sales_orders',
      'sales.salesOrders': 'sales_orders',
      'sales.followUps': 'follow_ups',
      'customer_po.customerPo': 'orders',
      'projects_job_cards.projects': 'projects',
      'projects_job_cards.jobCards': 'job_cards',
      'planning_scheduling.planning': 'planning_board',
      'engineering.engineering': 'bom_boq',
      'inventory_store.products': 'material_master',
      'inventory_store.stockSummary': 'stock_summary',
      'inventory_store.stockIn': 'material_inward',
      'inventory_store.stockOut': 'material_issue',
      'inventory_store.warehouse': 'stock_summary',
      'inventory_store.lowStockAlerts': 'low_stock',
      'purchase.purchaseOrders': 'purchase_orders',
      'purchase.grnMaterialReceipt': 'grn',
      'purchase.vendorLedger': 'vendor_ledger',
      'purchase.vendorOffers': 'vendor_offers',
      'production.materialRequirements': 'material_requirements',
      'production.jobCards': 'entries',
      'dispatch.readyForDispatch': 'ready',
      'dispatch.dispatchChallans': 'challans',
      'dispatch.shipmentTracking': 'tracking',
      'dispatch.deliveredOrders': 'delivered',
      'hr_admin.employees': 'employees',
      'hr_admin.attendance': 'attendance',
      'hr_admin.wages': 'wages',
      'finance.proformaInvoice': 'proforma',
      'finance.taxInvoice': 'invoices',
      'finance.paymentReceived': 'payments_received',
      'finance.outstanding': 'outstanding',
      'finance.expenseEntries': 'expenses',
      'reports.salesReport': 'sales',
      'reports.inquiryReport': 'inquiry',
      'reports.customerReport': 'customer',
      'reports.productReport': 'product',
      'reports.paymentReport': 'payment',
      'administration.rolesPermissions': 'roles',
      'administration.complianceLegal': 'compliance',
      'administration.companyProfile': 'company_profile',
      'administration.auditLogs': 'audit_logs',
    };
    return aliases['$module.$raw'] ?? raw;
  }

  static String? _canonicalizeLegacyKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split('.');
    if (parts.length == 2) {
      final module = _canonicalModuleId(parts[0]);
      final submodule = _canonicalSubmoduleId(module, parts[1]);
      return '$module.$submodule.view';
    }
    if (parts.length != 3) return trimmed;
    final module = _canonicalModuleId(parts[0]);
    final submodule = _canonicalSubmoduleId(module, parts[1]);
    return '$module.$submodule.${parts[2]}';
  }
}
