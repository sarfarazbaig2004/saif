import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerContactModel {
  final String id;
  final String name;
  final String designation;
  final String department;
  final String mobile;
  final String email;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerContactModel({
    required this.id,
    required this.name,
    this.designation = '',
    this.department = '',
    this.mobile = '',
    this.email = '',
    this.isPrimary = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerContactModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomerContactModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      designation: (map['designation'] ?? '').toString(),
      department: (map['department'] ?? '').toString(),
      mobile: (map['mobile'] ?? map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      isPrimary: map['isPrimary'] == true,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  factory CustomerContactModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CustomerContactModel.fromMap(doc.id, doc.data() ?? {});
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'designation': designation,
      'department': department,
      'mobile': mobile,
      'phone': mobile, // alias kept for follow-up screen backward compat
      'email': email,
      'isPrimary': isPrimary,
    };
  }
}
