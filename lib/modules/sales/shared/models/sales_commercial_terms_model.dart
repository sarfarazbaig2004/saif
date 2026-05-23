class SalesCommercialTermsModel {
  final bool freightIncluded;
  final bool packingIncluded;
  final bool insuranceIncluded;
  final bool gstExtra;
  final bool ldApplicable;
  final String paymentTerms;
  final String deliveryTerms;
  final String warrantyTerms;

  const SalesCommercialTermsModel({
    required this.freightIncluded,
    required this.packingIncluded,
    required this.insuranceIncluded,
    required this.gstExtra,
    required this.ldApplicable,
    required this.paymentTerms,
    required this.deliveryTerms,
    required this.warrantyTerms,
  });

  factory SalesCommercialTermsModel.empty() {
    return const SalesCommercialTermsModel(
      freightIncluded: false,
      packingIncluded: false,
      insuranceIncluded: false,
      gstExtra: true,
      ldApplicable: false,
      paymentTerms: '',
      deliveryTerms: '',
      warrantyTerms: '',
    );
  }

  factory SalesCommercialTermsModel.fromMap(Map<String, dynamic> map) {
    return SalesCommercialTermsModel(
      freightIncluded: map['freightIncluded'] == true,
      packingIncluded: map['packingIncluded'] == true,
      insuranceIncluded: map['insuranceIncluded'] == true,
      gstExtra: map['gstExtra'] != false,
      ldApplicable: map['ldApplicable'] == true,
      paymentTerms: (map['paymentTerms'] ?? '').toString(),
      deliveryTerms: (map['deliveryTerms'] ?? '').toString(),
      warrantyTerms: (map['warrantyTerms'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'freightIncluded': freightIncluded,
      'packingIncluded': packingIncluded,
      'insuranceIncluded': insuranceIncluded,
      'gstExtra': gstExtra,
      'ldApplicable': ldApplicable,
      'paymentTerms': paymentTerms,
      'deliveryTerms': deliveryTerms,
      'warrantyTerms': warrantyTerms,
    };
  }
}
