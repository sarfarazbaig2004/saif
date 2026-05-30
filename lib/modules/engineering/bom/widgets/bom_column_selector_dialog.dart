import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/widgets/bom_custom_field_manager_dialog.dart';

class BomColumnSelectorDialog extends StatefulWidget {
  final List<String> visibleColumns;
  final List<BomCustomField> customFields;

  const BomColumnSelectorDialog({
    super.key,
    required this.visibleColumns,
    required this.customFields,
  });

  @override
  State<BomColumnSelectorDialog> createState() =>
      _BomColumnSelectorDialogState();
}

class _BomColumnSelectorDialogState extends State<BomColumnSelectorDialog> {
  late Set<String> _selected;
  late List<BomCustomField> _customFields;

  @override
  void initState() {
    super.initState();
    _selected = BomColumnConfig.sanitize(widget.visibleColumns).toSet();
    _customFields = widget.customFields.toList();
  }

  void _applyPreset(String name) {
    setState(() {
      _selected = BomColumnConfig.sanitize(
        BomColumnConfig.presets[name] ?? const [],
      ).toSet();
    });
  }

  Future<void> _manageCustomFields() async {
    final result = await showDialog<List<BomCustomField>>(
      context: context,
      builder: (_) => BomCustomFieldManagerDialog(customFields: _customFields),
    );
    if (result == null) return;
    setState(() {
      final oldIds = _customFields.map((field) => field.id).toSet();
      final nextIds = result.map((field) => field.id).toSet();
      _customFields = result;
      _selected.removeWhere(
        (key) =>
            BomColumnConfig.isCustomKey(key) &&
            !nextIds.contains(BomColumnConfig.customId(key)),
      );
      for (final field in result) {
        if (!oldIds.contains(field.id)) {
          _selected.add(BomColumnConfig.customKey(field.id));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Customize Fields'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BomColumnConfig.presets.keys
                    .map(
                      (name) => ActionChip(
                        label: Text(name),
                        onPressed: () => _applyPreset(name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _manageCustomFields,
                icon: const Icon(Icons.tune_outlined, size: 18),
                label: const Text('Manage Custom Fields'),
              ),
              const SizedBox(height: 14),
              ..._checkboxes(),
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
          onPressed: () => Navigator.pop(
            context,
            BomFieldConfigResult(
              visibleColumns: BomColumnConfig.sanitize(_selected.toList()),
              customFields: _customFields,
            ),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  List<Widget> _checkboxes() {
    final system = BomColumnConfig.all.map(
      (column) => _checkbox(
        key: column.key,
        label: column.label,
        mandatory: column.mandatory,
      ),
    );
    final custom = _customFields.map(
      (field) => _checkbox(
        key: BomColumnConfig.customKey(field.id),
        label: '${field.name} (${field.type})',
      ),
    );
    return [...system, ...custom];
  }

  Widget _checkbox({
    required String key,
    required String label,
    bool mandatory = false,
  }) {
    return CheckboxListTile(
      value: _selected.contains(key),
      onChanged: mandatory
          ? null
          : (value) {
              setState(() {
                if (value == true) {
                  _selected.add(key);
                } else {
                  _selected.remove(key);
                }
              });
            },
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: mandatory ? const Text('Mandatory') : null,
    );
  }
}
