import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_header.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_material_lookup.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_table_cells.dart';
import 'package:QUIK/modules/inventory/material_master/models/material_master_model.dart';

class EngineeringBomTable extends StatelessWidget {
  final List<BomLineDraft> lines;
  final List<String> visibleColumns;
  final List<BomCustomField> customFields;
  final double projectQuantity;
  final String tenantId;
  final ScrollController scrollController;
  final VoidCallback onChanged;
  final ValueChanged<int> onDelete;

  const EngineeringBomTable({
    super.key,
    required this.lines,
    required this.visibleColumns,
    required this.customFields,
    required this.projectQuantity,
    required this.tenantId,
    required this.scrollController,
    required this.onChanged,
    required this.onDelete,
  });

  List<String> get _columns => BomColumnConfig.sanitize(visibleColumns);

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    final width = BomColumnConfig.tableWidth(columns, customFields);
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BomGridHeader(columns: columns, customFields: customFields),
              const Divider(height: 1, color: zBorder),
              for (var i = 0; i < lines.length; i++)
                _BomLineRow(
                  line: lines[i],
                  columns: columns,
                  customFields: customFields,
                  projectQuantity: projectQuantity,
                  lineNo: i + 1,
                  tenantId: tenantId,
                  canDelete: lines.length > 1,
                  onChanged: onChanged,
                  onDelete: () => onDelete(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BomGridHeader extends StatelessWidget {
  final List<String> columns;
  final List<BomCustomField> customFields;

  const _BomGridHeader({required this.columns, required this.customFields});

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

class _BomLineRow extends StatelessWidget {
  final BomLineDraft line;
  final List<String> columns;
  final List<BomCustomField> customFields;
  final double projectQuantity;
  final int lineNo;
  final String tenantId;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _BomLineRow({
    required this.line,
    required this.columns,
    required this.customFields,
    required this.projectQuantity,
    required this.lineNo,
    required this.tenantId,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bomTableText('$lineNo', 64),
          for (final key in columns) _column(context, key),
          SizedBox(
            width: 60,
            child: IconButton(
              tooltip: 'Delete line',
              onPressed: canDelete ? onDelete : null,
              icon: const Icon(Icons.delete_outline, color: zDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(BuildContext context, String key) {
    final width = BomColumnConfig.definitionFor(key, customFields).width;
    if (BomColumnConfig.isCustomKey(key)) {
      return _customCell(key, width);
    }
    switch (key) {
      case BomColumnKey.description:
        return _cell(
          line.itemDescription,
          'Description',
          width,
          required: true,
        );
      case BomColumnKey.sectionCode:
        return _materialCodeCell(context, width);
      case BomColumnKey.category:
        return _categoryCell(width);
      case BomColumnKey.materialName:
        return _cell(line.materialName, 'Material', width);
      case BomColumnKey.qtyPerStructure:
        return _cell(line.qtyPerStructure, 'Qty', width, number: true);
      case BomColumnKey.lengthMm:
        return _cell(line.lengthMm, 'Length', width, number: true);
      case BomColumnKey.widthMm:
        return _cell(line.widthMm, 'Width', width, number: true);
      case BomColumnKey.thicknessMm:
        return _cell(line.thicknessMm, 'Thick', width, number: true);
      case BomColumnKey.odMm:
        return _cell(line.odMm, 'OD/Dia', width, number: true);
      case BomColumnKey.idMm:
        return _cell(line.idMm, 'ID', width, number: true);
      case BomColumnKey.heightMm:
        return _cell(line.heightMm, 'Height', width, number: true);
      case BomColumnKey.kgPerM:
        return _cell(line.unitWeightKgPerMeter, 'Kg/m', width, number: true);
      case BomColumnKey.grade:
        return _cell(line.grade, 'Grade', width);
      case BomColumnKey.coating:
        return _cell(line.coatingType, 'Material', width);
      case BomColumnKey.coatingSpec:
        return _cell(line.coatingSpec, 'Coating Spec', width);
      case BomColumnKey.yieldStrength:
        return _cell(line.yieldStrength, 'Yield Strength', width);
      case BomColumnKey.micron:
        return _cell(line.galvanizingMicron, 'Micron', width, number: true);
      case BomColumnKey.remarks:
        return _cell(line.remarks, 'Remarks', width);
      case BomColumnKey.projectQty:
        return bomTableText(
          line.totalProjectQuantity(projectQuantity).toStringAsFixed(2),
          width,
        );
      case BomColumnKey.projectWeight:
        return bomTableText(
          line.totalProjectWeight(projectQuantity).toStringAsFixed(2),
          width,
          bold: true,
        );
      case BomColumnKey.formula:
        return _cell(line.formulaType, 'Formula', width);
      case BomColumnKey.steelWeight:
        return bomTableText(line.steelWeight.toStringAsFixed(2), width);
      case BomColumnKey.galvanisingWeight:
        return bomTableText(line.galvanisingWeight.toStringAsFixed(2), width);
      case BomColumnKey.weight:
      default:
        return bomTableText(
          line.lineWeight.toStringAsFixed(2),
          width,
          bold: true,
        );
    }
  }

  Widget _customCell(String key, double width) =>
      _customCellFor(BomColumnConfig.customId(key), width);

  Widget _customCellFor(String id, double width) {
    final field = customFields.firstWhere((field) => field.id == id);
    return _cell(
      line.customController(id),
      field.name,
      width,
      number: field.type == 'Number',
    );
  }

  Widget _materialCodeCell(BuildContext context, double width) {
    return bomFieldBox(
      width,
      TextFormField(
        controller: line.sectionCode,
        decoration: bomInputDecoration('Code').copyWith(
          suffixIcon: IconButton(
            tooltip: 'Select material',
            icon: const Icon(Icons.search, size: 18),
            onPressed: () => EngineeringBomMaterialLookup.pick(
              context: context,
              tenantId: tenantId,
              line: line,
              onChanged: onChanged,
            ),
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }

  Widget _categoryCell(double width) {
    return bomFieldBox(
      width,
      DropdownButtonFormField<String>(
        initialValue:
            MaterialMasterModel.materialTypes.contains(
              line.materialCategory.text,
            )
            ? line.materialCategory.text
            : null,
        decoration: bomInputDecoration('Category'),
        items: MaterialMasterModel.materialTypes
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (value) {
          line.materialCategory.text = value ?? '';
          onChanged();
        },
      ),
    );
  }

  Widget _cell(
    TextEditingController controller,
    String label,
    double width, {
    bool number = false,
    bool required = false,
  }) {
    return bomFieldBox(
      width,
      TextFormField(
        controller: controller,
        decoration: bomInputDecoration(label),
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        onChanged: (_) => onChanged(),
        validator: required
            ? (value) => (value ?? '').trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}
