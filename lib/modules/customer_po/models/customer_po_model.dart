class CustomerPoModel {
  final String id;
  final String companyId;
  final String poNumber;
  final DateTime poDate;
  final String customerName;
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

  const CustomerPoModel({
    required this.id,
    required this.companyId,
    required this.poNumber,
    required this.poDate,
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
    this.poFileUrl,
  });
}
