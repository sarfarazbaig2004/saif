import 'package:QUIK/modules/engineering/bom/services/bom_weight_engine.dart';

class EngineeringBomLineModel {
  final int lineNo;
  final String itemDescription;
  final String section;
  final String material;
  final double qty;
  final double lengthMm;
  final double widthMm;
  final double thicknessMm;
  final double odMm;
  final double idMm;
  final double weightPerMeter;
  final double calculatedWeight;
  final double galvanizingMicron;
  final String grade;
  final String materialMasterId;
  final String materialType;
  final String formulaType;
  final double density;

  const EngineeringBomLineModel({
    required this.lineNo,
    required this.itemDescription,
    required this.section,
    required this.material,
    required this.qty,
    required this.lengthMm,
    this.widthMm = 0,
    this.thicknessMm = 0,
    this.odMm = 0,
    this.idMm = 0,
    required this.weightPerMeter,
    required this.calculatedWeight,
    required this.galvanizingMicron,
    required this.grade,
    this.materialMasterId = '',
    this.materialType = '',
    this.formulaType = '',
    this.density = 0,
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
      widthMm: _toDouble(map['widthMm']),
      thicknessMm: _toDouble(map['thicknessMm']),
      odMm: _toDouble(map['odMm']),
      idMm: _toDouble(map['idMm']),
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
      materialMasterId: (map['materialMasterId'] ?? '').toString(),
      materialType: (map['materialType'] ?? '').toString(),
      formulaType: (map['formulaType'] ?? '').toString(),
      density: _toDouble(map['density']),
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
      'widthMm': widthMm,
      'thicknessMm': thicknessMm,
      'odMm': odMm,
      'idMm': idMm,
      'weightPerMeter': weightPerMeter,
      'calculatedWeight': weight,
      'galvanizingMicron': galvanizingMicron,
      'grade': grade,
      'materialMasterId': materialMasterId,
      'materialType': materialType,
      'formulaType': formulaType,
      'density': density,
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
