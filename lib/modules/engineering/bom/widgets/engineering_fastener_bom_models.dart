import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/models/engineering_fastener_line_model.dart';

class FastenerBomLineDraft {
  final location = TextEditingController();
  final description = TextEditingController();
  final boltDescription = TextEditingController();
  final boltLength = TextEditingController();
  final material = TextEditingController();
  final qtyPerStructure = TextEditingController();

  FastenerBomLineDraft({
    String location = '',
    String description = '',
    String boltDescription = '',
    String boltLength = '',
    String material = '',
    double qtyPerStructure = 0,
  }) {
    this.location.text = location;
    this.description.text = description;
    this.boltDescription.text = boltDescription;
    this.boltLength.text = boltLength;
    this.material.text = material;
    if (qtyPerStructure > 0) {
      this.qtyPerStructure.text = _format(qtyPerStructure);
    }
  }

  bool get isBlank {
    return location.text.trim().isEmpty &&
        description.text.trim().isEmpty &&
        boltDescription.text.trim().isEmpty &&
        qtyPerStructure.text.trim().isEmpty;
  }

  double get qtyPerStructureValue => _toDouble(qtyPerStructure.text);
  double qtyForProject(double projectQty) => qtyPerStructureValue * projectQty;

  EngineeringFastenerLineModel toModel(int lineNo, double projectQty) {
    return EngineeringFastenerLineModel(
      lineNo: lineNo,
      location: location.text.trim(),
      description: description.text.trim(),
      boltDescription: boltDescription.text.trim(),
      boltLength: boltLength.text.trim(),
      material: material.text.trim(),
      qtyPerStructure: qtyPerStructureValue,
      qtyForProject: qtyForProject(projectQty),
    );
  }

  void dispose() {
    for (final controller in [
      location,
      description,
      boltDescription,
      boltLength,
      material,
      qtyPerStructure,
    ]) {
      controller.dispose();
    }
  }

  static double _toDouble(String value) => double.tryParse(value.trim()) ?? 0;
  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
