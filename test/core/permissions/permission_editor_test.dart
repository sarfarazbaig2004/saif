import 'package:QUIK/core/modules/module_registry.dart';
import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('module bodies are lazy and dependency selection stays local', (
    tester,
  ) async {
    var hostBuilds = 0;
    Set<String>? latestSelection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostBuilds++;
              return SingleChildScrollView(
                child: PermissionEditor(
                  selectedPermissions: const <String>{},
                  visibleModuleIds: const {ModuleIds.sales},
                  onChanged: (value) => latestSelection = value,
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Inquiries'), findsNothing);

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();

    expect(find.text('Inquiries'), findsOneWidget);
    expect(find.text('Assign'), findsOneWidget);

    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(latestSelection, contains(PermissionKeys.salesInquiriesAssign));
    expect(latestSelection, contains(PermissionKeys.salesInquiriesView));
    expect(hostBuilds, 1);

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    expect(find.text('Inquiries'), findsNothing);
  });

  testWidgets('MEMCO-style editor remains responsive without overflow', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: PermissionEditor(
                key: ValueKey<double>(size.width),
                selectedPermissions: const {
                  PermissionKeys.salesInquiriesView,
                  PermissionKeys.salesInquiriesCreate,
                },
                visibleModuleIds: const {ModuleIds.sales},
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sales'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await pumpAt(const Size(390, 844));
    expect(find.text('Inquiries'), findsOneWidget);

    await pumpAt(const Size(1440, 1000));
    expect(find.text('Inquiries'), findsOneWidget);
  });
}
