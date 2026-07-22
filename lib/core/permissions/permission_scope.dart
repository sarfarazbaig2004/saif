import 'package:flutter/material.dart';

import 'package:QUIK/core/permissions/permission_evaluator.dart';

class PermissionScope extends InheritedWidget {
  final PermissionEvaluator evaluator;

  const PermissionScope({
    super.key,
    required this.evaluator,
    required super.child,
  });

  static PermissionEvaluator? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PermissionScope>()
        ?.evaluator;
  }

  static PermissionEvaluator of(BuildContext context) {
    final evaluator = maybeOf(context);
    assert(evaluator != null, 'No PermissionScope exists above this context.');
    return evaluator!;
  }

  static bool can(BuildContext context, String permissionKey) {
    return maybeOf(context)?.hasPermission(permissionKey) ?? false;
  }

  static bool require(
    BuildContext context,
    String permissionKey, {
    String message = 'You do not have permission to perform this action.',
  }) {
    if (can(context, permissionKey)) return true;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
    return false;
  }

  @override
  bool updateShouldNotify(PermissionScope oldWidget) {
    return evaluator.role != oldWidget.evaluator.role ||
        evaluator.hasExplicitPermissions !=
            oldWidget.evaluator.hasExplicitPermissions ||
        evaluator.permissions.length !=
            oldWidget.evaluator.permissions.length ||
        !evaluator.permissions.containsAll(oldWidget.evaluator.permissions);
  }
}
