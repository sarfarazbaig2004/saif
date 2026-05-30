import 'package:flutter/material.dart';

Future<String?> askEngineeringBomRevisionReason(BuildContext context) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Create Revision'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Revision Reason',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Create Revision'),
        ),
      ],
    ),
  );
  controller.dispose();
  return reason == null || reason.trim().isEmpty ? null : reason.trim();
}
