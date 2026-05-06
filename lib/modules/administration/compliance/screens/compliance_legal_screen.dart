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

class _ComplianceLegalScreenState extends State<ComplianceLegalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ComplianceDocumentService _service;
  ComplianceAccessCategory? _categoryFilter;
  ComplianceDocumentStatus? _statusFilter;
  bool _showQmsHistory = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = ComplianceDocumentService(tenantId: widget.tenantId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _role => widget.currentRole.trim().toLowerCase();

  bool get _isAdmin {
    return _role == 'software_super_admin' ||
        _role == 'company_super_admin' ||
        _role == 'owner' ||
        _role == 'admin' ||
        _role == 'manager';
  }

  bool get _canApproveQms {
    return _isAdmin || _role == 'qa';
  }

  List<ComplianceAccessCategory> get _allowedCategories {
    if (_isAdmin) return ComplianceAccessCategory.values;
    if (_role == 'finance') return const [ComplianceAccessCategory.financial];
    if (_role == 'hr') return const [ComplianceAccessCategory.hr];
    if (_role == 'production' || _role == 'qa') {
      return const [ComplianceAccessCategory.quality];
    }
    return const [];
  }

  List<ComplianceDocumentTag> get _allowedTags {
    final categories = _allowedCategories.toSet();
    return ComplianceDocumentTag.values
        .where((tag) => categories.contains(tag.accessCategory))
        .toList(growable: false);
  }

  bool _canSee(ComplianceDocumentModel document) {
    return _allowedCategories.any(document.hasAccessCategory);
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
        final registerDocuments = allDocuments
            .where(_canSee)
            .where((document) => !document.isQmsDocument)
            .where((document) {
              final categoryMatches =
                  _categoryFilter == null ||
                  document.hasAccessCategory(_categoryFilter!);
              final statusMatches =
                  _statusFilter == null || document.status == _statusFilter;
              return categoryMatches && statusMatches;
            })
            .toList(growable: false);
        final qmsDocuments = _qmsDisplayDocuments(
          allDocuments
              .where(_canSee)
              .where((document) {
                return document.isQmsDocument &&
                    document.hasAccessCategory(
                      ComplianceAccessCategory.quality,
                    );
              })
              .toList(growable: false),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  isSaving: _isSaving,
                  onUpload: () => _showUploadDialog(isQmsDocument: false),
                  onUploadQms:
                      _allowedCategories.contains(
                        ComplianceAccessCategory.quality,
                      )
                      ? () => _showUploadDialog(isQmsDocument: true)
                      : null,
                  compact: compact,
                ),
                const SizedBox(height: 12),
                _SectionTabs(controller: _tabController),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SummaryStrip(documents: registerDocuments),
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
                            child:
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: zBlue,
                                    ),
                                  )
                                : _DocumentList(
                                    documents: registerDocuments,
                                    compact: compact,
                                    onOpen: _openDocument,
                                  ),
                          ),
                        ],
                      ),
                      snapshot.connectionState == ConnectionState.waiting
                          ? const Center(
                              child: CircularProgressIndicator(color: zBlue),
                            )
                          : _QmsDocumentControlSection(
                              documents: qmsDocuments,
                              showHistory: _showQmsHistory,
                              canApprove: _canApproveQms,
                              compact: compact,
                              onShowHistoryChanged: (value) {
                                setState(() => _showQmsHistory = value);
                              },
                              onOpen: _openDocument,
                              onNewRevision: _showQmsRevisionDialog,
                              onApprove: _approveQmsDocument,
                              onArchive: _archiveQmsDocument,
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<ComplianceDocumentModel> _qmsDisplayDocuments(
    List<ComplianceDocumentModel> documents,
  ) {
    if (_showQmsHistory) {
      return documents..sort(_compareQmsDocuments);
    }

    final latestByKey = <String, ComplianceDocumentModel>{};
    for (final document in documents.where(
      (document) =>
          document.qmsApprovalStatus == QmsApprovalStatus.approved &&
          !document.isObsolete,
    )) {
      final current = latestByKey[document.qmsKey];
      if (current == null ||
          document.revisionSortValue > current.revisionSortValue ||
          (document.revisionSortValue == current.revisionSortValue &&
              (document.approvalDate ?? DateTime(1900)).isAfter(
                current.approvalDate ?? DateTime(1900),
              ))) {
        latestByKey[document.qmsKey] = document;
      }
    }

    return latestByKey.values.toList(growable: false)
      ..sort(_compareQmsDocuments);
  }

  int _compareQmsDocuments(
    ComplianceDocumentModel a,
    ComplianceDocumentModel b,
  ) {
    final titleCompare = a.title.compareTo(b.title);
    if (titleCompare != 0) return titleCompare;
    return b.revisionSortValue.compareTo(a.revisionSortValue);
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

  Future<void> _showUploadDialog({
    required bool isQmsDocument,
    ComplianceDocumentModel? baseRevision,
  }) async {
    final titleCtrl = TextEditingController();
    final docNoCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    ComplianceValidityType validityType = ComplianceValidityType.expiryBased;
    ComplianceDocumentStatus selectedStatus = ComplianceDocumentStatus.active;
    final dialogTags = isQmsDocument
        ? _allowedTags
              .where(
                (tag) => tag.accessCategory == ComplianceAccessCategory.quality,
              )
              .toList(growable: false)
        : _allowedTags;
    final defaultTag = isQmsDocument
        ? ComplianceDocumentTag.iso
        : dialogTags.first;
    final selectedTags = <ComplianceDocumentTag>{
      ...?baseRevision?.tags,
      defaultTag,
    }.where(dialogTags.contains).toSet();
    DateTime? issueDate;
    DateTime? expiryDate;
    DateTime? amendmentDate;
    final revisionCtrl = TextEditingController();
    final previousRevisionCtrl = TextEditingController();
    PlatformFile? pickedFile;

    if (baseRevision != null) {
      titleCtrl.text = baseRevision.title;
      docNoCtrl.text = baseRevision.documentNo;
      validityType = baseRevision.validityType;
      previousRevisionCtrl.text = baseRevision.revisionNo;
      final nextRevision = baseRevision.revisionSortValue + 1;
      revisionCtrl.text = nextRevision <= 0
          ? '01'
          : nextRevision.toString().padLeft(2, '0');
    } else if (isQmsDocument) {
      revisionCtrl.text = '00';
    }

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
              title: Text(
                isQmsDocument
                    ? 'Upload QMS / ISO Revision'
                    : 'Upload Compliance Document',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 560,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Document Title',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<ComplianceValidityType>(
                        initialValue: validityType,
                        decoration: const InputDecoration(
                          labelText: 'Validity Type',
                        ),
                        items: ComplianceValidityType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => validityType = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Document Categories',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: dialogTags.map((tag) {
                            final selected = selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(tag.label),
                              selected: selected,
                              onSelected: (value) {
                                setDialogState(() {
                                  if (value) {
                                    selectedTags.add(tag);
                                  } else if (selectedTags.length > 1) {
                                    selectedTags.remove(tag);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: docNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Document No / QMS Code',
                        ),
                      ),
                      if (isQmsDocument) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: revisionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Rev No',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: previousRevisionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Previous Revision',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                              label: 'Expiry Date Optional',
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
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: 'Amendment Date Optional',
                              value: amendmentDate,
                              onTap: () => pickDate(
                                current: amendmentDate,
                                onPicked: (date) {
                                  setDialogState(() => amendmentDate = date);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child:
                                DropdownButtonFormField<
                                  ComplianceDocumentStatus
                                >(
                                  initialValue: selectedStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'Amendment Status',
                                  ),
                                  items:
                                      const [
                                            ComplianceDocumentStatus.active,
                                            ComplianceDocumentStatus
                                                .amendmentRequired,
                                            ComplianceDocumentStatus.updated,
                                          ]
                                          .map(
                                            (status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status.label),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setDialogState(
                                      () => selectedStatus = value,
                                    );
                                  },
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
    if (titleCtrl.text.trim().isEmpty ||
        docNoCtrl.text.trim().isEmpty ||
        selectedTags.isEmpty ||
        file == null ||
        bytes == null) {
      _showSnack('Title, document no, category and file upload are required.');
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
          title: titleCtrl.text.trim(),
          tags: selectedTags.toList(growable: false),
          validityType: validityType,
          manualStatus: amendmentDate != null
              ? ComplianceDocumentStatus.updated
              : selectedStatus,
          documentNo: docNoCtrl.text.trim(),
          issueDate: issueDate,
          expiryDate: expiryDate,
          amendmentDate: amendmentDate,
          remarks: remarksCtrl.text.trim(),
          fileName: upload.fileName,
          fileUrl: upload.fileUrl,
          storagePath: upload.storagePath,
          uploadedBy: widget.currentUserUid,
          uploadedByEmail: widget.currentUserEmail,
          isQmsDocument: isQmsDocument,
          revisionNo: isQmsDocument ? revisionCtrl.text.trim() : '',
          previousRevision: isQmsDocument
              ? previousRevisionCtrl.text.trim()
              : '',
          approvedBy: '',
          approvalDate: null,
          isObsolete: false,
          qmsApprovalStatus: isQmsDocument
              ? QmsApprovalStatus.pendingApproval
              : QmsApprovalStatus.approved,
          createdAt: null,
          updatedAt: null,
        ),
      );
      _showSnack(
        isQmsDocument
            ? 'QMS revision uploaded for approval.'
            : 'Compliance document uploaded.',
      );
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

  Future<void> _showQmsRevisionDialog(ComplianceDocumentModel document) {
    return _showUploadDialog(isQmsDocument: true, baseRevision: document);
  }

  Future<void> _approveQmsDocument(ComplianceDocumentModel document) async {
    if (!_canApproveQms) {
      _showSnack('Only QA or admin can approve QMS revisions.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.approveDocument(
        document: document,
        approvedBy: widget.currentUserEmail,
        approvalDate: DateTime.now(),
      );
      _showSnack('QMS revision approved.');
    } catch (e) {
      _showSnack('Failed to approve revision: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _archiveQmsDocument(ComplianceDocumentModel document) async {
    if (!_canApproveQms) {
      _showSnack('Only QA or admin can archive QMS revisions.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.archiveDocument(document);
      _showSnack('QMS revision marked obsolete.');
    } catch (e) {
      _showSnack('Failed to archive revision: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    required this.onUploadQms,
    required this.compact,
  });

  final bool isSaving;
  final VoidCallback onUpload;
  final VoidCallback? onUploadQms;
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
          'GST, PAN, Aadhaar, MSME, licenses, ISO, PF, ESIC and audit files',
          style: TextStyle(
            color: zMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final uploadAction = FilledButton.icon(
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
    final qmsAction = OutlinedButton.icon(
      onPressed: isSaving ? null : onUploadQms,
      icon: const Icon(Icons.rule_folder_outlined),
      label: const Text('QMS Revision'),
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [if (onUploadQms != null) qmsAction, uploadAction],
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
              children: [title, const SizedBox(height: 12), actions],
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
                actions,
              ],
            ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        labelColor: zBlue,
        unselectedLabelColor: zMuted,
        indicatorColor: zBlue,
        tabs: const [
          Tab(text: 'Compliance Register'),
          Tab(text: 'QMS / ISO Control'),
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
        .where((doc) => doc.status == ComplianceDocumentStatus.active)
        .length;
    final soon = documents
        .where((doc) => doc.status == ComplianceDocumentStatus.expiringSoon)
        .length;
    final expired = documents
        .where((doc) => doc.status == ComplianceDocumentStatus.expired)
        .length;
    final amendmentRequired = documents
        .where(
          (doc) => doc.status == ComplianceDocumentStatus.amendmentRequired,
        )
        .length;
    final updated = documents
        .where((doc) => doc.status == ComplianceDocumentStatus.updated)
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
        _SummaryTile(
          label: 'Amendment Required',
          value: amendmentRequired.toString(),
          color: zPurple,
          icon: Icons.edit_calendar_outlined,
        ),
        _SummaryTile(
          label: 'Updated',
          value: updated.toString(),
          color: zInfo,
          icon: Icons.verified_outlined,
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

  final List<ComplianceAccessCategory> allowedCategories;
  final ComplianceAccessCategory? categoryFilter;
  final ComplianceDocumentStatus? statusFilter;
  final ValueChanged<ComplianceAccessCategory?> onCategoryChanged;
  final ValueChanged<ComplianceDocumentStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<ComplianceAccessCategory?>(
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
          child: DropdownButtonFormField<ComplianceDocumentStatus?>(
            initialValue: statusFilter,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ...ComplianceDocumentStatus.values.map(
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

class _QmsDocumentControlSection extends StatelessWidget {
  const _QmsDocumentControlSection({
    required this.documents,
    required this.showHistory,
    required this.canApprove,
    required this.compact,
    required this.onShowHistoryChanged,
    required this.onOpen,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final List<ComplianceDocumentModel> documents;
  final bool showHistory;
  final bool canApprove;
  final bool compact;
  final ValueChanged<bool> onShowHistoryChanged;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onNewRevision;
  final ValueChanged<ComplianceDocumentModel> onApprove;
  final ValueChanged<ComplianceDocumentModel> onArchive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: zBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rule_folder_outlined, color: zBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Latest approved revisions are shown by default',
                    style: TextStyle(color: zText, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              FilterChip(
                selected: showHistory,
                label: const Text('Show revision history'),
                onSelected: onShowHistoryChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: documents.isEmpty
              ? const Center(
                  child: Text(
                    'No QMS / ISO documents found.',
                    style: TextStyle(
                      color: zMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : compact
              ? ListView.separated(
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _QmsRevisionCard(
                      document: documents[index],
                      canApprove: canApprove,
                      onOpen: onOpen,
                      onNewRevision: onNewRevision,
                      onApprove: onApprove,
                      onArchive: onArchive,
                    );
                  },
                )
              : _QmsRevisionTable(
                  documents: documents,
                  canApprove: canApprove,
                  onOpen: onOpen,
                  onNewRevision: onNewRevision,
                  onApprove: onApprove,
                  onArchive: onArchive,
                ),
        ),
      ],
    );
  }
}

class _QmsRevisionTable extends StatelessWidget {
  const _QmsRevisionTable({
    required this.documents,
    required this.canApprove,
    required this.onOpen,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final List<ComplianceDocumentModel> documents;
  final bool canApprove;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onNewRevision;
  final ValueChanged<ComplianceDocumentModel> onApprove;
  final ValueChanged<ComplianceDocumentModel> onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
              DataColumn(label: Text('QMS Code')),
              DataColumn(label: Text('Rev')),
              DataColumn(label: Text('Previous')),
              DataColumn(label: Text('Approved By')),
              DataColumn(label: Text('Approval Date')),
              DataColumn(label: Text('Workflow')),
              DataColumn(label: Text('Actions')),
            ],
            rows: documents.map((document) {
              return DataRow(
                cells: [
                  DataCell(Text(document.title)),
                  DataCell(Text(document.documentNo)),
                  DataCell(Text(document.revisionNo)),
                  DataCell(
                    Text(
                      document.previousRevision.isEmpty
                          ? '-'
                          : document.previousRevision,
                    ),
                  ),
                  DataCell(
                    Text(
                      document.approvedBy.isEmpty ? '-' : document.approvedBy,
                    ),
                  ),
                  DataCell(Text(_dateLabel(document.approvalDate))),
                  DataCell(_QmsWorkflowPill(document: document)),
                  DataCell(
                    _QmsActions(
                      document: document,
                      canApprove: canApprove,
                      onOpen: onOpen,
                      onNewRevision: onNewRevision,
                      onApprove: onApprove,
                      onArchive: onArchive,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _QmsRevisionCard extends StatelessWidget {
  const _QmsRevisionCard({
    required this.document,
    required this.canApprove,
    required this.onOpen,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final ComplianceDocumentModel document;
  final bool canApprove;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onNewRevision;
  final ValueChanged<ComplianceDocumentModel> onApprove;
  final ValueChanged<ComplianceDocumentModel> onArchive;

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
                  document.title,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _QmsWorkflowPill(document: document),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${document.documentNo} • Rev ${document.revisionNo}',
            style: const TextStyle(color: zMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Previous ${document.previousRevision.isEmpty ? '-' : document.previousRevision} • Approved ${_dateLabel(document.approvalDate)}',
            style: const TextStyle(color: zMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _QmsActions(
            document: document,
            canApprove: canApprove,
            onOpen: onOpen,
            onNewRevision: onNewRevision,
            onApprove: onApprove,
            onArchive: onArchive,
          ),
        ],
      ),
    );
  }
}

class _QmsActions extends StatelessWidget {
  const _QmsActions({
    required this.document,
    required this.canApprove,
    required this.onOpen,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final ComplianceDocumentModel document;
  final bool canApprove;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onNewRevision;
  final ValueChanged<ComplianceDocumentModel> onApprove;
  final ValueChanged<ComplianceDocumentModel> onArchive;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        IconButton(
          tooltip: 'Open file',
          onPressed: () => onOpen(document),
          icon: const Icon(Icons.open_in_new, size: 18),
        ),
        IconButton(
          tooltip: 'New revision',
          onPressed: () => onNewRevision(document),
          icon: const Icon(Icons.add_circle_outline, size: 18),
        ),
        if (canApprove &&
            document.qmsApprovalStatus != QmsApprovalStatus.approved)
          IconButton(
            tooltip: 'Approve revision',
            onPressed: () => onApprove(document),
            icon: const Icon(Icons.verified_outlined, size: 18),
          ),
        if (canApprove && !document.isObsolete)
          IconButton(
            tooltip: 'Archive / obsolete',
            onPressed: () => onArchive(document),
            icon: const Icon(Icons.archive_outlined, size: 18),
          ),
      ],
    );
  }
}

class _QmsWorkflowPill extends StatelessWidget {
  const _QmsWorkflowPill({required this.document});

  final ComplianceDocumentModel document;

  @override
  Widget build(BuildContext context) {
    final label = document.isObsolete
        ? 'Obsolete'
        : document.qmsApprovalStatus.label;
    final colors = document.isObsolete
        ? (bg: zDangerSoft, fg: zDanger)
        : switch (document.qmsApprovalStatus) {
            QmsApprovalStatus.approved => (bg: zSuccessSoft, fg: zSuccess),
            QmsApprovalStatus.pendingApproval => (bg: zOrangeSoft, fg: zOrange),
            QmsApprovalStatus.draft => (bg: zBlueSoft, fg: zBlue),
            QmsApprovalStatus.rejected => (bg: zDangerSoft, fg: zDanger),
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.fg,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
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
        scrollDirection: Axis.horizontal,
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
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Categories')),
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Issue')),
              DataColumn(label: Text('Expiry')),
              DataColumn(label: Text('Amendment')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('File')),
            ],
            rows: documents.map((document) {
              return DataRow(
                cells: [
                  DataCell(Text(document.title.isEmpty ? '-' : document.title)),
                  DataCell(Text(document.tagLabel)),
                  DataCell(Text(document.documentNo)),
                  DataCell(Text(_dateLabel(document.issueDate))),
                  DataCell(Text(_dateLabel(document.expiryDate))),
                  DataCell(Text(_dateLabel(document.amendmentDate))),
                  DataCell(_StatusPill(status: document.status)),
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
                  document.title.isEmpty ? document.tagLabel : document.title,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(status: document.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            document.tagLabel,
            style: const TextStyle(color: zMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'No: ${document.documentNo}',
            style: const TextStyle(color: zMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Issue ${_dateLabel(document.issueDate)} • Expiry ${_dateLabel(document.expiryDate)}',
            style: const TextStyle(color: zMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Amendment ${_dateLabel(document.amendmentDate)}',
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

  final ComplianceDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      ComplianceDocumentStatus.active => (bg: zSuccessSoft, fg: zSuccess),
      ComplianceDocumentStatus.expiringSoon => (bg: zOrangeSoft, fg: zOrange),
      ComplianceDocumentStatus.expired => (bg: zDangerSoft, fg: zDanger),
      ComplianceDocumentStatus.amendmentRequired => (
        bg: zPurpleSoft,
        fg: zPurple,
      ),
      ComplianceDocumentStatus.updated => (bg: zInfoSoft, fg: zInfo),
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
