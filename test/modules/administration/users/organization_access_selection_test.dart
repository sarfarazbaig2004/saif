import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/modules/administration/users/models/organization_access_selection.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';

void main() {
  group('AccessSelectionMode', () {
    test('loads persisted modes with a safe multiple fallback', () {
      expect(
        AccessSelectionMode.fromStorage('single'),
        AccessSelectionMode.single,
      );
      expect(
        AccessSelectionMode.fromStorage('MULTIPLE'),
        AccessSelectionMode.multiple,
      );
      expect(
        AccessSelectionMode.fromStorage(null),
        AccessSelectionMode.multiple,
      );
    });
  });

  group('normalizeSelectionIds', () {
    test('deduplicates and sorts multiple selections', () {
      expect(
        normalizeSelectionIds(const [
          ' vertical-b ',
          'vertical-a',
          'vertical-a',
        ], AccessSelectionMode.multiple),
        {'vertical-a', 'vertical-b'},
      );
    });

    test('single mode keeps one deterministic selection', () {
      expect(
        normalizeSelectionIds(const [
          'vertical-b',
          'vertical-a',
        ], AccessSelectionMode.single),
        {'vertical-a'},
      );
    });
  });

  test('factory options are the union of selected vertical mappings', () {
    const verticals = [
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
    ];

    expect(
      factoryIdsForVerticals(
        verticals: verticals,
        selectedVerticalIds: {'vertical-a', 'vertical-b'},
      ),
      {'factory-1', 'factory-2', 'factory-3'},
    );
    expect(
      factoryIdsForVerticals(
        verticals: verticals,
        selectedVerticalIds: {'vertical-b'},
      ),
      {'factory-2', 'factory-3'},
    );
  });

  test('changing verticals can prune unavailable factory selections', () {
    const verticals = [
      VerticalModel(
        id: 'vertical-a',
        name: 'Projects',
        factoryIds: ['factory-1'],
        factoryNames: ['Unit 1'],
      ),
    ];
    final allowedIds = factoryIdsForVerticals(
      verticals: verticals,
      selectedVerticalIds: {'vertical-a'},
    );
    final pruned = normalizeSelectionIds(
      {'factory-1', 'factory-2'}.where(allowedIds.contains),
      AccessSelectionMode.multiple,
    );

    expect(pruned, {'factory-1'});
  });
}
