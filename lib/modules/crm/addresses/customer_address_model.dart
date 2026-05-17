import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAddressModel {
  static const List<String> addressTypes = [
    'Head Office',
    'Billing',
    'Dispatch',
    'Plant',
    'Site',
  ];

  final String id;
  final String addressType;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String gstNumber;
  final String contactPerson;
  final String mobile;
  final String email;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerAddressModel({
    required this.id,
    required this.addressType,
    required this.addressLine1,
    this.addressLine2 = '',
    this.city = '',
    this.state = '',
    this.country = 'India',
    this.pincode = '',
    this.gstNumber = '',
    this.contactPerson = '',
    this.mobile = '',
    this.email = '',
    this.isPrimary = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerAddressModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomerAddressModel(
      id: id,
      addressType: (map['addressType'] ?? 'Head Office').toString(),
      addressLine1: (map['addressLine1'] ?? '').toString(),
      addressLine2: (map['addressLine2'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      state: (map['state'] ?? '').toString(),
      country: (map['country'] ?? 'India').toString(),
      pincode: (map['pincode'] ?? '').toString(),
      gstNumber: (map['gstNumber'] ?? '').toString(),
      contactPerson: (map['contactPerson'] ?? '').toString(),
      mobile: (map['mobile'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      isPrimary: map['isPrimary'] == true,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  factory CustomerAddressModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CustomerAddressModel.fromMap(doc.id, doc.data() ?? {});
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'addressType': addressType,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'gstNumber': gstNumber,
      'contactPerson': contactPerson,
      'mobile': mobile,
      'email': email,
      'isPrimary': isPrimary,
    };
  }
}
