enum CustomerPoStatus {
  draft,
  received,
  underReview,
  accepted,
  amended,
  inProduction,
  partiallyDispatched,
  dispatched,
  billed,
  closed,
  cancelled,
}

extension CustomerPoStatusX on CustomerPoStatus {
  String get value {
    return name;
  }

  static CustomerPoStatus fromValue(String? value) {
    return CustomerPoStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CustomerPoStatus.draft,
    );
  }
}
