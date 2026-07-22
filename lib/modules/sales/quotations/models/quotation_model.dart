import 'package:QUIK/modules/sales/inquiries/models/inquiry_epc_details_model.dart';
import 'package:QUIK/modules/sales/quotations/models/quotation_item_model.dart';
import 'package:QUIK/modules/sales/shared/enums/quotation_status.dart';
import 'package:QUIK/modules/sales/shared/models/sales_commercial_terms_model.dart';
import 'package:QUIK/modules/sales/shared/models/sales_document_attachment_model.dart';
import 'package:QUIK/modules/sales/shared/models/sales_revision_model.dart';

class SalesQuotationModel {
  final String id;
  final String companyId;
  final String quotationNo;
  final String verticalId;
  final String verticalName;
  final int revisionNo;
  final String revisionId;

  final String linkedInquiryId;
  final String linkedInquiryRevisionId;

  final String customerId;
  final String customerName;

  final QuotationStatus status;
  final String salesPersonId;
  final String salesPersonName;

  final InquiryEpcDetailsModel epcDetails;
  final SalesCommercialTermsModel commercialTerms;

  final List<QuotationItemModel> items;
  final List<SalesDocumentAttachmentModel> attachments;

  final double totalBasic;
  final double totalTax;
  final double grandTotal;

  final SalesRevisionModel? revision;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String createdBy;
  final String updatedBy;

  const SalesQuotationModel({
    required this.id,
    required this.companyId,
    required this.quotationNo,
    required this.verticalId,
    required this.verticalName,
    required this.revisionNo,
    required this.revisionId,
    required this.linkedInquiryId,
    required this.linkedInquiryRevisionId,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.salesPersonId,
    required this.salesPersonName,
    required this.epcDetails,
    required this.commercialTerms,
    required this.items,
    required this.attachments,
    required this.totalBasic,
    required this.totalTax,
    required this.grandTotal,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory SalesQuotationModel.fromMap(Map<String, dynamic> map) {
    return SalesQuotationModel(
      id: (map['id'] ?? '').toString(),
      companyId: (map['companyId'] ?? '').toString(),
      quotationNo: (map['quotationNo'] ?? '').toString(),
      verticalId: (map['verticalId'] ?? '').toString(),
      verticalName:
          (map['verticalName'] ?? map['businessVertical'] ?? '').toString(),
      revisionNo: _toInt(map['revisionNo']),
      revisionId: (map['revisionId'] ?? '').toString(),
      linkedInquiryId: (map['linkedInquiryId'] ?? '').toString(),
      linkedInquiryRevisionId: (map['linkedInquiryRevisionId'] ?? '')
          .toString(),
      customerId: (map['customerId'] ?? '').toString(),
      customerName: (map['customerName'] ?? '').toString(),
      status: QuotationStatusX.fromValue(map['status']?.toString()),
      salesPersonId: (map['salesPersonId'] ?? '').toString(),
      salesPersonName: (map['salesPersonName'] ?? '').toString(),
      epcDetails: InquiryEpcDetailsModel.fromMap(_map(map['epcDetails'])),
      commercialTerms: SalesCommercialTermsModel.fromMap(
        _map(map['commercialTerms']),
      ),
      items: _list(map['items']).map(QuotationItemModel.fromMap).toList(),
      attachments: _list(
        map['attachments'],
      ).map(SalesDocumentAttachmentModel.fromMap).toList(),
      totalBasic: _toDouble(map['totalBasic']),
      totalTax: _toDouble(map['totalTax']),
      grandTotal: _toDouble(map['grandTotal']),
      revision: map['revision'] is Map
          ? SalesRevisionModel.fromMap(_map(map['revision']))
          : null,
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
      'quotationNo': quotationNo,
      'verticalId': verticalId,
      'verticalName': verticalName,
      'revisionNo': revisionNo,
      'revisionId': revisionId,
      'linkedInquiryId': linkedInquiryId,
      'linkedInquiryRevisionId': linkedInquiryRevisionId,
      'customerId': customerId,
      'customerName': customerName,
      'status': status.value,
      'salesPersonId': salesPersonId,
      'salesPersonName': salesPersonName,
      'epcDetails': epcDetails.toMap(),
      'commercialTerms': commercialTerms.toMap(),
      'items': items.map((item) => item.toMap()).toList(),
      'attachments': attachments.map((doc) => doc.toMap()).toList(),
      'totalBasic': totalBasic,
      'totalTax': totalTax,
      'grandTotal': grandTotal,
      'revision': revision?.toMap(),
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
