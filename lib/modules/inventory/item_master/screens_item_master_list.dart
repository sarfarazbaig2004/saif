import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/verticals/active_vertical_scope.dart';
import 'package:QUIK/modules/inventory/item_master/screens_add_item_master.dart';

class ScreenItemMasterList extends StatefulWidget {
  const ScreenItemMasterList({
    super.key,
    required this.tenantId,
  });

  final String tenantId;

  @override
  State<ScreenItemMasterList> createState() => _ScreenItemMasterListState();
}

class _ScreenItemMasterListState extends State<ScreenItemMasterList> {
  late final ItemMasterRepository _repository = ItemMasterRepository(
    tenantId: widget.tenantId,
  );

  final _searchController = TextEditingController();

  String _natureFilter = 'All';
  String _statusFilter = 'Active';
  String _categoryFilter = 'All';
  String _uomFilter = 'All';
  String _scopeFilter = 'All';
  String _controlFilter = 'All';
  bool _inventoryOnly = false;
  bool _technicalOnly = false;
  bool _filtersVisible = false;
  bool _importing = false;
  bool _loadingLibrary = false;
  ItemMasterModel? _selectedItem;
  int _pageIndex = 0;
  static const int _pageSize = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verticalState = ActiveVerticalScope.maybeOf(context);
    final activeVerticalId = verticalState?.activeVerticalId;
    final activeVerticalName = verticalState?.activeVerticalName;

    return StreamBuilder<List<ItemMasterModel>>(
      stream: _repository.watchItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'ITEM_MASTER_LIST_ERROR tenantId=${widget.tenantId} '
                'path=${_repository.collectionPath} error=${snapshot.error}',
          );
          return _ErrorState(
            message: 'Unable to load Item Master',
            details: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = snapshot.data ?? const <ItemMasterModel>[];
        final contextualItems = allItems
            .where((item) => item.isAvailableInVertical(activeVerticalId))
            .toList(growable: false);
        final categories = contextualItems
            .map((item) => item.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final uoms = contextualItems
            .map((item) => item.unit.trim().toUpperCase())
            .where((uom) => uom.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final filteredItems = _applyFilters(contextualItems);
        final pageCount = filteredItems.isEmpty
            ? 1
            : (filteredItems.length / _pageSize).ceil();
        final safePageIndex = _pageIndex.clamp(0, pageCount - 1).toInt();
        final start = safePageIndex * _pageSize;
        final end = (start + _pageSize).clamp(0, filteredItems.length).toInt();
        final pageItems = filteredItems.sublist(start, end);
        final selected = _selectedItem == null
            ? null
            : allItems.cast<ItemMasterModel?>().firstWhere(
              (item) => item?.id == _selectedItem!.id,
          orElse: () => null,
        );

        if (safePageIndex != _pageIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _pageIndex = safePageIndex);
          });
        }

