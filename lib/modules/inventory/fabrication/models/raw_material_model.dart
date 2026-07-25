import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class RawMaterialModel {
  final String materialId;
  final String verticalId;
  final String verticalName;
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
  // Item-master fields. Defaults keep every existing raw_materials document valid.
  final String itemType;
  final String itemCode;
  final String itemName;
  final String brandOrMake;
  final String hsnCode;
  final double gstPercent;
  final double minimumStock;
  final String warehouse;
  final String status;
  final Map<String, dynamic> itemDetails;

  const RawMaterialModel({
    required this.materialId,
    this.verticalId = '',
    this.verticalName = '',
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
    this.itemType = 'raw_material',
    this.itemCode = '',
    this.itemName = '',
    this.brandOrMake = '',
    this.hsnCode = '',
    this.gstPercent = 0,
    this.minimumStock = 0,
    this.warehouse = '',
    this.status = 'active',
    this.itemDetails = const <String, dynamic>{},
  });

  /// Legacy documents have no type and are always raw materials.
  String get effectiveItemType =>
      itemType.trim().isEmpty ? 'raw_material' : itemType;
  String get effectiveItemCode =>
      itemCode.trim().isEmpty ? materialCode : itemCode;
  String get effectiveItemName =>
      itemName.trim().isEmpty ? descriptionThickness : itemName;

  String get displayName {
    if (materialCode.trim().isEmpty) return descriptionThickness;
    if (descriptionThickness.trim().isEmpty) return materialCode;
    return '$materialCode - $descriptionThickness';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'verticalId': verticalId,
      'verticalName': verticalName,
      'itemType': effectiveItemType,
      'itemCode': effectiveItemCode,
      'itemName': effectiveItemName,
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
      'minimumStock': minimumStock,
      'brandOrMake': brandOrMake,
      'hsnCode': hsnCode,
      'gstPercent': gstPercent,
      'warehouse': warehouse,
      'status': status,
      ...itemDetails,
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
      verticalId: (data['verticalId'] ?? '').toString(),
      verticalName: (data['verticalName'] ?? data['vertical'] ?? '').toString(),
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
      itemType: (data['itemType'] ?? 'raw_material').toString(),
      itemCode: (data['itemCode'] ?? data['materialCode'] ?? '').toString(),
      itemName:
          (data['itemName'] ??
                  data['descriptionThickness'] ??
                  data['materialDescription'] ??
                  data['description'] ??
                  '')
              .toString(),
      brandOrMake: (data['brandOrMake'] ?? data['brand'] ?? data['make'] ?? '')
          .toString(),
      hsnCode: (data['hsnCode'] ?? '').toString(),
      gstPercent: doubleFromValue(data['gstPercent']),
      minimumStock: doubleFromValue(
        data['minimumStock'] ?? data['reorderLevel'],
      ),
      warehouse: (data['warehouse'] ?? data['warehouseName'] ?? '').toString(),
      status:
          (data['status'] ??
                  (data['isActive'] == false ? 'inactive' : 'active'))
              .toString(),
      itemDetails: Map<String, dynamic>.from(data),
    );
  }
}
