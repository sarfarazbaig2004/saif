class CustomerPoItemModel {
  final String id;
  final String quotationItemId;
  final String itemName;
  final String description;
  final double quantity;
  final String uom;
  final double unitRate;
  final double gstPercent;
  final double weightKg;
  final String material;
  final String finish;
  final String remarks;
  final String quotationLineType;
  final String bomSection;
  final String bomMaterial;
  final double bomLengthMm;
  final double bomWeight;

  const CustomerPoItemModel({
    required this.id,
    required this.quotationItemId,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.uom,
    required this.unitRate,
    required this.gstPercent,
    required this.weightKg,
    required this.material,
    required this.finish,
    required this.remarks,
    this.quotationLineType = 'commercial',
    this.bomSection = '',
    this.bomMaterial = '',
    this.bomLengthMm = 0,
    this.bomWeight = 0,
  });

  factory CustomerPoItemModel.fromMap(Map<String, dynamic> map) {
    return CustomerPoItemModel(
      id: (map['id'] ?? '').toString(),
      quotationItemId: (map['quotationItemId'] ?? '').toString(),
      itemName: (map['itemName'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      quantity: _toDouble(map['quantity']),
      uom: (map['uom'] ?? 'Nos').toString(),
      unitRate: _toDouble(map['unitRate']),
      gstPercent: _toDouble(map['gstPercent']),
      weightKg: _toDouble(map['weightKg']),
      material: (map['material'] ?? '').toString(),
      finish: (map['finish'] ?? '').toString(),
      remarks: (map['remarks'] ?? '').toString(),
      quotationLineType: (map['quotationLineType'] ?? 'commercial').toString(),
      bomSection: (map['bomSection'] ?? '').toString(),
      bomMaterial: (map['bomMaterial'] ?? '').toString(),
      bomLengthMm: _toDouble(map['bomLengthMm']),
      bomWeight: _toDouble(map['bomWeight']),
    );
  }

  double get basicAmount => quantity * unitRate;

  double get gstAmount => basicAmount * gstPercent / 100;

  double get totalAmount => basicAmount + gstAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotationItemId': quotationItemId,
      'itemName': itemName,
      'description': description,
      'quantity': quantity,
      'uom': uom,
      'unitRate': unitRate,
      'gstPercent': gstPercent,
      'weightKg': weightKg,
      'basicAmount': basicAmount,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'material': material,
      'finish': finish,
      'remarks': remarks,
      'quotationLineType': quotationLineType,
      'bomSection': bomSection,
      'bomMaterial': bomMaterial,
      'bomLengthMm': bomLengthMm,
      'bomWeight': bomWeight,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
