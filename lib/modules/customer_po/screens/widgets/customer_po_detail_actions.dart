import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';
import 'package:QUIK/core/verticals/active_vertical_scope.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_record_status_service.dart';
import 'package:QUIK/modules/production/core/production_firestore_utils.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';
import 'package:QUIK/modules/production/job_cards/repositories/job_card_repository.dart';
import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';

class CustomerPoDetailActions extends StatelessWidget {
  final String companyId;
  final String docId;
  final String activeVerticalId;
  final String activeVerticalName;
  final List<ActiveVerticalOption> availableVerticals;
  final bool canChangeVertical;

  const CustomerPoDetailActions({
    super.key,
    required this.companyId,
    required this.docId,
    this.activeVerticalId = '',
    this.activeVerticalName = '',
    this.availableVerticals = const <ActiveVerticalOption>[],
    this.canChangeVertical = false,
  });

  Future<void> _deleteCustomerPo(BuildContext context) async {
    if (!await _canMutatePo(context)) return;
    await CustomerPoRecordStatusService.deleteForTesting(
      companyId: companyId,
      docId: docId,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer PO deleted successfully')),
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
      _verifyActiveVertical(po);

      final repository = JobCardRepository(tenantId: companyId);
      final jobCardId = repository.newJobCardId();
      final items = _mapList(po['items']);
      final quantityLines = _quantityLinesFromItems(items);
      final plannedQty = quantityLines.fold<double>(
        0,
        (total, line) => total + line.quantity,
      );
      final poNumber = _string(po['internalPoNo'] ?? po['poNumber']);
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
      await poSnap.reference.update({
        'status': 'In Production',
        'jobCardCreated': true,
        'jobCardId': jobCardId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  Future<bool> _canMutatePo(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection(SalesCollections.customerPos)
          .doc(docId)
          .get();
      final data = snapshot.data();
      if (data == null) throw StateError('Customer PO not found.');
      _verifyActiveVertical(data);
      return true;
    } catch (error) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
      return false;
    }
  }

  void _verifyActiveVertical(Map<String, dynamic> data) {
    final activeId = activeVerticalId.trim();
    if (activeId.isEmpty) return;
    final recordId = (data['verticalId'] ?? '').toString().trim();
    if (recordId != activeId) {
      throw StateError(
        'This Customer PO does not belong to the active vertical.',
      );
    }
  }

  Future<void> _openEditor(BuildContext context) async {
    if (!await _canMutatePo(context) || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPoFormScreen(
          companyId: companyId,
          existingDocId: docId,
          activeVerticalId: activeVerticalId,
          activeVerticalName: activeVerticalName,
          availableVerticals: availableVerticals,
          canChangeVertical: canChangeVertical,
        ),
      ),
    );
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
          onPressed: () => _openEditor(context),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _deleteCustomerPo(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete Customer PO')),
          ],
        ),
      ],
    );
  }
}
