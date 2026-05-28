import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class MaterialRequirementLineModel {
  final int lineNo;
  final String sourceItemId;
  final String material;
  final String section;
  final double requiredWeightKg;
  final double requiredQty;
  final String unit;
  final double lengthMm;
  final String remarks;

  const MaterialRequirementLineModel({
    required this.lineNo,
    required this.sourceItemId,
    required this.material,
    required this.section,
    required this.requiredWeightKg,
    required this.requiredQty,
    required this.unit,
    required this.lengthMm,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'lineNo': lineNo,
      'sourceItemId': sourceItemId,
      'material': material,
      'section': section,
      'requiredWeightKg': requiredWeightKg,
      'requiredQty': requiredQty,
      'unit': unit,
      'lengthMm': lengthMm,
      'remarks': remarks,
    };
  }

  factory MaterialRequirementLineModel.fromMap(Object? value) {
    if (value is! Map) {
      return const MaterialRequirementLineModel(
        lineNo: 0,
        sourceItemId: '',
        material: '',
        section: '',
        requiredWeightKg: 0,
        requiredQty: 0,
        unit: 'KG',
        lengthMm: 0,
        remarks: '',
      );
    }

    final data = Map<String, dynamic>.from(value);
    return MaterialRequirementLineModel(
      lineNo: intFromValue(data['lineNo']),
      sourceItemId: (data['sourceItemId'] ?? '').toString(),
      material: (data['material'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      requiredWeightKg: doubleFromValue(data['requiredWeightKg']),
      requiredQty: doubleFromValue(data['requiredQty']),
      unit: (data['unit'] ?? 'KG').toString(),
      lengthMm: doubleFromValue(data['lengthMm']),
      remarks: (data['remarks'] ?? '').toString(),
    );
  }
}

class MaterialRequirementModel {
  final String requirementId;
  final String requirementNo;
  final String jobCardId;
  final String jobCardNo;
  final String customerName;
  final String projectCode;
  final String poNumber;
  final String status;
  final List<MaterialRequirementLineModel> lines;
  final double totalWeightKg;
  final String tenantId;
  final String companyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaterialRequirementModel({
    required this.requirementId,
    required this.requirementNo,
    required this.jobCardId,
    required this.jobCardNo,
    required this.customerName,
    required this.projectCode,
    required this.poNumber,
    required this.status,
    required this.lines,
    required this.totalWeightKg,
    required this.tenantId,
    required this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'requirementId': requirementId,
      'requirementNo': requirementNo,
      'jobCardId': jobCardId,
      'jobCardNo': jobCardNo,
      'customerName': customerName,
      'projectCode': projectCode,
      'poNumber': poNumber,
      'status': status,
      'lines': lines.map((line) => line.toMap()).toList(growable: false),
      'totalWeightKg': totalWeightKg,
      'tenantId': tenantId,
      'companyId': companyId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory MaterialRequirementModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final lines = data['lines'] is Iterable
        ? (data['lines'] as Iterable)
              .map(MaterialRequirementLineModel.fromMap)
              .toList(growable: false)
        : <MaterialRequirementLineModel>[];

    return MaterialRequirementModel(
      requirementId: (data['requirementId'] ?? snapshot.id).toString(),
      requirementNo: (data['requirementNo'] ?? '').toString(),
      jobCardId: (data['jobCardId'] ?? '').toString(),
      jobCardNo: (data['jobCardNo'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      projectCode: (data['projectCode'] ?? '').toString(),
      poNumber: (data['poNumber'] ?? '').toString(),
      status: (data['status'] ?? 'draft').toString(),
      lines: lines,
      totalWeightKg: doubleFromValue(data['totalWeightKg']),
      tenantId: (data['tenantId'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      createdAt: dateTimeFromValue(data['createdAt']),
      updatedAt: dateTimeFromValue(data['updatedAt']),
    );
  }
}
