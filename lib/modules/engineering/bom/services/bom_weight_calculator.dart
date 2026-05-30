class BomWeightCalculator {
  const BomWeightCalculator._();

  static double lineWeight({
    required double qtyPerStructure,
    required double lengthMm,
    required double widthMm,
    required double thicknessMm,
    required double unitWeightKgPerMeter,
    required String materialCategory,
  }) {
    final lengthM = lengthMm / 1000;
    final kgPerM = unitWeightKgPerMeter;
    if (qtyPerStructure <= 0 || lengthM <= 0) return 0;
    if (kgPerM > 0) return _round(qtyPerStructure * lengthM * kgPerM);

    if (!_isPlateLike(materialCategory)) return 0;
    final widthM = widthMm / 1000;
    final thickM = thicknessMm / 1000;
    if (widthM <= 0 || thickM <= 0) return 0;
    return _round(qtyPerStructure * lengthM * widthM * thickM * 7850);
  }

  static double totalProjectQuantity(
    double qtyPerStructure,
    double projectQty,
  ) {
    return _round(qtyPerStructure * projectQty);
  }

  static double totalProjectWeight(double lineWeight, double projectQty) {
    return _round(lineWeight * projectQty);
  }

  static bool _isPlateLike(String category) {
    final normalized = category.trim().toLowerCase();
    return normalized == 'plate' || normalized == 'roofing sheet';
  }

  static double _round(double value) => (value * 1000).roundToDouble() / 1000;
}
