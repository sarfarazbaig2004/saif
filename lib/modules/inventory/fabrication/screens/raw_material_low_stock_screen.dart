import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/verticals/active_vertical_scope.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_stock_summary_model.dart';
import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';

class RawMaterialLowStockScreen extends StatefulWidget {
  final String tenantId;

  const RawMaterialLowStockScreen({super.key, required this.tenantId});

  @override
  State<RawMaterialLowStockScreen> createState() =>
      _RawMaterialLowStockScreenState();
}

class _RawMaterialLowStockScreenState extends State<RawMaterialLowStockScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _plantFilter = 'all';
  String _warehouseFilter = 'all';

  String get _tenantId {
    final selectedTenantId = context.tenant.selectedTenantId.trim();
    return selectedTenantId.isNotEmpty ? selectedTenantId : widget.tenantId;
  }

  FabricationInventoryRepository get _repository {
    final verticalState = ActiveVerticalScope.maybeOf(context);
    return FabricationInventoryRepository(
      tenantId: _tenantId,
      verticalId: verticalState?.activeVerticalId ?? '',
      verticalName: verticalState?.activeVerticalName ?? '',
    );
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tenantId.trim().isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    return StreamBuilder<List<RawMaterialModel>>(
      stream: _repository.watchRawMaterials(activeOnly: true),
      builder: (context, materialSnapshot) {
        final materials = materialSnapshot.data ?? const <RawMaterialModel>[];
        final reorderByMaterial = {
          for (final material in materials) material.materialId: material,
        };

        return StreamBuilder<List<RawMaterialStockSummaryModel>>(
          stream: _repository.watchStockSummary(),
          builder: (context, stockSnapshot) {
            final alertRows =
                (stockSnapshot.data ?? const <RawMaterialStockSummaryModel>[])
                    .where((row) {
                      final material = reorderByMaterial[row.materialId];
                      final reorderLevel =
                          material?.reorderLevel ?? row.reorderLevel;
                      return reorderLevel > 0 &&
                          row.closingStockKg <= reorderLevel;
                    })
                    .toList(growable: false);
            final rows = alertRows.where(_matches).toList(growable: false);
            final plants = _filterValues(alertRows.map((row) => row.plantName));
            final warehouses = _filterValues(
              alertRows.map((row) => row.warehouseName),
            );

            return Column(
              children: [
                _Header(
                  search: _search,
                  count: rows.length,
                  plants: plants,
                  warehouses: warehouses,
                  plantFilter: _plantFilter,
                  warehouseFilter: _warehouseFilter,
                  onPlantChanged: (value) {
                    setState(() => _plantFilter = value ?? 'all');
                  },
                  onWarehouseChanged: (value) {
                    setState(() => _warehouseFilter = value ?? 'all');
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      stockSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !stockSnapshot.hasData
                      ? const Center(
                          child: CircularProgressIndicator(color: zBlue),
                        )
                      : rows.isEmpty
                      ? const Center(child: Text('No low stock alerts.'))
                      : _LowStockTable(
                          rows: rows,
                          materials: reorderByMaterial,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _matches(RawMaterialStockSummaryModel row) {
    if (_plantFilter != 'all' && row.plantName != _plantFilter) return false;
    if (_warehouseFilter != 'all' && row.warehouseName != _warehouseFilter) {
      return false;
    }
    if (_query.isEmpty) return true;
    return [
      row.materialCode,
      row.materialDescription,
      row.verticalName,
      row.grade,
      row.rawMaterialCategory,
      row.plantName,
      row.warehouseName,
    ].any((value) => value.toLowerCase().contains(_query));
  }

  List<String> _filterValues(Iterable<String> values) {
    final result = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    result.sort();
    return result;
  }
}

class _Header extends StatelessWidget {
  final TextEditingController search;
  final int count;
  final List<String> plants;
  final List<String> warehouses;
  final String plantFilter;
  final String warehouseFilter;
  final ValueChanged<String?> onPlantChanged;
  final ValueChanged<String?> onWarehouseChanged;

  const _Header({
    required this.search,
    required this.count,
    required this.plants,
    required this.warehouses,
    required this.plantFilter,
    required this.warehouseFilter,
    required this.onPlantChanged,
    required this.onWarehouseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.warning_amber_outlined, color: Colors.orange),
          const Text(
            'Low Stock Alerts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          SizedBox(
            width: 360,
            child: TextField(
              controller: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search material, grade, plant, warehouse',
              ),
            ),
          ),
          Chip(label: Text('$count alerts')),
          _FilterDropdown(
            label: 'Plant',
            value: plantFilter,
            values: plants,
            onChanged: onPlantChanged,
          ),
          _FilterDropdown(
            label: 'Warehouse',
            value: warehouseFilter,
            values: warehouses,
            onChanged: onWarehouseChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = value == 'all' || values.contains(value)
        ? value
        : 'all';
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: effectiveValue,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('All')),
          ...values.map(
            (value) => DropdownMenuItem(value: value, child: Text(value)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _LowStockTable extends StatelessWidget {
  final List<RawMaterialStockSummaryModel> rows;
  final Map<String, RawMaterialModel> materials;

  const _LowStockTable({required this.rows, required this.materials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Vertical')),
            DataColumn(label: Text('Material')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Plant')),
            DataColumn(label: Text('Warehouse')),
            DataColumn(label: Text('Closing Kg')),
            DataColumn(label: Text('Reorder Level')),
          ],
          rows: rows
              .map((row) {
                final material = materials[row.materialId];
                final reorderLevel = material?.reorderLevel ?? row.reorderLevel;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        row.verticalName.isEmpty
                            ? 'Not Assigned'
                            : row.verticalName,
                      ),
                    ),
                    DataCell(Text(row.materialDescription)),
                    DataCell(Text(row.grade)),
                    DataCell(Text(row.plantName)),
                    DataCell(Text(row.warehouseName)),
                    DataCell(Text(row.closingStockKg.toStringAsFixed(2))),
                    DataCell(Text(reorderLevel.toStringAsFixed(2))),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}
