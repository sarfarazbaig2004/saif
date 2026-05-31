class InquiryItemModel {
  final String id;
  final String itemName;
  final String description;
  final double quantity;
  final String uom;
  final double weightKg;
  final String material;
  final String finish;
  final String drawingRef;
  final String remarks;

  final String bomId;
  final String bomNumber;
  final String bomRevision;
  final String bomRevisionId;
  final String costingSheetId;
  final double totalWeightKg;

  const InquiryItemModel({
    required this.id,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.uom,
    required this.weightKg,
    required this.material,
    required this.finish,
    required this.drawingRef,
    required this.remarks,
    this.bomId = '',
    this.bomNumber = '',
    this.bomRevision = '',
    this.bomRevisionId = '',
    this.costingSheetId = '',
    this.totalWeightKg = 0,
  });

  factory InquiryItemModel.empty() {
    return const InquiryItemModel(
      id: '',
      itemName: '',
      description: '',
      quantity: 0,
      uom: 'Nos',
      weightKg: 0,
      material: '',
      finish: '',
      drawingRef: '',
      remarks: '',
    );
  }

  factory InquiryItemModel.fromMap(Map<String, dynamic> map) {
    return InquiryItemModel(
      id: (map['id'] ?? '').toString(),
      itemName: (map['itemName'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      quantity: _toDouble(map['quantity']),
      uom: (map['uom'] ?? 'Nos').toString(),
      weightKg: _toDouble(map['weightKg']),
      material: (map['material'] ?? '').toString(),
      finish: (map['finish'] ?? '').toString(),
      drawingRef: (map['drawingRef'] ?? '').toString(),
      remarks: (map['remarks'] ?? '').toString(),
      bomId: (map['bomId'] ?? '').toString(),
      bomNumber: (map['bomNumber'] ?? '').toString(),
      bomRevision: (map['bomRevision'] ?? '').toString(),
      bomRevisionId: (map['bomRevisionId'] ?? '').toString(),
      costingSheetId: (map['costingSheetId'] ?? '').toString(),
      totalWeightKg: _toDouble(map['totalWeightKg'] ?? map['weightKg']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'description': description,
      'quantity': quantity,
      'uom': uom,
      'weightKg': weightKg,
      'material': material,
      'finish': finish,
      'drawingRef': drawingRef,
      'remarks': remarks,
      'bomId': bomId,
      'bomNumber': bomNumber,
      'bomRevision': bomRevision,
      'bomRevisionId': bomRevisionId,
      'costingSheetId': costingSheetId,
      'totalWeightKg': totalWeightKg,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}