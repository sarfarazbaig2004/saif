import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/modules/administration/users/models/organization_access_selection.dart';
import 'package:QUIK/modules/administration/users/widgets/vertical_factory_access_selector.dart';
import 'package:QUIK/modules/settings/factory_master/factory_model.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';

void main() {
  testWidgets('filters factories and prunes selections when vertical changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _SelectorHarness());
    await tester.pumpAndSettle();

    expect(find.text('Vertical selection'), findsOneWidget);
    expect(find.text('Factory selection'), findsOneWidget);
    expect(find.text('Select a vertical first'), findsOneWidget);
    expect(
      tester
          .widgetList<InputDecorator>(find.byType(InputDecorator))
          .every((decorator) => !decorator.isEmpty),
      isTrue,
      reason: 'Field labels must float above their placeholder text.',
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Select one or more options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects').last);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Select one or more options'), findsOneWidget);

    await tester.tap(find.text('Select one or more options'));
    await tester.pumpAndSettle();
    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text('Unit 2'), findsOneWidget);
    expect(find.text('Unit 3'), findsNothing);
    await tester.tap(find.text('Unit 1'));
    await tester.tap(find.text('Unit 2'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Unit 1, Unit 2'), findsOneWidget);

    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects').last);
    await tester.tap(find.text('Products'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Unit 2'), findsOneWidget);
    expect(find.text('Unit 1, Unit 2'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _SelectorHarness extends StatefulWidget {
  const _SelectorHarness();

  @override
  State<_SelectorHarness> createState() => _SelectorHarnessState();
}

class _SelectorHarnessState extends State<_SelectorHarness> {
  final Stream<List<VerticalModel>> verticalStream = Stream.value(const [
    VerticalModel(
      id: 'vertical-a',
      name: 'Projects',
      factoryIds: ['factory-1', 'factory-2'],
      factoryNames: ['Unit 1', 'Unit 2'],
    ),
    VerticalModel(
      id: 'vertical-b',
      name: 'Products',
      factoryIds: ['factory-2', 'factory-3'],
      factoryNames: ['Unit 2', 'Unit 3'],
    ),
  ]);
  final Stream<List<FactoryModel>> factoryStream = Stream.value(const [
    FactoryModel(id: 'factory-1', plantName: 'Unit 1', address: ''),
    FactoryModel(id: 'factory-2', plantName: 'Unit 2', address: ''),
    FactoryModel(id: 'factory-3', plantName: 'Unit 3', address: ''),
  ]);
  AccessSelectionMode verticalMode = AccessSelectionMode.multiple;
  AccessSelectionMode factoryMode = AccessSelectionMode.multiple;
  final selectedVerticalIds = <String>{};
  final selectedFactoryIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: VerticalFactoryAccessSelector(
            verticalStream: verticalStream,
            factoryStream: factoryStream,
            verticalMode: verticalMode,
            selectedVerticalIds: selectedVerticalIds,
            factoryMode: factoryMode,
            selectedFactoryIds: selectedFactoryIds,
            verticalDecoration: const InputDecoration(
              labelText: 'Vertical',
              border: OutlineInputBorder(),
            ),
            factoryDecoration: const InputDecoration(
              labelText: 'Factory',
              border: OutlineInputBorder(),
            ),
            onVerticalChanged: (mode, ids) {
              setState(() {
                verticalMode = mode;
                selectedVerticalIds
                  ..clear()
                  ..addAll(ids);
              });
            },
            onFactoryChanged: (mode, ids) {
              setState(() {
                factoryMode = mode;
                selectedFactoryIds
                  ..clear()
                  ..addAll(ids);
              });
            },
          ),
        ),
      ),
    );
  }
}
