import 'package:cloud_firestore/cloud_firestore.dart';

class VerticalModel {
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
      createdBy: (data['createdBy'] ?? '').toString().trim(),
      updatedAt: _readDate(data['updatedAt']),
      updatedBy: (data['updatedBy'] ?? '').toString().trim(),
    );
  }

  VerticalModel copyWith({
    String? id,
    String? name,
    List<String>? factoryIds,
    List<String>? factoryNames,
    bool? isActive,
    bool? isDeleted,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return VerticalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      factoryIds: factoryIds ?? this.factoryIds,
      factoryNames: factoryNames ?? this.factoryNames,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'name': name.trim(),
    'nameNormalized': name.trim().toLowerCase(),
    'factoryIds': _normalizedList(factoryIds),
    'factoryNames': _normalizedList(factoryNames),
    'isActive': isActive,
    'isDeleted': false,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy.trim(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': updatedBy.trim(),
  };

  Map<String, dynamic> toUpdateMap() => {
    'name': name.trim(),
    'nameNormalized': name.trim().toLowerCase(),
    'factoryIds': _normalizedList(factoryIds),
    'factoryNames': _normalizedList(factoryNames),
    'isActive': isActive,
    'isDeleted': isDeleted,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': updatedBy.trim(),
  };

  // Compatibility for existing create flows.
  Map<String, dynamic> toMap() => toCreateMap();

  static List<String> _normalizedList(Iterable<String> values) {
    final seen = <String>{};
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && seen.add(value))
        .toList(growable: false);
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! Iterable) return const <String>[];
    return _normalizedList(value.map((item) => item.toString()));
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
