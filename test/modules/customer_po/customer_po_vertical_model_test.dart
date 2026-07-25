import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';

void main() {
  group('Customer PO vertical ownership', () {
    test('persists vertical lineage in its map', () {
      const po = CustomerPoModel(
        id: 'po-1',
        companyId: 'company-1',
        verticalId: 'vertical-1',
        verticalName: 'Fabrication',
        internalPoNo: 'PO-001',
        customerId: 'customer-1',
        customerName: 'Customer',
      );

      final data = po.toMap();

      expect(data['verticalId'], 'vertical-1');
      expect(data['verticalName'], 'Fabrication');
    });

    test('legacy PO without vertical stays explicitly unassigned', () {
      final po = CustomerPoModel.fromMap({
        'id': 'legacy-po',
        'companyId': 'company-1',
        'customerId': 'customer-1',
        'customerName': 'Customer',
      });

      expect(po.verticalId, isEmpty);
      expect(po.verticalName, isEmpty);
    });
  });
}
