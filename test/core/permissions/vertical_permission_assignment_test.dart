import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_evaluator.dart';
import 'package:QUIK/core/permissions/vertical_permission_assignment.dart';

void main() {
  test('keeps permissions independent and derives a compatibility union', () {
    final assignments = <String, Set<String>>{
      'vertical-1': {PermissionKeys.purchaseOrdersView},
      'vertical-2': {PermissionKeys.crmCustomersCreate},
    };

    final union = VerticalPermissionAssignments.unionForVerticals(
      assignments: assignments,
      selectedVerticalIds: const {'vertical-1', 'vertical-2'},
    );

    expect(union, contains(PermissionKeys.purchaseOrdersView));
    expect(union, contains(PermissionKeys.crmCustomersCreate));
    expect(union, contains(PermissionKeys.crmCustomersView));
    expect(
      assignments['vertical-1'],
      isNot(contains(PermissionKeys.crmCustomersView)),
    );
  });

  test('serializes only selected verticals with their own module lists', () {
    final stored = VerticalPermissionAssignments.toStorageMap(
      assignments: {
        'vertical-1': {PermissionKeys.purchaseOrdersView},
        'vertical-2': {PermissionKeys.crmCustomersView},
        'stale-vertical': {PermissionKeys.dashboardView},
      },
      selectedVerticalIds: const {'vertical-1', 'vertical-2'},
    );

    expect(stored.keys, containsAll(const ['vertical-1', 'vertical-2']));
    expect(stored, isNot(contains('stale-vertical')));
    expect(
      (stored['vertical-1'] as Map)['allowedModuleIds'],
      contains('purchase'),
    );
    expect((stored['vertical-2'] as Map)['allowedModuleIds'], contains('crm'));
    expect(VerticalPermissionAssignments.parse(stored), {
      'vertical-1': {PermissionKeys.purchaseOrdersView},
      'vertical-2': {PermissionKeys.crmCustomersView},
    });
  });

  test(
    'future vertical runtime reads scoped permissions with legacy fallback',
    () {
      final userData = <String, dynamic>{
        'role': 'sales',
        'permissions': {
          'crm': {
            'customers': {'view': true},
          },
          'purchase': {
            'purchase_orders': {'view': true},
          },
        },
        'permissionSchemaVersion': 1,
        'verticalPermissions': {
          'vertical-1': {
            'permissions': {
              'purchase': {
                'purchase_orders': {'view': true},
              },
            },
          },
        },
      };

      final scoped = PermissionEvaluator.fromUserDataForVertical(
        userData,
        verticalId: 'vertical-1',
      );
      expect(scoped.hasPermission(PermissionKeys.purchaseOrdersView), isTrue);
      expect(scoped.hasPermission(PermissionKeys.crmCustomersView), isFalse);

      final legacyFallback = PermissionEvaluator.fromUserDataForVertical(
        userData,
        verticalId: 'not-configured',
      );
      expect(
        legacyFallback.hasPermission(PermissionKeys.crmCustomersView),
        isTrue,
      );
    },
  );
}
