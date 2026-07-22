import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_evaluator.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF64748B);
const _blue = Color(0xFF3478F6);
const _blueInk = Color(0xFF173E8F);
const _blueWash = Color(0xFFE8F1FF);
const _moduleFill = Color(0xFFF8FAFC);
const _border = Color(0xFFDCE4EE);
const _openChevron = Color(0xFFF97316);

/// Shared MEMCO-style employee permission editor.
///
/// Selection state is localized here so a chip click does not rebuild the
/// entire Invite/Edit screen. Each module has its own notifier and collapsed
/// module bodies are created lazily.
class PermissionEditor extends StatefulWidget {
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
  State<PermissionEditor> createState() => _PermissionEditorState();
}

class _PermissionEditorState extends State<PermissionEditor> {
  late final _PermissionSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _PermissionSelectionController(
      selected: widget.selectedPermissions,
      onChanged: widget.onChanged,
    );
  }

  @override
  void didUpdateWidget(covariant PermissionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.onChanged = widget.onChanged;
    if (!setEquals(widget.selectedPermissions, _controller.selected)) {
      _controller.replaceAll(widget.selectedPermissions, notifyParent: false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modules = AmanPermissionCatalogue.modules.where(
      (module) =>
          widget.visibleModuleIds == null ||
          widget.visibleModuleIds!.contains(module.id),
    );

    return Column(
      children: [
        for (final module in modules)
          RepaintBoundary(
            child: _ModulePermissionCard(
              key: PageStorageKey<String>('permission-module-${module.id}'),
              module: module,
              selection: _controller.selectionFor(module.id),
              readOnly: widget.readOnly,
              onChanged: (value) => _controller.replaceModule(module.id, value),
            ),
          ),
      ],
    );
  }
}

class _PermissionSelectionController {
  Set<String> _selected;
  ValueChanged<Set<String>> onChanged;
  final Map<String, ValueNotifier<Set<String>>> _moduleSelections = {};

  _PermissionSelectionController({
    required Set<String> selected,
    required this.onChanged,
  }) : _selected = PermissionEvaluator.normalizeDependencies(selected);

  Set<String> get selected => _selected;

  ValueListenable<Set<String>> selectionFor(String moduleId) {
    return _moduleSelections.putIfAbsent(
      moduleId,
      () => ValueNotifier(_selectionForModule(moduleId)),
    );
  }

  void replaceModule(String moduleId, Set<String> moduleSelection) {
    final prefix = '$moduleId.';
    replaceAll({
      for (final key in _selected)
        if (!key.startsWith(prefix)) key,
      ...moduleSelection,
    });
  }

  void replaceAll(Iterable<String> value, {bool notifyParent = true}) {
    final next = PermissionEvaluator.normalizeDependencies(value);
    if (setEquals(next, _selected)) return;

    final affectedModules = <String>{
      for (final key in _selected.difference(next)) key.split('.').first,
      for (final key in next.difference(_selected)) key.split('.').first,
    };
    _selected = next;

    for (final moduleId in affectedModules) {
      final notifier = _moduleSelections[moduleId];
      if (notifier != null) {
        notifier.value = _selectionForModule(moduleId);
      }
    }

    if (notifyParent) onChanged(Set.unmodifiable(_selected));
  }

  Set<String> _selectionForModule(String moduleId) {
    final prefix = '$moduleId.';
    return Set.unmodifiable(_selected.where((key) => key.startsWith(prefix)));
  }

  void dispose() {
    for (final notifier in _moduleSelections.values) {
      notifier.dispose();
    }
  }
}

class _ModulePermissionCard extends StatefulWidget {
  final PermissionModuleDefinition module;
  final ValueListenable<Set<String>> selection;
  final bool readOnly;
  final ValueChanged<Set<String>> onChanged;

  const _ModulePermissionCard({
    super.key,
    required this.module,
    required this.selection,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  State<_ModulePermissionCard> createState() => _ModulePermissionCardState();
}

class _ModulePermissionCardState extends State<_ModulePermissionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final moduleKeys = <String>{
      for (final submodule in widget.module.submodules)
        for (final action in submodule.actions) submodule.keyFor(action.id),
    };

    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.selection,
      builder: (context, selected, _) {
        final selectedCount = moduleKeys.where(selected.contains).length;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _moduleFill,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Semantics(
                button: true,
                expanded: _expanded,
                label: '${widget.module.displayName} permissions',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 78),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.module.displayName,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            _SelectionCountPill(
                              selected: selectedCount,
                              total: moduleKeys.length,
                            ),
                            const SizedBox(width: 18),
                            AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _expanded ? _openChevron : _ink,
                                size: 25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                  child: Column(
                    children: [
                      for (final submodule in widget.module.submodules)
                        _SubmodulePermissionCard(
                          submodule: submodule,
                          selected: selected,
                          readOnly: widget.readOnly,
                          onChanged: widget.onChanged,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectionCountPill extends StatelessWidget {
  final int selected;
  final int total;

  const _SelectionCountPill({required this.selected, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected > 0 ? const Color(0xFFDBEAFE) : const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$selected / $total selected',
        style: TextStyle(
          color: selected > 0 ? const Color(0xFF1857C9) : _muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
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
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (submodule.needsReview) ...[
                      const SizedBox(width: 8),
                      const Tooltip(
                        message:
                            'This workflow is incomplete or needs confirmation.',
                        child: _NeedsReviewBadge(),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$selectedCount / ${keys.length}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final action in submodule.actions)
                _PermissionActionChip(
                  label: action.displayName,
                  description: action.description,
                  selected: selected.contains(submodule.keyFor(action.id)),
                  enabled: !readOnly,
                  onTap: () {
                    final key = submodule.keyFor(action.id);
                    Set<String> next;
                    if (!selected.contains(key)) {
                      next = PermissionEvaluator.normalizeDependencies({
                        ...selected,
                        key,
                      });
                    } else if (action.id == PermissionActionIds.view) {
                      next = PermissionEvaluator.withoutViewAndDependents(
                        selected,
                        key,
                      );
                    } else {
                      next = selected.toSet()..remove(key);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionActionChip extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PermissionActionChip({
    required this.label,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? _blueWash : Colors.white,
          border: Border.all(color: selected ? _blue : _border, width: 1.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: selected ? _blue : Colors.white,
                        shape: BoxShape.circle,
                        border: selected
                            ? null
                            : Border.all(color: _muted, width: 1.5),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? _blueInk : _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedsReviewBadge extends StatelessWidget {
  const _NeedsReviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Text(
        'Needs Review',
        style: TextStyle(
          color: Color(0xFFC2410C),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
