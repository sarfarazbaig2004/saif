import 'package:flutter/material.dart';

class PoTermsTab extends StatelessWidget {
  final TextEditingController paymentTerms;
  final TextEditingController deliveryTerms;
  final TextEditingController inspectionRequirement;
  final TextEditingController warranty;
  final TextEditingController ldClause;
  final Widget Function(
    String label,
    TextEditingController controller, {
    int maxLines,
    TextInputType keyboardType,
    bool required,
    bool readOnly,
  })
  fieldBuilder;

  const PoTermsTab({
    super.key,
    required this.paymentTerms,
    required this.deliveryTerms,
    required this.inspectionRequirement,
    required this.warranty,
    required this.ldClause,
    required this.fieldBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        fieldBuilder('Payment Terms', paymentTerms, maxLines: 3),
        const SizedBox(height: 12),
        fieldBuilder('Delivery Terms', deliveryTerms, maxLines: 3),
        const SizedBox(height: 12),
        fieldBuilder(
          'Inspection Requirement',
          inspectionRequirement,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        fieldBuilder('Warranty', warranty, maxLines: 2),
        const SizedBox(height: 12),
        fieldBuilder('LD Clause', ldClause, maxLines: 3),
      ],
    );
  }
}
