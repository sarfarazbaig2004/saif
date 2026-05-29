class CustomerPoValidationService {
  static String? validateInternalPoNo(String value) {
    if (value.trim().isEmpty) {
      return 'Internal PO number is required';
    }
    if (value.length < 3) {
      return 'Internal PO number too short';
    }
    return null;
  }

  static String? validateCustomer(String customerId) {
    if (customerId.trim().isEmpty) {
      return 'Customer is required';
    }
    return null;
  }
}
