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
        .set({...po.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateCustomerPo(CustomerPoModel po) async {
    await _firestore
        .collection('companies')
        .doc(po.companyId)
        .collection('customer_pos')
        .doc(po.id)
        .update({...po.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
  }
}
