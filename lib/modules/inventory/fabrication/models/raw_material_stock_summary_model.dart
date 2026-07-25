import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class RawMaterialStockSummaryModel {
  final String itemId;
  final String verticalId;
  final String verticalName;
  final String materialId;
  final String materialCode;
  final String materialDescription;
  final String grade;
  final String rawMaterialCategory;
  final String productFamily;
  final String plantName;
  final String warehouseName;
  final double lengthMm;
  final double unitWeightKgPerM;
  final double openingKg;
  final double inwardKg;
  final double returnKg;
  final double adjustmentKg;
  final double issueKg;
  final double scrapKg;
  final double closingStockKg;
  final double currentOpeningStockKg;
  final double quantityNos;
  final double reorderLevel;
  final String uom;
  final bool weightTracking;
  final DateTime? lastUpdatedAt;

  const RawMaterialStockSummaryModel({
    required this.itemId,
    this.verticalId = '',
    this.verticalName = '',
    required this.materialId,
    required this.materialCode,
    required this.materialDescription,
    required this.grade,
    required this.rawMaterialCategory,
    required this.productFamily,
    required this.plantName,
    required this.warehouseName,
    required this.lengthMm,
    required this.unitWeightKgPerM,
    required this.openingKg,
    required this.inwardKg,
    required this.returnKg,
    required this.adjustmentKg,
    required this.issueKg,
    required this.scrapKg,
    required this.closingStockKg,
    required this.currentOpeningStockKg,
    required this.quantityNos,
    required this.reorderLevel,
    required this.uom,
    required this.weightTracking,
    this.lastUpdatedAt,
  });

  factory RawMaterialStockSummaryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return RawMaterialStockSummaryModel(
      itemId: (data['itemId'] ?? snapshot.id).toString(),
      verticalId: (data['verticalId'] ?? '').toString(),
      verticalName: (data['verticalName'] ?? data['vertical'] ?? '').toString(),
      materialId: (data['materialId'] ?? '').toString(),
      materialCode: (data['materialCode'] ?? '').toString(),
      materialDescription:
          (data['materialDescription'] ?? data['description'] ?? '').toString(),
      grade: (data['grade'] ?? '').toString(),
      rawMaterialCategory: (data['rawMaterialCategory'] ?? '').toString(),
      productFamily: (data['productFamily'] ?? '').toString(),
      plantName: (data['plantName'] ?? data['plant'] ?? '').toString(),
      warehouseName: (data['warehouseName'] ?? data['warehouse'] ?? '')
          .toString(),
      lengthMm: doubleFromValue(data['lengthMm']),
      unitWeightKgPerM: doubleFromValue(data['unitWeightKgPerM']),
      openingKg: doubleFromValue(data['openingKg']),
      inwardKg: doubleFromValue(data['inwardKg']),
      returnKg: doubleFromValue(data['returnKg']),
      adjustmentKg: doubleFromValue(data['adjustmentKg']),
      issueKg: doubleFromValue(data['issueKg']),
      scrapKg: doubleFromValue(data['scrapKg']),
      closingStockKg: doubleFromValue(data['closingStockKg']),
      currentOpeningStockKg: doubleFromValue(data['currentOpeningStockKg']),
      quantityNos: doubleFromValue(data['quantityNos']),
      reorderLevel: doubleFromValue(data['reorderLevel']),
      uom: (data['uom'] ?? 'Kg').toString(),
      weightTracking:
          data['weightTracking'] == true ||
          doubleFromValue(data['unitWeightKgPerM']) > 0,
      lastUpdatedAt: dateTimeFromValue(
        data['lastUpdatedAt'] ?? data['updatedAt'],
      ),
    );
  }
}
