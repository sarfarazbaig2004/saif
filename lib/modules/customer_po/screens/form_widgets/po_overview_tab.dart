import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/form_widgets/po_customer_selector.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_detail_row.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_section_card.dart';

class PoOverviewTab extends StatelessWidget {
  final TextEditingController internalPoNo;
  final TextEditingController customerPoNumber;
  final DateTime poDate;
  final String status;
  final bool isEditMode;
  final bool customerErrorVisible;
  final String customerId;
  final bool isLoadingCustomers;
  final String customerName;
  final String customerEmail;
  final String customerMobile;
  final String customerGstNumber;
  final String customerAddress;
  final VoidCallback showCustomerPicker;
  final Widget Function(
    String label,
    TextEditingController controller, {
    int maxLines,
    TextInputType keyboardType,
    bool required,
    bool readOnly,
  })
  fieldBuilder;

  const PoOverviewTab({
    super.key,
    required this.internalPoNo,
    required this.customerPoNumber,
    required this.poDate,
    required this.status,
    required this.isEditMode,
    required this.customerErrorVisible,
    required this.customerId,
    required this.isLoadingCustomers,
    required this.customerName,
    required this.customerEmail,
    required this.customerMobile,
    required this.customerGstNumber,
    required this.customerAddress,
    required this.showCustomerPicker,
    required this.fieldBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        fieldBuilder('Internal PO No', internalPoNo, readOnly: true),
        const SizedBox(height: 12),
        fieldBuilder(
          'Customer PO No',
          customerPoNumber,
          readOnly: status != 'Draft',
        ),
        const SizedBox(height: 12),
        PoFormSectionCard(
          title: 'Customer PO Date',
          child: Text(
            '${poDate.day.toString().padLeft(2, '0')}/${poDate.month.toString().padLeft(2, '0')}/${poDate.year}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        PoCustomerSelector(
          hasError: customerErrorVisible && customerId.isEmpty,
          isLoadingCustomers: isLoadingCustomers,
          isEditMode: isEditMode,
          customerName: customerName,
          showCustomerPicker: showCustomerPicker,
        ),
        const SizedBox(height: 12),
        if (customerName.isNotEmpty)
          PoFormSectionCard(
            title: 'Selected Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customerEmail.isNotEmpty)
                  PoDetailRow(label: 'Email', value: customerEmail),
                if (customerMobile.isNotEmpty)
                  PoDetailRow(label: 'Mobile', value: customerMobile),
                if (customerGstNumber.isNotEmpty)
                  PoDetailRow(label: 'GST', value: customerGstNumber),
                if (customerAddress.isNotEmpty)
                  PoDetailRow(label: 'Address', value: customerAddress),
              ],
            ),
          ),
      ],
    );
  }
}
