import 'package:flutter/material.dart';

class PoAmendmentDialog extends StatefulWidget {
  const PoAmendmentDialog({super.key});

  @override
  State<PoAmendmentDialog> createState() => _PoAmendmentDialogState();
}

class _PoAmendmentDialogState extends State<PoAmendmentDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();

    if (reason.isEmpty) return;

    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Amended PO'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Amendment Reason',
          hintText: 'Customer revised quantity/specification/rate',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
