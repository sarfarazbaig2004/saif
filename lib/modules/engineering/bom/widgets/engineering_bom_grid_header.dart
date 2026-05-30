import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';

class EngineeringBomGridHeader extends StatelessWidget {
  final List<String> columns;
  final List<BomCustomField> customFields;

  const EngineeringBomGridHeader({
    super.key,
    required this.columns,
    required this.customFields,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w800, color: zMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 64, child: Text('Sl No', style: style)),
          for (final key in columns)
            SizedBox(
              width: BomColumnConfig.definitionFor(key, customFields).width,
              child: Text(
                BomColumnConfig.definitionFor(key, customFields).label,
                style: style,
              ),
            ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}
