import 'package:cloud_firestore/cloud_firestore.dart';

class CostingSheetModel {
  final String id;
  final String inquiryId;
  final String inquiryNumber;
  final String customerName;
  final String itemName;
  final double qty;
  final double totalWeightKg;
  final double rawMaterialRatePerKg;
  final double fabricationRatePerKg;
  final double galvanizingRatePerKg;
  final double packingRatePerKg;
  final double freightRatePerKg;
  final double overheadPercent;
  final double marginPercent;
  final double totalCost;
  final double sellingPrice;
  final double ratePerUnit;
  final String bomId;
  final String bomRevision;
  final String bomRevisionId;

  const CostingSheetModel({
    this.id = '',
    required this.inquiryId,
    required this.inquiryNumber,
    required this.customerName,
    required this.itemName,
    required this.qty,
    required this.totalWeightKg,
    required this.rawMaterialRatePerKg,
    required this.fabricationRatePerKg,
    required this.galvanizingRatePerKg,
    required this.packingRatePerKg,
    required this.freightRatePerKg,
    required this.overheadPercent,
    required this.marginPercent,
    required this.totalCost,
    required this.sellingPrice,
    required this.ratePerUnit,
    this.bomId = '',
    this.bomRevision = '',
    this.bomRevisionId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'inquiryId': inquiryId,
      'inquiryNumber': inquiryNumber,
      'customerName': customerName,
      'itemName': itemName,
      'qty': qty,
      'totalWeightKg': totalWeightKg,
      'rawMaterialRatePerKg': rawMaterialRatePerKg,
      'fabricationRatePerKg': fabricationRatePerKg,
      'galvanizingRatePerKg': galvanizingRatePerKg,
      'packingRatePerKg': packingRatePerKg,
      'freightRatePerKg': freightRatePerKg,
      'overheadPercent': overheadPercent,
      'marginPercent': marginPercent,
      'totalCost': totalCost,
      'sellingPrice': sellingPrice,
      'ratePerUnit': ratePerUnit,
      'bomId': bomId,
      'bomRevision': bomRevision,
      'bomRevisionId': bomRevisionId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> quotationItemMap() {
    return {
      'productId': 'costing_$id',
      'name': itemName,
      'description': itemName,
      'quantity': qty,
      'unit': 'Nos',
      'price': ratePerUnit,
      'costPrice': qty <= 0 ? 0 : totalCost / qty,
      'estimatedWeight': totalWeightKg,
      'bomWeight': totalWeightKg,
      'quotationLineType': 'costing',
    };
  }

  static double value(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse((raw ?? '').toString()) ?? 0;
  }

  factory CostingSheetModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CostingSheetModel(
      id: doc.id,
      inquiryId: (data['inquiryId'] ?? '').toString(),
      inquiryNumber: (data['inquiryNumber'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      itemName: (data['itemName'] ?? '').toString(),
      qty: value(data['qty']),
      totalWeightKg: value(data['totalWeightKg']),
      rawMaterialRatePerKg: value(data['rawMaterialRatePerKg']),
      fabricationRatePerKg: value(data['fabricationRatePerKg']),
      galvanizingRatePerKg: value(data['galvanizingRatePerKg']),
      packingRatePerKg: value(data['packingRatePerKg']),
      freightRatePerKg: value(data['freightRatePerKg']),
      overheadPercent: value(data['overheadPercent']),
      marginPercent: value(data['marginPercent']),
      totalCost: value(data['totalCost']),
      sellingPrice: value(data['sellingPrice']),
      ratePerUnit: value(data['ratePerUnit']),
      bomId: (data['bomId'] ?? '').toString(),
      bomRevision: (data['bomRevision'] ?? '').toString(),
      bomRevisionId: (data['bomRevisionId'] ?? '').toString(),
    );
  }
}
