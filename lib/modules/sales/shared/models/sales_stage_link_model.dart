class SalesStageLinkModel {
  final String inquiryId;
  final String quotationId;
  final String customerPoId;
  final String proformaInvoiceId;
  final String taxInvoiceId;
  final String dispatchId;
  final String sourceType;

  const SalesStageLinkModel({
    required this.inquiryId,
    required this.quotationId,
    required this.customerPoId,
    required this.proformaInvoiceId,
    required this.taxInvoiceId,
    required this.dispatchId,
    required this.sourceType,
  });

  factory SalesStageLinkModel.empty() {
    return const SalesStageLinkModel(
      inquiryId: '',
      quotationId: '',
      customerPoId: '',
      proformaInvoiceId: '',
      taxInvoiceId: '',
      dispatchId: '',
      sourceType: 'direct',
    );
  }

  factory SalesStageLinkModel.fromMap(Map<String, dynamic> map) {
    return SalesStageLinkModel(
      inquiryId: (map['inquiryId'] ?? '').toString(),
      quotationId: (map['quotationId'] ?? '').toString(),
      customerPoId: (map['customerPoId'] ?? '').toString(),
      proformaInvoiceId: (map['proformaInvoiceId'] ?? '').toString(),
      taxInvoiceId: (map['taxInvoiceId'] ?? '').toString(),
      dispatchId: (map['dispatchId'] ?? '').toString(),
      sourceType: (map['sourceType'] ?? 'direct').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inquiryId': inquiryId,
      'quotationId': quotationId,
      'customerPoId': customerPoId,
      'proformaInvoiceId': proformaInvoiceId,
      'taxInvoiceId': taxInvoiceId,
      'dispatchId': dispatchId,
      'sourceType': sourceType,
    };
  }
}
