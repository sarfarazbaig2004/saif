import 'package:flutter/material.dart';
import '../models/filter_data.dart';

class InvoiceFilter extends StatelessWidget {
  final Function(FilterData) onFilterChanged;
  const InvoiceFilter({required this.onFilterChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (val) => onFilterChanged(FilterData(search: val)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () {}, child: const Text('Apply')),
        ],
      ),
    );
  }
}
