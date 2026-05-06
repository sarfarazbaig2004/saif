import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplianceDocumentType {
  gst,
  pan,
  msme,
  factoryLicense,
  iso,
  pfEsic,
  auditReport,
  balanceSheet,
  inspectionDocument,
}

enum ComplianceDocumentCategory { financial, hr, quality, legal }

enum ComplianceExpiryStatus { active, expiringSoon, expired }

extension ComplianceDocumentTypeX on ComplianceDocumentType {
  String get key {
    switch (this) {
      case ComplianceDocumentType.gst:
        return 'gst';
      case ComplianceDocumentType.pan:
        return 'pan';
      case ComplianceDocumentType.msme:
        return 'msme';
      case ComplianceDocumentType.factoryLicense:
        return 'factory_license';
      case ComplianceDocumentType.iso:
        return 'iso';
      case ComplianceDocumentType.pfEsic:
        return 'pf_esic';
      case ComplianceDocumentType.auditReport:
        return 'audit_report';
      case ComplianceDocumentType.balanceSheet:
        return 'balance_sheet';
      case ComplianceDocumentType.inspectionDocument:
        return 'inspection_document';
    }
  }

  String get label {
    switch (this) {
      case ComplianceDocumentType.gst:
        return 'GST';
      case ComplianceDocumentType.pan:
        return 'PAN';
      case ComplianceDocumentType.msme:
        return 'MSME';
      case ComplianceDocumentType.factoryLicense:
        return 'Factory License';
      case ComplianceDocumentType.iso:
        return 'ISO';
      case ComplianceDocumentType.pfEsic:
        return 'PF / ESIC';
      case ComplianceDocumentType.auditReport:
        return 'Audit Report';
      case ComplianceDocumentType.balanceSheet:
        return 'Balance Sheet';
      case ComplianceDocumentType.inspectionDocument:
        return 'Inspection Document';
    }
  }

  ComplianceDocumentCategory get category {
    switch (this) {
      case ComplianceDocumentType.gst:
      case ComplianceDocumentType.pan:
      case ComplianceDocumentType.auditReport:
      case ComplianceDocumentType.balanceSheet:
        return ComplianceDocumentCategory.financial;
      case ComplianceDocumentType.pfEsic:
        return ComplianceDocumentCategory.hr;
      case ComplianceDocumentType.iso:
      case ComplianceDocumentType.inspectionDocument:
        return ComplianceDocumentCategory.quality;
      case ComplianceDocumentType.msme:
      case ComplianceDocumentType.factoryLicense:
        return ComplianceDocumentCategory.legal;
    }
  }

  static ComplianceDocumentType fromKey(String key) {
    return ComplianceDocumentType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => ComplianceDocumentType.gst,
    );
  }
}

extension ComplianceDocumentCategoryX on ComplianceDocumentCategory {
  String get key {
    switch (this) {
      case ComplianceDocumentCategory.financial:
        return 'financial';
      case ComplianceDocumentCategory.hr:
        return 'hr';
      case ComplianceDocumentCategory.quality:
        return 'quality';
      case ComplianceDocumentCategory.legal:
        return 'legal';
    }
  }

  String get label {
    switch (this) {
      case ComplianceDocumentCategory.financial:
        return 'Financial';
      case ComplianceDocumentCategory.hr:
        return 'HR Compliance';
      case ComplianceDocumentCategory.quality:
        return 'ISO & Inspection';
      case ComplianceDocumentCategory.legal:
        return 'Legal';
    }
  }
}

extension ComplianceExpiryStatusX on ComplianceExpiryStatus {
  String get label {
    switch (this) {
      case ComplianceExpiryStatus.active:
        return 'Active';
      case ComplianceExpiryStatus.expiringSoon:
        return 'Expiring Soon';
      case ComplianceExpiryStatus.expired:
        return 'Expired';
    }
  }
}

class ComplianceDocumentModel {
  const ComplianceDocumentModel({
    required this.id,
    required this.tenantId,
    required this.documentType,
    required this.documentNo,
    required this.issueDate,
    required this.expiryDate,
    required this.remarks,
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
    required this.uploadedBy,
    required this.uploadedByEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final ComplianceDocumentType documentType;
  final String documentNo;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String remarks;
  final String fileName;
  final String fileUrl;
  final String storagePath;
  final String uploadedBy;
  final String uploadedByEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComplianceDocumentCategory get category => documentType.category;

  ComplianceExpiryStatus get expiryStatus {
    final expiry = expiryDate;
    if (expiry == null) return ComplianceExpiryStatus.active;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedExpiry = DateTime(expiry.year, expiry.month, expiry.day);
    final daysLeft = normalizedExpiry.difference(normalizedToday).inDays;

    if (daysLeft < 0) return ComplianceExpiryStatus.expired;
    if (daysLeft <= 30) return ComplianceExpiryStatus.expiringSoon;
    return ComplianceExpiryStatus.active;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'companyId': tenantId,
      'documentType': documentType.key,
      'category': category.key,
      'documentNo': documentNo,
      'issueDate': issueDate == null ? null : Timestamp.fromDate(issueDate!),
      'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'remarks': remarks,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'uploadedBy': uploadedBy,
      'uploadedByEmail': uploadedByEmail,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ComplianceDocumentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ComplianceDocumentModel(
      id: doc.id,
      tenantId: _readString(data, 'tenantId'),
      documentType: ComplianceDocumentTypeX.fromKey(
        _readString(data, 'documentType'),
      ),
      documentNo: _readString(data, 'documentNo'),
      issueDate: _readDate(data['issueDate']),
      expiryDate: _readDate(data['expiryDate']),
      remarks: _readString(data, 'remarks'),
      fileName: _readString(data, 'fileName'),
      fileUrl: _readString(data, 'fileUrl'),
      storagePath: _readString(data, 'storagePath'),
      uploadedBy: _readString(data, 'uploadedBy'),
      uploadedByEmail: _readString(data, 'uploadedByEmail'),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static String _readString(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString();
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
