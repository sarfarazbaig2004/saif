import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class ContractorJobModel {
  final String jobId;
  final String tenantId;
  final String companyId;
  final String contractorId;
  final String contractorName;
  final String jobCardId;
  final String jobCardNo;
  final String projectCode;
  final String productName;
  final DateTime? issueDate;
  final double issueWeightKg;
  final double receivedWeightKg;
  final double pendingWeightKg;
  final double ratePerKg;
  final double amount;
  final String status;
  final String remarks;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ContractorJobModel({
    required this.jobId,
    required this.tenantId,
    required this.companyId,
    required this.contractorId,
    required this.contractorName,
    required this.jobCardId,
    required this.jobCardNo,
    required this.projectCode,
    required this.productName,
    required this.issueDate,
    required this.issueWeightKg,
    required this.receivedWeightKg,
    required this.pendingWeightKg,
    required this.ratePerKg,
    required this.amount,
    required this.status,
    required this.remarks,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'tenantId': tenantId,
      'companyId': companyId,
      'contractorId': contractorId,
      'contractorName': contractorName,
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'projectCode': projectCode,
      'productName': productName,
      'issueDate': issueDate == null ? null : Timestamp.fromDate(issueDate!),
      'issueWeightKg': issueWeightKg,
      'receivedWeightKg': receivedWeightKg,
      'pendingWeightKg': pendingWeightKg,
      'ratePerKg': ratePerKg,
      'amount': amount,
      'status': status,
      'remarks': remarks,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ContractorJobModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final issueWeightKg = doubleFromValue(data['issueWeightKg']);
    final receivedWeightKg = doubleFromValue(data['receivedWeightKg']);
    final ratePerKg = doubleFromValue(data['ratePerKg']);
    final pendingWeightKg = data.containsKey('pendingWeightKg')
        ? doubleFromValue(data['pendingWeightKg'])
        : issueWeightKg - receivedWeightKg;
    final amount = data.containsKey('amount')
        ? doubleFromValue(data['amount'])
        : receivedWeightKg * ratePerKg;

    return ContractorJobModel(
      jobId: (data['jobId'] ?? snapshot.id).toString(),
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      contractorId: (data['contractorId'] ?? '').toString(),
      contractorName: (data['contractorName'] ?? '').toString(),
      jobCardId: (data['jobCardId'] ?? '').toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      projectCode: (data['projectCode'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      issueDate: dateTimeFromValue(data['issueDate']),
      issueWeightKg: issueWeightKg,
      receivedWeightKg: receivedWeightKg,
      pendingWeightKg: pendingWeightKg,
      ratePerKg: ratePerKg,
      amount: amount,
      status: (data['status'] ?? 'issued').toString(),
      remarks: (data['remarks'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }
}
