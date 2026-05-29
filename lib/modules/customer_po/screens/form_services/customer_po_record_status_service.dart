import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoRecordStatusService {
  const CustomerPoRecordStatusService._();

  static Future<void> deleteForTesting({
    required String companyId,
    required String docId,
  }) async {
    final poRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.customerPos)
        .doc(docId);
    final poSnap = await poRef.get();
    final poData = poSnap.data();
    final linkedQuotationId =
        (poData?['linkedQuotationId'] ?? poData?['quotationId'] ?? '')
            .toString()
            .trim();

    await poRef.delete();

    if (linkedQuotationId.isEmpty) return;

    final quotationRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('quotations')
        .doc(linkedQuotationId);
    final quotationSnap = await quotationRef.get();
    if (!quotationSnap.exists) return;

    await quotationRef.update({
      'status': 'Approved',
      'convertedToCustomerPo': false,
      'convertedToCustomerPoId': '',
      'customerPoNo': '',
      'internalPoNo': '',
      'poNumber': '',
      'convertedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
