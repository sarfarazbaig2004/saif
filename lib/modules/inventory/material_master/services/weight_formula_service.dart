import 'dart:math' as math;

import 'package:QUIK/modules/engineering/bom/services/bom_weight_engine.dart';
import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';

class WeightFormulaInput {
  final String formulaType;
  final String materialGrade;
  final double qty;
  final double lengthMm;
  final double widthMm;
  final double thicknessMm;
  final double odMm;
  final double idMm;
  final double radiusMm;
  final double density;
  final double standardWeightPerMeter;

  const WeightFormulaInput({
    required this.formulaType,
    required this.materialGrade,
    required this.qty,
    required this.lengthMm,
    this.widthMm = 0,
    this.thicknessMm = 0,
    this.odMm = 0,
    this.idMm = 0,
    this.radiusMm = 0,
    this.density = 0,
    this.standardWeightPerMeter = 0,
  });
}

class WeightFormulaService {
  const WeightFormulaService._();

  static double densityForGrade(String grade) {
    final normalized = grade.trim().toLowerCase();
    for (final entry in MaterialMasterModel.densities.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return MaterialMasterModel.densities['MS']!;
  }

  static String formulaTypeForMaterial(String materialType) {
    switch (materialType.trim().toLowerCase()) {
      case 'plate':
      case 'flat':
      case 'flange':
        return 'plate';
      case 'pipe':
        return 'pipe';
      case 'round bar':
      case 'roundbar':
        return 'roundBar';
      case 'angle':
      case 'channel':
      case 'beam':
        return 'sectionWeightPerMeter';
      default:
        return 'sectionWeightPerMeter';
    }
  }

  static double calculateWeight(WeightFormulaInput input) {
    final qty = input.qty <= 0 ? 1.0 : input.qty;
    final density = input.density > 0
        ? input.density
        : densityForGrade(input.materialGrade);

    switch (input.formulaType.trim()) {
      case 'plate':
        return qty *
            _mm3ToM3(input.lengthMm * input.widthMm * input.thicknessMm) *
            density;
      case 'pipe':
        return qty *
            (math.pow(input.odMm, 2) - math.pow(input.idMm, 2)) *
            0.02466 *
            _mmToM(input.lengthMm);
      case 'roundBar':
        final radiusM = _mmToM(
          input.radiusMm > 0 ? input.radiusMm : input.odMm / 2,
        );
        return qty *
            math.pi *
            math.pow(radiusM, 2) *
            _mmToM(input.lengthMm) *
            density;
      case 'sectionWeightPerMeter':
      default:
        return BomWeightEngine.roundWeight(
          qty * _mmToM(input.lengthMm) * input.standardWeightPerMeter,
        );
    }
  }

  static double _mmToM(double value) => value / 1000;

  static double _mm3ToM3(double value) => value / 1000000000;
}
