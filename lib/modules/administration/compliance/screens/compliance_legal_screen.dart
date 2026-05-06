import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/administration/compliance/models/compliance_document_model.dart';
import 'package:QUIK/modules/administration/compliance/services/compliance_document_service.dart';

class ComplianceLegalScreen extends StatefulWidget {
  const ComplianceLegalScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
    required this.currentUserEmail,
    required this.currentRole,
  });

  final String tenantId;
  final String currentUserUid;
  final String currentUserEmail;
  final String currentRole;

  @override
  State<ComplianceLegalScreen> createState() => _ComplianceLegalScreenState();
}

class _ComplianceLegalScreenState extends State<ComplianceLegalScreen> {
  late final ComplianceDocumentService _service;
  ComplianceDocumentCategory? _categoryFilter;
  ComplianceExpiryStatus? _statusFilter;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _service = ComplianceDocumentService(tenantId: widget.tenantId);
  }

  String get _role => widget.currentRole.trim().toLowerCase();

  bool get _isAdmin {
    return _role == 'software_super_admin' ||
        _role == 'company_super_admin' ||
        _role == 'owner' ||
        _role == 'admin' ||
        _role == 'manager';
  }

  List<ComplianceDocumentCategory> get _allowedCategories {
    if (_isAdmin) return ComplianceDocumentCategory.values;
    if (_role == 'finance') return const [ComplianceDocumentCategory.financial];
    if (_role == 'hr') return const [ComplianceDocumentCategory.hr];
    if (_role == 'production' || _role == 'qa') {
      return const [ComplianceDocumentCategory.quality];
    }
    return const [];
  }

  List<ComplianceDocumentType> get _allowedTypes {
    final categories = _allowedCategories.toSet();
    return ComplianceDocumentType.values
        .where((type) => categories.contains(type.category))
        .toList(growable: false);
  }

  bool _canSee(ComplianceDocumentModel document) {
    return _allowedCategories.contains(document.category);
  }

  @override
  Widget build(BuildContext context) {
    if (_allowedCategories.isEmpty) {
      return _accessDenied();
    }

    return StreamBuilder<List<ComplianceDocumentModel>>(
      stream: _service.watchDocuments(allowedCategories: _allowedCategories),
      builder: (context, snapshot) {
        final allDocuments = snapshot.data ?? const <ComplianceDocumentModel>[];
        final visibleDocuments = allDocuments
            .where(_canSee)
            .where((document) {
              final categoryMatches =
                  _categoryFilter == null ||
                  document.category == _categoryFilter;
              final statusMatches =
                  _statusFilter == null ||
                  document.expiryStatus == _statusFilter;
              return categoryMatches && statusMatches;
            })
            .toList(growable: false);

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  isSaving: _isSaving,
                  onUpload: _showUploadDialog,
                  compact: compact,
                ),
                const SizedBox(height: 12),
                _SummaryStrip(documents: allDocuments.where(_canSee).toList()),
                const SizedBox(height: 12),
                _Filters(
                  allowedCategories: _allowedCategories,
                  categoryFilter: _categoryFilter,
                  statusFilter: _statusFilter,
                  onCategoryChanged: (value) {
                    setState(() => _categoryFilter = value);
                  },
                  onStatusChanged: (value) {
                    setState(() => _statusFilter = value);
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(
                          child: CircularProgressIndicator(color: zBlue),
                        )
                      : _DocumentList(
                          documents: visibleDocuments,
                          compact: compact,
                          onOpen: _openDocument,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _accessDenied() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: zBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 34, color: zMuted),
            SizedBox(height: 12),
            Text(
              'Compliance access unavailable',
              style: TextStyle(
                color: zText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your role does not include compliance document visibility.',
              textAlign: TextAlign.center,
              style: TextStyle(color: zMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUploadDialog() async {
    final docNoCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    ComplianceDocumentType selectedType = _allowedTypes.first;
    DateTime? issueDate;
    DateTime? expiryDate;
    PlatformFile? pickedFile;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate({
              required DateTime? current,
              required ValueChanged<DateTime> onPicked,
            }) async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: current ?? now,
                firstDate: DateTime(1990),
                lastDate: DateTime(now.year + 25),
              );
              if (picked != null) onPicked(picked);
            }

            return AlertDialog(
              title: const Text('Upload Compliance Document'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<ComplianceDocumentType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                        ),
                        items: _allowedTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedType = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: docNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Document No',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: 'Issue Date',
                              value: issueDate,
                              onTap: () => pickDate(
                                current: issueDate,
                                onPicked: (date) {
                                  setDialogState(() => issueDate = date);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateButton(
                              label: 'Expiry Date',
                              value: expiryDate,
                              onTap: () => pickDate(
                                current: expiryDate,
                                onPicked: (date) {
                                  setDialogState(() => expiryDate = date);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: remarksCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Remarks'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            withData: true,
                            type: FileType.custom,
                            allowedExtensions: const [
                              'pdf',
                              'png',
                              'jpg',
                              'jpeg',
                              'doc',
                              'docx',
                              'xls',
                              'xlsx',
                            ],
                          );
                          final file = result?.files.single;
                          if (file == null) return;
                          setDialogState(() => pickedFile = file);
                        },
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(
                          pickedFile?.name ?? 'Choose file',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final file = pickedFile;
    final bytes = file?.bytes;
    if (docNoCtrl.text.trim().isEmpty || file == null || bytes == null) {
      _showSnack('Document no and file upload are required.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final documentId = _service.newDocumentId();
      final upload = await _service.uploadFile(
        documentId: documentId,
        fileName: file.name,
        bytes: bytes,
      );
      await _service.saveDocument(
        ComplianceDocumentModel(
          id: documentId,
          tenantId: widget.tenantId,
          documentType: selectedType,
          documentNo: docNoCtrl.text.trim(),
          issueDate: issueDate,
          expiryDate: expiryDate,
          remarks: remarksCtrl.text.trim(),
          fileName: upload.fileName,
          fileUrl: upload.fileUrl,
          storagePath: upload.storagePath,
          uploadedBy: widget.currentUserUid,
          uploadedByEmail: widget.currentUserEmail,
          createdAt: null,
          updatedAt: null,
        ),
      );
      _showSnack('Compliance document uploaded.');
    } catch (e) {
      _showSnack('Failed to upload document: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openDocument(ComplianceDocumentModel document) async {
    final uri = Uri.tryParse(document.fileUrl);
    if (uri == null) {
      _showSnack('Document file link is unavailable.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _showSnack('Unable to open document.');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isSaving,
    required this.onUpload,
    required this.compact,
  });

  final bool isSaving;
  final VoidCallback onUpload;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Compliance & Legal',
          style: TextStyle(
            color: zText,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'GST, PAN, MSME, licenses, ISO, PF/ESIC, audits and balance sheets',
          style: TextStyle(
            color: zMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final action = FilledButton.icon(
      onPressed: isSaving ? null : onUpload,
      icon: isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file_outlined),
      label: const Text('Upload'),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 12), action],
            )
          : Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: zBlueSoft,
                  child: Icon(Icons.gavel_outlined, color: zBlue),
                ),
                const SizedBox(width: 12),
                Expanded(child: title),
                action,
              ],
            ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.documents});

  final List<ComplianceDocumentModel> documents;

  @override
  Widget build(BuildContext context) {
    final active = documents
        .where((doc) => doc.expiryStatus == ComplianceExpiryStatus.active)
        .length;
    final soon = documents
        .where((doc) => doc.expiryStatus == ComplianceExpiryStatus.expiringSoon)
        .length;
    final expired = documents
        .where((doc) => doc.expiryStatus == ComplianceExpiryStatus.expired)
        .length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryTile(
          label: 'Total Docs',
          value: documents.length.toString(),
          color: zBlue,
          icon: Icons.folder_copy_outlined,
        ),
        _SummaryTile(
          label: 'Active',
          value: active.toString(),
          color: zSuccess,
          icon: Icons.check_circle_outline,
        ),
        _SummaryTile(
          label: 'Expiring Soon',
          value: soon.toString(),
          color: zOrange,
          icon: Icons.schedule_outlined,
        ),
        _SummaryTile(
          label: 'Expired',
          value: expired.toString(),
          color: zDanger,
          icon: Icons.error_outline,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.allowedCategories,
    required this.categoryFilter,
    required this.statusFilter,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  final List<ComplianceDocumentCategory> allowedCategories;
  final ComplianceDocumentCategory? categoryFilter;
  final ComplianceExpiryStatus? statusFilter;
  final ValueChanged<ComplianceDocumentCategory?> onCategoryChanged;
  final ValueChanged<ComplianceExpiryStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<ComplianceDocumentCategory?>(
            initialValue: categoryFilter,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              ...allowedCategories.map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                ),
              ),
            ],
            onChanged: onCategoryChanged,
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<ComplianceExpiryStatus?>(
            initialValue: statusFilter,
            decoration: const InputDecoration(labelText: 'Expiry Alert'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Alerts')),
              ...ComplianceExpiryStatus.values.map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              ),
            ],
            onChanged: onStatusChanged,
          ),
        ),
      ],
    );
  }
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.documents,
    required this.compact,
    required this.onOpen,
  });

  final List<ComplianceDocumentModel> documents;
  final bool compact;
  final ValueChanged<ComplianceDocumentModel> onOpen;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(
        child: Text(
          'No compliance documents found.',
          style: TextStyle(color: zMuted, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (compact) {
      return ListView.separated(
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _DocumentCard(document: documents[index], onOpen: onOpen);
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: zMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          dataTextStyle: const TextStyle(
            color: zText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          columns: const [
            DataColumn(label: Text('Document')),
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Issue')),
            DataColumn(label: Text('Expiry')),
            DataColumn(label: Text('Alert')),
            DataColumn(label: Text('File')),
          ],
          rows: documents.map((document) {
            return DataRow(
              cells: [
                DataCell(Text(document.documentType.label)),
                DataCell(Text(document.documentNo)),
                DataCell(Text(_dateLabel(document.issueDate))),
                DataCell(Text(_dateLabel(document.expiryDate))),
                DataCell(_StatusPill(status: document.expiryStatus)),
                DataCell(
                  IconButton(
                    tooltip: 'Open file',
                    onPressed: () => onOpen(document),
                    icon: const Icon(Icons.open_in_new, size: 18),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.onOpen});

  final ComplianceDocumentModel document;
  final ValueChanged<ComplianceDocumentModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  document.documentType.label,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(status: document.expiryStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No: ${document.documentNo}',
            style: const TextStyle(color: zMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Issue ${_dateLabel(document.issueDate)} • Expiry ${_dateLabel(document.expiryDate)}',
            style: const TextStyle(color: zMuted, fontWeight: FontWeight.w600),
          ),
          if (document.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(document.remarks, style: const TextStyle(color: zText)),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => onOpen(document),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(
              document.fileName.isEmpty ? 'Open File' : document.fileName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ComplianceExpiryStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      ComplianceExpiryStatus.active => (bg: zSuccessSoft, fg: zSuccess),
      ComplianceExpiryStatus.expiringSoon => (bg: zOrangeSoft, fg: zOrange),
      ComplianceExpiryStatus.expired => (bg: zDangerSoft, fg: zDanger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.fg,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(_dateLabel(value)),
      ),
    );
  }
}

String _dateLabel(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('dd MMM yyyy').format(date);
}
