class CustomerPoFormState {
  String poNumber = '';
  String status = 'Draft';
  String customerId = '';
  String customerName = '';

  bool isLoading = false;
  bool isSaving = false;

  void reset() {
    poNumber = '';
    status = 'Draft';
    customerId = '';
    customerName = '';
  }
}
