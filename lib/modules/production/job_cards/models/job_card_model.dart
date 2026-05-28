import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class JobCardQuantityLine {
  final String label;
  final double quantity;
  final String unit;

  const JobCardQuantityLine({
    required this.label,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {'label': label, 'quantity': quantity, 'unit': unit};
  }

  factory JobCardQuantityLine.fromMap(Object? value) {
    if (value is! Map) {
      return const JobCardQuantityLine(label: '', quantity: 0, unit: 'nos');
    }

    final data = Map<String, dynamic>.from(value);
    return JobCardQuantityLine(
      label: (data['label'] ?? '').toString(),
      quantity: doubleFromValue(data['quantity']),
      unit: (data['unit'] ?? 'nos').toString(),
    );
  }
}

class JobCardModel {
  final String jobCardId;
  final String jobCardNo;
  final String projectCode;
  final String customerName;
  final String poNumber;
  final String division;
  final String productCode;
  final String productName;
  final String contractor;
  final String drawingNo;
  final String drawingRevision;
  final String revisionNo;
  final String bomId;
  final String bomReference;
  final String boqId;
  final double plannedQty;
  final double completedQty;
  final double balanceQty;
  final List<JobCardQuantityLine> quantityLines;
  final String unit;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? targetDate;
  final DateTime? dispatchCommitmentDate;
  final String priority;
  final String status;
  final String delayReason;
  final String remarks;
  final String tenantId;
  final String companyId;
  final String createdBy;
  final String customerPoId;
  final String quotationFormat;
  final List<Map<String, dynamic>> sourcePoItems;
  final Map<String, dynamic> bomMetadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const JobCardModel({
    required this.jobCardId,
    required this.jobCardNo,
    required this.projectCode,
    required this.customerName,
    required this.poNumber,
    required this.division,
    required this.productCode,
    required this.productName,
    required this.contractor,
    required this.drawingNo,
    required this.drawingRevision,
    required this.revisionNo,
    required this.bomId,
    required this.bomReference,
    required this.boqId,
    required this.plannedQty,
    required this.completedQty,
    required this.balanceQty,
    required this.quantityLines,
    required this.unit,
    required this.plannedStartDate,
    required this.plannedEndDate,
    required this.targetDate,
    required this.dispatchCommitmentDate,
    required this.priority,
    required this.status,
    required this.delayReason,
    required this.remarks,
    required this.tenantId,
    required this.companyId,
    required this.createdBy,
    this.customerPoId = '',
    this.quotationFormat = 'commercial',
    this.sourcePoItems = const [],
    this.bomMetadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  String get itemDisplayName {
    if (productName.trim().isNotEmpty) return productName.trim();
    return productCode.trim();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'projectCode': projectCode,
      'customerName': customerName,
      'poNumber': poNumber,
      'projectPo': poNumber,
      'division': division,
      'productCode': productCode,
      'productName': productName,
      'itemProduct': itemDisplayName,
      'contractor': contractor,
      'drawingNo': drawingNo,
      'drawingRevision': drawingRevision,
      'revisionNo': revisionNo,
      'bomId': bomId,
      'bomReference': bomReference,
      'boqId': boqId,
      'plannedQty': plannedQty,
      'completedQty': completedQty,
      'balanceQty': balanceQty,
      'quantityLines': quantityLines
          .map((line) => line.toMap())
          .toList(growable: false),
      'unit': unit,
      'plannedStartDate': plannedStartDate == null
          ? null
          : Timestamp.fromDate(plannedStartDate!),
      'plannedEndDate': plannedEndDate == null
          ? null
          : Timestamp.fromDate(plannedEndDate!),
      'targetDate': targetDate == null ? null : Timestamp.fromDate(targetDate!),
      'dispatchCommitmentDate': dispatchCommitmentDate == null
          ? null
          : Timestamp.fromDate(dispatchCommitmentDate!),
      'priority': priority,
      'status': status,
      'delayReason': delayReason,
      'remarks': remarks,
      'tenantId': tenantId,
      'companyId': companyId,
      'createdBy': createdBy,
      'customerPoId': customerPoId,
      'quotationFormat': quotationFormat,
      'sourcePoItems': sourcePoItems,
      'bomMetadata': bomMetadata,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory JobCardModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final plannedQty = doubleFromValue(data['plannedQty']);
    final completedQty = doubleFromValue(data['completedQty']);
    final balanceQty = data.containsKey('balanceQty')
        ? doubleFromValue(data['balanceQty'])
        : plannedQty - completedQty;
    final quantityLines = data['quantityLines'] is Iterable
        ? (data['quantityLines'] as Iterable)
              .map(JobCardQuantityLine.fromMap)
              .where((line) => line.quantity > 0)
              .toList(growable: false)
        : <JobCardQuantityLine>[];

    return JobCardModel(
      jobCardId: (data['jobCardId'] ?? snapshot.id).toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      projectCode: (data['projectCode'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      poNumber: (data['poNumber'] ?? data['projectPo'] ?? '').toString(),
      division: (data['division'] ?? '').toString(),
      productCode: (data['productCode'] ?? '').toString(),
      productName: (data['productName'] ?? data['itemProduct'] ?? '')
          .toString(),
      contractor: (data['contractor'] ?? '').toString(),
      drawingNo: (data['drawingNo'] ?? '').toString(),
      drawingRevision: (data['drawingRevision'] ?? '').toString(),
      revisionNo: (data['revisionNo'] ?? data['drawingRevision'] ?? '')
          .toString(),
      bomId: (data['bomId'] ?? '').toString(),
      bomReference: (data['bomReference'] ?? data['bomId'] ?? '').toString(),
      boqId: (data['boqId'] ?? '').toString(),
      plannedQty: plannedQty,
      completedQty: completedQty,
      balanceQty: balanceQty,
      quantityLines: quantityLines,
      unit: (data['unit'] ?? 'nos').toString(),
      plannedStartDate: dateTimeFromValue(data['plannedStartDate']),
      plannedEndDate: dateTimeFromValue(data['plannedEndDate']),
      targetDate: dateTimeFromValue(data['targetDate']),
      dispatchCommitmentDate: dateTimeFromValue(data['dispatchCommitmentDate']),
      priority: (data['priority'] ?? 'normal').toString(),
      status: (data['status'] ?? 'draft').toString(),
      delayReason: (data['delayReason'] ?? '').toString(),
      remarks: (data['remarks'] ?? '').toString(),
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      customerPoId: (data['customerPoId'] ?? '').toString(),
      quotationFormat: (data['quotationFormat'] ?? 'commercial').toString(),
      sourcePoItems: _mapList(data['sourcePoItems']),
      bomMetadata: data['bomMetadata'] is Map
          ? Map<String, dynamic>.from(data['bomMetadata'] as Map)
          : const {},
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
