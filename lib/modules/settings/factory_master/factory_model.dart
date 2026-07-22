import 'package:cloud_firestore/cloud_firestore.dart';

class FactoryModel {
  final String id;
  final String plantName;
  final String address;
  final String streetAddress;
  final String country;
  final String state;
  final String city;
  final String pincode;
  final String gstNo;
  final String panNo;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;

  const FactoryModel({
    required this.id,
    required this.plantName,
    required this.address,
    this.streetAddress = '',
    this.country = 'India',
    this.state = '',
    this.city = '',
    this.pincode = '',
    this.gstNo = '',
    this.panNo = '',
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  factory FactoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return FactoryModel.fromMap(snapshot.id, snapshot.data() ?? const {});
  }

  factory FactoryModel.fromMap(String id, Map<String, dynamic> map) {
    return FactoryModel(
      id: id,
      plantName: (map['plantName'] ?? '').toString().trim(),
      address: (map['address'] ?? '').toString().trim(),
      streetAddress: (map['streetAddress'] ?? map['address'] ?? '')
          .toString()
          .trim(),
      country: (map['country'] ?? 'India').toString().trim(),
      state: (map['state'] ?? '').toString().trim(),
      city: (map['city'] ?? '').toString().trim(),
      pincode: (map['pincode'] ?? '').toString().trim(),
      gstNo: (map['gstNo'] ?? '').toString().trim(),
      panNo: (map['panNo'] ?? '').toString().trim(),
      isActive: map['isActive'] != false,
      isDeleted: map['isDeleted'] == true,
      createdAt: _readDate(map['createdAt']),
      createdBy: (map['createdBy'] ?? '').toString(),
      updatedAt: _readDate(map['updatedAt']),
      updatedBy: (map['updatedBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'plantName': plantName.trim(),
    'plantNameNormalized': plantName.trim().toLowerCase(),
    'address': address.trim(),
    'streetAddress': streetAddress.trim(),
    'country': country.trim(),
    'state': state.trim(),
    'city': city.trim(),
    'pincode': pincode.trim(),
    if (gstNo.trim().isNotEmpty) 'gstNo': gstNo.trim().toUpperCase(),
    if (panNo.trim().isNotEmpty) 'panNo': panNo.trim().toUpperCase(),
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
