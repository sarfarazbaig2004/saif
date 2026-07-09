import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/purchase/purchase_orders/models/purchase_order_model.dart';

class PurchaseOrderRepository {
  PurchaseOrderRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref => _firestore
      .collection('companies')
      .doc(tenantId.trim())
      .collection('purchase_orders');

  CollectionReference<Map<String, dynamic>> get vendorsRef => _firestore
      .collection('companies')
      .doc(tenantId.trim())
      .collection('vendors');

  String newPurchaseOrderId() => _ref.doc().id;

  String nextPoNumber() {
    final now = DateTime.now();
    final suffix = (now.millisecondsSinceEpoch % 100000).toString().padLeft(
      5,
      '0',
    );
    return 'PO-${now.year}-$suffix';
  }

  Stream<List<PurchaseOrderModel>> watchPurchaseOrders() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PurchaseOrderModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> save(PurchaseOrderModel order) {
    final isCreate = order.id.trim().isEmpty;
    final docRef = isCreate ? _ref.doc() : _ref.doc(order.id);
    final normalizedOrder = isCreate ? order.copyWith(id: docRef.id) : order;

    return docRef.set(
      normalizedOrder.toFirestore(isCreate: isCreate),
      SetOptions(merge: true),
    );
  }

  Future<void> updateStatus({
    required String purchaseOrderId,
    required String status,
    String approvedByUid = '',
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == PurchaseOrderModel.statusApproved) {
      data['approvedByUid'] = approvedByUid;
      data['approvedAt'] = FieldValue.serverTimestamp();
    }

    await _ref.doc(purchaseOrderId).set(data, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> fetchVendors() async {
    final snapshot = await vendorsRef.orderBy('nameLower').limit(300).get();
    return snapshot.docs
        .where((doc) => doc.data()['isDeleted'] != true)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList(growable: false);
  }
}
