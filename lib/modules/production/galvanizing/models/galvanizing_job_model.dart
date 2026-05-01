import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class GalvanizingJobModel {
  final String galvanizingJobId;
  final String tenantId;
  final String companyId;
  final String vendorId;
  final String vendorName;
  final String jobCardId;
  final String jobCardNo;
  final DateTime? sendDate;
  final double sentWeightKg;
  final DateTime? receivedDate;
  final double receivedWeightKg;
  final double shortageKg;
  final double excessKg;
  final double ratePerKg;
  final double amount;
  final String status;
  final String remarks;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GalvanizingJobModel({
    required this.galvanizingJobId,
    required this.tenantId,
    required this.companyId,
    required this.vendorId,
    required this.vendorName,
    required this.jobCardId,
    required this.jobCardNo,
    required this.sendDate,
    required this.sentWeightKg,
    required this.receivedDate,
    required this.receivedWeightKg,
    required this.shortageKg,
    required this.excessKg,
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
      'galvanizingJobId': galvanizingJobId,
      'tenantId': tenantId,
      'companyId': companyId,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'sendDate': sendDate == null ? null : Timestamp.fromDate(sendDate!),
      'sentWeightKg': sentWeightKg,
      'receivedDate': receivedDate == null
          ? null
          : Timestamp.fromDate(receivedDate!),
      'receivedWeightKg': receivedWeightKg,
      'shortageKg': shortageKg,
      'excessKg': excessKg,
      'ratePerKg': ratePerKg,
      'amount': amount,
      'status': status,
      'remarks': remarks,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory GalvanizingJobModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final sentWeightKg = doubleFromValue(data['sentWeightKg']);
    final receivedWeightKg = doubleFromValue(data['receivedWeightKg']);
    final ratePerKg = doubleFromValue(data['ratePerKg']);
    final shortageKg = data.containsKey('shortageKg')
        ? doubleFromValue(data['shortageKg'])
        : _shortage(sentWeightKg, receivedWeightKg);
    final excessKg = data.containsKey('excessKg')
        ? doubleFromValue(data['excessKg'])
        : _excess(sentWeightKg, receivedWeightKg);
    final amount = data.containsKey('amount')
        ? doubleFromValue(data['amount'])
        : receivedWeightKg * ratePerKg;

    return GalvanizingJobModel(
      galvanizingJobId: (data['galvanizingJobId'] ?? snapshot.id).toString(),
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      vendorId: (data['vendorId'] ?? '').toString(),
      vendorName: (data['vendorName'] ?? '').toString(),
      jobCardId: (data['jobCardId'] ?? '').toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      sendDate: dateTimeFromValue(data['sendDate']),
      sentWeightKg: sentWeightKg,
      receivedDate: dateTimeFromValue(data['receivedDate']),
      receivedWeightKg: receivedWeightKg,
      shortageKg: shortageKg,
      excessKg: excessKg,
      ratePerKg: ratePerKg,
      amount: amount,
      status: (data['status'] ?? 'sent').toString(),
      remarks: (data['remarks'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }

  static double shortageFor(double sentWeightKg, double receivedWeightKg) {
    return _shortage(sentWeightKg, receivedWeightKg);
  }

  static double excessFor(double sentWeightKg, double receivedWeightKg) {
    return _excess(sentWeightKg, receivedWeightKg);
  }

  static double _shortage(double sentWeightKg, double receivedWeightKg) {
    final value = sentWeightKg - receivedWeightKg;
    return value > 0 ? value : 0;
  }

  static double _excess(double sentWeightKg, double receivedWeightKg) {
    final value = receivedWeightKg - sentWeightKg;
    return value > 0 ? value : 0;
  }
}
