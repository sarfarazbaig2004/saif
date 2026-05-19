import 'package:flutter/material.dart';

class PoCommercialTab extends StatelessWidget {
  final TextEditingController gstPercent;
  final double basicValue;
  final double gstAmount;
  final double totalValue;
  final Widget Function(
    String label,
    TextEditingController controller, {
    int maxLines,
    TextInputType keyboardType,
    bool required,
    bool readOnly,
  })
  fieldBuilder;
  final Widget Function(String label, String value, {bool bold}) summaryRow;
  final Widget Function({required String title, required Widget child})
  sectionCard;

  const PoCommercialTab({
    super.key,
    required this.gstPercent,
    required this.basicValue,
    required this.gstAmount,
    required this.totalValue,
    required this.fieldBuilder,
    required this.summaryRow,
    required this.sectionCard,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        fieldBuilder('GST %', gstPercent, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        sectionCard(
          title: 'Financial Summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryRow('Basic Value', '₹${basicValue.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              summaryRow(
                'GST (${gstPercent.text.trim()}%)',
                '₹${gstAmount.toStringAsFixed(2)}',
              ),
              const Divider(height: 20),
              summaryRow(
                'Total Value',
                '₹${totalValue.toStringAsFixed(2)}',
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
