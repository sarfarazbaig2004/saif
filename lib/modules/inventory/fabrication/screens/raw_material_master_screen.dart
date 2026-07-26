import 'dart:async';

import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/verticals/active_vertical_scope.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';

const _itemTypes = <String, String>{
  'raw_material': 'Raw Material',
  'consumable': 'Consumable',
  'tools_tackles': 'Tools & Tackles',
  'machinery_equipment': 'Machinery / Equipment',
  'spare_part': 'Spare Part',
  'safety_ppe': 'Safety / PPE',
  'packing_material': 'Packing Material',
  'office_admin': 'Office / Admin',
};
const _filters = <String, String>{
  'all': 'All',
  'raw_material': 'Raw Material',
  'consumable': 'Consumable',
  'tools_tackles': 'Tools',
  'machinery_equipment': 'Machinery',
  'spare_part': 'Spare Parts',
  'safety_ppe': 'Safety',
};

class RawMaterialMasterScreen extends StatefulWidget {
  final String tenantId;
  const RawMaterialMasterScreen({super.key, required this.tenantId});
  @override
  State<RawMaterialMasterScreen> createState() =>
      _RawMaterialMasterScreenState();
}

class _RawMaterialMasterScreenState extends State<RawMaterialMasterScreen> {
  final _search = TextEditingController();
  String _query = '', _selectedType = 'all';
  Timer? _searchDebounce;
  Stream<List<RawMaterialModel>>? _itemsStream;
  String _itemsStreamKey = '';

  String get _tenantId => context.tenant.selectedTenantId.trim().isNotEmpty
      ? context.tenant.selectedTenantId.trim()
      : widget.tenantId;
  FabricationInventoryRepository get _repository {
    final verticalState = ActiveVerticalScope.maybeOf(context);
    return FabricationInventoryRepository(
      tenantId: _tenantId,
      verticalId: verticalState?.activeVerticalId ?? '',
      verticalName: verticalState?.activeVerticalName ?? '',
      canManageAllVerticals: verticalState?.allowAllVerticals == true,
    );
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }
    _ensureItemsStream();
    return StreamBuilder<List<RawMaterialModel>>(
      stream: _itemsStream,
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <RawMaterialModel>[])
            .where(_matches)
            .toList();
        return Column(
          children: [
            _Header(
              search: _search,
              count: items.length,
              selectedType: _selectedType,
              onType: (v) => setState(() => _selectedType = v),
              onAdd: _openForm,
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData
                  ? const Center(child: CircularProgressIndicator(color: zBlue))
                  : items.isEmpty
                  ? _EmptyState(onAdd: _openForm)
                  : _ItemTable(
                      items: items,
                      onEdit: (i) => _openForm(item: i),
                      onDelete: _deleteItem,
                    ),
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      final nextQuery = _search.text.trim().toLowerCase();
      if (nextQuery == _query) return;
      setState(() => _query = nextQuery);
    });
  }

  void _ensureItemsStream() {
    final verticalState = ActiveVerticalScope.maybeOf(context);
    final streamKey = [
      _tenantId,
      verticalState?.activeVerticalId ?? '',
      verticalState?.allowAllVerticals == true,
    ].join('|');
    if (_itemsStream != null && _itemsStreamKey == streamKey) return;
    _itemsStreamKey = streamKey;
    _itemsStream = _repository.watchRawMaterials(activeOnly: true);
  }

  bool _matches(RawMaterialModel item) {
    if (_selectedType != 'all' && item.effectiveItemType != _selectedType) {
      return false;
    }
    if (_query.isEmpty) return true;
    return [
      item.effectiveItemCode,
      item.materialCode,
      item.effectiveItemName,
      item.descriptionThickness,
      item.verticalName,
      item.gradeIs,
      item.category,
      item.productFamily,
      item.effectiveItemType,
      _itemTypes[item.effectiveItemType] ?? '',
    ].any((v) => v.toLowerCase().contains(_query));
  }

