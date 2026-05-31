import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class PurchaseRequisitionLineModel {
  final int lineNo;
  final String material;
  final String section;
  final double requiredQty;
  final double availableQty;
  final double reservedQty;
  final double purchaseQty;
  final String unit;
  final String remarks;

  const PurchaseRequisitionLineModel({
    required this.lineNo,
    required this.material,
    required this.section,
    required this.requiredQty,
    required this.availableQty,
    required this.reservedQty,
    required this.purchaseQty,
    required this.unit,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'lineNo': lineNo,
      'material': material,
      'section': section,
      'requiredQty': requiredQty,
      'availableQty': availableQty,
      'reservedQty': reservedQty,
      'purchaseQty': purchaseQty,
      'unit': unit,
      'remarks': remarks,
    };
  }

  factory PurchaseRequisitionLineModel.fromMap(Object? value) {
    if (value is! Map) {
      return const PurchaseRequisitionLineModel(
        lineNo: 0,
        material: '',
        section: '',
        requiredQty: 0,
        availableQty: 0,
        reservedQty: 0,
        purchaseQty: 0,
        unit: 'KG',
        remarks: '',
      );
    }

    final data = Map<String, dynamic>.from(value);
    return PurchaseRequisitionLineModel(
      lineNo: intFromValue(data['lineNo']),
      material: (data['material'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      requiredQty: doubleFromValue(data['requiredQty']),
      availableQty: doubleFromValue(data['availableQty']),
      reservedQty: doubleFromValue(data['reservedQty']),
      purchaseQty: doubleFromValue(data['purchaseQty']),
      unit: (data['unit'] ?? 'KG').toString(),
      remarks: (data['remarks'] ?? '').toString(),
    );
  }
}

class PurchaseRequisitionModel {
  final String requisitionId;
  final String requisitionNo;
  final String materialRequirementId;
  final String materialRequirementNo;
  final String jobCardId;
  final String jobCardNo;
  final String customerPoId;
  final String poNumber;
  final String customerName;
  final String bomId;
  final String bomNumber;
  final String status;
  final List<PurchaseRequisitionLineModel> lines;
  final String tenantId;
  final String companyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PurchaseRequisitionModel({
    required this.requisitionId,
    required this.requisitionNo,
    required this.materialRequirementId,
    required this.materialRequirementNo,
    required this.jobCardId,
    required this.jobCardNo,
    required this.customerPoId,
    required this.poNumber,
    required this.customerName,
    required this.bomId,
    required this.bomNumber,
    required this.status,
    required this.lines,
    required this.tenantId,
    required this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  double get totalPurchaseQty =>
      lines.fold<double>(0, (total, line) => total + line.purchaseQty);

  Map<String, dynamic> toFirestore() {
    return {
      'requisitionId': requisitionId,
      'requisitionNo': requisitionNo,
      'materialRequirementId': materialRequirementId,
      'materialRequirementNo': materialRequirementNo,
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'customerPoId': customerPoId,
      'poNumber': poNumber,
      'customerName': customerName,
      'bomId': bomId,
      'bomNumber': bomNumber,
      'status': status,
      'lines': lines.map((line) => line.toMap()).toList(growable: false),
      'totalPurchaseQty': totalPurchaseQty,
      'tenantId': tenantId,
      'companyId': companyId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PurchaseRequisitionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final lines = data['lines'] is Iterable
        ? (data['lines'] as Iterable)
              .map(PurchaseRequisitionLineModel.fromMap)
              .toList(growable: false)
        : <PurchaseRequisitionLineModel>[];

    return PurchaseRequisitionModel(
      requisitionId: (data['requisitionId'] ?? snapshot.id).toString(),
      requisitionNo: (data['requisitionNo'] ?? '').toString(),
      materialRequirementId: (data['materialRequirementId'] ?? '').toString(),
      materialRequirementNo: (data['materialRequirementNo'] ?? '').toString(),
      jobCardId: (data['jobCardId'] ?? '').toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      customerPoId: (data['customerPoId'] ?? '').toString(),
      poNumber: (data['poNumber'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      bomId: (data['bomId'] ?? '').toString(),
      bomNumber: (data['bomNumber'] ?? '').toString(),
      status: (data['status'] ?? 'draft').toString(),
      lines: lines,
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }
}
