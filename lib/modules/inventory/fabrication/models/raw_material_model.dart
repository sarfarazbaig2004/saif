import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class RawMaterialModel {
  final String materialId;
  final String materialCode;
  final String descriptionThickness;
  final String gradeIs;
  final double length;
  final double unitWeight;
  final String uom;
  final String category;
  final String productFamily;
  final double reorderLevel;
  final String remarks;
  final bool isActive;

  const RawMaterialModel({
    required this.materialId,
    required this.materialCode,
    required this.descriptionThickness,
    required this.gradeIs,
    required this.length,
    required this.unitWeight,
    required this.uom,
    required this.category,
    required this.productFamily,
    required this.reorderLevel,
    required this.remarks,
    required this.isActive,
  });

  String get displayName {
    if (materialCode.trim().isEmpty) return descriptionThickness;
    if (descriptionThickness.trim().isEmpty) return materialCode;
    return '$materialCode - $descriptionThickness';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'materialCode': materialCode,
      'descriptionThickness': descriptionThickness,
      'materialDescription': descriptionThickness,
      'gradeIs': gradeIs,
      'grade': gradeIs,
      'length': length,
      'lengthMm': length,
      'unitWeight': unitWeight,
      'unitWeightKgPerM': unitWeight,
      'uom': uom,
      'category': category,
      'rawMaterialCategory': category,
      'productFamily': productFamily,
      'reorderLevel': reorderLevel,
      'remarks': remarks,
      'isActive': isActive,
      'futureTracking': const {
        'heatNumber': true,
        'batchTracking': true,
        'millCertificate': true,
        'qaLinkage': true,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory RawMaterialModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return RawMaterialModel(
      materialId: (data['materialId'] ?? snapshot.id).toString(),
      materialCode: (data['materialCode'] ?? data['itemCode'] ?? '').toString(),
      descriptionThickness:
          (data['descriptionThickness'] ??
                  data['materialDescription'] ??
                  data['description'] ??
                  '')
              .toString(),
      gradeIs: (data['gradeIs'] ?? data['grade'] ?? '').toString(),
      length: doubleFromValue(data['length'] ?? data['lengthMm']),
      unitWeight: doubleFromValue(
        data['unitWeight'] ?? data['unitWeightKgPerM'],
      ),
      uom: (data['uom'] ?? 'Nos').toString(),
      category: (data['category'] ?? data['rawMaterialCategory'] ?? '')
          .toString(),
      productFamily: (data['productFamily'] ?? '').toString(),
      reorderLevel: doubleFromValue(data['reorderLevel']),
      remarks: (data['remarks'] ?? data['notes'] ?? '').toString(),
      isActive: data['isActive'] == null ? true : data['isActive'] == true,
    );
  }
}
