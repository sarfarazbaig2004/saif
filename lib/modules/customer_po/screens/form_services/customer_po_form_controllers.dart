import 'package:flutter/material.dart';

class CustomerPoFormControllers {
  final poNumber = TextEditingController();
  final gstPercent = TextEditingController(text: '18');

  final projectName = TextEditingController();
  final siteLocation = TextEditingController();
  final subject = TextEditingController();

  final paymentTerms = TextEditingController();
  final deliveryTerms = TextEditingController();
  final inspectionRequirement = TextEditingController();
  final warranty = TextEditingController();
  final ldClause = TextEditingController();

  void dispose() {
    poNumber.dispose();
    gstPercent.dispose();
    projectName.dispose();
    siteLocation.dispose();
    subject.dispose();
    paymentTerms.dispose();
    deliveryTerms.dispose();
    inspectionRequirement.dispose();
    warranty.dispose();
    ldClause.dispose();
  }
}
