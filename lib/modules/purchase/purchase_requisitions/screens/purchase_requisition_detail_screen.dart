import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/purchase/purchase_requisitions/models/purchase_requisition_model.dart';
import 'package:QUIK/modules/purchase/purchase_requisitions/widgets/purchase_requisition_line_table.dart';

class PurchaseRequisitionDetailScreen extends StatelessWidget {
  final PurchaseRequisitionModel requisition;

  const PurchaseRequisitionDetailScreen({super.key, required this.requisition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(title: Text(requisition.requisitionNo)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(requisition: requisition),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              child: PurchaseRequisitionLineTable(lines: requisition.lines),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PurchaseRequisitionModel requisition;

  const _HeaderCard({required this.requisition});

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
            _Info(label: 'PR No', value: requisition.requisitionNo),
            _Info(label: 'MR No', value: requisition.materialRequirementNo),
            _Info(label: 'Customer', value: requisition.customerName),
            _Info(label: 'Customer PO', value: requisition.poNumber),
            _Info(label: 'Job Card', value: requisition.jobCardNo),
            _Info(label: 'BOM', value: requisition.bomNumber),
            _Info(
              label: 'Purchase Qty',
              value: _qty(requisition.totalPurchaseQty),
            ),
            _Info(label: 'Status', value: requisition.status),
          ],
        ),
      ),
    );
  }

  static String _qty(double value) => value.toStringAsFixed(2);
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
