import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';

class CustomerPoFormData {
  final String id;
  final String status;
  final DateTime poDate;
  final String internalPoNo;
  final String customerPoNumber;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerMobile;
  final String customerAddress;
  final String customerGstNumber;
  final String projectName;
  final String siteLocation;
  final String subject;
  final String gstPercent;
  final String paymentTerms;
  final String deliveryTerms;
  final String inspectionRequirement;
  final String warranty;
  final String ldClause;
  final String? poDocumentUrl;
  final String? poFileName;
  final DateTime? uploadedAt;
  final List<CustomerPoItemRow> items;

  const CustomerPoFormData({
    required this.id,
    required this.status,
    required this.poDate,
    required this.internalPoNo,
    required this.customerPoNumber,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerMobile,
    required this.customerAddress,
    required this.customerGstNumber,
    required this.projectName,
    required this.siteLocation,
    required this.subject,
    required this.gstPercent,
    required this.paymentTerms,
    required this.deliveryTerms,
    required this.inspectionRequirement,
    required this.warranty,
    required this.ldClause,
    required this.poDocumentUrl,
    required this.poFileName,
    required this.uploadedAt,
    required this.items,
  });
}
