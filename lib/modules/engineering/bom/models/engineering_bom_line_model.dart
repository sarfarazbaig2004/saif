import 'package:QUIK/modules/engineering/bom/services/bom_weight_engine.dart';

class EngineeringBomLineModel {
  final int lineNo;
  final String itemDescription;
  final String section;
  final String material;
  final String materialCategory;
  final String materialName;
  final double qty;
  final double projectQuantity;
  final double totalProjectQuantity;
  final double lengthMm;
  final double widthMm;
  final double thicknessMm;
  final double odMm;
  final double idMm;
  final double heightMm;
  final double weightPerMeter;
  final double calculatedWeight;
  final double totalProjectWeight;
  final double galvanizingMicron;
  final String coatingType;
  final String coatingSpec;
  final String grade;
  final String yieldStrength;
  final String remarks;
  final Map<String, String> customFieldValues;
  final String materialMasterId;
  final String materialType;
  final String formulaType;
  final double density;

  const EngineeringBomLineModel({
    required this.lineNo,
    required this.itemDescription,
    required this.section,
    required this.material,
    this.materialCategory = '',
    this.materialName = '',
    required this.qty,
    this.projectQuantity = 1,
    this.totalProjectQuantity = 0,
    required this.lengthMm,
    this.widthMm = 0,
    this.thicknessMm = 0,
    this.odMm = 0,
    this.idMm = 0,
    this.heightMm = 0,
    required this.weightPerMeter,
    required this.calculatedWeight,
    this.totalProjectWeight = 0,
    required this.galvanizingMicron,
    this.coatingType = '',
    this.coatingSpec = '',
    required this.grade,
    this.yieldStrength = '',
    this.remarks = '',
    this.customFieldValues = const {},
    this.materialMasterId = '',
    this.materialType = '',
    this.formulaType = '',
    this.density = 0,
  });

  factory EngineeringBomLineModel.fromMap(Map<String, dynamic> map) {
    final qty = _toDouble(map['qty'] ?? map['qtyPerStructure']);
    final projectQuantity = _toDouble(map['projectQuantity']);
    final lengthMm = _toDouble(map['lengthMm']);
    final weightPerMeter = _toDouble(
      map['weightPerMeter'] ?? map['unitWeightKgPerMeter'],
    );
    final calculatedWeight = _toDouble(map['calculatedWeight']);
    final lineWeight = calculatedWeight == 0
        ? BomWeightEngine.calculatedWeight(
            qty: qty,
            lengthMm: lengthMm,
            weightPerMeter: weightPerMeter,
          )
        : calculatedWeight;

    return EngineeringBomLineModel(
      lineNo: _toInt(map['lineNo']),
      itemDescription: (map['itemDescription'] ?? '').toString(),
      section: (map['section'] ?? map['sectionCode'] ?? '').toString(),
      material: (map['material'] ?? map['materialName'] ?? '').toString(),
      materialCategory: (map['materialCategory'] ?? map['materialType'] ?? '')
          .toString(),
      materialName: (map['materialName'] ?? map['material'] ?? '').toString(),
      qty: qty,
      projectQuantity: projectQuantity,
      totalProjectQuantity:
          _toDouble(map['totalProjectQuantity']) == 0 && projectQuantity > 0
          ? qty * projectQuantity
          : _toDouble(map['totalProjectQuantity']),
      lengthMm: lengthMm,
      widthMm: _toDouble(map['widthMm']),
      thicknessMm: _toDouble(map['thicknessMm']),
      odMm: _toDouble(map['odMm']),
      idMm: _toDouble(map['idMm']),
      heightMm: _toDouble(map['heightMm']),
      weightPerMeter: weightPerMeter,
      calculatedWeight: lineWeight,
      totalProjectWeight:
          _toDouble(map['totalProjectWeight']) == 0 && projectQuantity > 0
          ? lineWeight * projectQuantity
          : _toDouble(map['totalProjectWeight']),
      galvanizingMicron: _toDouble(map['galvanizingMicron']),
      coatingType: (map['coatingType'] ?? '').toString(),
      coatingSpec: (map['coatingSpec'] ?? '').toString(),
      grade: (map['grade'] ?? '').toString(),
      yieldStrength: (map['yieldStrength'] ?? map['grade'] ?? '').toString(),
      remarks: (map['remarks'] ?? '').toString(),
      customFieldValues: _stringMap(map['customFieldValues']),
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
      'sectionCode': section,
      'material': material,
      'materialCategory': materialCategory,
      'materialName': materialName.isEmpty ? material : materialName,
      'qty': qty,
      'qtyPerStructure': qty,
      'projectQuantity': projectQuantity,
      'totalProjectQuantity': totalProjectQuantity,
      'lengthMm': lengthMm,
      'widthMm': widthMm,
      'thicknessMm': thicknessMm,
      'odMm': odMm,
      'idMm': idMm,
      'heightMm': heightMm,
      'weightPerMeter': weightPerMeter,
      'unitWeightKgPerMeter': weightPerMeter,
      'calculatedWeight': weight,
      'weightPerStructure': weight,
      'totalProjectWeight': totalProjectWeight,
      'galvanizingMicron': galvanizingMicron,
      'coatingType': coatingType,
      'coatingSpec': coatingSpec,
      'grade': grade,
      'yieldStrength': yieldStrength,
      'remarks': remarks,
      'customFieldValues': customFieldValues,
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

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }
}
