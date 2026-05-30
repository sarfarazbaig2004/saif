import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';

class BomCustomFieldManagerDialog extends StatefulWidget {
  final List<BomCustomField> customFields;

  const BomCustomFieldManagerDialog({super.key, required this.customFields});

  @override
  State<BomCustomFieldManagerDialog> createState() =>
      _BomCustomFieldManagerDialogState();
}

class _BomCustomFieldManagerDialogState
    extends State<BomCustomFieldManagerDialog> {
  final _name = TextEditingController();
  String _type = 'Text';
  late List<BomCustomField> _fields;

  @override
  void initState() {
    super.initState();
    _fields = widget.customFields.toList();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addField() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _fields.add(
        BomCustomField(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          type: _type,
        ),
      );
      _name.clear();
      _type = 'Text';
    });
  }

  Future<void> _rename(int index) async {
    final controller = TextEditingController(text: _fields[index].name);
    final next = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Field'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Field Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.isEmpty) return;
    setState(() => _fields[index] = _fields[index].copyWith(name: next));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Custom Fields'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Field Name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Field Type'),
              items: const ['Text', 'Number', 'Dropdown', 'Date']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? 'Text'),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _addField,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Field'),
              ),
            ),
            const Divider(),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _fields.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final field = _fields.removeAt(oldIndex);
                    _fields.insert(newIndex, field);
                  });
                },
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  return ListTile(
                    key: ValueKey(field.id),
                    title: Text(field.name),
                    subtitle: Text(field.type),
                    leading: const Icon(Icons.drag_indicator),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Rename',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _rename(index),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => _fields.removeAt(index)),
                        ),
                      ],
                    ),
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
        FilledButton(
          onPressed: () => Navigator.pop(context, _fields),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
