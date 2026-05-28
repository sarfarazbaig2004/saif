import 'package:QUIK/modules/customer_po/models/customer_po_item_model.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';
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

  final DateTime? poDate;
  final String customerEmail;
  final String customerMobile;
  final String customerAddress;
  final String customerGstNumber;
  final String projectName;
  final String siteLocation;
  final String subject;
  final double gstPercent;
  final String inspectionRequirement;
  final String warranty;
  final String ldClause;
  final String? poDocumentUrl;
  final String? poFileName;
  final DateTime? uploadedAt;
  final String quotationFormat;
  final Map<String, dynamic> bomMetadata;

  const CustomerPoModel({
    required this.id,
    required this.companyId,
    String? customerPoNo,
    String? poNumber,
    this.revisionNo = 0,
    this.revisionId = '',
    this.linkedQuotationId = '',
    this.linkedQuotationRevisionId = '',
    required this.customerId,
    required this.customerName,
    this.status = CustomerPoStatus.draft,
    this.items = const [],
    this.attachments = const [],
    this.commercialTerms = const SalesCommercialTermsModel(
      freightIncluded: false,
      packingIncluded: false,
      insuranceIncluded: false,
      gstExtra: true,
      ldApplicable: false,
      paymentTerms: '',
      deliveryTerms: '',
      warrantyTerms: '',
    ),
    this.revision,
    double? totalBasic,
    double? basicValue,
    double? totalTax,
    double? gstAmount,
    double? grandTotal,
    double? totalValue,
    this.scopeFrozen = false,
    this.costingLocked = false,
    this.dispatchStatus = '',
    this.billingStatus = '',
    this.paymentStatus = '',
    this.createdAt,
    this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.poDate,
    this.customerEmail = '',
    this.customerMobile = '',
    this.customerAddress = '',
    this.customerGstNumber = '',
    this.projectName = '',
    this.siteLocation = '',
    this.subject = '',
    this.gstPercent = 0,
    String? paymentTerms,
    String? deliveryTerms,
    this.inspectionRequirement = '',
    this.warranty = '',
    this.ldClause = '',
    this.poDocumentUrl,
    this.poFileName,
    this.uploadedAt,
    this.quotationFormat = 'commercial',
    this.bomMetadata = const {},
  }) : customerPoNo = customerPoNo ?? poNumber ?? '',
       totalBasic = totalBasic ?? basicValue ?? 0,
       totalTax = totalTax ?? gstAmount ?? 0,
       grandTotal = grandTotal ?? totalValue ?? 0;

  String get poNumber => customerPoNo;
  double get basicValue => totalBasic;
  double get gstAmount => totalTax;
  double get totalValue => grandTotal;
  String get paymentTerms => commercialTerms.paymentTerms;
  String get deliveryTerms => commercialTerms.deliveryTerms;
  String get statuses => status.value;

  static const List<String> statusOptions = [
    'Draft',
    'Received',
    'Under Review',
    'Accepted',
    'Amended',
    'In Production',
    'Partially Dispatched',
    'Dispatched',
    'Billed',
    'Closed',
    'Cancelled',
  ];

  factory CustomerPoModel.fromMap(Map<String, dynamic> map) {
    return CustomerPoModel(
      id: (map['id'] ?? '').toString(),
      companyId: (map['companyId'] ?? '').toString(),
      customerPoNo: (map['customerPoNo'] ?? map['poNumber'] ?? '').toString(),
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
      totalBasic: _toDouble(map['totalBasic'] ?? map['basicValue']),
      totalTax: _toDouble(map['totalTax'] ?? map['gstAmount']),
      grandTotal: _toDouble(map['grandTotal'] ?? map['totalValue']),
      scopeFrozen: map['scopeFrozen'] == true,
      costingLocked: map['costingLocked'] == true,
      dispatchStatus: (map['dispatchStatus'] ?? '').toString(),
      billingStatus: (map['billingStatus'] ?? '').toString(),
      paymentStatus: (map['paymentStatus'] ?? '').toString(),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      createdBy: (map['createdBy'] ?? '').toString(),
      updatedBy: (map['updatedBy'] ?? '').toString(),
      poDate: _toDate(map['poDate']),
      customerEmail: (map['customerEmail'] ?? '').toString(),
      customerMobile: (map['customerMobile'] ?? '').toString(),
      customerAddress: (map['customerAddress'] ?? '').toString(),
      customerGstNumber: (map['customerGstNumber'] ?? '').toString(),
      projectName: (map['projectName'] ?? '').toString(),
      siteLocation: (map['siteLocation'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      gstPercent: _toDouble(map['gstPercent']),
      inspectionRequirement: (map['inspectionRequirement'] ?? '').toString(),
      warranty: (map['warranty'] ?? '').toString(),
      ldClause: (map['ldClause'] ?? '').toString(),
      poDocumentUrl: map['poDocumentUrl']?.toString(),
      poFileName: map['poFileName']?.toString(),
      uploadedAt: _toDate(map['uploadedAt']),
      quotationFormat: (map['quotationFormat'] ?? 'commercial').toString(),
      bomMetadata: _map(map['bomMetadata']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'customerPoNo': customerPoNo,
      'poNumber': poNumber,
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
      'basicValue': basicValue,
      'totalTax': totalTax,
      'gstAmount': gstAmount,
      'grandTotal': grandTotal,
      'totalValue': totalValue,
      'scopeFrozen': scopeFrozen,
      'costingLocked': costingLocked,
      'dispatchStatus': dispatchStatus,
      'billingStatus': billingStatus,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'poDate': poDate,
      'customerEmail': customerEmail,
      'customerMobile': customerMobile,
      'customerAddress': customerAddress,
      'customerGstNumber': customerGstNumber,
      'projectName': projectName,
      'siteLocation': siteLocation,
      'subject': subject,
      'gstPercent': gstPercent,
      'paymentTerms': paymentTerms,
      'deliveryTerms': deliveryTerms,
      'inspectionRequirement': inspectionRequirement,
      'warranty': warranty,
      'ldClause': ldClause,
      'poDocumentUrl': poDocumentUrl,
      'poFileName': poFileName,
      'uploadedAt': uploadedAt,
      'quotationFormat': quotationFormat,
      'bomMetadata': bomMetadata,
    };
  }

  static List<CustomerPoItemModel> itemRowsToModels(List<dynamic> rows) {
    return rows.map((row) {
      if (row is CustomerPoItemModel) return row;
      if (row is CustomerPoItemRow) {
        return CustomerPoItemModel(
          id: '',
          quotationItemId: '',
          itemName: row.description,
          description: row.description,
          quantity: row.quantity,
          uom: row.unit,
          unitRate: row.rate,
          gstPercent: 0,
          weightKg: 0,
          material: '',
          finish: '',
          remarks: '',
        );
      }
      return CustomerPoItemModel.fromMap({});
    }).toList();
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
    if (value is List) return value.whereType<Map<String, dynamic>>().toList();
    return [];
  }
}
