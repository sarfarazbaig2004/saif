import 'package:flutter/material.dart';
import '../models/invoice.dart';

class InvoiceTable extends StatelessWidget {
  final List<Invoice> invoices;
  const InvoiceTable({required this.invoices, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: invoices.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(invoices[i].number),
        subtitle: Text(invoices[i].customer),
        trailing: Text('\$${invoices[i].amount}'),
      ),
    );
  }
}
