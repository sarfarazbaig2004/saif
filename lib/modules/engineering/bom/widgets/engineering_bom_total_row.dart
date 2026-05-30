import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_table_cells.dart';

class EngineeringBomTotalRow extends StatelessWidget {
  final List<BomLineDraft> lines;
  final List<String> columns;
  final List<BomCustomField> customFields;
  final double projectQuantity;

  const EngineeringBomTotalRow({
    super.key,
    required this.lines,
    required this.columns,
    required this.customFields,
    required this.projectQuantity,
  });

  double get weightPerStructure {
    return lines.fold(0, (total, line) => total + line.lineWeight);
  }

  @override
  Widget build(BuildContext context) {
    final projectWeight = weightPerStructure * projectQuantity;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 64),
          for (final key in columns) _totalCell(key, projectWeight),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _totalCell(String key, double projectWeight) {
    final width = BomColumnConfig.definitionFor(key, customFields).width;
    final value = switch (key) {
      BomColumnKey.description => 'TOTAL WEIGHT (KG)',
      BomColumnKey.weight => weightPerStructure.toStringAsFixed(2),
      BomColumnKey.projectWeight => projectWeight.toStringAsFixed(2),
      _ => '',
    };
    return bomTableText(value, width, bold: value.isNotEmpty);
  }
}
