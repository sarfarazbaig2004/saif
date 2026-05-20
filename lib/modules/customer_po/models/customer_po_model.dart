import 'package:QUIK/modules/customer_po/models/customer_po_item_model.dart';
import 'package:QUIK/modules/sales/shared/enums/customer_po_status.dart';
import 'package:QUIK/modules/sales/shared/models/sales_commercial_terms_model.dart';
import 'package:QUIK/modules/sales/shared/models/sales_document_attachment_model.dart';
import 'package:QUIK/modules/sales/shared/models/sales_revision_model.dart';

class CustomerPoModel {
  final String id;
  final String companyId;
  final String customerPoNo;

  final int revisionNo;
  final String revisionId;

  final String linkedQuotationId;
  final String linkedQuotationRevisionId;

  final String customerId;
  final String customerName;

  final CustomerPoStatus status;

  final List<CustomerPoItemModel> items;
  final List<SalesDocumentAttachmentModel> attachments;

  final SalesCommercialTermsModel commercialTerms;
  final SalesRevisionModel? revision;

  final double totalBasic;
  final double totalTax;
  final double grandTotal;

  final bool scopeFrozen;
  final bool costingLocked;

  final String dispatchStatus;
  final String billingStatus;
  final String paymentStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String createdBy;
  final String updatedBy;

  const CustomerPoModel({
    required this.id,
    required this.companyId,
    required this.customerPoNo,
    required this.revisionNo,
    required this.revisionId,
    required this.linkedQuotationId,
    required this.linkedQuotationRevisionId,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.items,
    required this.attachments,
    required this.commercialTerms,
    required this.revision,
    required this.totalBasic,
    required this.totalTax,
    required this.grandTotal,
    required this.scopeFrozen,
    required this.costingLocked,
    required this.dispatchStatus,
    required this.billingStatus,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory CustomerPoModel.fromMap(Map<String, dynamic> map) {
    return CustomerPoModel(
      id: (map['id'] ?? '').toString(),
      companyId: (map['companyId'] ?? '').toString(),
      customerPoNo: (map['customerPoNo'] ?? '').toString(),
      revisionNo: _toInt(map['revisionNo']),
      revisionId: (map['revisionId'] ?? '').toString(),
      linkedQuotationId: (map['linkedQuotationId'] ?? '').toString(),
      linkedQuotationRevisionId: (map['linkedQuotationRevisionId'] ?? '')
          .toString(),
      customerId: (map['customerId'] ?? '').toString(),
      customerName: (map['customerName'] ?? '').toString(),
      status: CustomerPoStatusX.fromValue(map['status']?.toString()),
      items: _list(map['items']).map(CustomerPoItemModel.fromMap).toList(),
      attachments: _list(
        map['attachments'],
      ).map(SalesDocumentAttachmentModel.fromMap).toList(),
      commercialTerms: SalesCommercialTermsModel.fromMap(
        _map(map['commercialTerms']),
      ),
      revision: map['revision'] is Map
          ? SalesRevisionModel.fromMap(_map(map['revision']))
          : null,
      totalBasic: _toDouble(map['totalBasic']),
      totalTax: _toDouble(map['totalTax']),
      grandTotal: _toDouble(map['grandTotal']),
      scopeFrozen: map['scopeFrozen'] == true,
      costingLocked: map['costingLocked'] == true,
      dispatchStatus: (map['dispatchStatus'] ?? '').toString(),
      billingStatus: (map['billingStatus'] ?? '').toString(),
      paymentStatus: (map['paymentStatus'] ?? '').toString(),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      createdBy: (map['createdBy'] ?? '').toString(),
      updatedBy: (map['updatedBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'customerPoNo': customerPoNo,
      'revisionNo': revisionNo,
      'revisionId': revisionId,
      'linkedQuotationId': linkedQuotationId,
      'linkedQuotationRevisionId': linkedQuotationRevisionId,
      'customerId': customerId,
      'customerName': customerName,
      'status': status.value,
      'items': items.map((item) => item.toMap()).toList(),
      'attachments': attachments.map((doc) => doc.toMap()).toList(),
      'commercialTerms': commercialTerms.toMap(),
      'revision': revision?.toMap(),
      'totalBasic': totalBasic,
      'totalTax': totalTax,
      'grandTotal': grandTotal,
      'scopeFrozen': scopeFrozen,
      'costingLocked': costingLocked,
      'dispatchStatus': dispatchStatus,
      'billingStatus': billingStatus,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is DateTime) return value;
    return null;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
