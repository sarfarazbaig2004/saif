import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_inward_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_issue_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_purchase_bill_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_snapshot_line_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_snapshot_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_stock_summary_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_transaction_model.dart';
import 'package:QUIK/modules/production/core/production_firestore_utils.dart';

class FabricationInventoryRepository {
  FabricationInventoryRepository({
    FirebaseFirestore? firestore,
    required this.tenantId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String tenantId;

  DocumentReference<Map<String, dynamic>> get _tenantRef {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).companyRef;
  }

  CollectionReference<Map<String, dynamic>> get _snapshotsRef {
    return _tenantRef.collection('raw_material_stock_snapshots');
  }

  CollectionReference<Map<String, dynamic>> get _materialsRef {
    return _tenantRef.collection('raw_materials');
  }

  CollectionReference<Map<String, dynamic>> get _transactionsRef {
    return _tenantRef.collection('raw_material_transactions');
  }

  CollectionReference<Map<String, dynamic>> get _inwardRef {
    return _tenantRef.collection('raw_material_inward');
  }

  CollectionReference<Map<String, dynamic>> get _issueRef {
    return _tenantRef.collection('raw_material_issues');
  }

  CollectionReference<Map<String, dynamic>> get _purchaseBillRef {
    return _tenantRef.collection('raw_material_purchase_bills');
  }

  Stream<List<RawMaterialSnapshotModel>> watchSnapshots({int limit = 12}) {
    return _snapshotsRef
        .orderBy('monthKey', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RawMaterialSnapshotModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<RawMaterialSnapshotLineModel>> watchSnapshotLines(
    String snapshotId,
  ) {
    return _snapshotsRef
        .doc(snapshotId)
        .collection('lines')
        .orderBy('lineNo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RawMaterialSnapshotLineModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<RawMaterialModel>> watchRawMaterials({bool activeOnly = false}) {
    return _materialsRef
        .orderBy('materialCode')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RawMaterialModel.fromFirestore)
              .where((material) => !activeOnly || material.isActive)
              .toList(growable: false),
        );
  }

  Stream<List<RawMaterialStockSummaryModel>> watchStockSummary() {
    return _transactionsRef.snapshots().map((snapshot) {
      final transactions = snapshot.docs
          .map(RawMaterialTransactionModel.fromFirestore)
          .toList(growable: false);
      return _buildStockSummary(transactions);
    });
  }

  Stream<List<RawMaterialTransactionModel>> watchTransactions({
    RawMaterialTransactionType? type,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _transactionsRef;
    if (type != null) {
      query = query.where('transactionType', isEqualTo: type.key);
    }

    return query
        .orderBy('transactionDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RawMaterialTransactionModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<RawMaterialInwardModel>> watchInwardEntries({int limit = 50}) {
    return watchTransactions(
      type: RawMaterialTransactionType.inward,
      limit: limit,
    ).map(
      (rows) => rows
          .map(
            (row) => RawMaterialInwardModel(
              inwardId: row.transactionId,
              inwardDate: row.transactionDate,
              supplierName: row.partyOrProcess,
              challanNo: row.referenceNo,
              materialDescription: row.materialDescription,
              grade: row.grade,
              lengthMm: row.length,
              unitWeightKgPerM: row.unitWeight,
              quantityKg: row.quantityKg,
              quantityNos: row.quantityNos,
              remarks: row.remarks,
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<List<RawMaterialIssueModel>> watchIssueEntries({int limit = 50}) {
    return watchTransactions(
      type: RawMaterialTransactionType.issue,
      limit: limit,
    ).map(
      (rows) => rows
          .map(
            (row) => RawMaterialIssueModel(
              issueId: row.transactionId,
              issueDate: row.transactionDate,
              issuedTo: row.partyOrProcess,
              workOrderId: row.workOrderId,
              materialDescription: row.materialDescription,
              grade: row.grade,
              lengthMm: row.length,
              unitWeightKgPerM: row.unitWeight,
              quantityKg: row.quantityKg,
              remarks: row.remarks,
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<List<RawMaterialPurchaseBillModel>> watchPurchaseBills({
    int limit = 50,
  }) {
    return _purchaseBillRef
        .orderBy('billDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RawMaterialPurchaseBillModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<List<RawMaterialInwardModel>> fetchRecentInwardEntries({
    int limit = 100,
  }) async {
    final snapshot = await _inwardRef
        .orderBy('inwardDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(RawMaterialInwardModel.fromFirestore)
        .toList(growable: false);
  }

  String newInwardId() => _inwardRef.doc().id;

  String newIssueId() => _issueRef.doc().id;

  String newMaterialId() => _materialsRef.doc().id;

  String newTransactionId() => _transactionsRef.doc().id;

  String newPurchaseBillId() => _purchaseBillRef.doc().id;

  Future<void> saveRawMaterial(RawMaterialModel material) {
    final materialId = material.materialId.trim().isEmpty
        ? newMaterialId()
        : material.materialId.trim();
    return _materialsRef.doc(materialId).set({
      ...material.toFirestore(),
      'materialId': materialId,
      'companyId': tenantId,
      'tenantId': tenantId,
    }, SetOptions(merge: true));
  }

  Future<void> saveInwardEntry(RawMaterialInwardModel entry) async {
    return saveInventoryTransaction(
      RawMaterialTransactionModel(
        transactionId: entry.inwardId,
        transactionType: RawMaterialTransactionType.inward,
        transactionDate: entry.inwardDate,
        materialId: '',
        materialCode: '',
        materialDescription: entry.materialDescription,
        grade: entry.grade,
        length: entry.lengthMm,
        unitWeight: entry.unitWeightKgPerM,
        uom: 'Kg',
        category: '',
        productFamily: '',
        quantityNos: entry.quantityNos,
        quantityKg: _calculatedQuantityKg(
          quantityKg: entry.quantityKg,
          quantityNos: entry.quantityNos,
          length: entry.lengthMm,
          unitWeight: entry.unitWeightKgPerM,
        ),
        referenceNo: entry.challanNo,
        partyOrProcess: entry.supplierName,
        workOrderId: '',
        heatNumber: '',
        batchNo: '',
        millCertificateUrl: '',
        qaReferenceId: '',
        remarks: entry.remarks,
      ),
    );
  }

  Future<void> saveIssueEntry(RawMaterialIssueModel entry) async {
    return saveInventoryTransaction(
      RawMaterialTransactionModel(
        transactionId: entry.issueId,
        transactionType: RawMaterialTransactionType.issue,
        transactionDate: entry.issueDate,
        materialId: '',
        materialCode: '',
        materialDescription: entry.materialDescription,
        grade: entry.grade,
        length: entry.lengthMm,
        unitWeight: entry.unitWeightKgPerM,
        uom: 'Kg',
        category: '',
        productFamily: '',
        quantityNos: 0,
        quantityKg: entry.quantityKg,
        referenceNo: '',
        partyOrProcess: entry.issuedTo,
        workOrderId: entry.workOrderId,
        heatNumber: '',
        batchNo: '',
        millCertificateUrl: '',
        qaReferenceId: '',
        remarks: entry.remarks,
      ),
    );
  }

  Future<void> saveInventoryTransaction(
    RawMaterialTransactionModel entry,
  ) async {
    final transactionId = entry.transactionId.trim().isEmpty
        ? newTransactionId()
        : entry.transactionId.trim();
    final transactionRef = _transactionsRef.doc(transactionId);
    final legacyRef = entry.transactionType == RawMaterialTransactionType.issue
        ? _issueRef.doc(transactionId)
        : entry.transactionType == RawMaterialTransactionType.inward
        ? _inwardRef.doc(transactionId)
        : null;
    final normalizedEntry = _normalizeTransaction(entry, transactionId);

    await _firestore.runTransaction((transaction) async {
      if (normalizedEntry.transactionType.stockSign < 0) {
        final stockSnapshot = await _transactionsRef.get();
        final existing = stockSnapshot.docs
            .where((doc) => doc.id != transactionId)
            .map(RawMaterialTransactionModel.fromFirestore)
            .where((row) => _sameStockItem(row, normalizedEntry))
            .fold<double>(0, (total, row) => total + row.signedKg);

        if (existing + 0.0001 < normalizedEntry.quantityKg) {
          throw Exception(
            'Cannot ${normalizedEntry.transactionType.label.toLowerCase()} ${normalizedEntry.quantityKg.toStringAsFixed(2)} kg. Only ${existing.toStringAsFixed(2)} kg is available.',
          );
        }
      }

      transaction.set(transactionRef, {
        ...normalizedEntry.toFirestore(),
        'companyId': tenantId,
        'tenantId': tenantId,
      }, SetOptions(merge: true));

      if (legacyRef != null) {
        transaction.set(legacyRef, {
          ...normalizedEntry.toFirestore(),
          'companyId': tenantId,
          'tenantId': tenantId,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> savePurchaseBill(RawMaterialPurchaseBillModel bill) {
    return _purchaseBillRef.doc(bill.billId).set({
      ...bill.toFirestore(),
      'companyId': tenantId,
      'tenantId': tenantId,
    }, SetOptions(merge: true));
  }

  String _summaryItemId({
    required String materialDescription,
    required String grade,
    required double lengthMm,
  }) {
    final material = _normalizeText(materialDescription);
    final normalizedGrade = _normalizeText(grade);
    final normalizedLength = _normalizeLength(lengthMm).toString();

    return '$material-$normalizedGrade-$normalizedLength';
  }

  String _normalizeText(Object? value) {
    return value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  int _normalizeLength(Object? value) {
    return doubleFromValue(value).round();
  }

  RawMaterialTransactionModel _normalizeTransaction(
    RawMaterialTransactionModel entry,
    String transactionId,
  ) {
    final quantityKg = _calculatedQuantityKg(
      quantityKg: entry.quantityKg,
      quantityNos: entry.quantityNos,
      length: entry.length,
      unitWeight: entry.unitWeight,
    );

    return RawMaterialTransactionModel(
      transactionId: transactionId,
      transactionType: entry.transactionType,
      transactionDate: entry.transactionDate ?? DateTime.now(),
      materialId: entry.materialId,
      materialCode: entry.materialCode,
      materialDescription: entry.materialDescription,
      grade: entry.grade,
      length: entry.length,
      unitWeight: entry.unitWeight,
      uom: entry.uom.trim().isEmpty ? 'Kg' : entry.uom,
      category: entry.category,
      productFamily: entry.productFamily,
      quantityNos: entry.quantityNos,
      quantityKg: quantityKg,
      referenceNo: entry.referenceNo,
      partyOrProcess: entry.partyOrProcess,
      workOrderId: entry.workOrderId,
      heatNumber: entry.heatNumber,
      batchNo: entry.batchNo,
      millCertificateUrl: entry.millCertificateUrl,
      qaReferenceId: entry.qaReferenceId,
      remarks: entry.remarks,
    );
  }

  double _calculatedQuantityKg({
    required double quantityKg,
    required double quantityNos,
    required double length,
    required double unitWeight,
  }) {
    if (quantityKg > 0) return quantityKg;
    if (quantityNos <= 0 || length <= 0 || unitWeight <= 0) return 0;
    return quantityNos * (length / 1000) * unitWeight;
  }

  bool _sameStockItem(
    RawMaterialTransactionModel a,
    RawMaterialTransactionModel b,
  ) {
    if (a.materialId.trim().isNotEmpty && b.materialId.trim().isNotEmpty) {
      return a.materialId == b.materialId;
    }
    return _normalizeText(a.materialDescription) ==
            _normalizeText(b.materialDescription) &&
        _normalizeText(a.grade) == _normalizeText(b.grade) &&
        _normalizeLength(a.length) == _normalizeLength(b.length);
  }

  List<RawMaterialStockSummaryModel> _buildStockSummary(
    List<RawMaterialTransactionModel> transactions,
  ) {
    final Map<String, _SummaryAccumulator> rows = {};

    for (final transaction in transactions) {
      final key = transaction.materialId.trim().isNotEmpty
          ? transaction.materialId
          : _summaryItemId(
              materialDescription: transaction.materialDescription,
              grade: transaction.grade,
              lengthMm: transaction.length,
            );
      final row = rows.putIfAbsent(
        key,
        () => _SummaryAccumulator(
          itemId: key,
          materialCode: transaction.materialCode,
          materialDescription: transaction.materialDescription,
          grade: transaction.grade,
          category: transaction.category,
          productFamily: transaction.productFamily,
          length: transaction.length,
          unitWeight: transaction.unitWeight,
          uom: transaction.uom,
        ),
      );
      row.apply(transaction);
    }

    final result = rows.values.map((row) => row.toModel()).toList();
    result.sort((a, b) {
      final material = a.materialDescription.compareTo(b.materialDescription);
      if (material != 0) return material;
      final grade = a.grade.compareTo(b.grade);
      if (grade != 0) return grade;
      return a.lengthMm.compareTo(b.lengthMm);
    });
    return result;
  }
}

class _SummaryAccumulator {
  _SummaryAccumulator({
    required this.itemId,
    required this.materialCode,
    required this.materialDescription,
    required this.grade,
    required this.category,
    required this.productFamily,
    required this.length,
    required this.unitWeight,
    required this.uom,
  });

  final String itemId;
  String materialCode;
  String materialDescription;
  String grade;
  String category;
  String productFamily;
  double length;
  double unitWeight;
  String uom;
  double openingKg = 0;
  double inwardKg = 0;
  double returnKg = 0;
  double adjustmentKg = 0;
  double issueKg = 0;
  double scrapKg = 0;
  double quantityNos = 0;
  DateTime? lastUpdatedAt;

  void apply(RawMaterialTransactionModel transaction) {
    materialCode = materialCode.isEmpty
        ? transaction.materialCode
        : materialCode;
    materialDescription = materialDescription.isEmpty
        ? transaction.materialDescription
        : materialDescription;
    grade = grade.isEmpty ? transaction.grade : grade;
    category = category.isEmpty ? transaction.category : category;
    productFamily = productFamily.isEmpty
        ? transaction.productFamily
        : productFamily;
    length = length <= 0 ? transaction.length : length;
    unitWeight = unitWeight <= 0 ? transaction.unitWeight : unitWeight;
    uom = uom.isEmpty ? transaction.uom : uom;

    switch (transaction.transactionType) {
      case RawMaterialTransactionType.opening:
        openingKg += transaction.quantityKg;
        quantityNos += transaction.quantityNos;
      case RawMaterialTransactionType.inward:
        inwardKg += transaction.quantityKg;
        quantityNos += transaction.quantityNos;
      case RawMaterialTransactionType.returnMaterial:
        returnKg += transaction.quantityKg;
        quantityNos += transaction.quantityNos;
      case RawMaterialTransactionType.adjustment:
        adjustmentKg += transaction.quantityKg;
        quantityNos += transaction.quantityNos;
      case RawMaterialTransactionType.issue:
        issueKg += transaction.quantityKg;
        quantityNos -= transaction.quantityNos;
      case RawMaterialTransactionType.scrap:
        scrapKg += transaction.quantityKg;
        quantityNos -= transaction.quantityNos;
    }

    final date = transaction.transactionDate;
    if (date != null &&
        (lastUpdatedAt == null || date.isAfter(lastUpdatedAt!))) {
      lastUpdatedAt = date;
    }
  }

  RawMaterialStockSummaryModel toModel() {
    final closing =
        openingKg + inwardKg + returnKg + adjustmentKg - issueKg - scrapKg;
    return RawMaterialStockSummaryModel(
      itemId: itemId,
      materialCode: materialCode,
      materialDescription: materialDescription,
      grade: grade,
      rawMaterialCategory: category,
      productFamily: productFamily,
      lengthMm: length,
      unitWeightKgPerM: unitWeight,
      openingKg: openingKg,
      inwardKg: inwardKg,
      returnKg: returnKg,
      adjustmentKg: adjustmentKg,
      issueKg: issueKg,
      scrapKg: scrapKg,
      closingStockKg: closing,
      currentOpeningStockKg: openingKg,
      quantityNos: quantityNos,
      reorderLevel: 0,
      uom: uom.isEmpty ? 'Kg' : uom,
      weightTracking: unitWeight > 0,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}
