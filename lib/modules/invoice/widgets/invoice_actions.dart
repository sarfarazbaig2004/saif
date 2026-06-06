import 'package:flutter/material.dart';

class InvoiceActions extends StatelessWidget {
  final VoidCallback onExport;
  const InvoiceActions({required this.onExport, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(onPressed: onExport, child: const Text('Export CSV')),
        ],
      ),
    );
  }
}
