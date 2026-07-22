import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/core/modules/module_registry.dart';
import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_editor.dart';
import 'package:QUIK/core/permissions/vertical_permission_editor.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';

void main() {
  testWidgets('renders one editor and switches independent vertical state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VerticalPermissionEditor(
              verticalStream: Stream.value(const [
                VerticalModel(
                  id: 'vertical-1',
                  name: 'Projects',
                  factoryIds: ['factory-1'],
                  factoryNames: ['Unit 1'],
                ),
                VerticalModel(
                  id: 'vertical-2',
                  name: 'Products',
                  factoryIds: ['factory-2'],
                  factoryNames: ['Unit 2'],
                ),
              ]),
              selectedVerticalIds: const {'vertical-1', 'vertical-2'},
              permissionsByVertical: const {
                'vertical-1': {PermissionKeys.purchaseOrdersView},
                'vertical-2': {PermissionKeys.crmCustomersView},
              },
              fallbackPermissions: const {},
              visibleModuleIds: const {ModuleIds.crm, ModuleIds.purchase},
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PermissionEditor), findsOneWidget);
    expect(find.text('Projects  •  1 selected'), findsOneWidget);
    expect(find.text('Products  •  1 selected'), findsOneWidget);
    expect(find.text('Editing permissions for Projects'), findsOneWidget);
    expect(
      tester
          .widget<PermissionEditor>(find.byType(PermissionEditor))
          .selectedPermissions,
      contains(PermissionKeys.purchaseOrdersView),
    );

    await tester.tap(find.text('Products  •  1 selected'));
    await tester.pumpAndSettle();

    expect(find.byType(PermissionEditor), findsOneWidget);
    expect(find.text('Editing permissions for Products'), findsOneWidget);
    expect(
      tester
          .widget<PermissionEditor>(find.byType(PermissionEditor))
          .selectedPermissions,
      contains(PermissionKeys.crmCustomersView),
    );
    expect(tester.takeException(), isNull);
  });
}
