import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';

class EngineeringBomInquiryLinker {
  final String tenantId;
  final FirebaseFirestore firestore;

  const EngineeringBomInquiryLinker({
    required this.tenantId,
    required this.firestore,
  });

  Future<void> link({
    required String inquiryId,
    required String inquiryItemId,
    required String bomId,
    required String bomNumber,
    required String status,
  }) async {
    if (inquiryId.trim().isEmpty || inquiryItemId.trim().isEmpty) return;
    final inquiryRef = TenantFirestore(
      tenantId: tenantId,
      firestore: firestore,
    ).collection('inquiries').doc(inquiryId.trim());
    debugPrint(
      'BOM_LINK_FOUND path=companies/$tenantId/inquiries/${inquiryId.trim()} '
      'inquiryItemId=${inquiryItemId.trim()} bomId=$bomId '
      'bomNumber=$bomNumber bomStatus=$status',
    );
    final snapshot = await inquiryRef.get();
    if (!snapshot.exists) return;
    final data = snapshot.data() ?? const <String, dynamic>{};
    final products = _linkItems(
      data['products'],
      inquiryItemId,
      bomId,
      bomNumber,
      status,
    );
    final update = <String, dynamic>{
      'bomId': bomId,
      'bomNumber': bomNumber,
      'bomPrepared': true,
      'bomStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (products != null) update['products'] = products;
    await inquiryRef.set(update, SetOptions(merge: true));
    debugPrint(
      'INQUIRY_BOM_LINK inquiryId=$inquiryId inquiryItemId=$inquiryItemId '
      'bomLinked=true bomId=$bomId bomNumber=$bomNumber bomStatus=$status',
    );
  }

  List<Map<String, dynamic>>? _linkItems(
    Object? rawItems,
    String inquiryItemId,
    String bomId,
    String bomNumber,
    String status,
  ) {
    if (rawItems is! List) return null;
    return rawItems
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          if ((map['inquiryItemId'] ?? '').toString() != inquiryItemId) {
            return map;
          }
          return {
            ...map,
            'bomLinked': true,
            'bomId': bomId,
            'bomNumber': bomNumber,
            'bomStatus': status,
          };
        })
        .toList(growable: false);
  }
}
