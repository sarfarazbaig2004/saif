import 'package:flutter/material.dart';

import 'package:QUIK/modules/purchase/purchase_requisitions/models/purchase_requisition_model.dart';

class PurchaseRequisitionLineTable extends StatelessWidget {
  final List<PurchaseRequisitionLineModel> lines;

  const PurchaseRequisitionLineTable({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No purchase requisition lines found.'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Material')),
          DataColumn(label: Text('Section')),
          DataColumn(label: Text('Required')),
          DataColumn(label: Text('Available')),
          DataColumn(label: Text('Reserved')),
          DataColumn(label: Text('Purchase Qty')),
          DataColumn(label: Text('Unit')),
        ],
        rows: lines
            .map((line) {
              return DataRow(
                cells: [
                  DataCell(Text(_text(line.material))),
                  DataCell(Text(_text(line.section))),
                  DataCell(Text(_qty(line.requiredQty))),
                  DataCell(Text(_qty(line.availableQty))),
                  DataCell(Text(_qty(line.reservedQty))),
                  DataCell(Text(_qty(line.purchaseQty))),
                  DataCell(Text(_text(line.unit))),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }

  static String _text(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  static String _qty(double value) {
    return value.toStringAsFixed(2);
  }
}
