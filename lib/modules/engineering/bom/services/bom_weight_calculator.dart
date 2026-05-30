class BomWeightCalculator {
  const BomWeightCalculator._();

  static double lineWeight({
    required double qtyPerStructure,
    required double lengthMm,
    required double widthMm,
    required double thicknessMm,
    required double unitWeightKgPerMeter,
    required String materialCategory,
    String materialCode = '',
  }) {
    final lengthM = lengthMm / 1000;
    final kgPerM = unitWeightKgPerMeter;
    if (qtyPerStructure <= 0 || lengthM <= 0) return 0;
    if (kgPerM > 0) return _round(qtyPerStructure * lengthM * kgPerM);

    if (!_isPlateLike(materialCategory)) return 0;
    final derivedKgPerM = _derivedKgPerM(
      materialCode: materialCode,
      widthMm: widthMm,
      thicknessMm: thicknessMm,
    );
    if (derivedKgPerM <= 0) return 0;
    return _round(qtyPerStructure * lengthM * derivedKgPerM);
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
    return normalized == 'plate' ||
        normalized == 'sheet' ||
        normalized == 'roofing sheet';
  }

  static double _derivedKgPerM({
    required String materialCode,
    required double widthMm,
    required double thicknessMm,
  }) {
    if (widthMm > 0 && thicknessMm > 0) {
      return _kgPerM(widthMm, thicknessMm);
    }

    final normalized = materialCode.toUpperCase().replaceAll(' ', '');
    final plate = RegExp(
      r'PLATE(\d+(?:\.\d+)?)X(\d+(?:\.\d+)?)',
    ).firstMatch(normalized);
    if (plate != null) {
      return _kgPerM(_toDouble(plate.group(1)), _toDouble(plate.group(2)));
    }

    final sheet = RegExp(
      r'^(\d+(?:\.\d+)?)X(\d+(?:\.\d+)?)X(\d+(?:\.\d+)?)$',
    ).firstMatch(normalized);
    if (sheet == null) return 0;
    return _kgPerM(_toDouble(sheet.group(2)), _toDouble(sheet.group(3)));
  }

  static double _kgPerM(double widthMm, double thicknessMm) {
    return (widthMm / 1000) * (thicknessMm / 1000) * 7850;
  }

  static double _toDouble(String? value) {
    return double.tryParse(value ?? '') ?? 0;
  }

  static double _round(double value) => (value * 1000).roundToDouble() / 1000;
}
