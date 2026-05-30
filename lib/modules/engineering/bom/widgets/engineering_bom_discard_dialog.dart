import 'package:flutter/material.dart';

Future<bool> confirmDiscardEngineeringBomChanges(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Leave without saving?'),
      content: const Text('Unsaved Engineering BOM changes will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Stay'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return leave == true;
}
