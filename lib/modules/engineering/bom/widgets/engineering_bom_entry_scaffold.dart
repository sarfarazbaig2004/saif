import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_app_bar_actions.dart';

class EngineeringBomEntryScaffold extends StatelessWidget {
  final bool dirty;
  final bool saving;
  final bool readOnly;
  final Future<bool> Function() confirmDiscard;
  final ValueChanged<String> onGenerateQuotation;
  final VoidCallback onRefreshMaterials;
  final VoidCallback onCreateRevision;
  final VoidCallback onSaveDraft;
  final VoidCallback onSave;
  final Widget child;

  const EngineeringBomEntryScaffold({
    super.key,
    required this.dirty,
    required this.saving,
    required this.readOnly,
    required this.confirmDiscard,
    required this.onGenerateQuotation,
    required this.onRefreshMaterials,
    required this.onCreateRevision,
    required this.onSaveDraft,
    required this.onSave,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: zCanvasBg,
        appBar: AppBar(
          title: const Text('Engineering BOM'),
          actions: [
            EngineeringBomAppBarActions(
              saving: saving,
              readOnly: readOnly,
              onGenerateQuotation: onGenerateQuotation,
              onRefreshMaterials: onRefreshMaterials,
              onCreateRevision: onCreateRevision,
              onSaveDraft: onSaveDraft,
              onSave: onSave,
            ),
          ],
        ),
        body: SafeArea(child: child),
      ),
    );
  }
}
