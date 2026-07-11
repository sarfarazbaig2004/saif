import 'package:flutter_test/flutter_test.dart';
import 'package:QUIK/modules/inventory/fabrication/services/material_inward_weight_calculator.dart';

void main() {
  group('GRN received weight', () {
    double calculate(String quantity, {double length = 6}) =>
        calculateMaterialInwardWeightKg(
          unitWeightKgPerMeter: 19.2,
          lengthMeter: length,
          receivedQuantityNos: double.tryParse(quantity) ?? 0,
        );

    test('150 pieces', () => expect(calculate('150'), 17280));
    test('one piece', () => expect(calculate('1'), closeTo(115.2, 0.000001)));
    test('zero length', () => expect(calculate('150', length: 0), 0));
    test('blank quantity', () => expect(calculate(''), 0));
    test('invalid quantity', () => expect(calculate('invalid'), 0));

    test('quantity change recalculates', () {
      expect(calculate('1'), closeTo(115.2, 0.000001));
      expect(calculate('150'), 17280);
    });

    test('editing an existing GRN replaces its old kg calculation', () {
      const previouslySavedKg = 0.115;
      final recalculatedKg = calculate('150');

      expect(recalculatedKg, isNot(previouslySavedKg));
      expect(recalculatedKg, 17280);
    });

    test('formats final kg with up to three decimals', () {
      expect(formatMaterialInwardWeightKg(17280), '17280');
      expect(formatMaterialInwardWeightKg(115.2), '115.2');
      expect(formatMaterialInwardWeightKg(1.2344), '1.234');
    });
  });
}
