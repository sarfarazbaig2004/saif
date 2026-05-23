enum InquiryStatus {
  draft,
  submitted,
  underReview,
  estimated,
  quoted,
  won,
  lost,
  cancelled,
  converted,
}

extension InquiryStatusX on InquiryStatus {
  String get value {
    return name;
  }

  static InquiryStatus fromValue(String? value) {
    return InquiryStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => InquiryStatus.draft,
    );
  }
}
