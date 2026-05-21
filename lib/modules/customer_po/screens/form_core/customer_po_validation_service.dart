class CustomerPoValidationService {
  static String? validatePoNumber(String value) {
    if (value.trim().isEmpty) {
      return 'PO Number is required';
    }
    if (value.length < 3) {
      return 'PO Number too short';
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