        return Column(
          children: [
            _buildCommandBar(),
            if (_filtersVisible) ...[
              const SizedBox(height: 8),
              _buildInlineFilters(categories: categories, uoms: uoms),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        _buildListWorkspace(
                          allItems: contextualItems,
                          filteredItems: filteredItems,
                          pageItems: pageItems,
                          pageIndex: safePageIndex,
                          pageCount: pageCount,
                          activeVerticalId: activeVerticalId,
                          activeVerticalName: activeVerticalName,
                        ),
                        Positioned(
                          right: 18,
                          bottom: 18,
                          child: FloatingActionButton.extended(
                            heroTag: 'item_master_add_fab',
                            onPressed: () => _openAddItem(
                              activeVerticalId: activeVerticalId,
                              activeVerticalName: activeVerticalName,
                            ),
                            icon: const Icon(Icons.add, size: 19),
                            label: const Text('Add Item'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 320,
                      child: _buildDetailsPanel(
                        selected,
                        activeVerticalId: activeVerticalId,
                        activeVerticalName: activeVerticalName,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommandBar() {
    final filterCount = _activeFilterCount;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search by item, code or category',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: zMuted,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _resetPage();
                  },
                  icon: const Icon(Icons.close, size: 16),
                ),
                filled: true,
                fillColor: zSurfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: zBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.2,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (_) => _resetPage(),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: filterCount > 0,
            label: Text('$filterCount'),
            child: IconButton.filledTonal(
              tooltip: _filtersVisible ? 'Hide filters' : 'Show filters',
              onPressed: () {
                setState(() => _filtersVisible = !_filtersVisible);
              },
              icon: Icon(
                _filtersVisible ? Icons.filter_alt_off_outlined : Icons.tune,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 2),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: _handleHeaderAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                enabled: !_importing,
                child: ListTile(
                  dense: true,
                  leading: _importing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.upload_file_outlined),
                  title: Text(_importing ? 'Importing...' : 'Import CSV'),
                ),
              ),
              const PopupMenuItem(
                value: 'template',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.description_outlined),
                  title: Text('CSV Template'),
                ),
              ),
              PopupMenuItem(
                value: 'library',
                enabled: !_loadingLibrary,
                child: ListTile(
                  dense: true,
                  leading: _loadingLibrary
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.playlist_add_outlined),
                  title: Text(
                    _loadingLibrary
                        ? 'Loading Library...'
                        : 'Engineering Library',
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'cleanup',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.cleaning_services_outlined),
                  title: Text('Duplicate Maintenance'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineFilters({
    required List<String> categories,
    required List<String> uoms,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _compactDropdown(
                width: 190,
                value: _natureFilter,
                hint: 'Nature',
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All natures')),
                  ...ItemMasterModel.itemNatures.map(
                        (nature) => DropdownMenuItem(
                      value: nature,
                      child: Text(nature, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _natureFilter = value;
                    _pageIndex = 0;
                  });
                },
              ),
              _compactDropdown(
                width: 140,
                value: _statusFilter,
                hint: 'Status',
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All statuses')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _statusFilter = value;
                    _pageIndex = 0;
                  });
                },
              ),
              _compactDropdown(
                width: 210,
                value: categories.contains(_categoryFilter) ? _categoryFilter : 'All',
                hint: 'Category',
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All categories')),
                  ...categories.map(
                        (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _categoryFilter = value;
                    _pageIndex = 0;
                  });
                },
              ),
              _compactDropdown(
                width: 120,
                value: uoms.contains(_uomFilter) ? _uomFilter : 'All',
                hint: 'UOM',
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All UOM')),
                  ...uoms.map(
                        (uom) => DropdownMenuItem(value: uom, child: Text(uom)),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _uomFilter = value;
                    _pageIndex = 0;
                  });
                },
              ),
              _compactDropdown(
                width: 175,
                value: _scopeFilter,
                hint: 'Scope',
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All scopes')),
                  DropdownMenuItem(value: 'Global', child: Text('All verticals')),
                  DropdownMenuItem(value: 'Restricted', child: Text('Selected verticals')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _scopeFilter = value;
                    _pageIndex = 0;
                  });
                },
              ),
              _compactDropdown(
                width: 185,
                value: _controlFilter,
                hint: 'Controls',
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All controls')),
                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'QC', child: Text('Quality inspection')),
                  DropdownMenuItem(value: 'Batch', child: Text('Batch tracked')),
                  DropdownMenuItem(value: 'Serial', child: Text('Serial tracked')),
                  DropdownMenuItem(value: 'Expiry', child: Text('Expiry tracked')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _controlFilter = value;
                    _pageIndex = 0;
                  });
                },
              ),
              FilterChip(
                label: const Text('Inventory'),
                selected: _inventoryOnly,
                onSelected: (value) {
                  setState(() {
                    _inventoryOnly = value;
                    _pageIndex = 0;
                  });
                },
              ),
              FilterChip(
                label: const Text('Technical'),
                selected: _technicalOnly,
                onSelected: (value) {
                  setState(() {
                    _technicalOnly = value;
                    _pageIndex = 0;
                  });
                },
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.restart_alt, size: 17),
                label: const Text('Reset'),
              ),
            ],
          );
        },
      ),
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_natureFilter != 'All') count++;
    if (_statusFilter != 'Active') count++;
    if (_categoryFilter != 'All') count++;
    if (_uomFilter != 'All') count++;
    if (_scopeFilter != 'All') count++;
    if (_controlFilter != 'All') count++;
    if (_inventoryOnly) count++;
    if (_technicalOnly) count++;
    return count;
  }

  Widget _compactDropdown({
    required double width,
    required String value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      height: 42,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: zText,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: zSurfaceSoft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: zBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: zBorder),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListWorkspace({
    required List<ItemMasterModel> allItems,
    required List<ItemMasterModel> filteredItems,
    required List<ItemMasterModel> pageItems,
    required int pageIndex,
    required int pageCount,
    required String? activeVerticalId,
    required String? activeVerticalName,
  }) {
    if (allItems.isEmpty) {
      return _EmptyState(
        title: 'No items in this scope',
        message:
        'Create the first governed item record for procurement, inward and inventory.',
        actionLabel: 'Create Item',
        onAction: () => _openAddItem(
          activeVerticalId: activeVerticalId,
          activeVerticalName: activeVerticalName,
        ),
      );
    }

    if (filteredItems.isEmpty) {
      return _EmptyState(
        title: 'No matching items',
        message: 'Change the search or filters to find other records.',
        actionLabel: 'Reset Filters',
        onAction: _clearFilters,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTableToolbar(
            totalItems: filteredItems.length,
            pageIndex: pageIndex,
            pageCount: pageCount,
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: zSurfaceSoft,
              border: Border(
                top: BorderSide(color: zBorder),
                bottom: BorderSide(color: zBorder),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => _buildTableHeader(
                constraints.maxWidth,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: pageItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = pageItems[index];
                    return _ItemRow(
                      item: item,
                      width: constraints.maxWidth,
                      selected: _selectedItem?.id == item.id,
                      onTap: () => setState(() => _selectedItem = item),
                      onEdit: () => _openEditItem(
                        item,
                        activeVerticalId: activeVerticalId,
                        activeVerticalName: activeVerticalName,
                      ),
                      onDelete: () => _deleteItem(item),
                      onActivate: item.isActive ? null : () => _activateItem(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(double width) {
    final showCategory = width >= 760;
    final showScope = width >= 980;
    final showControls = width >= 1120;

    return Row(
      children: [
        const Expanded(flex: 5, child: _HeaderCell('Item')),
        const Expanded(flex: 2, child: _HeaderCell('Nature')),
        if (showCategory)
          const Expanded(flex: 2, child: _HeaderCell('Category')),
        const Expanded(flex: 1, child: _HeaderCell('UOM')),
        if (showScope)
          const Expanded(flex: 2, child: _HeaderCell('Scope')),
        if (showControls)
          const Expanded(flex: 2, child: _HeaderCell('Controls')),
        const SizedBox(width: 92, child: _HeaderCell('Status')),
        const SizedBox(width: 46),
      ],
    );
  }

  Widget _buildTableToolbar({
    required int totalItems,
    required int pageIndex,
    required int pageCount,
  }) {
    final from = totalItems == 0 ? 0 : pageIndex * _pageSize + 1;
    final to = ((pageIndex + 1) * _pageSize).clamp(0, totalItems).toInt();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Text(
            '$totalItems item${totalItems == 1 ? '' : 's'}',
            style: textTheme.labelLarge?.copyWith(
              color: zText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            '$from–$to',
            style: textTheme.labelMedium?.copyWith(
              color: zMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Previous page',
              onPressed: pageIndex > 0
                  ? () => setState(() => _pageIndex--)
                  : null,
              icon: const Icon(Icons.chevron_left, size: 20),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 42),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: zSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${pageIndex + 1}/$pageCount',
              style: textTheme.labelMedium?.copyWith(
                color: zText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Next page',
              onPressed: pageIndex + 1 < pageCount
                  ? () => setState(() => _pageIndex++)
                  : null,
              icon: const Icon(Icons.chevron_right, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(
      ItemMasterModel item, {
        required String? activeVerticalId,
        required String? activeVerticalName,
      }) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Item Profile',
                    style: const TextStyle(
                      color: zText,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close details',
                  onPressed: () => setState(() => _selectedItem = null),
                  icon: const Icon(Icons.close, size: 19),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _natureIcon(item.itemNature),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.itemName,
                    style: const TextStyle(
                      color: zText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    item.itemCode,
                    style: const TextStyle(
                      color: zMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _InfoChip(label: item.itemNature),
                      _StatusChip(isActive: item.isActive),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailsSection(
                    title: 'Classification',
                    rows: [
                      _DetailRow('Category', item.category),
                      _DetailRow('Subcategory', item.subCategory),
                      _DetailRow('HSN / SAC', item.hsnCode),
                      _DetailRow(
                        'Tax',
                        item.taxRate > 0 ? '${_formatNumber(item.taxRate)}%' : '',
                      ),
                    ],
                  ),
                  _DetailsSection(
                    title: 'Business Scope',
                    rows: [
                      _DetailRow('Verticals', item.scopeLabel),
                      _DetailRow('Measurement Profile', item.measurementProfileKey),
                      _DetailRow('Base UOM', item.unit),
                      _DetailRow('Purchase UOM', item.purchaseUnit),
                      _DetailRow('Issue UOM', item.issueUnit),
                      _DetailRow('Secondary UOM', item.secondaryUnit),
                      _DetailRow('Conversion Method', item.conversionMethod),
                      _DetailRow(
                        'Purchase Conversion',
                        _formatNumber(item.conversionFactor),
                      ),
                    ],
                  ),
                  _DetailsSection(
                    title: 'Operational Controls',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ControlTag(
                          label: 'Inventory',
                          enabled: item.inventoryTracked,
                        ),
                        _ControlTag(
                          label: 'Batch',
                          enabled: item.batchTracked,
                        ),
                        _ControlTag(
                          label: 'Serial',
                          enabled: item.serialTracked,
                        ),
                        _ControlTag(
                          label: 'Expiry',
                          enabled: item.expiryTracked,
                        ),
                        _ControlTag(
                          label: 'QC',
                          enabled: item.qualityInspectionRequired,
                        ),
                      ],
                    ),
                  ),
                  if (item.inventoryTracked)
                    _DetailsSection(
                      title: 'Stock Policy',
                      rows: [
                        _DetailRow(
                          'Minimum',
                          _formatNumber(item.minimumStockLevel),
                        ),
                        _DetailRow(
                          'Reorder',
                          _formatNumber(item.reorderLevel),
                        ),
                        _DetailRow(
                          'Maximum',
                          _formatNumber(item.maximumStockLevel),
                        ),
                        _DetailRow('Valuation', item.valuationMethod),
                      ],
                    ),
                  if (item.technicalSpecificationEnabled)
                    _DetailsSection(
                      title: 'Technical',
                      rows: [
                        _DetailRow('Type', item.itemType),
                        _DetailRow('Shape', item.itemShape),
                        _DetailRow('Grade', item.itemGrade),
                        _DetailRow('Coating', item.coatingType),
                        _DetailRow(
                          'Standard kg/m',
                          _formatNumber(item.standardWeightPerMeter),
                        ),
                      ],
                    ),
                  if (item.description.trim().isNotEmpty)
                    _DetailsSection(
                      title: 'Description',
                      child: Text(
                        item.description,
                        style: const TextStyle(
                          color: zMuted,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: zBorder)),
            ),
            child: Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Delete permanently',
                  onPressed: () => _deleteItem(item),
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openEditItem(
                      item,
                      activeVerticalId: activeVerticalId,
                      activeVerticalName: activeVerticalName,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Item'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ItemMasterModel> _applyFilters(List<ItemMasterModel> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      if (_statusFilter == 'Active' && !item.isActive) return false;
      if (_statusFilter == 'Inactive' && item.isActive) return false;
      if (_natureFilter != 'All' && item.itemNature != _natureFilter) {
        return false;
      }
      if (_categoryFilter != 'All' && item.category != _categoryFilter) {
        return false;
      }
      if (_uomFilter != 'All' &&
          item.unit.trim().toUpperCase() != _uomFilter) {
        return false;
      }
      if (_scopeFilter == 'Organization' && !item.appliesToAllVerticals) {
        return false;
      }
      if (_scopeFilter == 'Restricted' && item.appliesToAllVerticals) {
        return false;
      }
      if (_controlFilter == 'Standard' &&
          (item.qualityInspectionRequired || item.hasTrackingControl)) {
        return false;
      }
      if (_controlFilter == 'QC' && !item.qualityInspectionRequired) {
        return false;
      }
      if (_controlFilter == 'Batch' && !item.batchTracked) return false;
      if (_controlFilter == 'Serial' && !item.serialTracked) return false;
      if (_controlFilter == 'Expiry' && !item.expiryTracked) return false;
      if (_inventoryOnly && !item.inventoryTracked) return false;
      if (_technicalOnly && !item.technicalSpecificationEnabled) return false;

      if (query.isEmpty) return true;
      final haystack = [
        item.itemCode,
        item.itemName,
        item.itemNature,
        item.itemType,
        item.category,
        item.subCategory,
        item.itemGrade,
        item.scopeLabel,
        item.unit,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  void _resetPage() {
    setState(() => _pageIndex = 0);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _natureFilter = 'All';
      _statusFilter = 'Active';
      _categoryFilter = 'All';
      _uomFilter = 'All';
      _scopeFilter = 'All';
      _controlFilter = 'All';
      _inventoryOnly = false;
      _technicalOnly = false;
      _pageIndex = 0;
    });
  }

  Future<void> _openAddItem({
    required String? activeVerticalId,
    required String? activeVerticalName,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScreenAddItemMaster(
          tenantId: widget.tenantId,
          activeVerticalId: activeVerticalId,
          activeVerticalName: activeVerticalName,
        ),
      ),
    );
  }

  Future<void> _openEditItem(
      ItemMasterModel item, {
        required String? activeVerticalId,
        required String? activeVerticalName,
      }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScreenAddItemMaster(
          tenantId: widget.tenantId,
          item: item,
          activeVerticalId: activeVerticalId,
          activeVerticalName: activeVerticalName,
        ),
      ),
    );
  }

  Future<void> _activateItem(ItemMasterModel item) async {
    try {
      await _repository.setItemActive(item.id, true);
      _showSnack('Item activated.');
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_MASTER_ACTIVATE_ERROR itemId=${item.id} error=$error\n$stackTrace',
      );
      _showSnack('Unable to activate the item.');
    }
  }

  Future<void> _deleteItem(ItemMasterModel item) async {
    final confirmationController = TextEditingController();
    var canDelete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Delete item permanently?'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.displayName} will be permanently removed from Item Master.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This cannot be undone. Existing transaction snapshots may remain, but direct references to this Item Master document may no longer resolve.',
                      style: TextStyle(color: Colors.red, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Type ${item.itemCode} to confirm',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmationController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Item code',
                      ),
                      onChanged: (value) {
                        final matches = value.trim().toUpperCase() ==
                            item.itemCode.trim().toUpperCase();
                        if (matches != canDelete) {
                          setDialogState(() => canDelete = matches);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: canDelete
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );

    confirmationController.dispose();
    if (confirmed != true) return;

    try {
      await _repository.deleteItemPermanently(item.id);
      if (!mounted) return;
      setState(() {
        if (_selectedItem?.id == item.id) _selectedItem = null;
      });
      _showSnack('Item permanently deleted.');
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_MASTER_DELETE_ERROR itemId=${item.id} error=$error\n$stackTrace',
      );
      _showSnack('Unable to delete the item. Check Firestore permissions and references.');
    }
  }

  void _handleHeaderAction(String action) {
    switch (action) {
      case 'import':
        _importCsv();
      case 'template':
        _showTemplate();
      case 'library':
        _loadStandardEngineeringLibrary();
      case 'cleanup':
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => MaterialCleanupScreen(
              tenantId: widget.tenantId,
            ),
          ),
        );
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;

    setState(() => _importing = true);
    var imported = 0;
    var skipped = 0;

    try {
      final rows = _parseItemCsv(const Utf8Decoder().convert(bytes));
      for (final row in rows) {
        final code = (row['itemCode'] ?? row['materialCode'] ?? '').trim();
        if (code.isEmpty) {
          skipped++;
          continue;
        }
        final existing = await _repository.findByItemCode(code);
        final item = _itemFromRow(row, existingId: existing?.id);
        try {
          await _repository.saveItem(item);
          imported++;
        } on ItemMasterDuplicateException {
          skipped++;
        }
      }
      _showSnack('Import completed: $imported saved, $skipped skipped.');
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_MASTER_IMPORT_ERROR tenantId=${widget.tenantId} '
            'error=$error\n$stackTrace',
      );
      _showSnack('Unable to import the selected file.');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _loadStandardEngineeringLibrary() async {
    if (_loadingLibrary) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Load Engineering Library?'),
        content: const Text(
          'Matching item codes will be updated and missing standard engineering items will be created as organization-wide Raw Materials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loadingLibrary = true);
    var saved = 0;
    try {
      for (final row in _seedRows) {
        final code = (row['materialCode'] ?? '').trim();
        final existing = await _repository.findByItemCode(code);
        await _repository.saveItem(
          _itemFromRow(row, existingId: existing?.id),
        );
        saved++;
      }
      _showSnack('$saved standard engineering items saved.');
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_MASTER_LIBRARY_ERROR tenantId=${widget.tenantId} '
            'error=$error\n$stackTrace',
      );
      _showSnack('Unable to load the engineering library.');
    } finally {
      if (mounted) setState(() => _loadingLibrary = false);
    }
  }

  ItemMasterModel _itemFromRow(
      Map<String, String> row, {
        String? existingId,
      }) {
    final itemType = (
        row['itemType'] ??
            row['materialType'] ??
            row['category'] ??
            'Custom'
    ).trim();
    final itemNature = (row['itemNature'] ?? '').trim().isEmpty
        ? 'Raw Material'
        : row['itemNature']!.trim();
    final grade = (
        row['itemGrade'] ??
            row['materialGrade'] ??
            row['grade'] ??
            'MS'
    ).trim();
    final formulaValue = (
        row['weightFormula'] ??
            row['formulaType'] ??
            ''
    ).trim();
    final formula = formulaValue.isEmpty
        ? WeightFormulaService.formulaTypeForMaterial(itemType)
        : formulaValue;
    final coatingType = (
        row['coatingType'] ??
            row['coating'] ??
            ''
    ).trim();
    final baseUnit = (row['baseUnit'] ?? row['unit'] ?? 'KG').trim();
    final verticalIds = _splitPipeList(row['verticalIds'] ?? '');
    final verticalNames = _splitPipeList(row['verticalNames'] ?? '');

    return ItemMasterModel(
      id: existingId?.trim().isNotEmpty == true
          ? existingId!.trim()
          : _repository.newItemId(),
      itemCode: (row['itemCode'] ?? row['materialCode'] ?? '').trim(),
      itemName: (row['itemName'] ?? row['materialName'] ?? '').trim(),
      itemNature: itemNature,
      itemType: itemType,
      itemShape: (
          row['itemShape'] ??
              row['materialShape'] ??
              row['shape'] ??
              itemType
      ).trim(),
      itemGrade: grade,
      description: (row['description'] ?? '').trim(),
      category: (row['category'] ?? itemType).trim(),
      subCategory: (row['subCategory'] ?? '').trim(),
      purchaseUnit: (row['purchaseUnit'] ?? baseUnit).trim(),
      issueUnit: (row['issueUnit'] ?? baseUnit).trim(),
      conversionFactor:
      double.tryParse(row['conversionFactor'] ?? '') ?? 1,
      hsnCode: (row['hsnCode'] ?? '').trim(),
      taxRate: double.tryParse(row['taxRate'] ?? '') ?? 0,
      valuationMethod:
      (row['valuationMethod'] ?? 'Weighted Average').trim(),
      yieldStrength: (row['yieldStrength'] ?? '').trim().isEmpty
          ? (grade == 'MS' ? 'YS350' : grade)
          : row['yieldStrength']!.trim(),
      coating: coatingType,
      coatingType: coatingType,
      coatingSpec: (row['coatingSpec'] ?? '').trim(),
      density:
      double.tryParse(row['density'] ?? '') ??
          ItemMasterModel.densities[grade] ??
          7850,
      formulaType: formula,
      weightFormula: formula,
      standardWeightPerMeter:
      double.tryParse(row['standardWeightPerMeter'] ?? '') ?? 0,
      baseWeightPerMeter:
      double.tryParse(row['baseWeightPerMeter'] ?? '') ?? 0,
      coatingFormula: (row['coatingFormula'] ?? '').trim(),
      unit: baseUnit,
      inventoryTracked:
      (row['inventoryTracked'] ?? 'true').toLowerCase() != 'false',
      batchTracked:
      (row['batchTracked'] ?? 'false').toLowerCase() == 'true',
      serialTracked:
      (row['serialTracked'] ?? 'false').toLowerCase() == 'true',
      expiryTracked:
      (row['expiryTracked'] ?? 'false').toLowerCase() == 'true',
      qualityInspectionRequired:
      (row['qualityInspectionRequired'] ?? 'false').toLowerCase() ==
          'true',
      allowNegativeStock:
      (row['allowNegativeStock'] ?? 'false').toLowerCase() == 'true',
      technicalSpecificationEnabled:
      (row['technicalSpecificationEnabled'] ?? 'true').toLowerCase() !=
          'false',
      reorderLevel: double.tryParse(row['reorderLevel'] ?? '') ?? 0,
      minimumStockLevel:
      double.tryParse(row['minimumStockLevel'] ?? '') ?? 0,
      maximumStockLevel:
      double.tryParse(row['maximumStockLevel'] ?? '') ?? 0,
      purchaseTolerancePercent:
      double.tryParse(row['purchaseTolerancePercent'] ?? '') ?? 0,
      appliesToAllVerticals:
      (row['appliesToAllVerticals'] ?? 'true').toLowerCase() != 'false',
      verticalIds: verticalIds,
      verticalNames: verticalNames,
      isActive: (row['isActive'] ?? 'true').toLowerCase() != 'false',
    );
  }

  Future<void> _showTemplate() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Item Master CSV Template'),
        content: const SizedBox(
          width: 960,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(_templateCsv),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static IconData _natureIcon(String nature) {
    switch (nature) {
      case 'Raw Material':
        return Icons.view_in_ar_outlined;
      case 'Consumable':
        return Icons.local_fire_department_outlined;
      case 'Spare Part':
        return Icons.settings_outlined;
      case 'Tool & Equipment':
        return Icons.handyman_outlined;
      case 'Safety Item':
        return Icons.health_and_safety_outlined;
      case 'Packaging Material':
        return Icons.inventory_outlined;
      case 'Semi-Finished Good':
        return Icons.precision_manufacturing_outlined;
      case 'Finished Good':
        return Icons.task_alt_outlined;
      case 'Service':
        return Icons.design_services_outlined;
      case 'Asset':
        return Icons.apartment_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class MaterialMasterScreen extends ScreenItemMasterList {
  const MaterialMasterScreen({
    super.key,
    required super.tenantId,
  });
}

class _ItemRow extends StatefulWidget {
  const _ItemRow({
    required this.item,
    required this.width,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
  });

  final ItemMasterModel item;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onActivate;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = Theme.of(context).colorScheme.primary;
    final showCategory = widget.width >= 760;
    final showScope = widget.width >= 980;
    final showControls = widget.width >= 1120;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.selected
            ? color.withValues(alpha: 0.055)
            : _hovered
            ? zSurfaceSoft.withValues(alpha: 0.7)
            : Colors.white,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          _ScreenItemMasterListState._natureIcon(
                            item.itemNature,
                          ),
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: zText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.itemCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: zMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _BodyCell(
                    child: _InfoChip(label: item.itemNature),
                  ),
                ),
                if (showCategory)
                  Expanded(
                    flex: 2,
                    child: _BodyCell(
                      text: item.category,
                      secondary: item.subCategory,
                    ),
                  ),
                Expanded(
                  flex: 1,
                  child: _BodyCell(text: item.unit),
                ),
                if (showScope)
                  Expanded(
                    flex: 2,
                    child: _BodyCell(
                      text: item.scopeLabel,
                      icon: item.appliesToAllVerticals
                          ? Icons.language_outlined
                          : Icons.account_tree_outlined,
                    ),
                  ),
                if (showControls)
                  Expanded(
                    flex: 2,
                    child: _BodyCell(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (item.qualityInspectionRequired)
                            const _TinyControl(icon: Icons.fact_check_outlined),
                          if (item.batchTracked)
                            const _TinyControl(icon: Icons.qr_code_2_outlined),
                          if (item.serialTracked)
                            const _TinyControl(icon: Icons.qr_code_scanner_outlined),
                          if (item.expiryTracked)
                            const _TinyControl(icon: Icons.event_busy_outlined),
                          if (!item.qualityInspectionRequired &&
                              !item.hasTrackingControl)
                            const Text(
                              'Standard',
                              style: TextStyle(
                                color: zMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  width: 92,
                  child: _StatusChip(isActive: item.isActive),
                ),
                SizedBox(
                  width: 46,
                  child: PopupMenuButton<String>(
                    tooltip: 'Item actions',
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit();
                      if (value == 'activate') widget.onActivate?.call();
                      if (value == 'delete') widget.onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit Item'),
                        ),
                      ),
                      if (!item.isActive)
                        const PopupMenuItem(
                          value: 'activate',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.check_circle_outline),
                            title: Text('Activate'),
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red,
                          ),
                          title: Text(
                            'Delete Permanently',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: zMuted,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({
    this.text,
    this.secondary,
    this.icon,
    this.child,
  });

  final String? text;
  final String? secondary;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Align(alignment: Alignment.centerLeft, child: child!);
    }
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: zMuted),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (text ?? '').trim().isEmpty ? '—' : text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: zText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((secondary ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  secondary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: zMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final value = label.trim().isEmpty ? 'Not set' : label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: zSurfaceSoft,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: zText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? zSuccess : zMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.23)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyControl extends StatelessWidget {
  const _TinyControl({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _ControlTag extends StatelessWidget {
  const _ControlTag({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: enabled ? color.withValues(alpha: 0.08) : zSurfaceSoft,
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.28) : zBorder,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? color : zMuted,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    this.rows = const [],
    this.child,
  });

  final String title;
  final List<_DetailRow> rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows
        .where((row) => row.value.trim().isNotEmpty)
        .toList(growable: false);
    if (visibleRows.isEmpty && child == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: zMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 9),
          if (child != null) child!,
          ...visibleRows.map(
                (row) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        color: zMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: zText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 42,
                  color: zMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.details});

  final String message;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(details, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemPickerDialog extends StatefulWidget {
  const ItemPickerDialog({
    super.key,
    required this.tenantId,
    this.activeVerticalId,
    this.allowedNatures,
    this.inventoryTrackedOnly = true,
    this.technicalOnly = false,
    this.title = 'Select Item',
  });

  final String tenantId;
  final String? activeVerticalId;
  final Set<String>? allowedNatures;
  final bool inventoryTrackedOnly;
  final bool technicalOnly;
  final String title;

  @override
  State<ItemPickerDialog> createState() => _ItemPickerDialogState();
}

class _ItemPickerDialogState extends State<ItemPickerDialog> {
  late final ItemMasterRepository _repository = ItemMasterRepository(
    tenantId: widget.tenantId,
  );
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ItemMasterModel> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load([String query = '']) async {
    setState(() => _loading = true);
    try {
      final items = await _repository.searchItems(query);
      final deduped = <String, ItemMasterModel>{};
      for (final item in items) {
        if (!item.isAvailableInVertical(widget.activeVerticalId)) continue;
        if (widget.inventoryTrackedOnly && !item.inventoryTracked) continue;
        if (widget.technicalOnly && !item.technicalSpecificationEnabled) {
          continue;
        }
        final allowedNatures = widget.allowedNatures;
        if (allowedNatures != null &&
            allowedNatures.isNotEmpty &&
            !allowedNatures.contains(item.itemNature)) {
          continue;
        }
        final key = item.normalizedItemCode;
        if (key.isEmpty) continue;
        deduped.putIfAbsent(key, () => item);
      }
      if (!mounted) return;
      setState(() {
        _items = deduped.values.toList(growable: false);
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_PICKER_ERROR tenantId=${widget.tenantId} '
            'path=${_repository.collectionPath} error=$error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
          () => _load(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search active items',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 430,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('No active items found.'))
                  : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    leading: Icon(
                      _ScreenItemMasterListState._natureIcon(
                        item.itemNature,
                      ),
                    ),
                    title: Text(item.itemName),
                    subtitle: Text(
                      '${item.itemCode} • ${item.itemNature} • ${item.unit}',
                    ),
                    trailing: Text(item.scopeLabel),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class MaterialPickerDialog extends ItemPickerDialog {
  const MaterialPickerDialog({
    super.key,
    required super.tenantId,
    super.activeVerticalId,
    super.allowedNatures,
    super.inventoryTrackedOnly,
    super.technicalOnly,
    super.title,
  });
}

class MaterialCleanupScreen extends StatefulWidget {
  const MaterialCleanupScreen({
    super.key,
    required this.tenantId,
  });

  final String tenantId;

  @override
  State<MaterialCleanupScreen> createState() =>
      _MaterialCleanupScreenState();
}

class _MaterialCleanupScreenState extends State<MaterialCleanupScreen> {
  late final ItemMasterRepository _repository = ItemMasterRepository(
    tenantId: widget.tenantId,
  );
  Map<String, List<ItemMasterModel>> _duplicates = const {};
  bool _loading = true;
  String? _processingCode;

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  Future<void> _findDuplicates() async {
    setState(() => _loading = true);
    try {
      final all = await _repository.fetchAllItems(limit: 1000);
      final grouped = <String, List<ItemMasterModel>>{};
      for (final item in all) {
        final code = item.normalizedItemCode;
        if (code.isEmpty) continue;
        grouped.putIfAbsent(code, () => []).add(item);
      }
      grouped.removeWhere((_, items) => items.length < 2);
      if (!mounted) return;
      setState(() {
        _duplicates = grouped;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_CLEANUP_LOAD_ERROR tenantId=${widget.tenantId} '
            'error=$error\n$stackTrace',
      );
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteDuplicates(
      String normalizedCode,
      List<ItemMasterModel> items,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_outlined,
          color: Colors.red,
        ),
        title: const Text('Delete duplicate records?'),
        content: Text(
          'One preferred record will be kept and ${items.length - 1} '
              'duplicate record(s) for $normalizedCode will be permanently deleted. '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Duplicates'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingCode = normalizedCode);
    final sorted = [...items]
      ..sort((a, b) {
        final updatedComparison = (b.updatedAt ?? DateTime(1970)).compareTo(
          a.updatedAt ?? DateTime(1970),
        );
        if (updatedComparison != 0) return updatedComparison;
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.id.compareTo(b.id);
      });
    final keep = sorted.first;

    try {
      for (final duplicate in sorted.skip(1)) {
        await _repository.deleteItemPermanently(duplicate.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kept ${keep.displayName}; duplicate records were permanently deleted.',
          ),
        ),
      );
      await _findDuplicates();
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_CLEANUP_DELETE_ERROR code=$normalizedCode '
            'error=$error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete duplicate records.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate Item Maintenance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _duplicates.isEmpty
          ? const _EmptyState(
        title: 'No duplicate item codes',
        message:
        'No duplicate records were found in the first 1,000 Item Master documents.',
      )
          : ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: _duplicates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = _duplicates.entries.elementAt(index);
          final processing = _processingCode == entry.key;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Normalized Code: ${entry.key}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map(
                              (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${item.itemCode} | ${item.itemName} | '
                                  '${item.itemNature} | '
                                  '${item.isActive ? 'Active' : 'Inactive'}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: processing
                        ? null
                        : () => _deleteDuplicates(
                      entry.key,
                      entry.value,
                    ),
                    child: Text(
                      processing ? 'Deleting...' : 'Delete Duplicates',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

const _templateCsv =
    'itemCode,itemName,itemNature,category,subCategory,baseUnit,purchaseUnit,issueUnit,conversionFactor,hsnCode,taxRate,valuationMethod,inventoryTracked,batchTracked,serialTracked,expiryTracked,qualityInspectionRequired,allowNegativeStock,reorderLevel,minimumStockLevel,maximumStockLevel,purchaseTolerancePercent,appliesToAllVerticals,verticalIds,verticalNames,technicalSpecificationEnabled,itemType,itemShape,itemGrade,standardWeightPerMeter,density,coatingType,coatingSpec,isActive\n'
    'RM-STEEL-001,ISA 40x40x4 Angle,Raw Material,Structural Steel,Angle,KG,KG,KG,1,7216,18,Weighted Average,true,true,false,false,true,false,500,200,5000,5,true,,,true,Angle,Equal Angle,MS,2.42,7850,HDG,80,true\n'
    'CON-WELD-001,Welding Electrode E7018,Consumable,Welding Consumables,Electrode,BOX,BOX,NOS,100,8311,18,Weighted Average,true,true,false,true,true,false,10,5,100,3,false,verticalId1|verticalId2,Fabrication|Galvanizing,false,,,,0,0,,,true';

final _seedRows = _parseItemCsv(
  'materialCode,materialName,category,materialShape,standardWeightPerMeter,grade,coating,isActive,yieldStrength,coatingType,coatingSpec,weightFormula\n'
      '100CS50X15X2,C Section 100CS50X15X2,C Section,C Section,3.54,YS350,HDG,true,YS350,HDG,80,sectionWeightPerMeter\n'
      '60CS40X15X1.6,C Section 60CS40X15X1.6,C Section,C Section,1.72,YS550,Galvalume,true,YS550,Galvalume,AZ150,sectionWeightPerMeter\n'
      '80CS40X15X2,C Section 80CS40X15X2,C Section,C Section,2.85,MS,HDG,true,,,,sectionWeightPerMeter\n'
      '120CS50X15X2,C Section 120CS50X15X2,C Section,C Section,4.15,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISA40X40X4,Angle ISA40X40X4,Angle,Equal Angle,2.42,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISA50X50X5,Angle ISA50X50X5,Angle,Equal Angle,3.78,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISA65X65X6,Angle ISA65X65X6,Angle,Equal Angle,5.80,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISA75X75X6,Angle ISA75X75X6,Angle,Equal Angle,6.80,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISA90X90X8,Angle ISA90X90X8,Angle,Equal Angle,10.90,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISMC75,Channel ISMC75,Channel,ISMC,7.14,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISMC100,Channel ISMC100,Channel,ISMC,9.56,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISMC125,Channel ISMC125,Channel,ISMC,13.10,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISMC150,Channel ISMC150,Channel,ISMC,16.80,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'ISMC200,Channel ISMC200,Channel,ISMC,22.30,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'FLAT25X3,Flat 25X3,Flat,Flat,0.59,MS,HDG,true,,,,plate\n'
      'FLAT40X5,Flat 40X5,Flat,Flat,1.57,MS,HDG,true,,,,plate\n'
      'FLAT50X6,Flat 50X6,Flat,Flat,2.36,MS,HDG,true,,,,plate\n'
      'FLAT75X8,Flat 75X8,Flat,Flat,4.71,MS,HDG,true,,,,plate\n'
      'PLATE50X5,Plate 50X5,Plate,Plate,2.059829,YS550,HDG,true,YS550,HDG,80,plate\n'
      'PLATE75X6,Plate 75X6,Plate,Plate,0,MS,,true,,,,plate\n'
      'PLATE100X8,Plate 100X8,Plate,Plate,0,MS,,true,,,,plate\n'
      'PLATE150X10,Plate 150X10,Plate,Plate,0,MS,,true,,,,plate\n'
      'PIPE25NB,Pipe 25NB,Pipe,NB Pipe,2.44,MS,HDG,true,,,,pipe\n'
      'PIPE32NB,Pipe 32NB,Pipe,NB Pipe,3.14,MS,HDG,true,,,,pipe\n'
      'PIPE40NB,Pipe 40NB,Pipe,NB Pipe,3.61,MS,HDG,true,,,,pipe\n'
      'PIPE50NB,Pipe 50NB,Pipe,NB Pipe,5.10,MS,HDG,true,,,,pipe\n'
      'PIPE80NB,Pipe 80NB,Pipe,NB Pipe,8.47,MS,HDG,true,,,,pipe\n'
      'SHS50X50X3,Hollow Section SHS50X50X3,Hollow Section,SHS,4.31,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'SHS75X75X4,Hollow Section SHS75X75X4,Hollow Section,SHS,8.86,MS,HDG,true,,,,sectionWeightPerMeter\n'
      'RHS100X50X3,Hollow Section RHS100X50X3,Hollow Section,RHS,6.67,MS,HDG,true,,,,sectionWeightPerMeter\n'
      '1280X1063X0.5,Roofing Sheet 1280X1063X0.5,Roofing Sheet,Roofing Sheet,4.171875,YS550,Galvalume,true,YS550,Galvalume,AZ150,sectionWeightPerMeter',
);

List<Map<String, String>> _parseItemCsv(String csv) {
  final lines = const LineSplitter()
      .convert(csv)
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);
  if (lines.length < 2) return const [];
  final headers = _splitCsvLine(lines.first);
  return lines.skip(1).map((line) {
    final values = _splitCsvLine(line);
    return {
      for (var index = 0; index < headers.length; index++)
        headers[index]: index < values.length ? values[index] : '',
    };
  }).toList(growable: false);
}

List<String> _splitCsvLine(String line) {
  final values = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == '"') {
      if (inQuotes && index + 1 < line.length && line[index + 1] == '"') {
        buffer.write('"');
        index++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }
    if (character == ',' && !inQuotes) {
      values.add(buffer.toString().trim());
      buffer.clear();
      continue;
    }
    buffer.write(character);
  }
  values.add(buffer.toString().trim());
  return values;
}

List<String> _splitPipeList(String value) {
  return value
      .split('|')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}
