import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplianceValidityType { expiryBased, amendmentBased }

enum ComplianceAccessCategory { financial, hr, quality, legal }

enum ComplianceDocumentTag {
  gst,
  pan,
  aadhaar,
  pf,
  esic,
  msme,
  factoryLicense,
  iso,
  firstAid,
  auditReport,
  balanceSheet,
  inspectionDocument,
}

enum ComplianceDocumentStatus {
  active,
  expiringSoon,
  expired,
  amendmentRequired,
  updated,
}

enum QmsApprovalStatus { draft, pendingApproval, approved, rejected }

extension ComplianceValidityTypeX on ComplianceValidityType {
  String get key {
    switch (this) {
      case ComplianceValidityType.expiryBased:
        return 'expiry_based';
      case ComplianceValidityType.amendmentBased:
        return 'amendment_based';
    }
  }

  String get label {
    switch (this) {
      case ComplianceValidityType.expiryBased:
        return 'Expiry Based';
      case ComplianceValidityType.amendmentBased:
        return 'Non Expiry / Amendment Based';
    }
  }

  static ComplianceValidityType fromKey(String key) {
    return ComplianceValidityType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => ComplianceValidityType.expiryBased,
    );
  }
}

extension ComplianceAccessCategoryX on ComplianceAccessCategory {
  String get key {
    switch (this) {
      case ComplianceAccessCategory.financial:
        return 'financial';
      case ComplianceAccessCategory.hr:
        return 'hr';
      case ComplianceAccessCategory.quality:
        return 'quality';
      case ComplianceAccessCategory.legal:
        return 'legal';
    }
  }

  String get label {
    switch (this) {
      case ComplianceAccessCategory.financial:
        return 'Financial';
      case ComplianceAccessCategory.hr:
        return 'HR Compliance';
      case ComplianceAccessCategory.quality:
        return 'ISO & Inspection';
      case ComplianceAccessCategory.legal:
        return 'Legal';
    }
  }
}

extension ComplianceDocumentTagX on ComplianceDocumentTag {
  String get key {
    switch (this) {
      case ComplianceDocumentTag.gst:
        return 'gst';
      case ComplianceDocumentTag.pan:
        return 'pan';
      case ComplianceDocumentTag.aadhaar:
        return 'aadhaar';
      case ComplianceDocumentTag.pf:
        return 'pf';
      case ComplianceDocumentTag.esic:
        return 'esic';
      case ComplianceDocumentTag.msme:
        return 'msme';
      case ComplianceDocumentTag.factoryLicense:
        return 'factory_license';
      case ComplianceDocumentTag.iso:
        return 'iso';
      case ComplianceDocumentTag.firstAid:
        return 'first_aid';
      case ComplianceDocumentTag.auditReport:
        return 'audit_report';
      case ComplianceDocumentTag.balanceSheet:
        return 'balance_sheet';
      case ComplianceDocumentTag.inspectionDocument:
        return 'inspection_document';
    }
  }

  String get label {
    switch (this) {
      case ComplianceDocumentTag.gst:
        return 'GST';
      case ComplianceDocumentTag.pan:
        return 'PAN';
      case ComplianceDocumentTag.aadhaar:
        return 'Aadhaar';
      case ComplianceDocumentTag.pf:
        return 'PF';
      case ComplianceDocumentTag.esic:
        return 'ESIC';
      case ComplianceDocumentTag.msme:
        return 'MSME';
      case ComplianceDocumentTag.factoryLicense:
        return 'Factory License';
      case ComplianceDocumentTag.iso:
        return 'ISO';
      case ComplianceDocumentTag.firstAid:
        return 'First Aid';
      case ComplianceDocumentTag.auditReport:
        return 'Audit Report';
      case ComplianceDocumentTag.balanceSheet:
        return 'Balance Sheet';
      case ComplianceDocumentTag.inspectionDocument:
        return 'Inspection Document';
    }
  }

  ComplianceAccessCategory get accessCategory {
    switch (this) {
      case ComplianceDocumentTag.gst:
      case ComplianceDocumentTag.pan:
      case ComplianceDocumentTag.msme:
      case ComplianceDocumentTag.auditReport:
      case ComplianceDocumentTag.balanceSheet:
        return ComplianceAccessCategory.financial;
      case ComplianceDocumentTag.aadhaar:
      case ComplianceDocumentTag.pf:
      case ComplianceDocumentTag.esic:
      case ComplianceDocumentTag.firstAid:
        return ComplianceAccessCategory.hr;
      case ComplianceDocumentTag.iso:
      case ComplianceDocumentTag.inspectionDocument:
        return ComplianceAccessCategory.quality;
      case ComplianceDocumentTag.factoryLicense:
        return ComplianceAccessCategory.legal;
    }
  }

  bool get supportsAmendmentValidity {
    return this == ComplianceDocumentTag.gst ||
        this == ComplianceDocumentTag.pan ||
        this == ComplianceDocumentTag.aadhaar ||
        this == ComplianceDocumentTag.msme;
  }

