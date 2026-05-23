import 'package:QUIK/modules/sales/inquiries/models/inquiry_costing_snapshot_model.dart';
import 'package:QUIK/modules/sales/inquiries/models/inquiry_epc_details_model.dart';
import 'package:QUIK/modules/sales/inquiries/models/inquiry_item_model.dart';
import 'package:QUIK/modules/sales/shared/enums/inquiry_status.dart';
import 'package:QUIK/modules/sales/shared/models/sales_commercial_terms_model.dart';
import 'package:QUIK/modules/sales/shared/models/sales_document_attachment_model.dart';
import 'package:QUIK/modules/sales/shared/models/sales_revision_model.dart';

class SalesInquiryModel {
  final String id;
  final String companyId;
  final String inquiryNo;
  final int revisionNo;
  final String revisionId;
  final String customerId;
  final String customerName;
  final InquiryStatus status;
  final String priority;
  final String salesPersonId;
  final String salesPersonName;
  final InquiryEpcDetailsModel epcDetails;
  final SalesCommercialTermsModel commercialTerms;
  final InquiryCostingSnapshotModel costingSnapshot;
  final List<InquiryItemModel> items;
  final List<SalesDocumentAttachmentModel> attachments;
  final SalesRevisionModel? revision;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;

  const SalesInquiryModel({
    required this.id,
    required this.companyId,
    required this.inquiryNo,
    required this.revisionNo,
    required this.revisionId,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.priority,
    required this.salesPersonId,
    required this.salesPersonName,
    required this.epcDetails,
    required this.commercialTerms,
    required this.costingSnapshot,
    required this.items,
    required this.attachments,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory SalesInquiryModel.fromMap(Map<String, dynamic> map) {
    return SalesInquiryModel(
      id: (map['id'] ?? '').toString(),
      companyId: (map['companyId'] ?? '').toString(),
      inquiryNo: (map['inquiryNo'] ?? '').toString(),
      revisionNo: _toInt(map['revisionNo']),
      revisionId: (map['revisionId'] ?? '').toString(),
      customerId: (map['customerId'] ?? '').toString(),
      customerName: (map['customerName'] ?? '').toString(),
      status: InquiryStatusX.fromValue(map['status']?.toString()),
      priority: (map['priority'] ?? '').toString(),
      salesPersonId: (map['salesPersonId'] ?? '').toString(),
      salesPersonName: (map['salesPersonName'] ?? '').toString(),
      epcDetails: InquiryEpcDetailsModel.fromMap(_map(map['epcDetails'])),
      commercialTerms: SalesCommercialTermsModel.fromMap(
        _map(map['commercialTerms']),
      ),
      costingSnapshot: InquiryCostingSnapshotModel.fromMap(
        _map(map['costingSnapshot']),
      ),
      items: _list(map['items']).map(InquiryItemModel.fromMap).toList(),
      attachments: _list(
        map['attachments'],
      ).map(SalesDocumentAttachmentModel.fromMap).toList(),
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
      'inquiryNo': inquiryNo,
      'revisionNo': revisionNo,
      'revisionId': revisionId,
      'customerId': customerId,
      'customerName': customerName,
      'status': status.value,
      'priority': priority,
      'salesPersonId': salesPersonId,
      'salesPersonName': salesPersonName,
      'epcDetails': epcDetails.toMap(),
      'commercialTerms': commercialTerms.toMap(),
      'costingSnapshot': costingSnapshot.toMap(),
      'items': items.map((item) => item.toMap()).toList(),
      'attachments': attachments.map((doc) => doc.toMap()).toList(),
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
