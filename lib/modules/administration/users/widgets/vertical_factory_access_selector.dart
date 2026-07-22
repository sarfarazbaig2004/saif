import 'package:flutter/material.dart';

import 'package:QUIK/modules/administration/users/models/organization_access_selection.dart';
import 'package:QUIK/modules/settings/factory_master/factory_model.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';

class VerticalFactoryAccessSelector extends StatelessWidget {
  final Stream<List<VerticalModel>> verticalStream;
  final Stream<List<FactoryModel>> factoryStream;
  final AccessSelectionMode verticalMode;
  final Set<String> selectedVerticalIds;
  final AccessSelectionMode factoryMode;
  final Set<String> selectedFactoryIds;
  final void Function(AccessSelectionMode mode, Set<String> ids)
  onVerticalChanged;
  final void Function(AccessSelectionMode mode, Set<String> ids)
  onFactoryChanged;
  final InputDecoration verticalDecoration;
  final InputDecoration factoryDecoration;

  const VerticalFactoryAccessSelector({
    super.key,
    required this.verticalStream,
    required this.factoryStream,
    required this.verticalMode,
    required this.selectedVerticalIds,
    required this.factoryMode,
    required this.selectedFactoryIds,
    required this.onVerticalChanged,
    required this.onFactoryChanged,
    required this.verticalDecoration,
    required this.factoryDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VerticalModel>>(
      stream: verticalStream,
      builder: (context, verticalSnapshot) {
        final verticals = (verticalSnapshot.data ?? const <VerticalModel>[])
            .where((vertical) => vertical.isActive && !vertical.isDeleted)
            .toList(growable: false);
        final verticalLoading =
            verticalSnapshot.connectionState == ConnectionState.waiting &&
            !verticalSnapshot.hasData;

        return StreamBuilder<List<FactoryModel>>(
          stream: factoryStream,
          builder: (context, factorySnapshot) {
            final allFactories =
                (factorySnapshot.data ?? const <FactoryModel>[])
                    .where((factory) => factory.isActive && !factory.isDeleted)
                    .toList(growable: false);
            final factoryLoading =
                factorySnapshot.connectionState == ConnectionState.waiting &&
                !factorySnapshot.hasData;
            final allowedFactoryIds = factoryIdsForVerticals(
              verticals: verticals,
              selectedVerticalIds: selectedVerticalIds,
            );
            final factories = allFactories
                .where((factory) => allowedFactoryIds.contains(factory.id))
                .toList(growable: false);

            final verticalField = _AccessField(
              title: 'Vertical selection',
              mode: verticalMode,
              selectedIds: selectedVerticalIds,
              options: [
                for (final vertical in verticals)
                  _AccessOption(id: vertical.id, label: vertical.name),
              ],
              loading: verticalLoading,
              emptyMessage: 'No active verticals available',
              decoration: verticalDecoration,
              onModeChanged: (mode) {
                final nextVerticalIds = normalizeSelectionIds(
                  selectedVerticalIds,
                  mode,
                );
                final nextAllowedFactoryIds = factoryIdsForVerticals(
                  verticals: verticals,
                  selectedVerticalIds: nextVerticalIds,
                );
                onVerticalChanged(mode, nextVerticalIds);
                onFactoryChanged(
                  factoryMode,
                  normalizeSelectionIds(
                    selectedFactoryIds.where(nextAllowedFactoryIds.contains),
                    factoryMode,
                  ),
                );
              },
              onSelectionChanged: (ids) {
                final nextVerticalIds = normalizeSelectionIds(
                  ids,
                  verticalMode,
                );
                final nextAllowedFactoryIds = factoryIdsForVerticals(
                  verticals: verticals,
                  selectedVerticalIds: nextVerticalIds,
                );
                onVerticalChanged(verticalMode, nextVerticalIds);
                onFactoryChanged(
                  factoryMode,
                  normalizeSelectionIds(
                    selectedFactoryIds.where(nextAllowedFactoryIds.contains),
                    factoryMode,
                  ),
                );
              },
            );

            final factoryField = _AccessField(
              title: 'Factory selection',
              mode: factoryMode,
              selectedIds: selectedFactoryIds
                  .where(allowedFactoryIds.contains)
                  .toSet(),
              options: [
                for (final factory in factories)
                  _AccessOption(id: factory.id, label: factory.plantName),
              ],
              loading: factoryLoading,
              emptyMessage: selectedVerticalIds.isEmpty
                  ? 'Select a vertical first'
                  : 'No active factories mapped to selected verticals',
              decoration: factoryDecoration,
              onModeChanged: (mode) => onFactoryChanged(
                mode,
                normalizeSelectionIds(selectedFactoryIds, mode),
              ),
              onSelectionChanged: (ids) => onFactoryChanged(
                factoryMode,
                normalizeSelectionIds(ids, factoryMode),
              ),
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 860) {
                  return Column(
                    children: [
                      verticalField,
                      const SizedBox(height: 16),
                      factoryField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: verticalField),
                    const SizedBox(width: 16),
                    Expanded(child: factoryField),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AccessOption {
  final String id;
  final String label;

  const _AccessOption({required this.id, required this.label});
}

class _AccessField extends StatelessWidget {
  final String title;
  final AccessSelectionMode mode;
  final Set<String> selectedIds;
  final List<_AccessOption> options;
  final bool loading;
  final String emptyMessage;
  final InputDecoration decoration;
  final ValueChanged<AccessSelectionMode> onModeChanged;
  final ValueChanged<Set<String>> onSelectionChanged;

  const _AccessField({
    required this.title,
    required this.mode,
    required this.selectedIds,
    required this.options,
    required this.loading,
    required this.emptyMessage,
    required this.decoration,
    required this.onModeChanged,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabels = options
        .where((option) => selectedIds.contains(option.id))
        .map((option) => option.label)
        .toList(growable: false);
    final summary = loading
        ? 'Loading...'
        : selectedLabels.isEmpty
        ? options.isEmpty
              ? emptyMessage
              : mode == AccessSelectionMode.single
              ? 'Select one option'
              : 'Select one or more options'
        : selectedLabels.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            SegmentedButton<AccessSelectionMode>(
              segments: const [
                ButtonSegment(
                  value: AccessSelectionMode.single,
                  label: Text('Single'),
                ),
                ButtonSegment(
                  value: AccessSelectionMode.multiple,
                  label: Text('Multiple'),
                ),
              ],
              selected: {mode},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              onSelectionChanged: loading
                  ? null
                  : (selection) => onModeChanged(selection.first),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading || options.isEmpty ? null : () => _showPicker(context),
          child: InputDecorator(
            // The child always paints a placeholder. Marking this empty would
            // keep the label inline and paint it over that placeholder.
            isEmpty: false,
            decoration: decoration.copyWith(
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selectedLabels.isEmpty
                    ? const Color(0xFF64748B)
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final draft = Set<String>.from(selectedIds);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final optionList = ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final option = options[index];
              final selected = draft.contains(option.id);
              if (mode == AccessSelectionMode.single) {
                return RadioListTile<String>(
                  value: option.id,
                  title: Text(option.label),
                );
              }
              return CheckboxListTile(
                value: selected,
                title: Text(option.label),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setDialogState(() {
                    checked == true
                        ? draft.add(option.id)
                        : draft.remove(option.id);
                  });
                },
              );
            },
          );
          return AlertDialog(
            title: Text('Select $title'),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SizedBox(
              width: 430,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: mode == AccessSelectionMode.single
                    ? RadioGroup<String>(
                        groupValue: draft.isEmpty ? null : draft.first,
                        onChanged: (value) {
                          if (value == null) return;
                          Navigator.pop(dialogContext, <String>{value});
                        },
                        child: optionList,
                      )
                    : optionList,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              if (mode == AccessSelectionMode.multiple)
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, draft),
                  child: const Text('Apply'),
                ),
            ],
          );
        },
      ),
    );
    if (result != null) onSelectionChanged(result);
  }
}
