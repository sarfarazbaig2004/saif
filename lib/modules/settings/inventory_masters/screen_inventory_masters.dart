import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/inventory/item_master/screens_add_item_master.dart';

class InventoryMastersScreen extends StatefulWidget {
  const InventoryMastersScreen({
    super.key,
    required this.companyId,
    required this.canEdit,
  });

  final String companyId;
  final bool canEdit;

  @override
  State<InventoryMastersScreen> createState() =>
      _InventoryMastersScreenState();
}

class _InventoryMastersScreenState extends State<InventoryMastersScreen>
    with SingleTickerProviderStateMixin {
  late final ItemMasterConfigurationRepository _repository =
  ItemMasterConfigurationRepository(companyId: widget.companyId);
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  bool _saving = false;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Inventory Masters',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'UOMs'),
            Tab(text: 'Measurement Profiles'),
          ],
        ),
      ),
      body: StreamBuilder<ItemMasterConfiguration>(
        stream: _repository.watchConfiguration(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final configuration =
              snapshot.data ?? ItemMasterConfiguration.defaults();

          return Column(
            children: [
              _buildCommandBar(configuration),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCategories(configuration),
                    _buildUoms(configuration),
                    _buildProfiles(configuration),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommandBar(ItemMasterConfiguration configuration) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_outlined, color: zBlue),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Company-wide classifications and measurement rules used by Item Master.',
              style: TextStyle(
                color: zMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.canEdit)
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _confirmReset(configuration),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Repair Recommended Masters'),
            ),
        ],
      ),
    );
  }

  Widget _buildCategories(ItemMasterConfiguration configuration) {
    final categories = [...configuration.categories]
      ..sort((a, b) {
        final nature = a.nature.compareTo(b.nature);
        return nature != 0 ? nature : a.name.compareTo(b.name);
      });

    return _MasterPanel(
      title: 'Item Categories & Subcategories',
      actionLabel: 'Add Category',
      canEdit: widget.canEdit,
      onAdd: () => _editCategory(configuration),
      child: categories.isEmpty
          ? const _EmptyState(
        title: 'No categories configured',
        message: 'Load recommended defaults or create a category.',
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryCard(
            category: category,
            canEdit: widget.canEdit,
            onEdit: () => _editCategory(
              configuration,
              existing: category,
            ),
            onToggle: () => _replaceCategory(
              configuration,
              category,
              ItemCategoryDefinition(
                nature: category.nature,
                name: category.name,
                code: category.code,
                subcategories: category.subcategories,
                isActive: !category.isActive,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUoms(ItemMasterConfiguration configuration) {
    final uoms = [...configuration.uoms]
      ..sort((a, b) => a.code.compareTo(b.code));

    return _MasterPanel(
      title: 'Unit of Measurement Master',
      actionLabel: 'Add UOM',
      canEdit: widget.canEdit,
      onAdd: () => _editUom(configuration),
      child: uoms.isEmpty
          ? const _EmptyState(
        title: 'No UOMs configured',
        message: 'Load recommended defaults or create a UOM.',
      )
          : GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisExtent: 118,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: uoms.length,
        itemBuilder: (context, index) {
          final uom = uoms[index];
          return _UomCard(
            uom: uom,
            canEdit: widget.canEdit,
            onEdit: () => _editUom(configuration, existing: uom),
            onToggle: () => _replaceUom(
              configuration,
              uom,
              UomDefinition(
                code: uom.code,
                name: uom.name,
                dimension: uom.dimension,
                decimalPlaces: uom.decimalPlaces,
                isActive: !uom.isActive,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfiles(ItemMasterConfiguration configuration) {
    final profiles = [...configuration.measurementProfiles]
      ..sort((a, b) => a.name.compareTo(b.name));

    return _MasterPanel(
      title: 'Measurement Profiles',
      actionLabel: 'Add Profile',
      canEdit: widget.canEdit,
      onAdd: () => _editProfile(configuration),
      child: profiles.isEmpty
          ? const _EmptyState(
        title: 'No measurement profiles configured',
        message: 'Load recommended defaults or create a profile.',
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        itemCount: profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return _ProfileCard(
            profile: profile,
            canEdit: widget.canEdit,
            onEdit: () => _editProfile(
              configuration,
              existing: profile,
            ),
            onToggle: () => _replaceProfile(
              configuration,
              profile,
              MeasurementProfileDefinition(
                key: profile.key,
                name: profile.name,
                baseUom: profile.baseUom,
                purchaseUom: profile.purchaseUom,
                issueUom: profile.issueUom,
                secondaryUom: profile.secondaryUom,
                conversionMethod: profile.conversionMethod,
                defaultFactor: profile.defaultFactor,
                isActive: !profile.isActive,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editCategory(
      ItemMasterConfiguration configuration, {
        ItemCategoryDefinition? existing,
      }) async {
    final result = await showDialog<ItemCategoryDefinition>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CategoryDialog(
        existing: existing,
        profiles: configuration.measurementProfiles,
      ),
    );
    if (result == null) return;

    final duplicate = configuration.categories.any(
          (entry) =>
      !identical(entry, existing) &&
          entry.nature == result.nature &&
          entry.name.toLowerCase() == result.name.toLowerCase(),
    );
    if (duplicate) {
      _showSnack('A category with this name already exists for the nature.');
      return;
    }
    await _replaceCategory(configuration, existing, result);
  }

  Future<void> _replaceCategory(
      ItemMasterConfiguration configuration,
      ItemCategoryDefinition? existing,
      ItemCategoryDefinition replacement,
      ) async {
    final next = [...configuration.categories];
    if (existing == null) {
      next.add(replacement);
    } else {
      final index = next.indexOf(existing);
      if (index >= 0) next[index] = replacement;
    }
    await _save(
      ItemMasterConfiguration(
        categories: next,
        uoms: configuration.uoms,
        measurementProfiles: configuration.measurementProfiles,
      ),
    );
  }

  Future<void> _editUom(
      ItemMasterConfiguration configuration, {
        UomDefinition? existing,
      }) async {
    final result = await showDialog<UomDefinition>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UomDialog(existing: existing),
    );
    if (result == null) return;

    final duplicate = configuration.uoms.any(
          (entry) =>
      !identical(entry, existing) && entry.code == result.code,
    );
    if (duplicate) {
      _showSnack('This UOM code already exists.');
      return;
    }
    await _replaceUom(configuration, existing, result);
  }

  Future<void> _replaceUom(
      ItemMasterConfiguration configuration,
      UomDefinition? existing,
      UomDefinition replacement,
      ) async {
    final next = [...configuration.uoms];
    if (existing == null) {
      next.add(replacement);
    } else {
      final index = next.indexOf(existing);
      if (index >= 0) next[index] = replacement;
    }
    await _save(
      ItemMasterConfiguration(
        categories: configuration.categories,
        uoms: next,
        measurementProfiles: configuration.measurementProfiles,
      ),
    );
  }

  Future<void> _editProfile(
      ItemMasterConfiguration configuration, {
        MeasurementProfileDefinition? existing,
      }) async {
    final result = await showDialog<MeasurementProfileDefinition>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProfileDialog(
        existing: existing,
        uoms: configuration.uoms,
      ),
    );
    if (result == null) return;

    final duplicate = configuration.measurementProfiles.any(
          (entry) => !identical(entry, existing) && entry.key == result.key,
    );
    if (duplicate) {
      _showSnack('This measurement profile key already exists.');
      return;
    }
    await _replaceProfile(configuration, existing, result);
  }

  Future<void> _replaceProfile(
      ItemMasterConfiguration configuration,
      MeasurementProfileDefinition? existing,
      MeasurementProfileDefinition replacement,
      ) async {
    final next = [...configuration.measurementProfiles];
    if (existing == null) {
      next.add(replacement);
    } else {
      final index = next.indexOf(existing);
      if (index >= 0) next[index] = replacement;
    }
    await _save(
      ItemMasterConfiguration(
        categories: configuration.categories,
        uoms: configuration.uoms,
        measurementProfiles: next,
      ),
    );
  }

  Future<void> _save(ItemMasterConfiguration configuration) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository.saveConfiguration(configuration);
      _showSnack('Inventory masters updated.');
    } catch (error) {
      _showSnack('Unable to save inventory masters: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmReset(ItemMasterConfiguration configuration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair recommended masters?'),
        content: const Text(
          'Missing recommended categories, subcategories, UOMs and measurement profiles will be restored. Your custom masters and saved changes will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _repository.seedRecommendedDefaults();
      _showSnack('Recommended inventory masters repaired.');
    } catch (error) {
      _showSnack('Unable to load defaults: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MasterPanel extends StatelessWidget {
  const _MasterPanel({
    required this.title,
    required this.actionLabel,
    required this.canEdit,
    required this.onAdd,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final bool canEdit;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (canEdit)
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(actionLabel),
                ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.canEdit,
    required this.onEdit,
    required this.onToggle,
  });

  final ItemCategoryDefinition category;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: zBlueSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_tree_outlined, color: zBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          color: zText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Pill(label: category.code),
                    const SizedBox(width: 6),
                    _Pill(
                      label: category.isActive ? 'Active' : 'Inactive',
                      positive: category.isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  category.nature,
                  style: const TextStyle(
                    color: zMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: category.subcategories
                      .map((entry) => _Pill(label: entry.name))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle') onToggle();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(category.isActive ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UomCard extends StatelessWidget {
  const _UomCard({
    required this.uom,
    required this.canEdit,
    required this.onEdit,
    required this.onToggle,
  });

  final UomDefinition uom;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: zSurfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              uom.code,
              style: const TextStyle(
                color: zText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  uom.name,
                  style: const TextStyle(
                    color: zText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${uom.dimension} • ${uom.decimalPlaces} decimals',
                  style: const TextStyle(color: zMuted),
                ),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle') onToggle();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(uom.isActive ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.canEdit,
    required this.onEdit,
    required this.onToggle,
  });

  final MeasurementProfileDefinition profile;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten_outlined, color: zBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        style: const TextStyle(
                          color: zText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Pill(label: profile.key),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Base ${profile.baseUom} • Purchase ${profile.purchaseUom} • Issue ${profile.issueUom}'
                      '${profile.secondaryUom.isEmpty ? '' : ' • Secondary ${profile.secondaryUom}'}',
                  style: const TextStyle(color: zMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.conversionMethod,
                  style: const TextStyle(
                    color: zMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle') onToggle();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(profile.isActive ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    required this.existing,
    required this.profiles,
  });

  final ItemCategoryDefinition? existing;
  final List<MeasurementProfileDefinition> profiles;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.existing?.code ?? '',
  );
  late String _nature = widget.existing?.nature ?? 'Raw Material';
  late bool _isActive = widget.existing?.isActive ?? true;
  late List<_SubcategoryDraft> _subcategories;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subcategories =
        (widget.existing?.subcategories ?? const <ItemSubcategoryDefinition>[])
            .map(_SubcategoryDraft.fromDefinition)
            .toList();
    if (_subcategories.isEmpty) {
      _subcategories.add(_defaultSubcategoryForNature(_nature));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    for (final draft in _subcategories) {
      draft.dispose();
    }
    super.dispose();
  }

  _SubcategoryDraft _defaultSubcategoryForNature(String nature) {
    switch (nature) {
      case 'Raw Material':
      case 'Scrap':
        return _SubcategoryDraft.general(
          templateKey: 'generic',
          profileKey: 'WEIGHT',
        );
      case 'Semi-Finished Good':
        return _SubcategoryDraft.general(
          templateKey: 'fabricatedMember',
          profileKey: 'COUNT_WEIGHT',
        );
      case 'Finished Good':
        return _SubcategoryDraft.general(
          templateKey: 'assembly',
          profileKey: 'ASSEMBLY',
        );
      case 'Service':
        return _SubcategoryDraft.general(
          templateKey: 'service',
          profileKey: 'SERVICE',
        );
      default:
        return _SubcategoryDraft.general(
          templateKey: 'generic',
          profileKey: 'COUNT',
        );
    }
  }

  String? _validateSubcategories() {
    if (_subcategories.isEmpty) {
      return 'At least one subcategory is required.';
    }
    final names = <String>{};
    final codes = <String>{};
    for (final draft in _subcategories) {
      final name = draft.name.text.trim().toLowerCase();
      final code = draft.code.text.trim().toUpperCase();
      if (!names.add(name)) {
        return 'Subcategory names must be unique within the category.';
      }
      if (!codes.add(code)) {
        return 'Subcategory codes must be unique within the category.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Category' : 'Edit Category'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _nature,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Item Nature',
                        ),
                        items: ItemMasterModel.itemNatures
                            .map(
                              (entry) => DropdownMenuItem(
                            value: entry,
                            child: Text(entry),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _nature = value;
                            _error = null;
                            if (_subcategories.length == 1 &&
                                _subcategories.first.isGeneralDraft) {
                              final previous = _subcategories.removeAt(0);
                              previous.dispose();
                              _subcategories.add(
                                _defaultSubcategoryForNature(value),
                              );
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Category name is required.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Code',
                        ),
                        validator: (value) =>
                        RegExp(r'^[A-Za-z0-9]{2,5}$').hasMatch(
                          (value ?? '').trim(),
                        )
                            ? null
                            : 'Use 2–5 letters/numbers.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subcategories',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Required: controls UOM, conversion and smart fields.',
                            style: TextStyle(color: zMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(
                            () => _subcategories.add(_SubcategoryDraft.empty()),
                      ),
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text('Add Subcategory'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_subcategories.length, (index) {
                  final draft = _subcategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: zSurfaceSoft,
                        border: Border.all(color: zBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: draft.name,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                isDense: true,
                              ),
                              validator: (value) =>
                              (value ?? '').trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 95,
                            child: TextFormField(
                              controller: draft.code,
                              textCapitalization:
                              TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Code',
                                isDense: true,
                              ),
                              validator: (value) => RegExp(
                                r'^[A-Za-z0-9]{2,5}$',
                              ).hasMatch((value ?? '').trim())
                                  ? null
                                  : '2–5 chars',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: draft.templateKey,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Attribute Template',
                                isDense: true,
                              ),
                              items: _attributeTemplateOptions
                                  .map(
                                    (entry) => DropdownMenuItem(
                                  value: entry,
                                  child: Text(entry),
                                ),
                              )
                                  .toList(),
                              onChanged: (value) => setState(
                                    () => draft.templateKey = value ?? 'generic',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: widget.profiles.any(
                                    (entry) => entry.key == draft.profileKey,
                              )
                                  ? draft.profileKey
                                  : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Measurement Profile',
                                isDense: true,
                              ),
                              items: widget.profiles
                                  .where((entry) => entry.isActive)
                                  .map(
                                    (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.name),
                                ),
                              )
                                  .toList(),
                              onChanged: (value) => setState(
                                    () => draft.profileKey = value ?? 'COUNT',
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _subcategories.length == 1
                                ? 'At least one subcategory is required'
                                : 'Remove',
                            onPressed: _subcategories.length == 1
                                ? null
                                : () {
                              setState(() {
                                final removed =
                                _subcategories.removeAt(index);
                                removed.dispose();
                                _error = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            final validationError = _validateSubcategories();
            if (validationError != null) {
              setState(() => _error = validationError);
              return;
            }
            Navigator.pop(
              context,
              ItemCategoryDefinition(
                nature: _nature,
                name: _name.text.trim(),
                code: _code.text.trim().toUpperCase(),
                subcategories: _subcategories
                    .map((entry) => entry.toDefinition())
                    .toList(growable: false),
                isActive: _isActive,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SubcategoryDraft {
  _SubcategoryDraft({
    required this.name,
    required this.code,
    required this.templateKey,
    required this.profileKey,
  });

  final TextEditingController name;
  final TextEditingController code;
  String templateKey;
  String profileKey;

  factory _SubcategoryDraft.empty() => _SubcategoryDraft(
    name: TextEditingController(),
    code: TextEditingController(),
    templateKey: 'generic',
    profileKey: 'COUNT',
  );

  factory _SubcategoryDraft.general({
    required String templateKey,
    required String profileKey,
  }) => _SubcategoryDraft(
    name: TextEditingController(text: 'General'),
    code: TextEditingController(text: 'GEN'),
    templateKey: templateKey,
    profileKey: profileKey,
  );

  bool get isGeneralDraft =>
      name.text.trim().toLowerCase() == 'general' &&
          code.text.trim().toUpperCase() == 'GEN';

  factory _SubcategoryDraft.fromDefinition(
      ItemSubcategoryDefinition definition,
      ) => _SubcategoryDraft(
    name: TextEditingController(text: definition.name),
    code: TextEditingController(text: definition.code),
    templateKey: definition.attributeTemplateKey,
    profileKey: definition.measurementProfileKey,
  );

  ItemSubcategoryDefinition toDefinition() => ItemSubcategoryDefinition(
    name: name.text.trim(),
    code: code.text.trim().toUpperCase(),
    attributeTemplateKey: templateKey,
    measurementProfileKey: profileKey,
  );

  void dispose() {
    name.dispose();
    code.dispose();
  }
}

class _UomDialog extends StatefulWidget {
  const _UomDialog({required this.existing});

  final UomDefinition? existing;

  @override
  State<_UomDialog> createState() => _UomDialogState();
}

class _UomDialogState extends State<_UomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code = TextEditingController(
    text: widget.existing?.code ?? '',
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String _dimension = widget.existing?.dimension ?? 'Count';
  late int _decimalPlaces = widget.existing?.decimalPlaces ?? 3;
  late bool _isActive = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dimensions = [
      'Weight',
      'Count',
      'Length',
      'Area',
      'Volume',
      'Pack',
      'Time',
      'Service',
    ];
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add UOM' : 'Edit UOM'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      controller: _code,
                      readOnly: widget.existing != null,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Code'),
                      validator: (value) => RegExp(
                        r'^[A-Za-z0-9]{1,8}$',
                      ).hasMatch((value ?? '').trim())
                          ? null
                          : 'Use 1–8 characters.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Name is required.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _dimension,
                decoration: const InputDecoration(labelText: 'Dimension'),
                items: dimensions
                    .map(
                      (entry) => DropdownMenuItem(
                    value: entry,
                    child: Text(entry),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _dimension = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _decimalPlaces,
                decoration: const InputDecoration(
                  labelText: 'Decimal Places',
                ),
                items: List.generate(
                  7,
                      (index) => DropdownMenuItem(
                    value: index,
                    child: Text('$index'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _decimalPlaces = value);
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              UomDefinition(
                code: _code.text.trim().toUpperCase(),
                name: _name.text.trim(),
                dimension: _dimension,
                decimalPlaces: _decimalPlaces,
                isActive: _isActive,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.existing, required this.uoms});

  final MeasurementProfileDefinition? existing;
  final List<UomDefinition> uoms;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _key = TextEditingController(
    text: widget.existing?.key ?? '',
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _factor = TextEditingController(
    text: '${widget.existing?.defaultFactor ?? 1}',
  );
  late String _base = widget.existing?.baseUom ?? 'NOS';
  late String _purchase = widget.existing?.purchaseUom ?? 'NOS';
  late String _issue = widget.existing?.issueUom ?? 'NOS';
  late String _secondary = widget.existing?.secondaryUom ?? '';
  late String _method = widget.existing?.conversionMethod ?? 'Fixed';
  late bool _isActive = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    _key.dispose();
    _name.dispose();
    _factor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uomCodes = widget.uoms
        .where((entry) => entry.isActive)
        .map((entry) => entry.code)
        .toList(growable: false);
    const methods = [
      'Fixed',
      'Formula',
      'Transaction Entered',
      'BOM Calculated',
      'Not Applicable',
    ];

    Widget uomField(String label, String value, ValueChanged<String> changed) {
      return DropdownButtonFormField<String>(
        initialValue: uomCodes.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: uomCodes
            .map(
              (entry) => DropdownMenuItem(
            value: entry,
            child: Text(entry),
          ),
        )
            .toList(),
        onChanged: (value) {
          if (value != null) changed(value);
        },
        validator: (value) => value == null ? '$label is required.' : null,
      );
    }

    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Add Measurement Profile'
            : 'Edit Measurement Profile',
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 190,
                      child: TextFormField(
                        controller: _key,
                        readOnly: widget.existing != null,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Key'),
                        validator: (value) => RegExp(
                          r'^[A-Za-z0-9_]{2,30}$',
                        ).hasMatch((value ?? '').trim())
                            ? null
                            : 'Use letters, numbers and underscores.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Name is required.'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: uomField(
                        'Base UOM',
                        _base,
                            (value) => setState(() => _base = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: uomField(
                        'Purchase UOM',
                        _purchase,
                            (value) => setState(() => _purchase = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: uomField(
                        'Issue UOM',
                        _issue,
                            (value) => setState(() => _issue = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _secondary.isEmpty ? '' : _secondary,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Secondary UOM',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('None'),
                          ),
                          ...uomCodes.map(
                                (entry) => DropdownMenuItem(
                              value: entry,
                              child: Text(entry),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _secondary = value ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _method,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Conversion Method',
                        ),
                        items: methods
                            .map(
                              (entry) => DropdownMenuItem(
                            value: entry,
                            child: Text(entry),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _method = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _factor,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Default Factor',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          return parsed != null && parsed > 0
                              ? null
                              : 'Enter > 0';
                        },
                      ),
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              MeasurementProfileDefinition(
                key: _key.text.trim().toUpperCase(),
                name: _name.text.trim(),
                baseUom: _base,
                purchaseUom: _purchase,
                issueUom: _issue,
                secondaryUom: _secondary,
                conversionMethod: _method,
                defaultFactor: double.parse(_factor.text.trim()),
                isActive: _isActive,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.positive});

  final String label;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    final color = positive == true
        ? const Color(0xFF15803D)
        : positive == false
        ? zMuted
        : zBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: zMuted),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: zText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: zMuted)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Unable to load inventory masters.\n$message',
        textAlign: TextAlign.center,
      ),
    );
  }
}

const _attributeTemplateOptions = <String>[
  'generic',
  'angle',
  'flat',
  'plate',
  'roundBar',
  'pipe',
  'hollowSection',
  'section',
  'coldFormedSection',
  'fastener',
  'chemical',
  'packaged',
  'gas',
  'fabricatedMember',
  'assembly',
  'service',
];
