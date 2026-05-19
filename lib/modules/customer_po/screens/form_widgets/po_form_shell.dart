import 'package:flutter/material.dart';

class PoFormShell extends StatelessWidget {
  final bool isEditMode;
  final bool isSaving;
  final VoidCallback onSave;
  final GlobalKey<FormState> formKey;
  final Widget body;

  const PoFormShell({
    super.key,
    required this.isEditMode,
    required this.isSaving,
    required this.onSave,
    required this.formKey,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? 'Edit Customer PO' : 'Create Customer PO'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: isSaving ? null : onSave,
                child: Text(isEditMode ? 'Update' : 'Save'),
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Commercial'),
              Tab(text: 'Project Split'),
              Tab(text: 'Engineering'),
              Tab(text: 'Terms'),
              Tab(text: 'Attachments'),
            ],
          ),
        ),
        body: Form(key: formKey, child: body),
      ),
    );
  }
}
