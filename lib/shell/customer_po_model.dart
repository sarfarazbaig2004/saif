// Model for Customer PO
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoModel {
  final String id;
  final String poNumber;
  final String projectName;
  final String customerName;
  final DateTime expectedDeliveryDate;
  final DateTime poDate;
  final String status;
  final double totalOrderValue;

  CustomerPoModel({
    required this.id,
    required this.poNumber,
    required this.projectName,
    required this.customerName,
    required this.expectedDeliveryDate,
    required this.poDate,
    required this.status,
    required this.totalOrderValue,
  });

  factory CustomerPoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomerPoModel(
      id: documentId,
      poNumber: map['poNumber']?.toString() ?? '',
      projectName: map['projectName']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      expectedDeliveryDate: (map['expectedDeliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      poDate: (map['poDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status']?.toString() ?? 'Pending',
      totalOrderValue: (map['totalOrderValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'poNumber': poNumber,
      'projectName': projectName,
      'customerName': customerName,
      'expectedDeliveryDate': Timestamp.fromDate(expectedDeliveryDate),
      'poDate': Timestamp.fromDate(poDate),
      'status': status,
      'totalOrderValue': totalOrderValue,
    };
  }
}