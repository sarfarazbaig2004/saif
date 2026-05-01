// lib/modules/inventory/products/services/product_service.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import '../../../../models/item_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _productsRef(String companyId) {
    return TenantFirestore(
      tenantId: companyId,
      firestore: _db,
    ).collection('products');
  }

  // 🔴 Active products only (filters out soft-deleted)
  Stream<List<Item>> watchProducts(String companyId) {
    return _productsRef(companyId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Item.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> saveProduct({required Item product, bool isEdit = false}) async {
    final tenantId = TenantFirestore.requireTenantId(product.companyId);
    final data = {
      ...product.toFirestore(),
      'companyId': tenantId,
      'tenantId': tenantId,
    };
    if (isEdit) {
      await _productsRef(tenantId).doc(product.id).update(data);
    } else {
      await _productsRef(tenantId).add(data);
    }
  }

  // 🔴 ERP Standard: Soft Delete
  Future<void> softDeleteProduct(
    String companyId,
    String productId,
    String deletedByUid,
  ) async {
    await _productsRef(companyId).doc(productId).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedByUid': deletedByUid,
    });
  }

  Future<String> uploadProductMedia(
    String companyId,
    String uploaderUid,
    String fileName,
    Uint8List bytes,
    String contentType,
    String folder,
  ) async {
    final ref = _storage.ref().child(
      'companies/$companyId/products/$folder/$fileName',
    );
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'companyId': companyId,
        'tenantId': companyId,
        'uploadedBy': uploaderUid,
        'module': 'products',
      },
    );
    final task = await ref.putData(bytes, metadata);
    if (task.state != TaskState.success) throw Exception('Upload failed');
    return await ref.getDownloadURL();
  }

  // User RBAC Fetcher
  Future<Map<String, dynamic>> loadUserCompanyProfile(
    String uid,
    String tenantId,
  ) async {
    final safeTenantId = TenantFirestore.requireTenantId(tenantId);
    final companyUserDoc = await _db
        .collection('companies')
        .doc(safeTenantId)
        .collection('users')
        .doc(uid)
        .get();
    return {
      ...(companyUserDoc.data() ?? {}),
      'companyId': safeTenantId,
      'tenantId': safeTenantId,
    };
  }
}
