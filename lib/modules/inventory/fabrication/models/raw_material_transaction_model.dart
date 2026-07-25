import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

enum RawMaterialTransactionType {
  opening,
  inward,
  issue,
  returnMaterial,
  scrap,
  adjustment,
}

extension RawMaterialTransactionTypeX on RawMaterialTransactionType {
  String get key {
    switch (this) {
      case RawMaterialTransactionType.opening:
        return 'opening';
      case RawMaterialTransactionType.inward:
        return 'inward';
      case RawMaterialTransactionType.issue:
        return 'issue';
      case RawMaterialTransactionType.returnMaterial:
        return 'return';
      case RawMaterialTransactionType.scrap:
        return 'scrap';
      case RawMaterialTransactionType.adjustment:
        return 'adjustment';
    }
  }

  String get label {
    switch (this) {
      case RawMaterialTransactionType.opening:
        return 'Opening';
      case RawMaterialTransactionType.inward:
        return 'Inward';
      case RawMaterialTransactionType.issue:
        return 'Issue';
      case RawMaterialTransactionType.returnMaterial:
        return 'Return';
      case RawMaterialTransactionType.scrap:
        return 'Scrap';
      case RawMaterialTransactionType.adjustment:
        return 'Adjustment';
    }
  }

  int get stockSign {
    switch (this) {
      case RawMaterialTransactionType.issue:
      case RawMaterialTransactionType.scrap:
        return -1;
      case RawMaterialTransactionType.opening:
      case RawMaterialTransactionType.inward:
      case RawMaterialTransactionType.returnMaterial:
      case RawMaterialTransactionType.adjustment:
        return 1;
    }
  }

  static RawMaterialTransactionType fromKey(String value) {
    switch (value.trim().toLowerCase()) {
      case 'opening':
        return RawMaterialTransactionType.opening;
      case 'issue':
        return RawMaterialTransactionType.issue;
      case 'return':
        return RawMaterialTransactionType.returnMaterial;
      case 'scrap':
        return RawMaterialTransactionType.scrap;
      case 'adjustment':
        return RawMaterialTransactionType.adjustment;
      case 'inward':
      default:
        return RawMaterialTransactionType.inward;
    }
  }
}

class RawMaterialTransactionModel {
  final String transactionId;
  final String verticalId;
  final String verticalName;
  final RawMaterialTransactionType transactionType;
  final DateTime? transactionDate;
  final String materialId;
  final String materialCode;
  final String materialDescription;
  final String grade;
  final double length;
  final double unitWeight;
  final String uom;
  final String category;
  final String productFamily;
  final String plantName;
  final String warehouseName;
  final double quantityNos;
  final double quantityKg;
  final String referenceNo;
  final String partyOrProcess;
  final String workOrderId;
  final String heatNumber;
  final String batchNo;
  final String millCertificateUrl;
  final String qaReferenceId;
  final String remarks;

  const RawMaterialTransactionModel({
    required this.transactionId,
    this.verticalId = '',
    this.verticalName = '',
    required this.transactionType,
    this.transactionDate,
    required this.materialId,
    required this.materialCode,
    required this.materialDescription,
    required this.grade,
    required this.length,
    required this.unitWeight,
    required this.uom,
    required this.category,
    required this.productFamily,
    required this.plantName,
    required this.warehouseName,
    required this.quantityNos,
    required this.quantityKg,
    required this.referenceNo,
    required this.partyOrProcess,
    required this.workOrderId,
    required this.heatNumber,
    required this.batchNo,
    required this.millCertificateUrl,
    required this.qaReferenceId,
    required this.remarks,
  });

  double get signedKg => quantityKg * transactionType.stockSign;

  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'verticalId': verticalId,
      'verticalName': verticalName,
      'transactionType': transactionType.key,
      'transactionDate': transactionDate == null
          ? null
          : Timestamp.fromDate(transactionDate!),
      'materialId': materialId,
      'materialCode': materialCode,
      'materialDescription': materialDescription,
      'grade': grade,
      'length': length,
      'lengthMm': length,
      'unitWeight': unitWeight,
      'unitWeightKgPerM': unitWeight,
      'uom': uom,
      'category': category,
      'rawMaterialCategory': category,
      'productFamily': productFamily,
      'plantName': plantName,
      'warehouseName': warehouseName,
      'quantityNos': quantityNos,
      'quantityKg': quantityKg,
      'referenceNo': referenceNo,
      'partyOrProcess': partyOrProcess,
      'workOrderId': workOrderId,
      'heatNumber': heatNumber,
      'batchNo': batchNo,
      'millCertificateUrl': millCertificateUrl,
      'qaReferenceId': qaReferenceId,
      'remarks': remarks,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory RawMaterialTransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final type = RawMaterialTransactionTypeX.fromKey(
      (data['transactionType'] ?? data['type'] ?? '').toString(),
    );
    return RawMaterialTransactionModel(
      transactionId: (data['transactionId'] ?? snapshot.id).toString(),
      verticalId: (data['verticalId'] ?? '').toString(),
      verticalName: (data['verticalName'] ?? data['vertical'] ?? '').toString(),
      transactionType: type,
      transactionDate: dateTimeFromValue(
        data['transactionDate'] ?? data['inwardDate'] ?? data['issueDate'],
      ),
      materialId: (data['materialId'] ?? data['itemId'] ?? '').toString(),
      materialCode: (data['materialCode'] ?? '').toString(),
      materialDescription: (data['materialDescription'] ?? '').toString(),
      grade: (data['grade'] ?? data['gradeIs'] ?? '').toString(),
      length: doubleFromValue(data['length'] ?? data['lengthMm']),
      unitWeight: doubleFromValue(
        data['unitWeight'] ?? data['unitWeightKgPerM'],
      ),
      uom: (data['uom'] ?? 'Kg').toString(),
      category: (data['category'] ?? data['rawMaterialCategory'] ?? '')
          .toString(),
      productFamily: (data['productFamily'] ?? '').toString(),
      plantName: (data['plantName'] ?? data['plant'] ?? 'Plant 1').toString(),
      warehouseName:
          (data['warehouseName'] ?? data['warehouse'] ?? 'Main Store')
              .toString(),
      quantityNos: doubleFromValue(data['quantityNos']),
      quantityKg: doubleFromValue(data['quantityKg']),
      referenceNo: (data['referenceNo'] ?? data['challanNo'] ?? '').toString(),
      partyOrProcess:
          (data['partyOrProcess'] ??
                  data['supplierName'] ??
                  data['issuedTo'] ??
                  '')
              .toString(),
      workOrderId: (data['workOrderId'] ?? '').toString(),
      heatNumber: (data['heatNumber'] ?? '').toString(),
      batchNo: (data['batchNo'] ?? '').toString(),
      millCertificateUrl: (data['millCertificateUrl'] ?? '').toString(),
      qaReferenceId: (data['qaReferenceId'] ?? '').toString(),
      remarks: (data['remarks'] ?? '').toString(),
    );
  }
}
