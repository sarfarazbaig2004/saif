import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class InspectionModel {
  final String inspectionId;
  final String tenantId;
  final String companyId;
  final String jobCardId;
  final String jobCardNo;
  final String projectCode;
  final String productName;
  final DateTime? inspectionDate;
  final DateTime? dispatchCommitmentDate;
  final double inspectedQty;
  final double approvedQty;
  final double rejectedQty;
  final String rejectionReason;
  final String inspectorName;
  final bool clientInspectionRequired;
  final String clientInspectionStatus;
  final String dispatchClearanceStatus;
  final String delayReason;
  final String remarks;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InspectionModel({
    required this.inspectionId,
    required this.tenantId,
    required this.companyId,
    required this.jobCardId,
    required this.jobCardNo,
    required this.projectCode,
    required this.productName,
    required this.inspectionDate,
    required this.dispatchCommitmentDate,
    required this.inspectedQty,
    required this.approvedQty,
    required this.rejectedQty,
    required this.rejectionReason,
    required this.inspectorName,
    required this.clientInspectionRequired,
    required this.clientInspectionStatus,
    required this.dispatchClearanceStatus,
    required this.delayReason,
    required this.remarks,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'inspectionId': inspectionId,
      'tenantId': tenantId,
      'companyId': companyId,
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'projectCode': projectCode,
      'productName': productName,
      'inspectionDate': inspectionDate == null
          ? null
          : Timestamp.fromDate(inspectionDate!),
      'dispatchCommitmentDate': dispatchCommitmentDate == null
          ? null
          : Timestamp.fromDate(dispatchCommitmentDate!),
      'inspectedQty': inspectedQty,
      'approvedQty': approvedQty,
      'rejectedQty': rejectedQty,
      'rejectionReason': rejectionReason,
      'inspectorName': inspectorName,
      'clientInspectionRequired': clientInspectionRequired,
      'clientInspectionStatus': clientInspectionStatus,
      'dispatchClearanceStatus': dispatchClearanceStatus,
      'delayReason': delayReason,
      'remarks': remarks,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory InspectionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return InspectionModel(
      inspectionId: (data['inspectionId'] ?? snapshot.id).toString(),
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      jobCardId: (data['jobCardId'] ?? '').toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      projectCode: (data['projectCode'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      inspectionDate: dateTimeFromValue(data['inspectionDate']),
      dispatchCommitmentDate: dateTimeFromValue(
        data['dispatchCommitmentDate'],
      ),
      inspectedQty: doubleFromValue(data['inspectedQty']),
      approvedQty: doubleFromValue(data['approvedQty']),
      rejectedQty: doubleFromValue(data['rejectedQty']),
      rejectionReason: (data['rejectionReason'] ?? '').toString(),
      inspectorName: (data['inspectorName'] ?? '').toString(),
      clientInspectionRequired: data['clientInspectionRequired'] == true,
      clientInspectionStatus:
          (data['clientInspectionStatus'] ?? 'pending').toString(),
      dispatchClearanceStatus:
          (data['dispatchClearanceStatus'] ?? 'pending').toString(),
      delayReason: (data['delayReason'] ?? '').toString(),
      remarks: (data['remarks'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }

  bool get isDispatchAllowed => dispatchClearanceStatus == 'approved';

  bool get isPendingNearDispatch {
    final dispatchDate = dispatchCommitmentDate;
    if (dispatchClearanceStatus != 'pending' || dispatchDate == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      dispatchDate.year,
      dispatchDate.month,
      dispatchDate.day,
    );
    final days = target.difference(today).inDays;
    return days >= 0 && days <= 3;
  }
}
