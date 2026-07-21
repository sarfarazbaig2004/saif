import 'package:flutter/material.dart';

import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_evaluator.dart';

class PermissionEditor extends StatelessWidget {
  final Set<String> selectedPermissions;
  final ValueChanged<Set<String>> onChanged;
  final Set<String>? visibleModuleIds;
  final bool readOnly;

  const PermissionEditor({
    super.key,
    required this.selectedPermissions,
    required this.onChanged,
    this.visibleModuleIds,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final selected = PermissionEvaluator.normalizeDependencies(
      selectedPermissions,
    );
    final modules = AmanPermissionCatalogue.modules
        .where(
          (module) =>
              visibleModuleIds == null || visibleModuleIds!.contains(module.id),
        )
        .toList(growable: false);

    return Column(
      children: modules
          .map(
            (module) => _ModulePermissionCard(
              module: module,
              selected: selected,
              readOnly: readOnly,
              onChanged: onChanged,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ModulePermissionCard extends StatelessWidget {
  final PermissionModuleDefinition module;
  final Set<String> selected;
  final bool readOnly;
  final ValueChanged<Set<String>> onChanged;

  const _ModulePermissionCard({
    required this.module,
    required this.selected,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final moduleKeys = <String>{
      for (final submodule in module.submodules)
        for (final action in submodule.actions) submodule.keyFor(action.id),
    };
    final selectedCount = moduleKeys.where(selected.contains).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('permission-module-${module.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Expanded(
              child: Text(
                module.displayName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '$selectedCount / ${moduleKeys.length} selected',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: readOnly
            ? null
            : Wrap(
                spacing: 6,
                children: [
                  TextButton(
                    onPressed: selectedCount == moduleKeys.length
                        ? null
                        : () => onChanged(
                            PermissionEvaluator.normalizeDependencies({
                              ...selected,
                              ...moduleKeys,
                            }),
                          ),
                    child: const Text('Select module'),
                  ),
                  TextButton(
                    onPressed: selectedCount == 0
                        ? null
                        : () => onChanged(selected.difference(moduleKeys)),
                    child: const Text('Clear module'),
                  ),
                ],
              ),
        children: module.submodules
            .map(
              (submodule) => _SubmodulePermissionCard(
                submodule: submodule,
                selected: selected,
                readOnly: readOnly,
                onChanged: onChanged,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SubmodulePermissionCard extends StatelessWidget {
  final PermissionSubmoduleDefinition submodule;
  final Set<String> selected;
  final bool readOnly;
  final ValueChanged<Set<String>> onChanged;

  const _SubmodulePermissionCard({
    required this.submodule,
    required this.selected,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final keys = {
      for (final action in submodule.actions) submodule.keyFor(action.id),
    };
    final selectedCount = keys.where(selected.contains).length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        submodule.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (submodule.needsReview) ...[
                      const SizedBox(width: 8),
                      const Tooltip(
                        message:
                            'This area is a placeholder or its workflow is incomplete.',
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            'Needs Review',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$selectedCount / ${keys.length}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              if (!readOnly) ...[
                const SizedBox(width: 6),
                PopupMenuButton<bool>(
                  tooltip: 'Submodule selection',
                  onSelected: (selectAll) => onChanged(
                    selectAll
                        ? PermissionEvaluator.normalizeDependencies({
                            ...selected,
                            ...keys,
                          })
                        : selected.difference(keys),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: true, child: Text('Select all')),
                    PopupMenuItem(value: false, child: Text('Clear')),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: submodule.actions
                .map((action) {
                  final key = submodule.keyFor(action.id);
                  final isSelected = selected.contains(key);
                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: true,
                    label: Text(action.displayName),
                    tooltip: action.description,
                    onSelected: readOnly
                        ? null
                        : (value) {
                            Set<String> next;
                            if (value) {
                              next = PermissionEvaluator.normalizeDependencies({
                                ...selected,
                                key,
                              });
                            } else if (action.id == PermissionActionIds.view) {
                              next =
                                  PermissionEvaluator.withoutViewAndDependents(
                                    selected,
                                    key,
                                  );
                            } else {
                              next = selected.toSet()..remove(key);
                            }
                            onChanged(next);
                          },
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
