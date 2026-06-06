import 'package:flutter/material.dart';
import 'widgets/invoice_filter.dart';
import 'widgets/invoice_table.dart';
import 'widgets/invoice_actions.dart';
import 'services/invoice_service.dart';
import 'models/invoice.dart';
import 'models/filter_data.dart';

class InvoiceExportScreen extends StatefulWidget {
  const InvoiceExportScreen({super.key});

  @override
  State<InvoiceExportScreen> createState() => _InvoiceExportScreenState();
}

class _InvoiceExportScreenState extends State<InvoiceExportScreen> {
  final InvoiceService _service = InvoiceService();
  List<Invoice> invoices = [];
  FilterData currentFilter = FilterData();

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  void _fetchInvoices() async {
    final data = await _service.fetchInvoices(currentFilter);
    setState(() => invoices = data);
  }

  void _onFilterChanged(FilterData filter) {
    setState(() => currentFilter = filter);
    _fetchInvoices();
  }

  void _exportInvoices() async {
    await _service.exportToCSV(invoices);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Invoices exported successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Invoice')),
      body: Column(
        children: [
          InvoiceFilter(onFilterChanged: _onFilterChanged),
          Expanded(child: InvoiceTable(invoices: invoices)),
          InvoiceActions(onExport: _exportInvoices),
        ],
      ),
    );
  }
}
