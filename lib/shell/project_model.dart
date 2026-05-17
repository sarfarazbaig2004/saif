// Model for Projects
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String companyId;
  final String projectCode;
  final String linkedPoId;
  final String linkedPoNumber;
  final String projectName;
  final String status;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.companyId,
    required this.projectCode,
    required this.linkedPoId,
    required this.linkedPoNumber,
    required this.projectName,
    this.status = 'Planning',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'projectCode': projectCode,
      'linkedPoId': linkedPoId,
      'linkedPoNumber': linkedPoNumber,
      'projectName': projectName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProjectModel(
      id: documentId,
      companyId: map['companyId'] ?? '',
      projectCode: map['projectCode'] ?? '',
      linkedPoId: map['linkedPoId'] ?? '',
      linkedPoNumber: map['linkedPoNumber'] ?? '',
      projectName: map['projectName'] ?? '',
      status: map['status'] ?? 'Planning',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}