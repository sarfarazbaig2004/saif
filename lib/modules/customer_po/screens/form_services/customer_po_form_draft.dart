import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';

class CustomerPoFormDraft {
  final String id;
  final String companyId;
  final String verticalId;
  final String verticalName;
  final String internalPoNo;
  final String customerPoNumber;
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
  final List<CustomerPoItemRow> items;
  final String? poDocumentUrl;
  final String? poFileName;
  final DateTime? uploadedAt;

  const CustomerPoFormDraft({
    required this.id,
    required this.companyId,
    required this.verticalId,
    required this.verticalName,
    required this.internalPoNo,
    required this.customerPoNumber,
    required this.poDate,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerMobile,
    required this.customerAddress,
    required this.customerGstNumber,
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
    required this.items,
    required this.poDocumentUrl,
    required this.poFileName,
    required this.uploadedAt,
  });
}
