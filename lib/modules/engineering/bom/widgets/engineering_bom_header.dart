import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class EngineeringBomHeader extends StatelessWidget {
  final TextEditingController bomNo;
  final TextEditingController inquiryId;
  final TextEditingController customer;
  final TextEditingController project;
  final TextEditingController projectQuantity;
  final TextEditingController revision;
  final VoidCallback onChanged;

  const EngineeringBomHeader({
    super.key,
    required this.bomNo,
    required this.inquiryId,
    required this.customer,
    required this.project,
    required this.projectQuantity,
    required this.revision,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fields = [
      _field(bomNo, 'BOM No', required: true),
      _field(inquiryId, 'Inquiry ID'),
      _field(customer, 'Customer', required: true),
      _field(project, 'Project'),
      _field(projectQuantity, 'Project / Structure Qty', number: true),
      _field(revision, 'Revision'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 820
            ? Column(children: fields.map(_gap).toList())
            : Wrap(spacing: 12, runSpacing: 12, children: fields),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
  }) {
    return SizedBox(
      width: 220,
      child: TextFormField(
        controller: controller,
        decoration: bomInputDecoration(label),
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        onChanged: (_) => onChanged(),
        validator: required
            ? (value) => (value ?? '').trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _gap(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
}

class EngineeringBomSummary extends StatelessWidget {
  final double weightPerStructure;
  final double totalProjectWeight;
  final VoidCallback onAddLine;

  const EngineeringBomSummary({
    super.key,
    required this.weightPerStructure,
    required this.totalProjectWeight,
    required this.onAddLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(color: zBlueSoft),
      child: Row(
        children: [
          const Icon(Icons.scale_outlined, color: zBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Weight per structure: ${weightPerStructure.toStringAsFixed(3)} kg'
              '  •  Total project weight: ${totalProjectWeight.toStringAsFixed(3)} kg',
              style: const TextStyle(fontWeight: FontWeight.w800, color: zText),
            ),
          ),
          FilledButton.icon(
            onPressed: onAddLine,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Line'),
          ),
        ],
      ),
    );
  }
}

InputDecoration bomInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: zSurfaceSoft,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: zBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: zBlue, width: 1.2),
    ),
  );
}

BoxDecoration _box({Color color = Colors.white}) => BoxDecoration(
  color: color,
  border: Border.all(color: zBorder),
  borderRadius: BorderRadius.circular(12),
);
