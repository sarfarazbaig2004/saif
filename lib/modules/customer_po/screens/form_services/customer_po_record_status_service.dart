import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoRecordStatusService {
  const CustomerPoRecordStatusService._();

  static Future<void> markAsDuplicate({
    required String companyId,
    required String docId,
    required String reason,
  }) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.customerPos)
        .doc(docId)
        .update({
          'isDeleted': true,
          'recordStatus': 'duplicate',
          'duplicateReason': reason,
          'markedDuplicateAt': FieldValue.serverTimestamp(),
        });
  }
}
