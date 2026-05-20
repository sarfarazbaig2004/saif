import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoDuplicateService {
  const CustomerPoDuplicateService._();

  static Future<String?> findDuplicatePoId({
    required String companyId,
    required String customerId,
    required String poNumber,
    String? currentDocId,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.customerPos)
        .where('customerId', isEqualTo: customerId)
        .where('poNumber', isEqualTo: poNumber.trim())
        .limit(5)
        .get();

    for (final doc in snap.docs) {
      if (doc.id != currentDocId) {
        return doc.id;
      }
    }

    return null;
  }
}
