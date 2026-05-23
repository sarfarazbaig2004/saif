import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoRevisionService {
  const CustomerPoRevisionService._();

  static Future<void> createRevision({
    required String companyId,
    required String docId,
    required int currentRevisionNo,
    required String amendmentReason,
    required String? previousPoDocumentUrl,
    required String? newPoDocumentUrl,
    required String? newPoFileName,
  }) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.customerPos)
        .doc(docId)
        .update({
          'revisionNo': currentRevisionNo + 1,
          'isAmended': true,
          'amendmentReason': amendmentReason,
          'previousPoDocumentUrl': previousPoDocumentUrl,
          'poDocumentUrl': newPoDocumentUrl,
          'poFileName': newPoFileName,
          'amendedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
