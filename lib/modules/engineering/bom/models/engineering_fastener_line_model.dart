class EngineeringFastenerLineModel {
  final int lineNo;
  final String location;
  final String description;
  final String boltDescription;
  final String boltLength;
  final String material;
  final double qtyPerStructure;
  final double qtyForProject;

  const EngineeringFastenerLineModel({
    required this.lineNo,
    required this.location,
    required this.description,
    required this.boltDescription,
    required this.boltLength,
    required this.material,
    required this.qtyPerStructure,
    required this.qtyForProject,
  });

  factory EngineeringFastenerLineModel.fromMap(Map<String, dynamic> map) {
    return EngineeringFastenerLineModel(
      lineNo: _toInt(map['lineNo']),
      location: (map['location'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      boltDescription: (map['boltDescription'] ?? '').toString(),
      boltLength: (map['boltLength'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      qtyPerStructure: _toDouble(map['qtyPerStructure']),
      qtyForProject: _toDouble(map['qtyForProject']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lineNo': lineNo,
      'location': location,
      'description': description,
      'boltDescription': boltDescription,
      'boltLength': boltLength,
      'material': material,
      'qtyPerStructure': qtyPerStructure,
      'qtyForProject': qtyForProject,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
