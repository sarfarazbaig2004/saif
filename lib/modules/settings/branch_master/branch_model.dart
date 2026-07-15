import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String name;
  final String code;
  final String description;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;

  const BranchModel({
    required this.id,
    required this.name,
    required this.code,
    this.description = '',
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  factory BranchModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return BranchModel.fromMap(snapshot.id, snapshot.data() ?? const {});
  }

  factory BranchModel.fromMap(String id, Map<String, dynamic> map) {
    return BranchModel(
      id: id,
      name: (map['name'] ?? '').toString().trim(),
      code: (map['code'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      isActive: map['isActive'] != false,
      isDeleted: map['isDeleted'] == true,
      createdAt: _readDate(map['createdAt']),
      createdBy: (map['createdBy'] ?? '').toString(),
      updatedAt: _readDate(map['updatedAt']),
      updatedBy: (map['updatedBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'nameNormalized': name.trim().toLowerCase(),
    'code': code.trim().toUpperCase(),
    'codeNormalized': code.trim().toLowerCase(),
    'description': description.trim(),
    'isActive': isActive,
    'isDeleted': isDeleted,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': updatedBy,
  };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
