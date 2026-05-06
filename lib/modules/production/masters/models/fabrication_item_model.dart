import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class FabricationItemModel {
  final String itemId;
  final String itemCode;
  final String itemName;
  final String description;
  final String itemType;
  final String category;
  final String rawMaterialCategory;
  final String productFamily;
  final String uom;
  final String section;
  final double standardLength;
  final double unitWeight;
  final bool weightTracking;
  final String makeOrBuy;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FabricationItemModel({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.itemType,
    required this.category,
    required this.rawMaterialCategory,
    required this.productFamily,
    required this.uom,
    required this.section,
    required this.standardLength,
    required this.unitWeight,
    required this.weightTracking,
    required this.makeOrBuy,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'itemCode': itemCode,
      'itemName': itemName,
      'description': description,
      'itemType': itemType,
      'category': category,
      'rawMaterialCategory': rawMaterialCategory,
      'productFamily': productFamily,
      'uom': uom,
      'unit': uom,
      'section': section,
      'standardLength': standardLength,
      'unitWeight': unitWeight,
      'weightTracking': weightTracking,
      'makeOrBuy': makeOrBuy,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory FabricationItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return FabricationItemModel(
      itemId: (data['itemId'] ?? snapshot.id).toString(),
      itemCode: (data['itemCode'] ?? '').toString(),
      itemName: (data['itemName'] ?? data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      itemType: (data['itemType'] ?? 'manufactured').toString(),
      category: (data['category'] ?? '').toString(),
      rawMaterialCategory: (data['rawMaterialCategory'] ?? '').toString(),
      productFamily: (data['productFamily'] ?? '').toString(),
      uom: (data['uom'] ?? data['unit'] ?? 'nos').toString(),
      section: (data['section'] ?? '').toString(),
      standardLength: doubleFromValue(data['standardLength']),
      unitWeight: doubleFromValue(data['unitWeight']),
      weightTracking:
          data['weightTracking'] == true ||
          doubleFromValue(data['unitWeight']) > 0,
      makeOrBuy: (data['makeOrBuy'] ?? 'make').toString(),
      isActive: data['isActive'] != false,
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }
}
