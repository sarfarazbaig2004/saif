import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_evaluator.dart';
import 'package:QUIK/core/verticals/active_vertical_scope.dart';

void main() {
  const verticals = [
    ActiveVerticalOption(id: 'vertical-1', name: 'Vertical 1'),
    ActiveVerticalOption(id: 'vertical-2', name: 'Vertical 2'),
    ActiveVerticalOption(id: 'vertical-3', name: 'Vertical 3'),
  ];

  final userData = <String, dynamic>{
    'role': 'sales',
    'verticalIds': ['vertical-1', 'vertical-2'],
    'permissionSchemaVersion': PermissionEvaluator.schemaVersion,
    'permissions': {
      'crm': {
        'customers': {'view': true},
      },
      'purchase': {
        'purchase_orders': {'view': true},
      },
    },
    'verticalPermissions': {
      'vertical-1': {
        'permissions': {
          'purchase': {
            'purchase_orders': {'view': true},
          },
        },
      },
      'vertical-2': {
        'permissions': {
          'crm': {
            'customers': {'view': true},
          },
        },
      },
    },
  };

  test('regular user defaults to the first assigned active vertical', () {
    final state = ActiveVerticalState.resolve(
      userData: userData,
      allActiveVerticals: verticals,
      requestedVerticalId: null,
      isFullAccess: false,
    );

    expect(state.activeVerticalId, 'vertical-1');
    expect(state.availableVerticals.map((vertical) => vertical.id), [
      'vertical-1',
      'vertical-2',
    ]);
    expect(state.allowAllVerticals, isFalse);
    expect(state.isDataScoped, isTrue);
  });

  test('selected vertical uses only its own module permissions', () {
    final state = ActiveVerticalState.resolve(
      userData: userData,
      allActiveVerticals: verticals,
      requestedVerticalId: 'vertical-2',
      isFullAccess: false,
    );
    final evaluator = state.permissionEvaluatorFor(userData);

    expect(evaluator.hasPermission(PermissionKeys.crmCustomersView), isTrue);
    expect(evaluator.hasPermission(PermissionKeys.purchaseOrdersView), isFalse);
    expect(state.canAccessRecord('vertical-2'), isTrue);
    expect(state.canAccessRecord('vertical-1'), isFalse);
  });

  test('configured assignment without permissions fails closed', () {
    final incompleteUserData = <String, dynamic>{
      'role': 'sales',
      'verticalIds': ['vertical-1'],
      'permissionSchemaVersion': PermissionEvaluator.schemaVersion,
      'permissions': {
        'sales': {
          'inquiries': {'view': true},
        },
      },
      'verticalPermissions': <String, dynamic>{},
    };
    final state = ActiveVerticalState.resolve(
      userData: incompleteUserData,
      allActiveVerticals: verticals,
      requestedVerticalId: null,
      isFullAccess: false,
    );

    expect(state.isLegacyUnscoped, isFalse);
    expect(
      state
          .permissionEvaluatorFor(incompleteUserData)
          .hasPermission(PermissionKeys.salesInquiriesView),
      isFalse,
    );
  });

  test('legacy user remains unscoped until assignments are configured', () {
    final state = ActiveVerticalState.resolve(
      userData: {
        'role': 'sales',
        'permissionSchemaVersion': PermissionEvaluator.schemaVersion,
        'permissions': {
          'sales': {
            'inquiries': {'view': true},
          },
        },
      },
      allActiveVerticals: verticals,
      requestedVerticalId: null,
      isFullAccess: false,
    );

    expect(state.isLegacyUnscoped, isTrue);
    expect(state.isDataScoped, isFalse);
    expect(state.canAccessRecord('any-vertical'), isTrue);
    expect(
      state
          .permissionEvaluatorFor({
            'role': 'sales',
            'permissionSchemaVersion': PermissionEvaluator.schemaVersion,
            'permissions': {
              'sales': {
                'inquiries': {'view': true},
              },
            },
          })
          .hasPermission(PermissionKeys.salesInquiriesView),
      isTrue,
    );
  });

  test('super admin can use all verticals or select one', () {
    final allState = ActiveVerticalState.resolve(
      userData: const {'role': 'company_super_admin'},
      allActiveVerticals: verticals,
      requestedVerticalId: null,
      isFullAccess: true,
    );
    final selectedState = ActiveVerticalState.resolve(
      userData: const {'role': 'company_super_admin'},
      allActiveVerticals: verticals,
      requestedVerticalId: 'vertical-3',
      isFullAccess: true,
    );

    expect(allState.allowAllVerticals, isTrue);
    expect(allState.activeVerticalId, isNull);
    expect(allState.canAccessRecord('vertical-1'), isTrue);
    expect(selectedState.activeVerticalId, 'vertical-3');
    expect(selectedState.canAccessRecord('vertical-2'), isFalse);
  });
}
