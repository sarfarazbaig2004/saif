import '../models/invoice.dart';
import '../models/filter_data.dart';

class InvoiceService {
  Future<List<Invoice>> fetchInvoices(FilterData filter) async {
    return []; // Replace with API/database fetch logic
  }

  Future<void> exportToCSV(List<Invoice> invoices) async {
    // Replace with CSV export logic
  }
}
