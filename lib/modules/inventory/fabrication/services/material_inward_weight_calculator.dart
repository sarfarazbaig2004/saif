double calculateMaterialInwardWeightKg({
  required double unitWeightKgPerMeter,
  required double lengthMeter,
  required double receivedQuantityNos,
}) {
  if (unitWeightKgPerMeter <= 0 ||
      lengthMeter <= 0 ||
      receivedQuantityNos <= 0) {
    return 0;
  }

  return unitWeightKgPerMeter * lengthMeter * receivedQuantityNos;
}

String formatMaterialInwardWeightKg(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
