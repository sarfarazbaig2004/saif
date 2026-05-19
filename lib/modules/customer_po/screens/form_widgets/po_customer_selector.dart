import 'package:flutter/material.dart';

class PoCustomerSelector extends StatelessWidget {
  final bool hasError;
  final bool isLoadingCustomers;
  final bool isEditMode;
  final String customerName;
  final VoidCallback showCustomerPicker;

  const PoCustomerSelector({
    super.key,
    required this.hasError,
    required this.isLoadingCustomers,
    required this.isEditMode,
    required this.customerName,
    required this.showCustomerPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: (isLoadingCustomers || isEditMode) ? null : showCustomerPicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Customer *',
              border: const OutlineInputBorder(),
              errorText: hasError ? 'Please select a customer' : null,
              filled: isEditMode,
              fillColor: isEditMode ? Colors.grey.shade100 : null,
              suffixIcon: isEditMode
                  ? null
                  : isLoadingCustomers
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              customerName.isEmpty ? 'Select Customer' : customerName,
              style: TextStyle(
                color: customerName.isEmpty ? Colors.grey.shade600 : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Customer details are managed in CRM',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
