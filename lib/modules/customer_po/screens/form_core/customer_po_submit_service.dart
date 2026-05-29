import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoSubmitService {
  static Future<void> submit({
    required String companyId,
    required String internalPoNo,
    String customerPoNumber = '',
    required String customerId,
    required String status,
  }) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('customer_pos')
        .add({
          'internalPoNo': internalPoNo,
          'poNumber': internalPoNo,
          'customerPoNumber': customerPoNumber,
          'customerId': customerId,
          'status': status,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
