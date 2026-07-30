import 'package:cloud_firestore/cloud_firestore.dart';

class FactoryModel {
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
      streetAddress:
      (map['streetAddress'] ?? map['address'] ?? '').toString().trim(),
      country: (map['country'] ?? 'India').toString().trim(),
      state: (map['state'] ?? '').toString().trim(),
      city: (map['city'] ?? '').toString().trim(),
      pincode: (map['pincode'] ?? '').toString().trim(),
      gstNo: (map['gstNo'] ?? '').toString().trim(),
      panNo: (map['panNo'] ?? '').toString().trim(),
      isActive: map['isActive'] != false,
      isDeleted: map['isDeleted'] == true,
      createdAt: _readDate(map['createdAt']),
      createdBy: (map['createdBy'] ?? '').toString().trim(),
      updatedAt: _readDate(map['updatedAt']),
      updatedBy: (map['updatedBy'] ?? '').toString().trim(),
    );
  }

  FactoryModel copyWith({
    String? id,
    String? plantName,
    String? address,
    String? streetAddress,
    String? country,
    String? state,
    String? city,
    String? pincode,
    String? gstNo,
    String? panNo,
    bool? isActive,
    bool? isDeleted,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return FactoryModel(
      id: id ?? this.id,
      plantName: plantName ?? this.plantName,
      address: address ?? this.address,
      streetAddress: streetAddress ?? this.streetAddress,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      gstNo: gstNo ?? this.gstNo,
      panNo: panNo ?? this.panNo,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toCreateMap() => {
    ..._commonMap(),
    'isDeleted': false,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy.trim(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': updatedBy.trim(),
  };

  Map<String, dynamic> toUpdateMap() => {
    ..._commonMap(),
    'isDeleted': isDeleted,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': updatedBy.trim(),
  };

  // Compatibility for existing create flows.
  Map<String, dynamic> toMap() => toCreateMap();

  Map<String, dynamic> _commonMap() => {
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
  };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
