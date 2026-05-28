import 'package:QUIK/modules/engineering/bom/services/bom_weight_engine.dart';

class EngineeringBomLineModel {
  final int lineNo;
  final String itemDescription;
  final String section;
  final String material;
  final double qty;
  final double lengthMm;
  final double weightPerMeter;
  final double calculatedWeight;
  final double galvanizingMicron;
  final String grade;

  const EngineeringBomLineModel({
    required this.lineNo,
    required this.itemDescription,
    required this.section,
    required this.material,
    required this.qty,
    required this.lengthMm,
    required this.weightPerMeter,
    required this.calculatedWeight,
    required this.galvanizingMicron,
    required this.grade,
  });

  factory EngineeringBomLineModel.fromMap(Map<String, dynamic> map) {
    final qty = _toDouble(map['qty']);
    final lengthMm = _toDouble(map['lengthMm']);
    final weightPerMeter = _toDouble(map['weightPerMeter']);
    final calculatedWeight = _toDouble(map['calculatedWeight']);

    return EngineeringBomLineModel(
      lineNo: _toInt(map['lineNo']),
      itemDescription: (map['itemDescription'] ?? '').toString(),
      section: (map['section'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      qty: qty,
      lengthMm: lengthMm,
      weightPerMeter: weightPerMeter,
      calculatedWeight: calculatedWeight == 0
          ? BomWeightEngine.calculatedWeight(
              qty: qty,
              lengthMm: lengthMm,
              weightPerMeter: weightPerMeter,
            )
          : calculatedWeight,
      galvanizingMicron: _toDouble(map['galvanizingMicron']),
      grade: (map['grade'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final weight = calculatedWeight == 0
        ? BomWeightEngine.calculatedWeight(
            qty: qty,
            lengthMm: lengthMm,
            weightPerMeter: weightPerMeter,
          )
        : calculatedWeight;

    return {
      'lineNo': lineNo,
      'itemDescription': itemDescription,
      'section': section,
      'material': material,
      'qty': qty,
      'lengthMm': lengthMm,
      'weightPerMeter': weightPerMeter,
      'calculatedWeight': weight,
      'galvanizingMicron': galvanizingMicron,
      'grade': grade,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
