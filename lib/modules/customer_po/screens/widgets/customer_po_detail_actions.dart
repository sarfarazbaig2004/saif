import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_record_status_service.dart';
import 'package:QUIK/modules/production/core/production_firestore_utils.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';
import 'package:QUIK/modules/production/job_cards/repositories/job_card_repository.dart';
import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';

class CustomerPoDetailActions extends StatelessWidget {
  final String companyId;
  final String docId;

  const CustomerPoDetailActions({
    super.key,
    required this.companyId,
    required this.docId,
  });

  Future<void> _markDuplicate(BuildContext context) async {
    await CustomerPoRecordStatusService.markAsDuplicate(
      companyId: companyId,
      docId: docId,
      reason: 'Created twice by mistake',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate Customer PO deleted from active list'),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _createJobCard(BuildContext context) async {
    try {
      final poSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection(SalesCollections.customerPos)
          .doc(docId)
          .get();
      final po = poSnap.data();
      if (po == null) {
        throw StateError('Customer PO not found.');
      }

      final repository = JobCardRepository(tenantId: companyId);
      final jobCardId = repository.newJobCardId();
      final items = _mapList(po['items']);
      final quantityLines = _quantityLinesFromItems(items);
      final plannedQty = quantityLines.fold<double>(
        0,
        (total, line) => total + line.quantity,
      );
      final poNumber = _string(po['customerPoNo'] ?? po['poNumber']);
      final projectName = _string(po['projectName'] ?? po['subject']);

      final jobCard = JobCardModel(
        jobCardId: jobCardId,
        jobCardNo: 'JC-${DateTime.now().millisecondsSinceEpoch}',
        projectCode: projectName,
        customerName: _string(po['customerName']),
        poNumber: poNumber,
        division: 'Production',
        productCode: '',
        productName: projectName.isEmpty ? poNumber : projectName,
        contractor: '',
        drawingNo: '',
        drawingRevision: '',
        revisionNo: '',
        bomId: _string(
          po['bomMetadata'] is Map
              ? (po['bomMetadata'] as Map)['engineeringBomId']
              : '',
        ),
        bomReference: _string(po['bomMetadata']),
        boqId: '',
        plannedQty: plannedQty,
        completedQty: 0,
        balanceQty: plannedQty,
        quantityLines: quantityLines,
        unit: quantityLines.isEmpty ? 'nos' : quantityLines.first.unit,
        plannedStartDate: null,
        plannedEndDate: null,
        targetDate: null,
        dispatchCommitmentDate: null,
        priority: 'normal',
        status: 'draft',
        delayReason: '',
        remarks: 'Created from Customer PO $poNumber',
        tenantId: companyId,
        companyId: companyId,
        createdBy: '',
        customerPoId: docId,
        quotationFormat: _string(po['quotationFormat']).isEmpty
            ? 'commercial'
            : _string(po['quotationFormat']),
        sourcePoItems: items,
        bomMetadata: po['bomMetadata'] is Map
            ? Map<String, dynamic>.from(po['bomMetadata'] as Map)
            : const {},
      );

      await repository.saveJobCard(jobCard);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Production job card draft created.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create job card: $e')));
    }
  }

  List<JobCardQuantityLine> _quantityLinesFromItems(
    List<Map<String, dynamic>> items,
  ) {
    final lines = items
        .map((item) {
          final label = _firstNonEmpty([
            item['bomSection'],
            item['itemName'],
            item['description'],
          ]);
          final bomWeight = doubleFromValue(item['bomWeight']);
          final qty = bomWeight > 0
              ? bomWeight
              : doubleFromValue(item['quantity']);
          final unit = bomWeight > 0
              ? 'KG'
              : _string(item['uom'] ?? item['unit']);
          return JobCardQuantityLine(
            label: label.isEmpty ? 'PO Item' : label,
            quantity: qty,
            unit: unit.isEmpty ? 'nos' : unit,
          );
        })
        .where((line) => line.quantity > 0)
        .toList(growable: false);

    if (lines.isNotEmpty) return lines;
    return const [
      JobCardQuantityLine(label: 'Total', quantity: 1, unit: 'nos'),
    ];
  }

  List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _string(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _string(Object? value) {
    return value?.toString().trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => _createJobCard(context),
          icon: const Icon(Icons.precision_manufacturing_outlined),
          label: const Text('Create Job Card'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit PO',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerPoFormScreen(
                companyId: companyId,
                existingDocId: docId,
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'duplicate') _markDuplicate(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'duplicate',
              child: Text('Delete Duplicate Entry'),
            ),
          ],
        ),
      ],
    );
  }
}
