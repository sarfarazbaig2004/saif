import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/sales/shared/models/sales_revision_model.dart';

class SalesRevisionRepository {
  final FirebaseFirestore _db;

  SalesRevisionRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _db
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.revisions);
  }

  Future<void> save({
    required String companyId,
    required SalesRevisionModel revision,
  }) {
    return _collection(
      companyId,
    ).doc(revision.revisionCode).set(revision.toMap());
  }

  Future<SalesRevisionModel?> getById({
    required String companyId,
    required String revisionId,
  }) async {
    final doc = await _collection(companyId).doc(revisionId).get();
    final data = doc.data();
    if (data == null) return null;
    return SalesRevisionModel.fromMap({...data, 'id': doc.id});
  }

  Stream<List<SalesRevisionModel>> watchBySource({
    required String companyId,
    required String sourceId,
  }) {
    return _collection(companyId)
        .where('sourceId', isEqualTo: sourceId)
        .orderBy('revisionNo', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    SalesRevisionModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }
}
