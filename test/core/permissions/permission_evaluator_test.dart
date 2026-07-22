import 'package:QUIK/core/modules/module_registry.dart';
import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('permission catalogue', () {
    test('has one ordered, unique canonical key list', () {
      final keys = AmanPermissionCatalogue.orderedKeys;

      expect(keys, isNotEmpty);
      expect(keys.toSet().length, keys.length);
      expect(
        AmanPermissionCatalogue.modules.map((module) => module.order),
        orderedEquals(
          AmanPermissionCatalogue.modules.map((module) => module.order).toList()
            ..sort(),
        ),
      );
    });

    test('every route permission is a known view permission', () {
      for (final permission
          in AmanPermissionCatalogue.routeViewPermission.values) {
        expect(AmanPermissionCatalogue.knownKeys, contains(permission));
        expect(permission, endsWith('.view'));
      }
    });
  });

  group('PermissionEvaluator dependencies', () {
    test('selecting create automatically selects view', () {
      final normalized = PermissionEvaluator.normalizeDependencies({
        PermissionKeys.salesInquiriesCreate,
      });

      expect(normalized, contains(PermissionKeys.salesInquiriesCreate));
      expect(normalized, contains(PermissionKeys.salesInquiriesView));
    });

    test('selecting edit automatically selects view', () {
      final normalized = PermissionEvaluator.normalizeDependencies({
        PermissionKeys.crmCustomersEdit,
      });

      expect(normalized, contains(PermissionKeys.crmCustomersEdit));
      expect(normalized, contains(PermissionKeys.crmCustomersView));
    });

    test('clearing view removes all dependent submodule actions', () {
      final result = PermissionEvaluator.withoutViewAndDependents({
        PermissionKeys.salesInquiriesView,
        PermissionKeys.salesInquiriesCreate,
        PermissionKeys.salesInquiriesEdit,
        PermissionKeys.crmCustomersView,
      }, PermissionKeys.salesInquiriesView);

      expect(result, isNot(contains(PermissionKeys.salesInquiriesView)));
      expect(result, isNot(contains(PermissionKeys.salesInquiriesCreate)));
      expect(result, isNot(contains(PermissionKeys.salesInquiriesEdit)));
      expect(result, contains(PermissionKeys.crmCustomersView));
    });
  });

  group('PermissionEvaluator persistence', () {
    test('serializes only selected leaves in catalogue order', () {
      final stored = PermissionEvaluator.toStorageMap({
        PermissionKeys.salesInquiriesEdit,
        PermissionKeys.dashboardView,
      });

      expect(stored, {
        'dashboard': {
          'overview': {'view': true},
        },
        'sales': {
          'inquiries': {'view': true, 'edit': true},
        },
      });
      expect(stored.keys.toList(), ['dashboard', 'sales']);
    });

    test('round trips canonical nested maps exactly', () {
      final original = {
        PermissionKeys.dispatchReadyCreate,
        PermissionKeys.purchaseOrdersApprove,
      };
      final stored = PermissionEvaluator.toStorageMap(original);
      final parsed = PermissionEvaluator.parsePermissions(stored);

      expect(
        PermissionEvaluator.ordered(parsed.keys),
        PermissionEvaluator.ordered(original),
      );
    });

    test('derives level-one module ids from detailed permissions', () {
      final moduleIds = PermissionEvaluator.deriveAllowedModuleIds({
        PermissionKeys.salesInquiriesView,
        PermissionKeys.dispatchDeliveredView,
      });

      expect(moduleIds, [ModuleIds.sales, ModuleIds.dispatch]);
    });
  });

  group('PermissionEvaluator compatibility and enforcement', () {
    test('legacy module-only users receive full equivalent module access', () {
      final evaluator = PermissionEvaluator.fromUserData({
        'role': 'sales',
        'allowedModuleIds': [ModuleIds.sales],
      });

      expect(evaluator.hasExplicitPermissions, isFalse);
      expect(evaluator.canViewModule(ModuleIds.sales), isTrue);
      expect(
        evaluator.hasPermission(PermissionKeys.salesInquiriesDelete),
        isTrue,
      );
      expect(evaluator.canViewModule(ModuleIds.purchase), isFalse);
    });

    test('pre-v1 empty permission map falls back to legacy modules', () {
      final evaluator = PermissionEvaluator.fromUserData({
        'permissions': <String, dynamic>{},
        'allowedModuleIds': [ModuleIds.crm],
      });

      expect(evaluator.hasExplicitPermissions, isFalse);
      expect(
        evaluator.hasPermission(PermissionKeys.crmCustomersCreate),
        isTrue,
      );
    });

    test('v1 empty permission map means intentional no access', () {
      final evaluator = PermissionEvaluator.fromUserData({
        'permissionSchemaVersion': PermissionEvaluator.schemaVersion,
        'permissions': <String, dynamic>{},
        'allowedModuleIds': [ModuleIds.crm],
      });

      expect(evaluator.hasExplicitPermissions, isTrue);
      expect(evaluator.canViewModule(ModuleIds.crm), isFalse);
    });

    test('ordinary role changes do not add permissions', () {
      final manager = PermissionEvaluator.fromExplicit(
        permissions: {
          'crm': {
            'customers': {'view': true},
          },
        },
        role: 'manager',
      );
      final employee = PermissionEvaluator.fromExplicit(
        permissions: PermissionEvaluator.toStorageMap(manager.permissions),
        role: 'sales',
      );

      expect(employee.permissions, manager.permissions);
      expect(employee.isFullAccess, isFalse);
    });

    test('module and submodule visibility require detailed permission', () {
      final evaluator = PermissionEvaluator.fromExplicit(
        permissions: [PermissionKeys.salesInquiriesView],
      );

      expect(evaluator.canViewModule(ModuleIds.sales), isTrue);
      expect(evaluator.canViewSubmodule(ModuleIds.sales, 'inquiries'), isTrue);
      expect(
        evaluator.canViewSubmodule(ModuleIds.sales, 'quotations'),
        isFalse,
      );
    });

    test('missing route and action permissions are denied', () {
      final evaluator = PermissionEvaluator.fromExplicit(
        permissions: [PermissionKeys.salesInquiriesView],
      );

      final purchaseRoutePermission =
          AmanPermissionCatalogue.routeViewPermission['purchasePurchaseOrders'];
      expect(purchaseRoutePermission, isNotNull);
      expect(evaluator.hasPermission(purchaseRoutePermission!), isFalse);
      expect(
        evaluator.hasPermission(PermissionKeys.salesInquiriesDelete),
        isFalse,
      );
    });

    test('only central super-admin roles bypass detailed permissions', () {
      for (final role in ['software_super_admin', 'company_super_admin']) {
        final evaluator = PermissionEvaluator.fromExplicit(
          permissions: const <String>[],
          role: role,
        );
        expect(
          evaluator.hasPermission(PermissionKeys.purchaseOrdersApprove),
          isTrue,
        );
      }

      for (final role in ['admin', 'manager', 'sales']) {
        final evaluator = PermissionEvaluator.fromExplicit(
          permissions: const <String>[],
          role: role,
        );
        expect(
          evaluator.hasPermission(PermissionKeys.purchaseOrdersApprove),
          isFalse,
        );
      }
    });

    test('unknown persisted permissions are tolerated but never granted', () {
      final evaluator = PermissionEvaluator.fromExplicit(
        permissions: {
          'future_module': {
            'future_area': {'launch': true},
          },
        },
      );

      expect(evaluator.permissions, isEmpty);
      expect(
        evaluator.unknownPermissions,
        contains('future_module.future_area.launch'),
      );
      expect(
        evaluator.hasPermission('future_module.future_area.launch'),
        isFalse,
      );
    });
  });
}
