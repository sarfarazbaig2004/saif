import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_field.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_summary_row.dart';

class PoFormHelpers {
  const PoFormHelpers._();

  static Widget field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return PoFormField(
      label: label,
      controller: controller,
      requiredField: required,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  static Widget summaryRow(String label, String value, {bool bold = false}) {
    return PoSummaryRow(label: label, value: value, bold: bold);
  }
}
