import 'package:cloud_firestore/cloud_firestore.dart';
import 'coating_master_model.dart';

class CoatingMasterRepository {
  final String tenantId;

  CoatingMasterRepository({required this.tenantId});

  CollectionReference<Map<String, dynamic>> get _ref => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(tenantId)
      .collection('coating_master');

  Stream<List<CoatingMasterModel>> watch() {
    return _ref.snapshots().map(
      (snap) => snap.docs
          .map((d) => CoatingMasterModel.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  Future<void> save(CoatingMasterModel model) async {
    final id = model.id.isEmpty
        ? '${model.status}_${model.spec}'.replaceAll(' ', '_').toLowerCase()
        : model.id;

    await _ref.doc(id).set(model.toMap(), SetOptions(merge: true));
  }
}
