import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';

class CustomerPoRepository {
  CustomerPoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.customerPos);
  }

  Future<void> save({required String companyId, required CustomerPoModel po}) {
    return _collection(companyId).doc(po.id).set(po.toMap());
  }

  Future<void> createCustomerPo(CustomerPoModel po) {
    return save(companyId: po.companyId, po: po);
  }

  Future<void> updateCustomerPo(CustomerPoModel po) {
    return save(companyId: po.companyId, po: po);
  }

  Future<CustomerPoModel?> getById({
    required String companyId,
    required String poId,
  }) async {
    final doc = await _collection(companyId).doc(poId).get();
    final data = doc.data();
    if (data == null) return null;
    return CustomerPoModel.fromMap({...data, 'id': doc.id});
  }

  Stream<List<CustomerPoModel>> watchAll(String companyId) {
    return _collection(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CustomerPoModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }
}
