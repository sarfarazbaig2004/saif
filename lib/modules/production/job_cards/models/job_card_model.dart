import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class JobCardModel {
  final String jobCardId;
  final String jobCardNo;
  final String projectCode;
  final String customerName;
  final String poNumber;
  final String productCode;
  final String productName;
  final String drawingNo;
  final String drawingRevision;
  final String bomId;
  final String boqId;
  final double plannedQty;
  final double completedQty;
  final double balanceQty;
  final String unit;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? dispatchCommitmentDate;
  final String priority;
  final String status;
  final String delayReason;
  final String remarks;
  final String tenantId;
  final String companyId;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const JobCardModel({
    required this.jobCardId,
    required this.jobCardNo,
    required this.projectCode,
    required this.customerName,
    required this.poNumber,
    required this.productCode,
    required this.productName,
    required this.drawingNo,
    required this.drawingRevision,
    required this.bomId,
    required this.boqId,
    required this.plannedQty,
    required this.completedQty,
    required this.balanceQty,
    required this.unit,
    required this.plannedStartDate,
    required this.plannedEndDate,
    required this.dispatchCommitmentDate,
    required this.priority,
    required this.status,
    required this.delayReason,
    required this.remarks,
    required this.tenantId,
    required this.companyId,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'projectCode': projectCode,
      'customerName': customerName,
      'poNumber': poNumber,
      'productCode': productCode,
      'productName': productName,
      'drawingNo': drawingNo,
      'drawingRevision': drawingRevision,
      'bomId': bomId,
      'boqId': boqId,
      'plannedQty': plannedQty,
      'completedQty': completedQty,
      'balanceQty': balanceQty,
      'unit': unit,
      'plannedStartDate': plannedStartDate == null
          ? null
          : Timestamp.fromDate(plannedStartDate!),
      'plannedEndDate': plannedEndDate == null
          ? null
          : Timestamp.fromDate(plannedEndDate!),
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

    return JobCardModel(
      jobCardId: (data['jobCardId'] ?? snapshot.id).toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      projectCode: (data['projectCode'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      poNumber: (data['poNumber'] ?? '').toString(),
      productCode: (data['productCode'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      drawingNo: (data['drawingNo'] ?? '').toString(),
      drawingRevision: (data['drawingRevision'] ?? '').toString(),
      bomId: (data['bomId'] ?? '').toString(),
      boqId: (data['boqId'] ?? '').toString(),
      plannedQty: plannedQty,
      completedQty: completedQty,
      balanceQty: balanceQty,
      unit: (data['unit'] ?? 'nos').toString(),
      plannedStartDate: dateTimeFromValue(data['plannedStartDate']),
      plannedEndDate: dateTimeFromValue(data['plannedEndDate']),
      dispatchCommitmentDate: dateTimeFromValue(data['dispatchCommitmentDate']),
      priority: (data['priority'] ?? 'normal').toString(),
      status: (data['status'] ?? 'draft').toString(),
      delayReason: (data['delayReason'] ?? '').toString(),
      remarks: (data['remarks'] ?? '').toString(),
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }
}
