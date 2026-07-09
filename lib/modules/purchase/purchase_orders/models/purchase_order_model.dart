import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrderAttachmentModel {
  final String id;
  final String fileName;
  final String fileUrl;
  final String documentType;
  final String uploadedByUid;
  final DateTime? uploadedAt;

  const PurchaseOrderAttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.documentType,
    required this.uploadedByUid,
    this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'documentType': documentType,
      'uploadedByUid': uploadedByUid,
      'uploadedAt': uploadedAt,
    };
  }

  factory PurchaseOrderAttachmentModel.fromMap(Object? value) {
    if (value is! Map) {
      return const PurchaseOrderAttachmentModel(
        id: '',
        fileName: '',
        fileUrl: '',
        documentType: '',
        uploadedByUid: '',
      );
    }

    final map = Map<String, dynamic>.from(value);
    return PurchaseOrderAttachmentModel(
      id: _safeString(map['id']),
      fileName: _safeString(map['fileName'] ?? map['name']),
      fileUrl: _safeString(map['fileUrl'] ?? map['url']),
      documentType: _safeString(map['documentType'] ?? map['type']),
      uploadedByUid: _safeString(map['uploadedByUid']),
      uploadedAt: _dateTimeFromValue(map['uploadedAt']),
    );
  }
}

class PurchaseOrderItemModel {
  final String itemId;
  final String itemName;
  final String description;
  final String hsnSac;
  final String unit;
  final double quantity;
  final double rate;
  final double gstPercent;
  final double receivedQty;

  const PurchaseOrderItemModel({
    required this.itemId,
    required this.itemName,
    this.description = '',
    this.hsnSac = '',
    this.unit = 'Nos',
    this.quantity = 0,
    this.rate = 0,
    this.gstPercent = 18,
    this.receivedQty = 0,
  });

  double get amount => quantity * rate;
  double get gstAmount => amount * gstPercent / 100;
  double get totalAmount => amount + gstAmount;
  double get pendingQty =>
      (quantity - receivedQty).clamp(0, double.infinity).toDouble();

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'description': description,
      'hsnSac': hsnSac,
      'unit': unit,
      'quantity': quantity,
      'rate': rate,
      'gstPercent': gstPercent,
      'amount': amount,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'orderedQty': quantity,
      'receivedQty': receivedQty,
      'pendingQty': pendingQty,
    };
  }

  factory PurchaseOrderItemModel.fromMap(Object? value) {
    if (value is! Map) {
      return const PurchaseOrderItemModel(itemId: '', itemName: '');
    }

    final map = Map<String, dynamic>.from(value);
    return PurchaseOrderItemModel(
      itemId: _safeString(
        map['itemId'] ?? map['materialId'] ?? map['productId'],
      ),
      itemName: _safeString(
        map['itemName'] ??
            map['materialName'] ??
            map['productName'] ??
            map['name'],
      ),
      description: _safeString(map['description']),
      hsnSac: _safeString(map['hsnSac'] ?? map['hsnCode'] ?? map['sacCode']),
      unit: _safeString(map['unit'] ?? map['uom']).isEmpty
          ? 'Nos'
          : _safeString(map['unit'] ?? map['uom']),
      quantity: _doubleFromValue(
        map['quantity'] ?? map['qty'] ?? map['orderedQty'],
      ),
      rate: _doubleFromValue(map['rate'] ?? map['unitPrice']),
      gstPercent: _doubleFromValue(map['gstPercent'] ?? map['gstRate'] ?? 18),
      receivedQty: _doubleFromValue(map['receivedQty']),
    );
  }
}

class PurchaseOrderModel {
  static const statusDraft = 'draft';
  static const statusApproved = 'approved';
  static const statusCancelled = 'cancelled';

  static const purchaseTypes = [
    'Raw Material',
    'Consumable',
    'Spare / Accessory',
    'Capital Equipment',
    'Service',
    'Job Work',
  ];