  Future<void> _openForm({RawMaterialModel? item}) async {
    final verticalState = ActiveVerticalScope.maybeOf(context);
    final verticals = List<ActiveVerticalOption>.from(
      verticalState?.availableVerticals ?? const <ActiveVerticalOption>[],
    );
    if (item != null &&
        item.verticalId.trim().isNotEmpty &&
        !verticals.any((vertical) => vertical.id == item.verticalId)) {
      verticals.add(
        ActiveVerticalOption(
          id: item.verticalId,
          name: item.verticalName.trim().isEmpty
              ? 'Assigned vertical'
              : item.verticalName,
        ),
      );
    }
    if (verticals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configure at least one business vertical before saving inventory items.',
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _ItemFormDialog(
        repository: _repository,
        item: item,
        verticals: verticals,
        defaultVerticalId: verticalState?.activeVerticalId ?? '',
        canChangeVertical: verticalState?.allowAllVerticals == true,
      ),
    );
  }

  Future<void> _deleteItem(RawMaterialModel item) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Delete ${item.displayName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) await _repository.deleteRawMaterial(item.materialId);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.search,
    required this.count,
    required this.selectedType,
    required this.onType,
    required this.onAdd,
  });
  final TextEditingController search;
  final int count;
  final String selectedType;
  final ValueChanged<String> onType;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: zBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, color: zBlue),
            const SizedBox(
              width: 220,
              child: Text(
                'Item Master',
                style: TextStyle(
                  color: zText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: TextField(
                controller: search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search item code, name, grade, category or type',
                ),
              ),
            ),
            Chip(label: Text('$count items')),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('New Item'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filters.entries
              .map(
                (e) => ChoiceChip(
                  label: Text(e.value),
                  selected: selectedType == e.key,
                  onSelected: (_) => onType(e.key),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _ItemTable extends StatefulWidget {
  const _ItemTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });
  final List<RawMaterialModel> items;
  final ValueChanged<RawMaterialModel> onEdit;
  final ValueChanged<RawMaterialModel> onDelete;

  @override
  State<_ItemTable> createState() => _ItemTableState();
}

class _ItemTableState extends State<_ItemTable> {
  static const _tableWidth = 1518.0;
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const _TableScrollHint(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: SizedBox(
                    width: _tableWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        const _ItemTableHeader(),
                        const Divider(height: 1, color: zBorder),
                        Expanded(
                          child: Scrollbar(
                            controller: _verticalController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            interactive: true,
                            child: ListView.builder(
                              controller: _verticalController,
                              primary: false,
                              itemExtent: 56,
                              itemCount: widget.items.length,
                              itemBuilder: (context, index) => _ItemTableRow(
                                item: widget.items[index],
                                onEdit: widget.onEdit,
                                onDelete: widget.onDelete,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableScrollHint extends StatelessWidget {
  const _TableScrollHint();

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: const Color(0xFFF8FAFC),
    child: const Row(
      children: [
        Icon(Icons.mouse_outlined, size: 15, color: zMuted),
        SizedBox(width: 6),
        Text(
          'Mouse wheel: vertical  •  Shift + wheel or bottom bar: horizontal',
          style: TextStyle(
            color: zMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ItemTableHeader extends StatelessWidget {
  const _ItemTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    color: const Color(0xFFF8FAFC),
    child: const Row(
      children: [
        _ItemCell(text: 'Vertical', width: 150, header: true),
        _ItemCell(text: 'Item Type', width: 160, header: true),
        _ItemCell(text: 'Item Code', width: 130, header: true),
        _ItemCell(text: 'Item Name / Description', width: 280, header: true),
        _ItemCell(text: 'Grade / IS', width: 120, header: true),
        _ItemCell(text: 'UOM', width: 80, header: true),
        _ItemCell(text: 'Category', width: 140, header: true),
        _ItemCell(text: 'Product Family', width: 160, header: true),
        _ItemCell(text: 'Reorder Level', width: 120, header: true),
        SizedBox(width: 138),
      ],
    ),
  );
}

class _ItemTableRow extends StatelessWidget {
  const _ItemTableRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final RawMaterialModel item;
  final ValueChanged<RawMaterialModel> onEdit;
  final ValueChanged<RawMaterialModel> onDelete;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3))),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _ItemCell(
            text: item.verticalName.isEmpty ? '-' : item.verticalName,
            width: 150,
          ),
          _ItemCell(
            text: _itemTypes[item.effectiveItemType] ?? item.effectiveItemType,
            width: 160,
          ),
          _ItemCell(text: item.effectiveItemCode, width: 130),
          _ItemCell(text: item.effectiveItemName, width: 280),
          _ItemCell(text: item.gradeIs, width: 120),
          _ItemCell(text: item.uom, width: 80),
          _ItemCell(text: item.category, width: 140),
          _ItemCell(text: item.productFamily, width: 160),
          _ItemCell(text: _number(item.reorderLevel), width: 120),
          SizedBox(
            width: 138,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onEdit(item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onDelete(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  static String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({
    required this.text,
    required this.width,
    this.header = false,
  });

  final String text;
  final double width;
  final bool header;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: text,
        waitDuration: const Duration(milliseconds: 500),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: header ? zText : const Color(0xFF334155),
            fontSize: header ? 12 : 13,
            fontWeight: header ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({
    required this.repository,
    required this.verticals,
    required this.defaultVerticalId,
    required this.canChangeVertical,
    this.item,
  });
  final FabricationInventoryRepository repository;
  final List<ActiveVerticalOption> verticals;
  final String defaultVerticalId;
  final bool canChangeVertical;
  final RawMaterialModel? item;
  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = {};
  bool _saving = false;
  late String _type;
  String? _selectedVerticalId;
  TextEditingController c(String key, [String fallback = '']) => _c.putIfAbsent(
    key,
    () => TextEditingController(
      text: widget.item?.itemDetails[key]?.toString() ?? fallback,
    ),
  );
  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _type = i?.effectiveItemType ?? 'raw_material';
    final itemVerticalId = i?.verticalId.trim() ?? '';
    final defaultVerticalId = widget.defaultVerticalId.trim();
    _selectedVerticalId = itemVerticalId.isNotEmpty
        ? itemVerticalId
        : defaultVerticalId.isNotEmpty
        ? defaultVerticalId
        : null;
    _set('itemCode', i?.effectiveItemCode ?? '');
    _set('itemName', i?.effectiveItemName ?? '');
    _set('description', i?.descriptionThickness ?? '');
    _set('grade', i?.gradeIs ?? '');
    _set('length', _n(i?.length ?? 0));
    _set('unitWeight', _n(i?.unitWeight ?? 0));
    _set('uom', i?.uom ?? 'Nos');
    _set('category', i?.category ?? '');
    _set('productFamily', i?.productFamily ?? '');
    _set('brandOrMake', i?.brandOrMake ?? '');
    _set('hsnCode', i?.hsnCode ?? '');
    _set('gstPercent', _n(i?.gstPercent ?? 0));
    _set('minimumStock', _n(i?.minimumStock ?? 0));
    _set('reorderLevel', _n(i?.reorderLevel ?? 0));
    _set('warehouse', i?.warehouse ?? '');
    _set('status', i?.status ?? 'active');
    _set('remarks', i?.remarks ?? '');
  }

  void _set(String key, String value) {
    _c[key] = TextEditingController(text: value);
  }

  @override
  void dispose() {
    for (final x in _c.values) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'New Item' : 'Edit Item'),
    content: SizedBox(
      width: 780,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 488,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedVerticalId,
                  decoration: InputDecoration(
                    labelText: 'Business Vertical',
                    prefixIcon: const Icon(Icons.account_tree_outlined),
                    helperText: widget.canChangeVertical
                        ? 'Full access: you can assign or move this item.'
                        : 'Locked to your active vertical.',
                  ),
                  items: widget.verticals
                      .map(
                        (vertical) => DropdownMenuItem(
                          value: vertical.id,
                          child: Text(vertical.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.canChangeVertical
                      ? (value) => setState(() => _selectedVerticalId = value)
                      : null,
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Select a vertical' : null,
                ),
              ),
              SizedBox(
                width: 238,
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Item Type'),
                  items: _itemTypes.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              ..._commonFields(),
              ..._typeFields(),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.save_outlined),
        label: Text(_saving ? 'Saving' : 'Save'),
      ),
    ],
  );
  List<Widget> _commonFields() => [
    _field('itemCode', 'Item Code', required: true),
    _field('itemName', 'Item Name / Description', width: 488, required: true),
    _field('category', 'Category'),
    _field('productFamily', 'Product Family'),
    _field('uom', 'UOM', required: true),
    _field('brandOrMake', 'Brand / Make'),
    _field('hsnCode', 'HSN Code'),
    _field('gstPercent', 'GST %', number: true),
    _field('minimumStock', 'Minimum Stock', number: true),
    _field('reorderLevel', 'Reorder Level', number: true),
    _field('warehouse', 'Warehouse'),
    _field('status', 'Status'),
  ];
  List<Widget> _typeFields() {
    if (_type == 'raw_material') {
      return [
        _field(
          'description',
          'Description / Thickness',
          width: 488,
          required: true,
        ),
        _field('grade', 'Grade / IS'),
        _field('length', 'Length', number: true),
        _field('unitWeight', 'Unit Weight', number: true),
        _field('size', 'Size'),
        _field('shape', 'Shape'),
      ];
    }
    final labels = switch (_type) {
      'consumable' => [
        'brand',
        'size',
        'packSize',
        'shelfLife',
        'batchTracking',
      ],
      'tools_tackles' => [
        'toolCode',
        'serialNo',
        'returnable',
        'assignedTo',
        'condition',
        'location',
      ],
      'machinery_equipment' => [
        'assetCode',
        'serialNumber',
        'make',
        'model',
        'purchaseDate',
        'warrantyExpiry',
        'location',
        'assignedTo',
        'maintenanceDueDate',
        'equipmentStatus',
      ],
      'spare_part' => [
        'partNumber',
        'usedForMachine',
        'compatibleModel',
        'criticalSpare',
      ],
      'safety_ppe' => ['size', 'issueToEmployee', 'replacementCycle'],
      _ => <String>[],
    };
    return [
      ...labels.map((key) => _field(key, _label(key))),
      _field('remarks', 'Remarks', width: 488),
    ];
  }

  Widget _field(
    String key,
    String label, {
    double width = 238,
    bool required = false,
    bool number = false,
  }) => SizedBox(
    width: width,
    child: TextFormField(
      controller: c(key),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final t = (v ?? '').trim();
        if (required && t.isEmpty) return 'Required';
        if (number && t.isNotEmpty && double.tryParse(t) == null) {
          return 'Enter valid number';
        }
        return null;
      },
    ),
  );
  String _label(String v) => v
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
      .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final details = {for (final e in _c.entries) e.key: e.value.text.trim()};
      final selectedVerticalId = (_selectedVerticalId ?? '').trim();
      final selectedVertical = widget.verticals
          .where((vertical) => vertical.id == selectedVerticalId)
          .toList(growable: false);
      final selectedVerticalName = selectedVertical.isEmpty
          ? ''
          : selectedVertical.first.name;
      await widget.repository.saveRawMaterial(
        RawMaterialModel(
          materialId:
              widget.item?.materialId ?? widget.repository.newMaterialId(),
          verticalId: selectedVerticalId,
          verticalName: selectedVerticalName,
          materialCode: c('itemCode').text.trim(),
          descriptionThickness: c('description').text.trim().isEmpty
              ? c('itemName').text.trim()
              : c('description').text.trim(),
          gradeIs: c('grade').text.trim(),
          length: _d('length'),
          unitWeight: _d('unitWeight'),
          uom: c('uom').text.trim().isEmpty ? 'Nos' : c('uom').text.trim(),
          category: c('category').text.trim(),
          productFamily: c('productFamily').text.trim(),
          reorderLevel: _d('reorderLevel'),
          remarks: c('remarks').text.trim(),
          isActive: c('status').text.trim().toLowerCase() != 'inactive',
          itemType: _type,
          itemCode: c('itemCode').text.trim(),
          itemName: c('itemName').text.trim(),
          brandOrMake: c('brandOrMake').text.trim(),
          hsnCode: c('hsnCode').text.trim(),
          gstPercent: _d('gstPercent'),
          minimumStock: _d('minimumStock'),
          warehouse: c('warehouse').text.trim(),
          status: c('status').text.trim().isEmpty
              ? 'active'
              : c('status').text.trim(),
          itemDetails: details,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item saved')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _d(String key) => double.tryParse(c(key).text.trim()) ?? 0;
  String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 42, color: zMuted),
        const SizedBox(height: 10),
        const Text(
          'No items yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('New Item'),
        ),
      ],
    ),
  );
}
