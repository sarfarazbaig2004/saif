class CustomerPoFormState {
  String internalPoNo = '';
  String customerPoNumber = '';
  String status = 'Draft';
  String customerId = '';
  String customerName = '';

  bool isLoading = false;
  bool isSaving = false;

  void reset() {
    internalPoNo = '';
    customerPoNumber = '';
    status = 'Draft';
    customerId = '';
    customerName = '';
  }
}
