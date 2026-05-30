import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_fastener_line_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';

class EngineeringBomModel {
  final String id;
  final String bomNo;
  final String inquiryId;
  final String inquiryItemId;
  final String customer;
  final String project;
  final String revision;
  final String status;
  final String revisionReason;
  final String createdBy;
  final String approvedBy;
  final List<Map<String, dynamic>> attachments;
  final double projectQuantity;
  final List<String> visibleColumns;
  final List<BomCustomField> customFields;
  final List<EngineeringBomLineModel> lines;
  final List<EngineeringFastenerLineModel> fastenerLines;
  final double totalCalculatedWeight;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EngineeringBomModel({
    required this.id,
    required this.bomNo,
    required this.inquiryId,
    this.inquiryItemId = '',
    required this.customer,
    required this.project,
    required this.revision,
    this.status = 'Saved',
    this.revisionReason = '',
    this.createdBy = '',
    this.approvedBy = '',
    this.attachments = const [],
    this.projectQuantity = 1,
    this.visibleColumns = const [],
    this.customFields = const [],
    required this.lines,
    this.fastenerLines = const [],
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
    final rawFasteners = data['fastenerLines'];
    final fasteners = rawFasteners is List
        ? rawFasteners
              .whereType<Map>()
              .map(
                (line) => EngineeringFastenerLineModel.fromMap(
                  Map<String, dynamic>.from(line),
                ),
              )
              .toList(growable: false)
        : <EngineeringFastenerLineModel>[];

    return EngineeringBomModel(
      id: snapshot.id,
      bomNo: (data['bomNo'] ?? '').toString(),
      inquiryId: (data['inquiryId'] ?? '').toString(),
      inquiryItemId: (data['inquiryItemId'] ?? '').toString(),
      customer: (data['customer'] ?? '').toString(),
      project: (data['project'] ?? '').toString(),
      revision: (data['revision'] ?? 'A').toString(),
      status: (data['status'] ?? 'Saved').toString(),
      revisionReason: (data['revisionReason'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      approvedBy: (data['approvedBy'] ?? '').toString(),
      attachments: _mapList(data['attachments']),
      projectQuantity: _toDouble(
        data['projectQuantity'] ?? data['structureQuantity'],
      ),
      visibleColumns: (data['visibleColumns'] is List)
          ? List<String>.from(data['visibleColumns'] as List)
          : const [],
      customFields: (data['customFields'] is List)
          ? (data['customFields'] as List)
                .whereType<Map>()
                .map((field) => BomCustomField.fromMap(Map.from(field)))
                .toList()
          : const [],
      lines: lines,
      fastenerLines: fasteners,
      totalCalculatedWeight: _toDouble(data['totalCalculatedWeight']),
      createdAt: _dateTime(data['createdAt']),
      updatedAt: _dateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bomNo': bomNo,
      'bomNumber': bomNo,
      'bomId': id,
      'inquiryId': inquiryId,
      'inquiryItemId': inquiryItemId,
      'customer': customer,
      'project': project,
      'revision': revision,
      'status': status,
      'revisionReason': revisionReason,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'attachments': attachments,
      'projectQuantity': projectQuantity,
      'structureQuantity': projectQuantity,
      'visibleColumns': visibleColumns,
      'customFields': customFields.map((field) => field.toMap()).toList(),
      'lines': lines.map((line) => line.toMap()).toList(growable: false),
      'fastenerLines': fastenerLines
          .map((line) => line.toMap())
          .toList(growable: false),
      'totalCalculatedWeight': totalCalculatedWeight,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdOn': FieldValue.serverTimestamp(),
    };
  }

  EngineeringBomModel copyForRevision({
    required String id,
    required String revision,
    required String status,
    String revisionReason = '',
  }) {
    return EngineeringBomModel(
      id: id,
      bomNo: bomNo,
      inquiryId: inquiryId,
      inquiryItemId: inquiryItemId,
      customer: customer,
      project: project,
      revision: revision,
      status: status,
      revisionReason: revisionReason,
      createdBy: createdBy,
      approvedBy: '',
      attachments: attachments,
      projectQuantity: projectQuantity,
      visibleColumns: visibleColumns,
      customFields: customFields,
      lines: lines,
      fastenerLines: fastenerLines,
      totalCalculatedWeight: totalCalculatedWeight,
    );
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

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
