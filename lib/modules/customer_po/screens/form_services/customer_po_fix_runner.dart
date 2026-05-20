import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoFixRunner {
  static Future<void> fixPoNumber({
    required String companyId,
    required String docId,
  }) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('customer_pos')
        .doc(docId)
        .update({
      'poNumberFixed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
