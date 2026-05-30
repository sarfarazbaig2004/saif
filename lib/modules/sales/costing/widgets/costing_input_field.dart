import 'package:flutter/material.dart';

class CostingInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final ValueChanged<String> onChanged;

  const CostingInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: label == 'Item Name'
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        validator: requiredField
            ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
            : null,
        onChanged: onChanged,
      ),
    );
  }
}
