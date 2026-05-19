import 'package:flutter/material.dart';

class PoCustomerPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const PoCustomerPickerDialog({
    super.key,
    required this.customers,
    required this.onSelected,
  });

  @override
  State<PoCustomerPickerDialog> createState() => _PoCustomerPickerDialogState();
}

class _PoCustomerPickerDialogState extends State<PoCustomerPickerDialog> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.customers.where((c) {
      final name = (c['name'] as String).toLowerCase();
      return search.isEmpty || name.contains(search.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search customer...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          title: Text(c['name'] as String),
                          subtitle: (c['email'] as String).isNotEmpty
                              ? Text(c['email'] as String)
                              : null,
                          onTap: () {
                            widget.onSelected(c);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
