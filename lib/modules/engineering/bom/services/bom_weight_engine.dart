class BomWeightEngine {
  const BomWeightEngine._();

  static double calculatedWeight({
    required double qty,
    required double lengthMm,
    required double weightPerMeter,
  }) {
    if (qty <= 0 || lengthMm <= 0 || weightPerMeter <= 0) return 0;
    return roundWeight(qty * (lengthMm / 1000) * weightPerMeter);
  }

  static double roundWeight(double value) {
    return (value * 1000).roundToDouble() / 1000;
  }
}
