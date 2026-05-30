import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_table.dart';

class EngineeringBomGridCard extends StatelessWidget {
  final List<BomLineDraft> lines;
  final List<String> visibleColumns;
  final List<BomCustomField> customFields;
  final String tenantId;
  final ScrollController scrollController;
  final VoidCallback onChanged;
  final VoidCallback onCustomizeColumns;
  final ValueChanged<int> onDelete;

  const EngineeringBomGridCard({
    super.key,
    required this.lines,
    required this.visibleColumns,
    required this.customFields,
    required this.tenantId,
    required this.scrollController,
    required this.onChanged,
    required this.onCustomizeColumns,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onCustomizeColumns,
              icon: const Icon(Icons.view_column_outlined, size: 18),
              label: const Text('Customize Fields'),
            ),
          ),
          const SizedBox(height: 10),
          EngineeringBomTable(
            lines: lines,
            visibleColumns: visibleColumns,
            customFields: customFields,
            tenantId: tenantId,
            scrollController: scrollController,
            onChanged: onChanged,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}
