class DocumentLayoutModel {
  static const double pageWidthPt = 595.28;
  static const double pageHeightPt = 841.89;

  final String backgroundUrl;
  final String backgroundStoragePath;
  final String backgroundFileName;
  final String backgroundFileType;
  final int backgroundSizeBytes;
  final double headerHeightPt;
  final double footerHeightPt;
  final double leftMarginPt;
  final double rightMarginPt;
  final double topMarginPt;
  final double bottomMarginPt;

  const DocumentLayoutModel({
    this.backgroundUrl = '', this.backgroundStoragePath = '',
    this.backgroundFileName = '', this.backgroundFileType = '',
    this.backgroundSizeBytes = 0, this.headerHeightPt = 72,
    this.footerHeightPt = 54, this.leftMarginPt = 36,
    this.rightMarginPt = 36, this.topMarginPt = 18,
    this.bottomMarginPt = 18,
  });

  factory DocumentLayoutModel.fromMap(Map<String, dynamic> map) {
    double number(String key, double fallback) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    return DocumentLayoutModel(
      backgroundUrl: (map['backgroundUrl'] ?? '').toString(),
      backgroundStoragePath: (map['backgroundStoragePath'] ?? '').toString(),
      backgroundFileName: (map['backgroundFileName'] ?? '').toString(),
      backgroundFileType: (map['backgroundFileType'] ?? '').toString(),
      backgroundSizeBytes: (map['backgroundSizeBytes'] as num?)?.toInt() ?? 0,
      headerHeightPt: number('headerHeightPt', 72),
      footerHeightPt: number('footerHeightPt', 54),
      leftMarginPt: number('leftMarginPt', 36),
      rightMarginPt: number('rightMarginPt', 36),
      topMarginPt: number('topMarginPt', 18),
      bottomMarginPt: number('bottomMarginPt', 18),
    );
  }

  Map<String, dynamic> toMap() => {
    'backgroundUrl': backgroundUrl,
    'backgroundStoragePath': backgroundStoragePath,
    'backgroundFileName': backgroundFileName,
    'backgroundFileType': backgroundFileType,
    'backgroundSizeBytes': backgroundSizeBytes,
    'pageSize': 'A4', 'orientation': 'portrait',
    'headerHeightPt': headerHeightPt, 'footerHeightPt': footerHeightPt,
    'leftMarginPt': leftMarginPt, 'rightMarginPt': rightMarginPt,
    'topMarginPt': topMarginPt, 'bottomMarginPt': bottomMarginPt,
  };

  DocumentLayoutModel copyWith({
    String? backgroundUrl, String? backgroundStoragePath,
    String? backgroundFileName, String? backgroundFileType,
    int? backgroundSizeBytes, double? headerHeightPt,
    double? footerHeightPt, double? leftMarginPt, double? rightMarginPt,
    double? topMarginPt, double? bottomMarginPt,
  }) => DocumentLayoutModel(
    backgroundUrl: backgroundUrl ?? this.backgroundUrl,
    backgroundStoragePath: backgroundStoragePath ?? this.backgroundStoragePath,
    backgroundFileName: backgroundFileName ?? this.backgroundFileName,
    backgroundFileType: backgroundFileType ?? this.backgroundFileType,
    backgroundSizeBytes: backgroundSizeBytes ?? this.backgroundSizeBytes,
    headerHeightPt: headerHeightPt ?? this.headerHeightPt,
    footerHeightPt: footerHeightPt ?? this.footerHeightPt,
    leftMarginPt: leftMarginPt ?? this.leftMarginPt,
    rightMarginPt: rightMarginPt ?? this.rightMarginPt,
    topMarginPt: topMarginPt ?? this.topMarginPt,
    bottomMarginPt: bottomMarginPt ?? this.bottomMarginPt,
  );

  static double pointsToMillimetres(double points) => points * 25.4 / 72;
}
