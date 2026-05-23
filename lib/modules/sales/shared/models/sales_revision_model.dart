class SalesRevisionModel {
  final int revisionNo;
  final String revisionCode;
  final String reason;
  final String changedByUid;
  final String changedByName;
  final DateTime? changedAt;

  const SalesRevisionModel({
    required this.revisionNo,
    required this.revisionCode,
    required this.reason,
    required this.changedByUid,
    required this.changedByName,
    required this.changedAt,
  });

  factory SalesRevisionModel.fromMap(Map<String, dynamic> map) {
    return SalesRevisionModel(
      revisionNo: _toInt(map['revisionNo']),
      revisionCode: (map['revisionCode'] ?? '').toString(),
      reason: (map['reason'] ?? '').toString(),
      changedByUid: (map['changedByUid'] ?? '').toString(),
      changedByName: (map['changedByName'] ?? '').toString(),
      changedAt: _toDate(map['changedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'revisionNo': revisionNo,
      'revisionCode': revisionCode,
      'reason': reason,
      'changedByUid': changedByUid,
      'changedByName': changedByName,
      'changedAt': changedAt,
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
}
