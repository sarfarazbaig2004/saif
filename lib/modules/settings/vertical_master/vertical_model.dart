import 'package:cloud_firestore/cloud_firestore.dart';

class VerticalModel {
  final String id;
  final String name;
  final List<String> factoryIds;
  final List<String> factoryNames;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;

  const VerticalModel({
    required this.id,
    required this.name,
    required this.factoryIds,
    required this.factoryNames,
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  factory VerticalModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return VerticalModel(
      id: snapshot.id,
      name: (data['name'] ?? '').toString().trim(),
      factoryIds: _readStringList(data['factoryIds']),
      factoryNames: _readStringList(data['factoryNames']),
      isActive: data['isActive'] != false,
      isDeleted: data['isDeleted'] == true,
      createdAt: _readDate(data['createdAt']),
      createdBy: (data['createdBy'] ?? '').toString(),
      updatedAt: _readDate(data['updatedAt']),
      updatedBy: (data['updatedBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'nameNormalized': name.trim().toLowerCase(),
    'factoryIds': factoryIds,
    'factoryNames': factoryNames,
    'isActive': isActive,
    'isDeleted': isDeleted,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': updatedBy,
  };

  static List<String> _readStringList(dynamic value) {
    if (value is! Iterable) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
