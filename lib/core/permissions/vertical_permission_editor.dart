import 'package:flutter/material.dart';

import 'package:QUIK/core/permissions/permission_editor.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';

class VerticalPermissionEditor extends StatefulWidget {
  final Stream<List<VerticalModel>> verticalStream;
  final Set<String> selectedVerticalIds;
  final Map<String, Set<String>> permissionsByVertical;
  final Set<String> fallbackPermissions;
  final Set<String>? visibleModuleIds;
  final ValueChanged<Map<String, Set<String>>> onChanged;

  const VerticalPermissionEditor({
    super.key,
    required this.verticalStream,
    required this.selectedVerticalIds,
    required this.permissionsByVertical,
    required this.fallbackPermissions,
    required this.onChanged,
    this.visibleModuleIds,
  });

  @override
  State<VerticalPermissionEditor> createState() =>
      _VerticalPermissionEditorState();
}

class _VerticalPermissionEditorState extends State<VerticalPermissionEditor> {
  String? _activeVerticalId;
  late Map<String, Set<String>> _assignments;
  late final ValueNotifier<Map<String, int>> _permissionCounts;

  @override
  void initState() {
    super.initState();
    _assignments = _copyAssignments(widget.permissionsByVertical);
    _permissionCounts = ValueNotifier(_countsFor(_assignments));
  }

  @override
  void didUpdateWidget(covariant VerticalPermissionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _assignments = _copyAssignments(widget.permissionsByVertical);
    _permissionCounts.value = _countsFor(_assignments);
  }

  @override
  void dispose() {
    _permissionCounts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VerticalModel>>(
      stream: widget.verticalStream,
      builder: (context, snapshot) {
        final verticals = (snapshot.data ?? const <VerticalModel>[])
            .where((vertical) => !vertical.isDeleted)
            .toList(growable: false);
        final verticalById = <String, VerticalModel>{
          for (final vertical in verticals) vertical.id: vertical,
        };
        final selectedIds = <String>[
          for (final vertical in verticals)
            if (widget.selectedVerticalIds.contains(vertical.id)) vertical.id,
          for (final id in widget.selectedVerticalIds)
            if (!verticalById.containsKey(id)) id,
        ];

        if (selectedIds.isEmpty) {
          return _NoVerticalPermissions(
            fallbackPermissions: widget.fallbackPermissions,
            visibleModuleIds: widget.visibleModuleIds,
          );
        }

        final activeId = selectedIds.contains(_activeVerticalId)
            ? _activeVerticalId!
            : selectedIds.first;
        final activeName =
            verticalById[activeId]?.name.trim().isNotEmpty == true
            ? verticalById[activeId]!.name.trim()
            : activeId;
        final activeSelection = _assignments[activeId] ?? const <String>{};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permissions for selected verticals',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a vertical, then configure its module permissions independently.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ValueListenableBuilder<Map<String, int>>(
                    valueListenable: _permissionCounts,
                    builder: (context, counts, _) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final verticalId in selectedIds)
                          ChoiceChip(
                            selected: verticalId == activeId,
                            showCheckmark: false,
                            avatar: Icon(
                              Icons.account_tree_outlined,
                              size: 17,
                              color: verticalId == activeId
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF64748B),
                            ),
                            label: Text(
                              '${verticalById[verticalId]?.name ?? verticalId}  •  '
                              '${counts[verticalId] ?? 0} selected',
                            ),
                            selectedColor: const Color(0xFFDBEAFE),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: verticalId == activeId
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFDCE4EE),
                            ),
                            labelStyle: TextStyle(
                              color: verticalId == activeId
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setState(() {
                              _activeVerticalId = verticalId;
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Text(
                'Editing permissions for $activeName',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PermissionEditor(
              key: ValueKey<String>('vertical-permissions-$activeId'),
              selectedPermissions: activeSelection,
              visibleModuleIds: widget.visibleModuleIds,
              onChanged: (value) {
                final next = <String, Set<String>>{
                  for (final entry in _assignments.entries)
                    entry.key: Set<String>.from(entry.value),
                  activeId: Set<String>.from(value),
                };
                _assignments = next;
                _permissionCounts.value = _countsFor(next);
                widget.onChanged(_copyAssignments(next));
              },
            ),
          ],
        );
      },
    );
  }

  static Map<String, Set<String>> _copyAssignments(
    Map<String, Set<String>> value,
  ) {
    return <String, Set<String>>{
      for (final entry in value.entries)
        entry.key: Set<String>.from(entry.value),
    };
  }

  static Map<String, int> _countsFor(Map<String, Set<String>> value) {
    return <String, int>{
      for (final entry in value.entries) entry.key: entry.value.length,
    };
  }
}

class _NoVerticalPermissions extends StatelessWidget {
  final Set<String> fallbackPermissions;
  final Set<String>? visibleModuleIds;

  const _NoVerticalPermissions({
    required this.fallbackPermissions,
    required this.visibleModuleIds,
  });

  @override
  Widget build(BuildContext context) {
    if (fallbackPermissions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Text(
              'Legacy company-wide permissions are shown below. Select a vertical above to start vertical-wise access.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PermissionEditor(
            selectedPermissions: fallbackPermissions,
            visibleModuleIds: visibleModuleIds,
            readOnly: true,
            onChanged: (_) {},
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_tree_outlined, size: 30, color: Color(0xFF64748B)),
          SizedBox(height: 10),
          Text(
            'Select at least one vertical above to configure its permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
