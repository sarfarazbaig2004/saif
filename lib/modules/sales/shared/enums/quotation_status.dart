enum QuotationStatus {
  draft,
  underReview,
  approved,
  sent,
  revised,
  accepted,
  rejected,
  cancelled,
  converted,
}

extension QuotationStatusX on QuotationStatus {
  String get value {
    return name;
  }

  static QuotationStatus fromValue(String? value) {
    return QuotationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => QuotationStatus.draft,
    );
  }
}
