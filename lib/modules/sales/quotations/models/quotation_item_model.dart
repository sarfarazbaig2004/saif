class QuotationItemModel {
  final String id;
  final String inquiryItemId;
  final String itemName;
  final String description;
  final double quantity;
  final String uom;
  final double weightKg;
  final double unitRate;
  final double gstPercent;
  final String material;
  final String finish;
  final String remarks;

  const QuotationItemModel({
    required this.id,
    required this.inquiryItemId,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.uom,
    required this.weightKg,
    required this.unitRate,
    required this.gstPercent,
    required this.material,
    required this.finish,
    required this.remarks,
  });

  factory QuotationItemModel.fromMap(Map<String, dynamic> map) {
    return QuotationItemModel(
      id: (map['id'] ?? '').toString(),
      inquiryItemId: (map['inquiryItemId'] ?? '').toString(),
      itemName: (map['itemName'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      quantity: _toDouble(map['quantity']),
      uom: (map['uom'] ?? 'Nos').toString(),
      weightKg: _toDouble(map['weightKg']),
      unitRate: _toDouble(map['unitRate']),
      gstPercent: _toDouble(map['gstPercent']),
      material: (map['material'] ?? '').toString(),
      finish: (map['finish'] ?? '').toString(),
      remarks: (map['remarks'] ?? '').toString(),
    );
  }

  double get basicAmount => quantity * unitRate;

  double get gstAmount => basicAmount * gstPercent / 100;

  double get totalAmount => basicAmount + gstAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inquiryItemId': inquiryItemId,
      'itemName': itemName,
      'description': description,
      'quantity': quantity,
      'uom': uom,
      'weightKg': weightKg,
      'unitRate': unitRate,
      'gstPercent': gstPercent,
      'basicAmount': basicAmount,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'material': material,
      'finish': finish,
      'remarks': remarks,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
