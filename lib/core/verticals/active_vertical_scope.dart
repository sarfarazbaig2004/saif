import 'package:flutter/widgets.dart';

import 'package:QUIK/core/permissions/permission_evaluator.dart';

class ActiveVerticalOption {
  final String id;
  final String name;

  const ActiveVerticalOption({required this.id, required this.name});
}

class ActiveVerticalState {
  final List<ActiveVerticalOption> availableVerticals;
  final String? activeVerticalId;
  final bool allowAllVerticals;
  final bool isLegacyUnscoped;

  const ActiveVerticalState({
    required this.availableVerticals,
    required this.activeVerticalId,
    required this.allowAllVerticals,
    required this.isLegacyUnscoped,
  });

  factory ActiveVerticalState.resolve({
    required Map<String, dynamic> userData,
    required Iterable<ActiveVerticalOption> allActiveVerticals,
    required String? requestedVerticalId,
    required bool isFullAccess,
  }) {
    final allVerticals = allActiveVerticals
        .where((vertical) => vertical.id.trim().isNotEmpty)
        .toList(growable: false);
    final assignedIds = _readStringSet(userData['verticalIds']);
    final isLegacyUnscoped = !isFullAccess && assignedIds.isEmpty;
    final availableVerticals = isFullAccess
        ? allVerticals
        : allVerticals
              .where((vertical) => assignedIds.contains(vertical.id))
              .toList(growable: false);

    final requested = (requestedVerticalId ?? '').trim();
    final requestedIsAvailable = availableVerticals.any(
      (vertical) => vertical.id == requested,
    );

    String? activeVerticalId;
    if (requestedIsAvailable) {
      activeVerticalId = requested;
    } else if (!isFullAccess && availableVerticals.isNotEmpty) {
      activeVerticalId = availableVerticals.first.id;
    }

    return ActiveVerticalState(
      availableVerticals: List.unmodifiable(availableVerticals),
      activeVerticalId: activeVerticalId,
      allowAllVerticals: isFullAccess,
      isLegacyUnscoped: isLegacyUnscoped,
    );
  }

  bool get isDataScoped => (activeVerticalId ?? '').isNotEmpty;

  bool get hasUnavailableAssignments =>
      !allowAllVerticals && !isLegacyUnscoped && availableVerticals.isEmpty;

  String get activeVerticalName {
    final activeId = activeVerticalId;
    if (activeId == null) return '';
    for (final vertical in availableVerticals) {
      if (vertical.id == activeId) return vertical.name;
    }
    return '';
  }

  PermissionEvaluator permissionEvaluatorFor(Map<String, dynamic> userData) {
    final activeId = activeVerticalId;
    if (activeId != null && activeId.isNotEmpty) {
      final assignments = userData['verticalPermissions'];
      final assignment = assignments is Map ? assignments[activeId] : null;
      if (assignment is Map && assignment.containsKey('permissions')) {
        return PermissionEvaluator.fromUserDataForVertical(
          userData,
          verticalId: activeId,
        );
      }
      return PermissionEvaluator.fromExplicit(
        permissions: const <String, dynamic>{},
        role: (userData['role'] ?? '').toString(),
      );
    }

    if (allowAllVerticals || isLegacyUnscoped) {
      return PermissionEvaluator.fromUserData(userData);
    }

    return PermissionEvaluator.fromExplicit(
      permissions: const <String, dynamic>{},
      role: (userData['role'] ?? '').toString(),
    );
  }

  bool canAccessRecord(String? recordVerticalId) {
    if (!isDataScoped) {
      return allowAllVerticals || isLegacyUnscoped;
    }
    return (recordVerticalId ?? '').trim() == activeVerticalId;
  }

  static Set<String> _readStringSet(dynamic value) {
    if (value is! Iterable) return const <String>{};
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }
}

class ActiveVerticalScope extends InheritedWidget {
  final ActiveVerticalState state;

  const ActiveVerticalScope({
    super.key,
    required this.state,
    required super.child,
  });

  static ActiveVerticalState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ActiveVerticalScope>()
        ?.state;
  }

  static ActiveVerticalState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No ActiveVerticalScope exists above this context.');
    return state!;
  }

  @override
  bool updateShouldNotify(ActiveVerticalScope oldWidget) {
    return state.activeVerticalId != oldWidget.state.activeVerticalId ||
        state.allowAllVerticals != oldWidget.state.allowAllVerticals ||
        state.isLegacyUnscoped != oldWidget.state.isLegacyUnscoped ||
        state.availableVerticals.length !=
            oldWidget.state.availableVerticals.length;
  }
}
