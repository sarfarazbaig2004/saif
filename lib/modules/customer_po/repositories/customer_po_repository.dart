import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';

class CustomerPoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createCustomerPo(CustomerPoModel po) async {
    await _firestore
        .collection('companies')
        .doc(po.companyId)
        .collection('customer_pos')
        .doc(po.id)
        .set({
          'id': po.id,
          'companyId': po.companyId,
          'poNumber': po.poNumber,
          'poDate': po.poDate.toIso8601String(),
          'customerName': po.customerName,
          'projectName': po.projectName,
          'siteLocation': po.siteLocation,
          'subject': po.subject,
          'basicValue': po.basicValue,
          'gstPercent': po.gstPercent,
          'gstAmount': po.gstAmount,
          'totalValue': po.totalValue,
          'paymentTerms': po.paymentTerms,
          'deliveryTerms': po.deliveryTerms,
          'inspectionRequirement': po.inspectionRequirement,
          'warranty': po.warranty,
          'ldClause': po.ldClause,
          'status': po.status,
          'poFileUrl': po.poFileUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
