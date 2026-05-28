import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';

class EngineeringBomModel {
  final String id;
  final String bomNo;
  final String inquiryId;
  final String customer;
  final String project;
  final String revision;
  final List<EngineeringBomLineModel> lines;
  final double totalCalculatedWeight;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EngineeringBomModel({
    required this.id,
    required this.bomNo,
    required this.inquiryId,
    required this.customer,
    required this.project,
    required this.revision,
    required this.lines,
    required this.totalCalculatedWeight,
    this.createdAt,
    this.updatedAt,
  });

  factory EngineeringBomModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final rawLines = data['lines'];
    final lines = rawLines is List
        ? rawLines
              .whereType<Map>()
              .map(
                (line) => EngineeringBomLineModel.fromMap(
                  Map<String, dynamic>.from(line),
                ),
              )
              .toList(growable: false)
        : <EngineeringBomLineModel>[];

    return EngineeringBomModel(
      id: snapshot.id,
      bomNo: (data['bomNo'] ?? '').toString(),
      inquiryId: (data['inquiryId'] ?? '').toString(),
      customer: (data['customer'] ?? '').toString(),
      project: (data['project'] ?? '').toString(),
      revision: (data['revision'] ?? 'R0').toString(),
      lines: lines,
      totalCalculatedWeight: _toDouble(data['totalCalculatedWeight']),
      createdAt: _dateTime(data['createdAt']),
      updatedAt: _dateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bomNo': bomNo,
      'inquiryId': inquiryId,
      'customer': customer,
      'project': project,
      'revision': revision,
      'lines': lines.map((line) => line.toMap()).toList(growable: false),
      'totalCalculatedWeight': totalCalculatedWeight,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
