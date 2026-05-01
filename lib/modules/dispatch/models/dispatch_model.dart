import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class DispatchModel {
  final String dispatchId;
  final String tenantId;
  final String companyId;
  final String inspectionId;
  final String jobCardId;
  final String jobCardNo;
  final String projectCode;
  final String productName;
  final DateTime? dispatchDate;
  final DateTime? dispatchCommitmentDate;
  final double dispatchQty;
  final double approvedQty;
  final String vehicleNumber;
  final String driverName;
  final String transportName;
  final String lrNumber;
  final String invoiceNumber;
  final String dispatchStatus;
  final String delayReason;
  final String remarks;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DispatchModel({
    required this.dispatchId,
    required this.tenantId,
    required this.companyId,
    required this.inspectionId,
    required this.jobCardId,
    required this.jobCardNo,
    required this.projectCode,
    required this.productName,
    required this.dispatchDate,
    required this.dispatchCommitmentDate,
    required this.dispatchQty,
    required this.approvedQty,
    required this.vehicleNumber,
    required this.driverName,
    required this.transportName,
    required this.lrNumber,
    required this.invoiceNumber,
    required this.dispatchStatus,
    required this.delayReason,
    required this.remarks,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'dispatchId': dispatchId,
      'tenantId': tenantId,
      'companyId': companyId,
      'inspectionId': inspectionId,
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'projectCode': projectCode,
      'productName': productName,
      'dispatchDate': dispatchDate == null
          ? null
          : Timestamp.fromDate(dispatchDate!),
      'dispatchCommitmentDate': dispatchCommitmentDate == null
          ? null
          : Timestamp.fromDate(dispatchCommitmentDate!),
      'dispatchQty': dispatchQty,
      'approvedQty': approvedQty,
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'transportName': transportName,
      'lrNumber': lrNumber,
      'invoiceNumber': invoiceNumber,
      'dispatchStatus': dispatchStatus,
      'delayReason': delayReason,
      'remarks': remarks,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory DispatchModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return DispatchModel(
      dispatchId: (data['dispatchId'] ?? snapshot.id).toString(),
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      inspectionId: (data['inspectionId'] ?? '').toString(),
      jobCardId: (data['jobCardId'] ?? '').toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      projectCode: (data['projectCode'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      dispatchDate: dateTimeFromValue(data['dispatchDate']),
      dispatchCommitmentDate: dateTimeFromValue(data['dispatchCommitmentDate']),
      dispatchQty: doubleFromValue(data['dispatchQty']),
      approvedQty: doubleFromValue(data['approvedQty']),
      vehicleNumber: (data['vehicleNumber'] ?? '').toString(),
      driverName: (data['driverName'] ?? '').toString(),
      transportName: (data['transportName'] ?? '').toString(),
      lrNumber: (data['lrNumber'] ?? '').toString(),
      invoiceNumber: (data['invoiceNumber'] ?? '').toString(),
      dispatchStatus: (data['dispatchStatus'] ?? 'planned').toString(),
      delayReason: (data['delayReason'] ?? '').toString(),
      remarks: (data['remarks'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }

  bool get isDelayed {
    final dispatch = dispatchDate;
    final commitment = dispatchCommitmentDate;
    if (dispatch == null || commitment == null) return false;
    final dispatchDay = DateTime(dispatch.year, dispatch.month, dispatch.day);
    final commitmentDay = DateTime(
      commitment.year,
      commitment.month,
      commitment.day,
    );
    return dispatchDay.isAfter(commitmentDay);
  }
}
