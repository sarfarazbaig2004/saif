import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/modules/inventory/fabrication/models/raw_material_inward_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_issue_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_transaction_model.dart';

void main() {
  group('inventory vertical ownership', () {
    test('raw material master persists its vertical', () {
      const material = RawMaterialModel(
        materialId: 'material-1',
        verticalId: 'vertical-1',
        verticalName: 'Fabrication',
        materialCode: 'RM-001',
        descriptionThickness: 'MS Plate',
        gradeIs: 'IS 2062',
        length: 6000,
        unitWeight: 12.5,
        uom: 'Kg',
        category: 'Steel',
        productFamily: 'Plate',
        reorderLevel: 100,
        remarks: '',
        isActive: true,
      );

      final data = material.toFirestore();

      expect(data['verticalId'], 'vertical-1');
      expect(data['verticalName'], 'Fabrication');
    });

    test('stock transaction persists its vertical', () {
      final transaction = RawMaterialTransactionModel(
        transactionId: 'transaction-1',
        verticalId: 'vertical-2',
        verticalName: 'Precast',
        transactionType: RawMaterialTransactionType.inward,
        transactionDate: DateTime(2026, 7, 25),
        materialId: 'material-2',
        materialCode: 'RM-002',
        materialDescription: 'Cement',
        grade: 'OPC 53',
        length: 0,
        unitWeight: 0,
        uom: 'Bag',
        category: 'Cement',
        productFamily: 'Cement',
        plantName: 'Plant 2',
        warehouseName: 'Main Store',
        quantityNos: 10,
        quantityKg: 500,
        referenceNo: 'GRN-1',
        partyOrProcess: 'Supplier',
        workOrderId: '',
        heatNumber: '',
        batchNo: '',
        millCertificateUrl: '',
        qaReferenceId: '',
        remarks: '',
      );

      final data = transaction.toFirestore();

      expect(data['verticalId'], 'vertical-2');
      expect(data['verticalName'], 'Precast');
    });

    test('legacy inward and issue records remain backward compatible', () {
      const inward = RawMaterialInwardModel(
        inwardId: 'inward-1',
        supplierName: 'Supplier',
        challanNo: 'CH-1',
        materialDescription: 'Steel',
        grade: 'A',
        lengthMm: 1000,
        unitWeightKgPerM: 1,
        quantityKg: 10,
        quantityNos: 10,
        remarks: '',
      );
      const issue = RawMaterialIssueModel(
        issueId: 'issue-1',
        issuedTo: 'Cutting',
        workOrderId: 'WO-1',
        materialDescription: 'Steel',
        grade: 'A',
        lengthMm: 1000,
        unitWeightKgPerM: 1,
        quantityKg: 2,
        remarks: '',
      );

      expect(inward.toFirestore()['verticalId'], isEmpty);
      expect(issue.toFirestore()['verticalId'], isEmpty);
    });
  });
}
