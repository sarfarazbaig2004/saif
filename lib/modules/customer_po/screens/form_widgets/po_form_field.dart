import 'package:flutter/material.dart';

class PoFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool requiredField;
  final bool readOnly;
  final TextInputType keyboardType;
  final int maxLines;

  const PoFormField({
    super.key,
    required this.label,
    required this.controller,
    this.requiredField = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
      ),
    );
  }
}
