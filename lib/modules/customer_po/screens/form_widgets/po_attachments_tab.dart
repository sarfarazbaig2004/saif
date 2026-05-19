import 'package:flutter/material.dart';

class PoAttachmentsTab extends StatelessWidget {
  final Widget pdfUploadWidget;

  const PoAttachmentsTab({super.key, required this.pdfUploadWidget});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [pdfUploadWidget],
    );
  }
}