  final String id;
  final String poNumber;
  final DateTime poDate;
  final String vendorId;
  final String vendorName;
  final String vendorGst;
  final String vendorAddress;
  final String purchaseType;
  final DateTime? expectedDeliveryDate;
  final String deliveryAddress;
  final String paymentTerms;
  final String status;
  final String remarks;
  final List<PurchaseOrderItemModel> items;
  final List<PurchaseOrderAttachmentModel> attachments;
  final String tenantId;
  final String companyId;
  final String createdByUid;
  final String approvedByUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.poDate,
    required this.vendorId,
    required this.vendorName,
    this.vendorGst = '',
    this.vendorAddress = '',
    this.purchaseType = 'Raw Material',
    this.expectedDeliveryDate,
    this.deliveryAddress = '',
    this.paymentTerms = '',
    this.status = statusDraft,
    this.remarks = '',
    this.items = const [],
    this.attachments = const [],
    required this.tenantId,
    required this.companyId,
    this.createdByUid = '',
    this.approvedByUid = '',
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
  });

  double get subtotal =>
      items.fold<double>(0, (running, item) => running + item.amount);
  double get gstTotal =>
      items.fold<double>(0, (running, item) => running + item.gstAmount);
  double get grandTotal =>
      items.fold<double>(0, (running, item) => running + item.totalAmount);
  int get itemCount => items.length;

  PurchaseOrderModel copyWith({
    String? id,
    String? poNumber,
    DateTime? poDate,
    String? vendorId,
    String? vendorName,
    String? vendorGst,
    String? vendorAddress,
    String? purchaseType,
    DateTime? expectedDeliveryDate,
    String? deliveryAddress,
    String? paymentTerms,
    String? status,
    String? remarks,
    List<PurchaseOrderItemModel>? items,
    List<PurchaseOrderAttachmentModel>? attachments,
    String? tenantId,
    String? companyId,
    String? createdByUid,
    String? approvedByUid,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      poDate: poDate ?? this.poDate,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorGst: vendorGst ?? this.vendorGst,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      purchaseType: purchaseType ?? this.purchaseType,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      items: items ?? this.items,
      attachments: attachments ?? this.attachments,
      tenantId: tenantId ?? this.tenantId,
      companyId: companyId ?? this.companyId,
      createdByUid: createdByUid ?? this.createdByUid,
      approvedByUid: approvedByUid ?? this.approvedByUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'poNumber': poNumber,
      'poNo': poNumber,
      'poDate': Timestamp.fromDate(poDate),
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorGst': vendorGst,
      'vendorAddress': vendorAddress,
      'purchaseType': purchaseType,
      'expectedDeliveryDate': expectedDeliveryDate == null
          ? null
          : Timestamp.fromDate(expectedDeliveryDate!),
      'deliveryAddress': deliveryAddress,
      'paymentTerms': paymentTerms,
      'status': status,
      'remarks': remarks,
      'items': items.map((item) => item.toMap()).toList(growable: false),
      'lines': items.map((item) => item.toMap()).toList(growable: false),
      'attachments': attachments
          .map((attachment) => attachment.toMap())
          .toList(growable: false),
      'subtotal': subtotal,
      'gstTotal': gstTotal,
      'grandTotal': grandTotal,
      'totalAmount': grandTotal,
      'itemCount': itemCount,
      'tenantId': tenantId,
      'companyId': companyId,
      'createdByUid': createdByUid,
      'approvedByUid': approvedByUid,
      'approvedAt': approvedAt,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PurchaseOrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final rawItems = data['items'] ?? data['lines'];
    final rawAttachments =
        data['attachments'] ?? data['sourceOfferAttachments'];

    final items = rawItems is Iterable
        ? rawItems
              .map(PurchaseOrderItemModel.fromMap)
              .where((item) => item.itemName.trim().isNotEmpty)
              .toList(growable: false)
        : <PurchaseOrderItemModel>[];

    final attachments = rawAttachments is Iterable
        ? rawAttachments
              .map(PurchaseOrderAttachmentModel.fromMap)
              .where((attachment) => attachment.fileUrl.trim().isNotEmpty)
              .toList(growable: false)
        : <PurchaseOrderAttachmentModel>[];

    return PurchaseOrderModel(
      id: snapshot.id,
      poNumber: _safeString(data['poNumber'] ?? data['poNo']).isEmpty
          ? snapshot.id
          : _safeString(data['poNumber'] ?? data['poNo']),
      poDate:
          _dateTimeFromValue(data['poDate']) ??
          _dateTimeFromValue(data['createdAt']) ??
          DateTime.now(),
      vendorId: _safeString(data['vendorId']),
      vendorName: _safeString(data['vendorName']),
      vendorGst: _safeString(data['vendorGst'] ?? data['vendorGstin']),
      vendorAddress: _safeString(data['vendorAddress']),
      purchaseType: _safeString(data['purchaseType']).isEmpty
          ? 'Raw Material'
          : _safeString(data['purchaseType']),
      expectedDeliveryDate: _dateTimeFromValue(data['expectedDeliveryDate']),
      deliveryAddress: _safeString(data['deliveryAddress']),
      paymentTerms: _safeString(data['paymentTerms']),
      status: _safeString(data['status']).isEmpty
          ? PurchaseOrderModel.statusDraft
          : _safeString(data['status']).toLowerCase(),
      remarks: _safeString(data['remarks']),
      items: items,
      attachments: attachments,
      tenantId: _safeString(data['tenantId']),
      companyId: _safeString(data['companyId']),
      createdByUid: _safeString(data['createdByUid']),
      approvedByUid: _safeString(data['approvedByUid']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      approvedAt: _dateTimeFromValue(data['approvedAt']),
    );
  }
}

String _safeString(dynamic value) {
  if (value == null) return '';
  final text = value.toString().trim();
  return text == 'null' ? '' : text;
}

double _doubleFromValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble().isNaN ? 0 : value.toDouble();
  final parsed = double.tryParse(value.toString().replaceAll(',', '').trim());
  return parsed == null || parsed.isNaN ? 0 : parsed;
}

DateTime? _dateTimeFromValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}
