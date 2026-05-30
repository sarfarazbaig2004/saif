import 'package:QUIK/modules/engineering/bom/services/bom_weight_engine.dart';
import 'package:QUIK/modules/inventory/material_master/services/weight_formula_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('section weight uses length in meters, not millimeters', () {
    final weight = BomWeightEngine.calculatedWeight(
      qty: 1310,
      lengthMm: 1969,
      weightPerMeter: 3.54,
    );

    expect(weight, closeTo(9131.041, 0.001));
  });

  test(
    'BOM screen weight formula uses lengthMm / 1000 for std kg per meter',
    () {
      final weight = WeightFormulaService.calculateWeight(
        const WeightFormulaInput(
          formulaType: 'sectionWeightPerMeter',
          materialGrade: 'MS',
          qty: 1310,
          lengthMm: 1969,
          standardWeightPerMeter: 3.54,
        ),
      );

      expect(weight, closeTo(9131.041, 0.001));
    },
  );
}
