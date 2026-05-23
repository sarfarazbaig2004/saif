class SalesDocumentAttachmentModel {
  final String id;
  final String fileName;
  final String fileUrl;
  final String documentType;
  final String uploadedByUid;
  final DateTime? uploadedAt;

  const SalesDocumentAttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.documentType,
    required this.uploadedByUid,
    required this.uploadedAt,
  });

  factory SalesDocumentAttachmentModel.fromMap(Map<String, dynamic> map) {
    return SalesDocumentAttachmentModel(
      id: (map['id'] ?? '').toString(),
      fileName: (map['fileName'] ?? '').toString(),
      fileUrl: (map['fileUrl'] ?? '').toString(),
      documentType: (map['documentType'] ?? '').toString(),
      uploadedByUid: (map['uploadedByUid'] ?? '').toString(),
      uploadedAt: _toDate(map['uploadedAt']),
    );
  }

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

  static DateTime? _toDate(dynamic value) {
    if (value is DateTime) return value;
    return null;
  }
}
