import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/purchase/purchase_requisitions/models/purchase_requisition_model.dart';
import 'package:QUIK/modules/purchase/purchase_requisitions/repositories/purchase_requisition_repository.dart';

class PurchaseRequisitionListScreen extends StatelessWidget {
  final String tenantId;

  const PurchaseRequisitionListScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();

    if (activeTenantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Select a company workspace first.')),
      );
    }

    final repository = PurchaseRequisitionRepository(tenantId: activeTenantId);

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(title: const Text('Purchase Requisitions')),
      body: StreamBuilder<List<PurchaseRequisitionModel>>(
        stream: repository.watchRequisitions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load purchase requisitions: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requisitions = snapshot.data ?? const [];

          if (requisitions.isEmpty) {
            return const Center(child: Text('No purchase requisitions found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('PR No')),
                    DataColumn(label: Text('MR No')),
                    DataColumn(label: Text('Customer PO')),
                    DataColumn(label: Text('Job Card')),
                    DataColumn(label: Text('BOM')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Purchase Qty')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: requisitions
                      .map((requisition) {
                        return DataRow(
                          cells: [
                            DataCell(Text(_dash(requisition.requisitionNo))),
                            DataCell(
                              Text(_dash(requisition.materialRequirementNo)),
                            ),
                            DataCell(Text(_dash(requisition.poNumber))),
                            DataCell(Text(_dash(requisition.jobCardNo))),
                            DataCell(Text(_dash(requisition.bomNumber))),
                            DataCell(Text(_dash(requisition.customerName))),
                            DataCell(Text(_qty(requisition.totalPurchaseQty))),
                            DataCell(Text(_dash(requisition.status))),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _dash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  static String _qty(double value) {
    return value.toStringAsFixed(2);
  }
}
