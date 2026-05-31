import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/material_requirements/models/material_requirement_model.dart';
import 'package:QUIK/modules/production/material_requirements/services/material_requirement_pr_service.dart';

class MaterialRequirementDetailScreen extends StatelessWidget {
  final String tenantId;
  final MaterialRequirementModel requirement;

  const MaterialRequirementDetailScreen({
    super.key,
    required this.tenantId,
    required this.requirement,
  });

  Future<void> _createPurchaseRequisition(BuildContext context) async {
    try {
      final requisition = await MaterialRequirementPrService(
        tenantId: tenantId,
      ).createFromRequirement(requirement: requirement);

      if (!context.mounted) return;

      final message = requisition == null
          ? 'No purchase required. Shortage quantity is zero.'
          : 'Purchase requisition created: ${requisition.requisitionNo}';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create purchase requisition: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: Text(requirement.requirementNo),
        actions: [
          TextButton.icon(
            onPressed: () => _createPurchaseRequisition(context),
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: const Text('Create PR'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(requirement: requirement),
            const SizedBox(height: 12),
            _LinesCard(requirement: requirement),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final MaterialRequirementModel requirement;

  const _HeaderCard({required this.requirement});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Info(label: 'MR No', value: requirement.requirementNo),
            _Info(label: 'Customer', value: requirement.customerName),
            _Info(label: 'Customer PO', value: requirement.poNumber),
            _Info(label: 'Job Card', value: requirement.jobCardNo),
            _Info(label: 'BOM', value: requirement.bomNumber),
            _Info(label: 'Status', value: requirement.status),
          ],
        ),
      ),
    );
  }
}

class _LinesCard extends StatelessWidget {
  final MaterialRequirementModel requirement;

  const _LinesCard({required this.requirement});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Line')),
            DataColumn(label: Text('Material')),
            DataColumn(label: Text('Section')),
            DataColumn(label: Text('Required')),
            DataColumn(label: Text('Available')),
            DataColumn(label: Text('Reserved')),
            DataColumn(label: Text('Shortage')),
            DataColumn(label: Text('Purchase Required')),
            DataColumn(label: Text('Unit')),
          ],
          rows: requirement.lines
              .map((line) {
                return DataRow(
                  cells: [
                    DataCell(Text(line.lineNo.toString())),
                    DataCell(Text(_dash(line.material))),
                    DataCell(Text(_dash(line.section))),
                    DataCell(Text(_qty(line.requiredQty))),
                    DataCell(Text(_qty(line.availableQty))),
                    DataCell(Text(_qty(line.reservedQty))),
                    DataCell(Text(_qty(line.shortageQty))),
                    DataCell(Text(_qty(line.purchaseRequiredQty))),
                    DataCell(Text(_dash(line.unit))),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  static String _qty(double value) => value.toStringAsFixed(2);

  static String _dash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;

  const _Info({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: zMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: const TextStyle(
              color: zText,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
