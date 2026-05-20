import 'package:flutter/material.dart';

class PoPdfUploadCard extends StatelessWidget {
  final String? fileName;
  final bool isUploading;
  final VoidCallback onPickPdf;
  final VoidCallback? onUploadAmendedPdf;
  final VoidCallback onRemovePdf;
  final VoidCallback? onOpenPdf;

  const PoPdfUploadCard({
    super.key,
    required this.fileName,
    required this.isUploading,
    required this.onPickPdf,
    this.onUploadAmendedPdf,
    required this.onRemovePdf,
    this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PO Document (PDF)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (fileName != null)
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onOpenPdf != null)
                    TextButton.icon(
                      onPressed: onOpenPdf,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open'),
                    ),
                  if (onUploadAmendedPdf != null)
                    TextButton.icon(
                      onPressed: isUploading ? null : onUploadAmendedPdf,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Amend'),
                    ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onRemovePdf,
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: isUploading ? null : onPickPdf,
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(isUploading ? 'Uploading…' : 'Select PDF'),
              ),
          ],
        ),
      ),
    );
  }
}
