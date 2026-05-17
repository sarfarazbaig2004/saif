import '../widgets/customer_po_item_row.dart';

class CustomerPoModel {
  final String id;
  final String companyId;
  final String poNumber;
  final DateTime poDate;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerMobile;
  final String customerAddress;
  final String customerGstNumber;
  final String projectName;
  final String siteLocation;
  final String subject;
  final double basicValue;
  final double gstPercent;
  final double gstAmount;
  final double totalValue;
  final String paymentTerms;
  final String deliveryTerms;
  final String inspectionRequirement;
  final String warranty;
  final String ldClause;
  final String status;
  final String? poFileUrl;
  final String? poDocumentUrl;
  final String? poFileName;
  final DateTime? uploadedAt;
  final List<CustomerPoItemRow> items;

  const CustomerPoModel({
    required this.id,
    required this.companyId,
    required this.poNumber,
    required this.poDate,
    required this.customerId,
    required this.customerName,
    required this.projectName,
    required this.siteLocation,
    required this.subject,
    required this.basicValue,
    required this.gstPercent,
    required this.gstAmount,
    required this.totalValue,
    required this.paymentTerms,
    required this.deliveryTerms,
    required this.inspectionRequirement,
    required this.warranty,
    required this.ldClause,
    required this.status,
    this.customerEmail = '',
    this.customerMobile = '',
    this.customerAddress = '',
    this.customerGstNumber = '',
    this.poFileUrl,
    this.poDocumentUrl,
    this.poFileName,
    this.uploadedAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'poNumber': poNumber,
      'poDate': poDate.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerMobile': customerMobile,
      'customerAddress': customerAddress,
      'customerGstNumber': customerGstNumber,
      'projectName': projectName,
      'siteLocation': siteLocation,
      'subject': subject,
      'basicValue': basicValue,
      'gstPercent': gstPercent,
      'gstAmount': gstAmount,
      'totalValue': totalValue,
      'paymentTerms': paymentTerms,
      'deliveryTerms': deliveryTerms,
      'inspectionRequirement': inspectionRequirement,
      'warranty': warranty,
      'ldClause': ldClause,
      'status': status,
      'poFileUrl': poFileUrl,
      'poDocumentUrl': poDocumentUrl,
      'poFileName': poFileName,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}
