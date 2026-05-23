class InquiryCostingSnapshotModel {
  final double estimatedSteelWeightKg;
  final double estimatedFabricationCost;
  final double estimatedGalvanizingCost;
  final double estimatedTransportCost;
  final double estimatedPackingCost;
  final double estimatedInsuranceCost;
  final double targetMarginPercent;
  final double targetSellingPrice;

  const InquiryCostingSnapshotModel({
    required this.estimatedSteelWeightKg,
    required this.estimatedFabricationCost,
    required this.estimatedGalvanizingCost,
    required this.estimatedTransportCost,
    required this.estimatedPackingCost,
    required this.estimatedInsuranceCost,
    required this.targetMarginPercent,
    required this.targetSellingPrice,
  });

  factory InquiryCostingSnapshotModel.empty() {
    return const InquiryCostingSnapshotModel(
      estimatedSteelWeightKg: 0,
      estimatedFabricationCost: 0,
      estimatedGalvanizingCost: 0,
      estimatedTransportCost: 0,
      estimatedPackingCost: 0,
      estimatedInsuranceCost: 0,
      targetMarginPercent: 0,
      targetSellingPrice: 0,
    );
  }

  factory InquiryCostingSnapshotModel.fromMap(Map<String, dynamic> map) {
    return InquiryCostingSnapshotModel(
      estimatedSteelWeightKg: _toDouble(map['estimatedSteelWeightKg']),
      estimatedFabricationCost: _toDouble(map['estimatedFabricationCost']),
      estimatedGalvanizingCost: _toDouble(map['estimatedGalvanizingCost']),
      estimatedTransportCost: _toDouble(map['estimatedTransportCost']),
      estimatedPackingCost: _toDouble(map['estimatedPackingCost']),
      estimatedInsuranceCost: _toDouble(map['estimatedInsuranceCost']),
      targetMarginPercent: _toDouble(map['targetMarginPercent']),
      targetSellingPrice: _toDouble(map['targetSellingPrice']),
    );
  }

  double get estimatedTotalCost {
    return estimatedFabricationCost +
        estimatedGalvanizingCost +
        estimatedTransportCost +
        estimatedPackingCost +
        estimatedInsuranceCost;
  }

  Map<String, dynamic> toMap() {
    return {
      'estimatedSteelWeightKg': estimatedSteelWeightKg,
      'estimatedFabricationCost': estimatedFabricationCost,
      'estimatedGalvanizingCost': estimatedGalvanizingCost,
      'estimatedTransportCost': estimatedTransportCost,
      'estimatedPackingCost': estimatedPackingCost,
      'estimatedInsuranceCost': estimatedInsuranceCost,
      'targetMarginPercent': targetMarginPercent,
      'targetSellingPrice': targetSellingPrice,
      'estimatedTotalCost': estimatedTotalCost,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
