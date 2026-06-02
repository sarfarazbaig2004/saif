class CoatingMasterModel {
  final String id;
  final String status;
  final String spec;
  final double percent;
  final bool isActive;

  const CoatingMasterModel({
    required this.id,
    required this.status,
    required this.spec,
    required this.percent,
    this.isActive = true,
  });

  factory CoatingMasterModel.fromMap(String id, Map<String, dynamic> map) {
    return CoatingMasterModel(
      id: id,
      status: (map['status'] ?? '').toString(),
      spec: (map['spec'] ?? '').toString(),
      percent: (map['percent'] is num)
          ? (map['percent'] as num).toDouble()
          : double.tryParse((map['percent'] ?? '0').toString()) ?? 0,
      isActive: map['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'spec': spec,
      'percent': percent,
      'isActive': isActive,
    };
  }
}
