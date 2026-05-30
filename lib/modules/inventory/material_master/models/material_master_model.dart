import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class MaterialMasterModel {
  final String id;
  final String materialCode;
  final String materialName;
  final String materialType;
  final String materialShape;
  final String materialGrade;
  final String yieldStrength;
  final String coating;
  final String coatingType;
  final String coatingSpec;
  final double density;
  final String formulaType;
  final String weightFormula;
  final double standardWeightPerMeter;
  final String unit;
  final bool isActive;

  const MaterialMasterModel({
    required this.id,
    required this.materialCode,
    required this.materialName,
    required this.materialType,
    required this.materialShape,
    required this.materialGrade,
    this.yieldStrength = '',
    this.coating = '',
    this.coatingType = '',
    this.coatingSpec = '',
    required this.density,
    required this.formulaType,
    this.weightFormula = '',
    required this.standardWeightPerMeter,
    required this.unit,
    this.isActive = true,
  });

  static const materialTypes = [
    'Plate',
    'Pipe',
    'Round Bar',
    'Flange',
    'Flat',
    'Angle',
    'Channel',
    'C Section',
    'Roofing Sheet',
    'Hollow Section',
    'Beam',
    'Custom',
  ];

  static const densities = {'MS': 7850.0, 'SS304': 8000.0, 'Aluminium': 2700.0};

  String get displayName {
    final code = materialCode.trim();
    final name = materialName.trim();
    if (code.isEmpty) return name;
    if (name.isEmpty) return code;
    return '$code - $name';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materialCode': materialCode,
      'materialName': materialName,
      'materialType': materialType,
      'category': materialType,
      'materialShape': materialShape,
      'shape': materialShape,
      'materialGrade': materialGrade,
      'grade': materialGrade,
      'yieldStrength': yieldStrength,
      'coating': coating,
      'coatingType': coatingType,
      'coatingSpec': coatingSpec,
      'density': density,
      'formulaType': formulaType,
      'weightFormula': weightFormula.isEmpty ? formulaType : weightFormula,
      'standardWeightPerMeter': standardWeightPerMeter,
      'unit': unit,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MaterialMasterModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return MaterialMasterModel.fromMap({...data, 'id': snapshot.id});
  }

  factory MaterialMasterModel.fromMap(Map<String, dynamic> map) {
    return MaterialMasterModel(
      id: (map['id'] ?? '').toString(),
      materialCode: (map['materialCode'] ?? '').toString(),
      materialName: (map['materialName'] ?? '').toString(),
      materialType: (map['materialType'] ?? map['category'] ?? '').toString(),
      materialShape: (map['materialShape'] ?? map['shape'] ?? '').toString(),
      materialGrade: (map['materialGrade'] ?? map['grade'] ?? '').toString(),
      yieldStrength: (map['yieldStrength'] ?? map['grade'] ?? '').toString(),
      coating: (map['coating'] ?? map['coatingType'] ?? '').toString(),
      coatingType: (map['coatingType'] ?? map['coating'] ?? '').toString(),
      coatingSpec: (map['coatingSpec'] ?? '').toString(),
      density: doubleFromValue(map['density']),
      formulaType: (map['formulaType'] ?? map['weightFormula'] ?? '')
          .toString(),
      weightFormula: (map['weightFormula'] ?? map['formulaType'] ?? '')
          .toString(),
      standardWeightPerMeter: doubleFromValue(
        map['standardWeightPerMeter'] ?? map['unitWeightKgPerM'],
      ),
      unit: (map['unit'] ?? 'KG').toString(),
      isActive: map['isActive'] == null ? true : map['isActive'] == true,
    );
  }
}
