import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_header.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_table_cells.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_models.dart';

class EngineeringFastenerBomTable extends StatelessWidget {
  final List<FastenerBomLineDraft> lines;
  final double projectQuantity;
  final VoidCallback onAddLine;
  final ValueChanged<int> onDelete;
  final VoidCallback onChanged;
  final bool readOnly;

  const EngineeringFastenerBomTable({
    super.key,
    required this.lines,
    required this.projectQuantity,
    required this.onAddLine,
    required this.onDelete,
    required this.onChanged,
    this.readOnly = false,
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Fastener BOM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: readOnly ? null : onAddLine,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Fastener'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1300,
              child: Column(
                children: [
                  const _FastenerHeader(),
                  const Divider(height: 1, color: zBorder),
                  for (var i = 0; i < lines.length; i++)
                    _FastenerRow(
                      line: lines[i],
                      lineNo: i + 1,
                      projectQuantity: projectQuantity,
                      canDelete: !readOnly && lines.length > 1,
                      onChanged: onChanged,
                      onDelete: () => onDelete(i),
                      readOnly: readOnly,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FastenerHeader extends StatelessWidget {
  const _FastenerHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w800, color: zMuted);
    const headers = [
      ('Sr No', 64.0),
      ('Location', 190.0),
      ('Description', 260.0),
      ('Bolt Description', 160.0),
      ('Bolt Length', 120.0),
      ('Material', 150.0),
      ('Qty Per Structure', 140.0),
      ('Qty For Project', 140.0),
      ('', 60.0),
    ];
    return Row(
      children: [
        for (final header in headers)
          SizedBox(
            width: header.$2,
            child: Text(header.$1, style: style),
          ),
      ],
    );
  }
}

class _FastenerRow extends StatelessWidget {
  final FastenerBomLineDraft line;
  final int lineNo;
  final double projectQuantity;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final bool readOnly;

  const _FastenerRow({
    required this.line,
    required this.lineNo,
    required this.projectQuantity,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          bomTableText('$lineNo', 64),
          _cell(line.location, 'Location', 190),
          _cell(line.description, 'Description', 260),
          _cell(line.boltDescription, 'Bolt', 160),
          _cell(line.boltLength, 'Length', 120, number: true),
          _cell(line.material, 'Material', 150),
          _cell(line.qtyPerStructure, 'Qty', 140, number: true),
          bomTableText(
            line.qtyForProject(projectQuantity).toStringAsFixed(0),
            140,
          ),
          SizedBox(
            width: 60,
            child: IconButton(
              tooltip: 'Delete fastener',
              onPressed: canDelete && !readOnly ? onDelete : null,
              icon: const Icon(Icons.delete_outline, color: zDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    TextEditingController controller,
    String label,
    double width, {
    bool number = false,
  }) {
    return bomFieldBox(
      width,
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: bomInputDecoration(label),
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
