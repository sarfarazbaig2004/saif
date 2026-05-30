import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
import 'package:QUIK/modules/engineering/bom/services/bom_weight_calculator.dart';
import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';

class BomLineDraft {
  final itemDescription = TextEditingController();
  final sectionCode = TextEditingController();
  final materialCategory = TextEditingController();
  final materialName = TextEditingController();
  final qtyPerStructure = TextEditingController(text: '1');
  final lengthMm = TextEditingController();
  final widthMm = TextEditingController();
  final thicknessMm = TextEditingController();
  final odMm = TextEditingController();
  final idMm = TextEditingController();
  final heightMm = TextEditingController();
  final unitWeightKgPerMeter = TextEditingController();
  final coatingType = TextEditingController(text: 'HDG');
  final coatingSpec = TextEditingController();
  final yieldStrength = TextEditingController();
  final galvanizingMicron = TextEditingController();
  final grade = TextEditingController();
  final formulaType = TextEditingController();
  final remarks = TextEditingController();
  final customValues = <String, TextEditingController>{};
  String materialMasterId = '';

  BomLineDraft({String? itemDescription, double? qty}) {
    this.itemDescription.text = (itemDescription ?? '').trim();
    if (qty != null && qty > 0) qtyPerStructure.text = _format(qty);
  }

  bool get isBlank {
    return itemDescription.text.trim().isEmpty &&
        sectionCode.text.trim().isEmpty &&
        materialName.text.trim().isEmpty &&
        lengthMm.text.trim().isEmpty;
  }

  double get qtyPerStructureValue => _toDouble(qtyPerStructure.text);
  double get lengthMmValue => _toDouble(lengthMm.text);
  double get widthMmValue => _toDouble(widthMm.text);
  double get thicknessMmValue => _toDouble(thicknessMm.text);
  double get odMmValue => _toDouble(odMm.text);
  double get idMmValue => _toDouble(idMm.text);
  double get heightMmValue => _toDouble(heightMm.text);
  double get unitWeightKgPerMeterValue => _toDouble(unitWeightKgPerMeter.text);
  double get steelWeight => lineWeight;
  double get galvanisingWeight => 0;
  double get lineWeight => BomWeightCalculator.lineWeight(
    qtyPerStructure: qtyPerStructureValue,
    lengthMm: lengthMmValue,
    widthMm: widthMmValue,
    thicknessMm: thicknessMmValue,
    unitWeightKgPerMeter: unitWeightKgPerMeterValue,
    materialCategory: materialCategory.text,
  );

  TextEditingController customController(String fieldId) {
    return customValues.putIfAbsent(fieldId, TextEditingController.new);
  }

  double totalProjectQuantity(double projectQuantity) {
    return BomWeightCalculator.totalProjectQuantity(
      qtyPerStructureValue,
      projectQuantity,
    );
  }

  double totalProjectWeight(double projectQuantity) {
    return BomWeightCalculator.totalProjectWeight(lineWeight, projectQuantity);
  }

  void applyMaterial(MaterialMasterModel selected) {
    materialMasterId = selected.id;
    sectionCode.text = selected.materialCode;
    materialCategory.text = _categoryFrom(selected);
    materialName.text = selected.materialName.trim().isEmpty
        ? selected.displayName
        : selected.materialName;
    final selectedGrade = selected.materialGrade.trim();
    if (selectedGrade.isNotEmpty) {
      grade.text = selectedGrade;
    }
    final selectedYield = selected.yieldStrength.trim();
    if (selectedYield.isNotEmpty) {
      yieldStrength.text = selectedYield;
    } else if (selectedGrade.isNotEmpty) {
      yieldStrength.text = selectedGrade;
    }
    final selectedCoating = selected.coatingType.trim().isNotEmpty
        ? selected.coatingType.trim()
        : selected.coating.trim();
    if (selectedCoating.isNotEmpty) {
      coatingType.text = selectedCoating;
    }
    if (selected.coatingSpec.trim().isNotEmpty) {
      coatingSpec.text = selected.coatingSpec;
    }
    final formula = selected.weightFormula.trim().isNotEmpty
        ? selected.weightFormula.trim()
        : selected.formulaType.trim();
    if (formula.isNotEmpty) {
      formulaType.text = formula;
    }
    if (selected.standardWeightPerMeter > 0) {
      unitWeightKgPerMeter.text = _format(selected.standardWeightPerMeter);
    }
  }

  EngineeringBomLineModel toModel(
    int lineNo,
    double projectQuantity,
    List<BomCustomField> customFields,
  ) {
    return EngineeringBomLineModel(
      lineNo: lineNo,
      itemDescription: itemDescription.text.trim(),
      section: sectionCode.text.trim(),
      material: materialName.text.trim(),
      qty: qtyPerStructureValue,
      projectQuantity: projectQuantity,
      totalProjectQuantity: BomWeightCalculator.totalProjectQuantity(
        qtyPerStructureValue,
        projectQuantity,
      ),
      lengthMm: lengthMmValue,
      widthMm: widthMmValue,
      thicknessMm: thicknessMmValue,
      odMm: odMmValue,
      idMm: idMmValue,
      heightMm: heightMmValue,
      weightPerMeter: unitWeightKgPerMeterValue,
      calculatedWeight: lineWeight,
      totalProjectWeight: totalProjectWeight(projectQuantity),
      galvanizingMicron: _toDouble(galvanizingMicron.text),
      coatingType: coatingType.text.trim(),
      coatingSpec: coatingSpec.text.trim(),
      grade: grade.text.trim(),
      yieldStrength: yieldStrength.text.trim(),
      remarks: remarks.text.trim(),
      customFieldValues: {
        for (final field in customFields)
          field.id: customController(field.id).text.trim(),
      },
      materialMasterId: materialMasterId,
      materialType: materialCategory.text.trim(),
      formulaType: formulaType.text.trim(),
    );
  }

  void dispose() {
    for (final c in [
      itemDescription,
      sectionCode,
      materialCategory,
      materialName,
      qtyPerStructure,
      lengthMm,
      widthMm,
      thicknessMm,
      odMm,
      idMm,
      heightMm,
      unitWeightKgPerMeter,
      coatingType,
      coatingSpec,
      yieldStrength,
      galvanizingMicron,
      grade,
      formulaType,
      remarks,
    ]) {
      c.dispose();
    }
    for (final controller in customValues.values) {
      controller.dispose();
    }
  }

  static String _categoryFrom(MaterialMasterModel m) {
    if (m.materialType.trim().isNotEmpty) return m.materialType.trim();
    return m.materialShape.trim();
  }

  static double _toDouble(String value) => double.tryParse(value.trim()) ?? 0;
  static String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
