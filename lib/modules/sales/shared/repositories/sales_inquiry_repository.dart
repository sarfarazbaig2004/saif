import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:QUIK/modules/sales/inquiries/models/inquiry_model.dart';

class SalesInquiryRepository {
  SalesInquiryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('sales_inquiries');
  }

  Future<void> save({
    required String companyId,
    required SalesInquiryModel inquiry,
  }) {
    return _collection(companyId).doc(inquiry.id).set(inquiry.toMap());
  }

  Future<SalesInquiryModel?> getById({
    required String companyId,
    required String inquiryId,
  }) async {
    final doc = await _collection(companyId).doc(inquiryId).get();
    final data = doc.data();
    if (data == null) return null;
    return SalesInquiryModel.fromMap({...data, 'id': doc.id});
  }

  Stream<List<SalesInquiryModel>> watchAll(String companyId) {
    return _collection(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    SalesInquiryModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }
}