  static ComplianceDocumentTag fromKey(String key) {
    return ComplianceDocumentTag.values.firstWhere(
      (tag) => tag.key == key,
      orElse: () => ComplianceDocumentTag.gst,
    );
  }
}

extension ComplianceDocumentStatusX on ComplianceDocumentStatus {
  String get key {
    switch (this) {
      case ComplianceDocumentStatus.active:
        return 'active';
      case ComplianceDocumentStatus.expiringSoon:
        return 'expiring_soon';
      case ComplianceDocumentStatus.expired:
        return 'expired';
      case ComplianceDocumentStatus.amendmentRequired:
        return 'amendment_required';
      case ComplianceDocumentStatus.updated:
        return 'updated';
    }
  }

  String get label {
    switch (this) {
      case ComplianceDocumentStatus.active:
        return 'Active';
      case ComplianceDocumentStatus.expiringSoon:
        return 'Expiring Soon';
      case ComplianceDocumentStatus.expired:
        return 'Expired';
      case ComplianceDocumentStatus.amendmentRequired:
        return 'Amendment Required';
      case ComplianceDocumentStatus.updated:
        return 'Updated';
    }
  }

  static ComplianceDocumentStatus fromKey(String key) {
    return ComplianceDocumentStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => ComplianceDocumentStatus.active,
    );
  }
}

extension QmsApprovalStatusX on QmsApprovalStatus {
  String get key {
    switch (this) {
      case QmsApprovalStatus.draft:
        return 'draft';
      case QmsApprovalStatus.pendingApproval:
        return 'pending_approval';
      case QmsApprovalStatus.approved:
        return 'approved';
      case QmsApprovalStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case QmsApprovalStatus.draft:
        return 'Draft';
      case QmsApprovalStatus.pendingApproval:
        return 'Pending Approval';
      case QmsApprovalStatus.approved:
        return 'Approved';
      case QmsApprovalStatus.rejected:
        return 'Rejected';
    }
  }

  static QmsApprovalStatus fromKey(String key) {
    return QmsApprovalStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => QmsApprovalStatus.draft,
    );
  }
}

