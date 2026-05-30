import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_model.dart';
import 'package:QUIK/modules/engineering/bom/repositories/engineering_bom_audit_helper.dart';
import 'package:QUIK/modules/engineering/bom/repositories/engineering_bom_inquiry_linker.dart';

class EngineeringBomRepository {
  EngineeringBomRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('engineering_boms');
  }

  String newBomId() => _ref.doc().id;

  Future<EngineeringBomModel?> getBom(String bomId) async {
    final id = bomId.trim();
    if (id.isEmpty) return null;
    final snapshot = await _ref.doc(id).get();
    if (!snapshot.exists) return null;
    return EngineeringBomModel.fromFirestore(snapshot);
  }

  Future<EngineeringBomModel?> findForInquiryItem({
    required String inquiryId,
    required String inquiryItemId,
  }) async {
    final inquiry = inquiryId.trim();
    final item = inquiryItemId.trim();
    if (inquiry.isEmpty || item.isEmpty) return null;
    final snapshot = await _ref
        .where('inquiryId', isEqualTo: inquiry)
        .where('inquiryItemId', isEqualTo: item)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final bom = EngineeringBomModel.fromFirestore(snapshot.docs.first);
    debugPrint('BOM_FOUND bomId=${bom.id}');
    return bom;
  }

  Future<String> nextBomNo() async {
    final normalizedTenantId = TenantFirestore.requireTenantId(tenantId);
    final counterRef = _firestore
        .collection('companies')
        .doc(normalizedTenantId)
        .collection('counters')
        .doc('engineering_bom');
    final next = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final current = (snapshot.data()?['lastNo'] as num?)?.toInt() ?? 0;
      final value = current + 1;
      transaction.set(counterRef, {
        'lastNo': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return value;
    });
    return 'ENG-BOM-${next.toString().padLeft(4, '0')}';
  }

  Future<EngineeringBomSaveResult> saveBom(
    EngineeringBomModel bom, {
    String changedBy = '',
    String changedByName = '',
  }) async {
    final docRef = _ref.doc(bom.id);
    final existing = await docRef.get();
    final now = FieldValue.serverTimestamp();
    final audit = EngineeringBomAuditHelper.entry(
      action: existing.exists ? 'updated' : 'created',
      changedBy: changedBy,
      changedByName: changedByName,
      changes: existing.exists
          ? EngineeringBomAuditHelper.summary(existing.data() ?? const {}, bom)
          : ['BOM created as ${bom.status}'],
    );

    if (existing.exists && _isApproved(existing.data()?['status'])) {
      final newRef = _ref.doc();
      final existingData = existing.data() ?? const <String, dynamic>{};
      final nextRevision = _nextRevisionLabel(
        (existingData['revision'] ?? bom.revision).toString(),
      );
      final revisedBom = bom.copyForRevision(
        id: newRef.id,
        revision: nextRevision,
        status: 'Draft',
        revisionReason: bom.revisionReason,
      );
      final revisionAudit = EngineeringBomAuditHelper.entry(
        action: 'revision_created',
        changedBy: changedBy,
        changedByName: changedByName,
        changes: [
          'Approved BOM was not overwritten',
          'Created revision $nextRevision from ${existing.id}',
          ...EngineeringBomAuditHelper.summary(existingData, revisedBom),
        ],
      );
      await newRef.set({
        ...revisedBom.toFirestore(),
        'companyId': tenantId,
        'tenantId': tenantId,
        'previousBomId': existing.id,
        'revisionSourceBomId': existing.id,
        'revisionReason': bom.revisionReason,
        'createdBy': changedBy,
        'createdByName': changedByName,
        'updatedBy': changedBy,
        'updatedByName': changedByName,
        'updatedAt': now,
        'revisionHistory': FieldValue.arrayUnion([revisionAudit]),
        'auditTrail': FieldValue.arrayUnion(
          EngineeringBomAuditHelper.fieldEntries(
            existingData,
            revisedBom,
            changedBy,
          ),
        ),
      }, SetOptions(merge: true));
      await _linkInquiryItem(
        inquiryId: revisedBom.inquiryId,
        inquiryItemId: revisedBom.inquiryItemId,
        bomId: newRef.id,
        bomNumber: revisedBom.bomNo,
        status: 'Draft',
      );
      return EngineeringBomSaveResult(
        bomId: newRef.id,
        bomNo: revisedBom.bomNo,
        revision: nextRevision,
        status: 'Draft',
        inquiryId: revisedBom.inquiryId,
        inquiryItemId: revisedBom.inquiryItemId,
        createdNewRevision: true,
      );
    }

    await docRef.set({
      ...bom.toFirestore(),
      'companyId': tenantId,
      'tenantId': tenantId,
      if (!existing.exists) 'createdBy': changedBy,
      if (!existing.exists) 'createdByName': changedByName,
      if (bom.status.toLowerCase() == 'approved') 'approvedBy': changedBy,
      if (bom.status.toLowerCase() == 'approved')
        'approvedByName': changedByName,
      if (bom.status.toLowerCase() == 'approved')
        'approvedOn': FieldValue.serverTimestamp(),
      'updatedBy': changedBy,
      'updatedByName': changedByName,
      'updatedAt': now,
      'revisionHistory': FieldValue.arrayUnion([audit]),
      'auditTrail': FieldValue.arrayUnion(
        existing.exists
            ? EngineeringBomAuditHelper.fieldEntries(
                existing.data() ?? const {},
                bom,
                changedBy,
              )
            : [
                EngineeringBomAuditHelper.field(
                  fieldChanged: 'status',
                  oldValue: '',
                  newValue: bom.status,
                  changedBy: changedBy,
                ),
              ],
      ),
    }, SetOptions(merge: true));
    await _linkInquiryItem(
      inquiryId: bom.inquiryId,
      inquiryItemId: bom.inquiryItemId,
      bomId: bom.id,
      bomNumber: bom.bomNo,
      status: bom.status,
    );
    return EngineeringBomSaveResult(
      bomId: bom.id,
      bomNo: bom.bomNo,
      revision: bom.revision,
      status: bom.status,
      inquiryId: bom.inquiryId,
      inquiryItemId: bom.inquiryItemId,
    );
  }

  bool _isApproved(Object? status) {
    return status?.toString().trim().toLowerCase() == 'approved';
  }

  Future<void> _linkInquiryItem({
    required String inquiryId,
    required String inquiryItemId,
    required String bomId,
    required String bomNumber,
    required String status,
  }) async {
    if (inquiryId.trim().isEmpty || inquiryItemId.trim().isEmpty) return;
    await EngineeringBomInquiryLinker(
      tenantId: tenantId,
      firestore: _firestore,
    ).link(
      inquiryId: inquiryId,
      inquiryItemId: inquiryItemId,
      bomId: bomId,
      bomNumber: bomNumber,
      status: status,
    );
  }

  String _nextRevisionLabel(String current) {
    final trimmed = current.trim().toUpperCase();
    final letter = RegExp(r'[A-Z]$').firstMatch(trimmed)?.group(0);
    if (letter == null) return 'A';
    if (letter == 'Z') return 'AA';
    return String.fromCharCode(letter.codeUnitAt(0) + 1);
  }
}

class EngineeringBomSaveResult {
  final String bomId;
  final String bomNo;
  final String revision;
  final String status;
  final String inquiryId;
  final String inquiryItemId;
  final bool createdNewRevision;

  const EngineeringBomSaveResult({
    required this.bomId,
    required this.bomNo,
    required this.revision,
    required this.status,
    this.inquiryId = '',
    this.inquiryItemId = '',
    this.createdNewRevision = false,
  });
}
