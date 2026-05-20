import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:QUIK/modules/sales/quotations/models/quotation_model.dart';

class SalesQuotationRepository {
  SalesQuotationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.quotations);
  }

  Future<void> save({
    required String companyId,
    required SalesQuotationModel quotation,
  }) {
    return _collection(companyId).doc(quotation.id).set(quotation.toMap());
  }

  Future<SalesQuotationModel?> getById({
    required String companyId,
    required String quotationId,
  }) async {
    final doc = await _collection(companyId).doc(quotationId).get();
    final data = doc.data();
    if (data == null) return null;
    return SalesQuotationModel.fromMap({...data, 'id': doc.id});
  }

  Stream<List<SalesQuotationModel>> watchAll(String companyId) {
    return _collection(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    SalesQuotationModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }
}