class ComplianceDocumentModel {
  const ComplianceDocumentModel({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.tags,
    required this.validityType,
    required this.manualStatus,
    required this.documentNo,
    required this.issueDate,
    required this.expiryDate,
    required this.amendmentDate,
    required this.remarks,
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
    required this.uploadedBy,
    required this.uploadedByEmail,
    required this.isQmsDocument,
    required this.revisionNo,
    required this.previousRevision,
    required this.approvedBy,
    required this.approvalDate,
    required this.isObsolete,
    required this.qmsApprovalStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String title;
  final List<ComplianceDocumentTag> tags;
  final ComplianceValidityType validityType;
  final ComplianceDocumentStatus manualStatus;
  final String documentNo;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime? amendmentDate;
  final String remarks;
  final String fileName;
  final String fileUrl;
  final String storagePath;
  final String uploadedBy;
  final String uploadedByEmail;
  final bool isQmsDocument;
  final String revisionNo;
  final String previousRevision;
  final String approvedBy;
  final DateTime? approvalDate;
  final bool isObsolete;
  final QmsApprovalStatus qmsApprovalStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<ComplianceAccessCategory> get accessCategories {
    return tags
        .map((tag) => tag.accessCategory)
        .toSet()
        .toList(growable: false);
  }

  bool hasAccessCategory(ComplianceAccessCategory category) {
    return accessCategories.contains(category);
  }

  bool get hasAmendmentTag {
    return tags.any((tag) => tag.supportsAmendmentValidity);
  }

  String get tagLabel {
    if (tags.isEmpty) return '-';
    return tags.map((tag) => tag.label).join(', ');
  }

  String get qmsKey {
    final number = documentNo.trim();
    if (number.isNotEmpty) return number.toLowerCase();
    return title.trim().toLowerCase();
  }

  int get revisionSortValue {
    final digits = revisionNo.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  ComplianceDocumentStatus get status {
    if (validityType == ComplianceValidityType.amendmentBased ||
        (expiryDate == null && hasAmendmentTag)) {
      if (amendmentDate != null) return ComplianceDocumentStatus.updated;
      return manualStatus == ComplianceDocumentStatus.amendmentRequired
          ? ComplianceDocumentStatus.amendmentRequired
          : ComplianceDocumentStatus.active;
    }

    final expiry = expiryDate;
    if (expiry == null) return ComplianceDocumentStatus.active;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedExpiry = DateTime(expiry.year, expiry.month, expiry.day);
    final daysLeft = normalizedExpiry.difference(normalizedToday).inDays;

    if (daysLeft < 0) return ComplianceDocumentStatus.expired;
    if (daysLeft <= 30) return ComplianceDocumentStatus.expiringSoon;
    return ComplianceDocumentStatus.active;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'companyId': tenantId,
      'title': title,
      'documentTitle': title,
      'documentCategories': tags.map((tag) => tag.key).toList(),
      'accessCategories': accessCategories
          .map((category) => category.key)
          .toList(),
      'validityType': validityType.key,
      'status': manualStatus.key,
      'documentNo': documentNo,
      'issueDate': issueDate == null ? null : Timestamp.fromDate(issueDate!),
      'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'amendmentDate': amendmentDate == null
          ? null
          : Timestamp.fromDate(amendmentDate!),
      'remarks': remarks,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'uploadedFileUrl': fileUrl,
      'storagePath': storagePath,
      'uploadedBy': uploadedBy,
      'uploadedByEmail': uploadedByEmail,
      'isQmsDocument': isQmsDocument,
      'revisionNo': revisionNo,
      'previousRevision': previousRevision,
      'approvedBy': approvedBy,
      'approvalDate': approvalDate == null
          ? null
          : Timestamp.fromDate(approvalDate!),
      'isObsolete': isObsolete,
      'qmsApprovalStatus': qmsApprovalStatus.key,
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
    final tags = _readTags(data);
    return ComplianceDocumentModel(
      id: doc.id,
      tenantId: _readString(data, 'tenantId'),
      title: _readString(data, 'title').isNotEmpty
          ? _readString(data, 'title')
          : _readString(data, 'documentTitle'),
      tags: tags,
      validityType: ComplianceValidityTypeX.fromKey(
        _readString(data, 'validityType'),
      ),
      manualStatus: ComplianceDocumentStatusX.fromKey(
        _readString(data, 'status'),
      ),
      documentNo: _readString(data, 'documentNo'),
      issueDate: _readDate(data['issueDate']),
      expiryDate: _readDate(data['expiryDate']),
      amendmentDate: _readDate(data['amendmentDate']),
      remarks: _readString(data, 'remarks'),
      fileName: _readString(data, 'fileName'),
      fileUrl: _readString(data, 'fileUrl').isNotEmpty
          ? _readString(data, 'fileUrl')
          : _readString(data, 'uploadedFileUrl'),
      storagePath: _readString(data, 'storagePath'),
      uploadedBy: _readString(data, 'uploadedBy'),
      uploadedByEmail: _readString(data, 'uploadedByEmail'),
      isQmsDocument: _readBool(data, 'isQmsDocument'),
      revisionNo: _readString(data, 'revisionNo'),
      previousRevision: _readString(data, 'previousRevision'),
      approvedBy: _readString(data, 'approvedBy'),
      approvalDate: _readDate(data['approvalDate']),
      isObsolete: _readBool(data, 'isObsolete'),
      qmsApprovalStatus: QmsApprovalStatusX.fromKey(
        _readString(data, 'qmsApprovalStatus'),
      ),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  ComplianceDocumentModel copyWith({
    String? id,
    String? tenantId,
    String? title,
    List<ComplianceDocumentTag>? tags,
    ComplianceValidityType? validityType,
    ComplianceDocumentStatus? manualStatus,
    String? documentNo,
    DateTime? issueDate,
    DateTime? expiryDate,
    DateTime? amendmentDate,
    String? remarks,
    String? fileName,
    String? fileUrl,
    String? storagePath,
    String? uploadedBy,
    String? uploadedByEmail,
    bool? isQmsDocument,
    String? revisionNo,
    String? previousRevision,
    String? approvedBy,
    DateTime? approvalDate,
    bool? isObsolete,
    QmsApprovalStatus? qmsApprovalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComplianceDocumentModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      validityType: validityType ?? this.validityType,
      manualStatus: manualStatus ?? this.manualStatus,
      documentNo: documentNo ?? this.documentNo,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      amendmentDate: amendmentDate ?? this.amendmentDate,
      remarks: remarks ?? this.remarks,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByEmail: uploadedByEmail ?? this.uploadedByEmail,
      isQmsDocument: isQmsDocument ?? this.isQmsDocument,
      revisionNo: revisionNo ?? this.revisionNo,
      previousRevision: previousRevision ?? this.previousRevision,
      approvedBy: approvedBy ?? this.approvedBy,
      approvalDate: approvalDate ?? this.approvalDate,
      isObsolete: isObsolete ?? this.isObsolete,
      qmsApprovalStatus: qmsApprovalStatus ?? this.qmsApprovalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<ComplianceDocumentTag> _readTags(Map<String, dynamic> data) {
    final rawTags = data['documentCategories'];
    if (rawTags is Iterable) {
      return rawTags
          .map((value) => ComplianceDocumentTagX.fromKey(value.toString()))
          .toSet()
          .toList(growable: false);
    }

    final legacyType = _readString(data, 'documentType');
    if (legacyType.isNotEmpty) {
      return [ComplianceDocumentTagX.fromKey(legacyType)];
    }

    return const [];
  }

  static String _readString(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString();
  }

  static bool _readBool(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
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
