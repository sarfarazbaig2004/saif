import 'package:flutter/material.dart';

class PoProjectSplitTab extends StatelessWidget {
  final TextEditingController projectName;
  final TextEditingController siteLocation;
  final TextEditingController subject;
  final Widget Function(
    String label,
    TextEditingController controller, {
    int maxLines,
    TextInputType keyboardType,
    bool required,
    bool readOnly,
  })
  fieldBuilder;

  const PoProjectSplitTab({
    super.key,
    required this.projectName,
    required this.siteLocation,
    required this.subject,
    required this.fieldBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        fieldBuilder('Project Name', projectName),
        const SizedBox(height: 12),
        fieldBuilder('Site Location', siteLocation),
        const SizedBox(height: 12),
        fieldBuilder('Subject / Scope', subject, maxLines: 3),
      ],
    );
  }
}
