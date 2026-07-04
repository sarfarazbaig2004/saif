import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/administration/compliance/models/compliance_document_model.dart';
import 'package:QUIK/modules/administration/compliance/services/compliance_document_service.dart';

import 'package:QUIK/core/utils/file_upload_limits.dart';

enum _QmsDocumentBucket { all, iso, inspection }

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
  _QmsDocumentBucket _qmsBucket = _QmsDocumentBucket.all;
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

  bool get _canDeleteNormalCompliance {
    return _role == 'software_super_admin' || _role == 'company_super_admin';
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

  bool _matchesQmsBucket(ComplianceDocumentModel document) {
    switch (_qmsBucket) {
      case _QmsDocumentBucket.all:
        return true;
      case _QmsDocumentBucket.iso:
        return document.tags.any((tag) => tag.isIsoQmsTag);
      case _QmsDocumentBucket.inspection:
        return document.tags.any((tag) => tag.isInspectionTag);
    }
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
                    ) &&
                    _matchesQmsBucket(document);
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
                                    canDelete: _canDeleteNormalCompliance,
                                    onView: _showDocumentDetails,
                                    onOpen: _openDocument,
                                    onEdit: _showEditDialog,
                                    onArchive: _archiveDocument,
                                    onDelete: _deleteNormalDocument,
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
                              selectedBucket: _qmsBucket,
                              canApprove: _canApproveQms,
                              compact: compact,
                              onBucketChanged: (value) {
                                setState(() => _qmsBucket = value);
                              },
                              onShowHistoryChanged: (value) {
                                setState(() => _showQmsHistory = value);
                              },
                              onOpen: _openDocument,
                              onView: _showDocumentDetails,
                              onEdit: _showEditDialog,
                              onNewRevision: _showQmsRevisionDialog,
                              onApprove: _approveQmsDocument,
                              onArchive: _archiveDocument,
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
        ? _qualityTagsForBucket(_qmsBucket)
        : _allowedTags;
    if (dialogTags.isEmpty) {
      _showSnack('No document categories are available for this role.');
      return;
    }

    final defaultTag = dialogTags.first;
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

                          if (result != null &&
                              hasFileOverUploadLimit(result.files)) {
                            _showSnack(maxUploadFileSizeMessage);
                            return;
                          }

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

  List<ComplianceDocumentTag> _qualityTagsForBucket(_QmsDocumentBucket bucket) {
    final qualityTags = _allowedTags.where((tag) {
      return tag.accessCategory == ComplianceAccessCategory.quality;
    });

    switch (bucket) {
      case _QmsDocumentBucket.iso:
        return qualityTags
            .where((tag) => tag.isIsoQmsTag)
            .toList(growable: false);
      case _QmsDocumentBucket.inspection:
        return qualityTags
            .where((tag) => tag.isInspectionTag)
            .toList(growable: false);
      case _QmsDocumentBucket.all:
        return qualityTags.toList(growable: false);
    }
  }

  _QmsDocumentBucket _bucketForDocument(ComplianceDocumentModel document) {
    final hasIso = document.tags.any((tag) => tag.isIsoQmsTag);
    final hasInspection = document.tags.any((tag) => tag.isInspectionTag);
    if (hasIso && !hasInspection) return _QmsDocumentBucket.iso;
    if (hasInspection && !hasIso) return _QmsDocumentBucket.inspection;
    return _QmsDocumentBucket.all;
  }

  Future<void> _openDocument(ComplianceDocumentModel document) async {
    String url = '';
    try {
      url = await _service.resolveDownloadUrl(document);
    } catch (e) {
      _showSnack('Unable to prepare document link: $e');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('Document file link is unavailable.');
      return;
    }
    final opened = kIsWeb
        ? await launchUrl(uri, webOnlyWindowName: '_blank')
        : await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _showSnack('Unable to open document.');
  }

  Future<void> _showDocumentDetails(ComplianceDocumentModel document) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document.title.isEmpty ? 'Document' : document.title),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailLine('Categories', document.tagLabel),
                  _DetailLine('Document No', document.documentNo),
                  _DetailLine('Issue Date', _dateLabel(document.issueDate)),
                  _DetailLine('Expiry Date', _dateLabel(document.expiryDate)),
                  _DetailLine(
                    'Amendment Date',
                    _dateLabel(document.amendmentDate),
                  ),
                  _DetailLine('Status', document.status.label),
                  if (document.isQmsDocument) ...[
                    _DetailLine('Rev No', document.revisionNo),
                    _DetailLine('Previous Rev', document.previousRevision),
                    _DetailLine('QMS Status', document.qmsApprovalStatus.label),
                    _DetailLine('Approved By', document.approvedBy),
                    _DetailLine(
                      'Approval Date',
                      _dateLabel(document.approvalDate),
                    ),
                    _DetailLine('Obsolete', document.isObsolete ? 'Yes' : 'No'),
                  ],
                  _DetailLine('File URL', document.fileUrl),
                  _DetailLine('Storage Path', document.storagePath),
                  if (document.remarks.isNotEmpty)
                    _DetailLine('Remarks', document.remarks),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openDocument(document);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open File'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showQmsRevisionDialog(ComplianceDocumentModel document) {
    return _showUploadDialog(isQmsDocument: true, baseRevision: document);
  }

  Future<void> _showEditDialog(ComplianceDocumentModel document) async {
    final titleCtrl = TextEditingController(text: document.title);
    final docNoCtrl = TextEditingController(text: document.documentNo);
    final remarksCtrl = TextEditingController(text: document.remarks);
    final revisionCtrl = TextEditingController(text: document.revisionNo);
    final previousRevisionCtrl = TextEditingController(
      text: document.previousRevision,
    );
    var validityType = document.validityType;
    var manualStatus = document.manualStatus;
    var qmsStatus = document.qmsApprovalStatus;
    var issueDate = document.issueDate;
    var expiryDate = document.expiryDate;
    var amendmentDate = document.amendmentDate;
    var selectedTags = document.tags.where(_allowedTags.contains).toSet();
    if (selectedTags.isEmpty && _allowedTags.isNotEmpty) {
      selectedTags = {_allowedTags.first};
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate({
              required DateTime? current,
              required ValueChanged<DateTime?> onPicked,
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

            final editableTags = document.isQmsDocument
                ? _qualityTagsForBucket(_bucketForDocument(document))
                : _allowedTags;

            return AlertDialog(
              title: Text(
                document.isQmsDocument
                    ? 'Edit QMS Metadata'
                    : 'Edit Document Metadata',
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
                          children: editableTags.map((tag) {
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
                      if (document.isQmsDocument) ...[
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
                                  initialValue: manualStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
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
                                    setDialogState(() => manualStatus = value);
                                  },
                                ),
                          ),
                        ],
                      ),
                      if (document.isQmsDocument) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<QmsApprovalStatus>(
                          initialValue: qmsStatus,
                          decoration: const InputDecoration(
                            labelText: 'QMS Workflow Status',
                          ),
                          items: QmsApprovalStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: _canApproveQms
                              ? (value) {
                                  if (value == null) return;
                                  setDialogState(() => qmsStatus = value);
                                }
                              : null,
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: remarksCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Remarks'),
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
    if (titleCtrl.text.trim().isEmpty ||
        docNoCtrl.text.trim().isEmpty ||
        selectedTags.isEmpty) {
      _showSnack('Title, document no and category are required.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.saveDocument(
        ComplianceDocumentModel(
          id: document.id,
          tenantId: widget.tenantId,
          title: titleCtrl.text.trim(),
          tags: selectedTags.toList(growable: false),
          validityType: validityType,
          manualStatus: amendmentDate != null
              ? ComplianceDocumentStatus.updated
              : manualStatus,
          documentNo: docNoCtrl.text.trim(),
          issueDate: issueDate,
          expiryDate: expiryDate,
          amendmentDate: amendmentDate,
          remarks: remarksCtrl.text.trim(),
          fileName: document.fileName,
          fileUrl: document.fileUrl,
          storagePath: document.storagePath,
          uploadedBy: document.uploadedBy,
          uploadedByEmail: document.uploadedByEmail,
          isQmsDocument: document.isQmsDocument,
          revisionNo: document.isQmsDocument ? revisionCtrl.text.trim() : '',
          previousRevision: document.isQmsDocument
              ? previousRevisionCtrl.text.trim()
              : '',
          approvedBy: document.approvedBy,
          approvalDate: document.approvalDate,
          isObsolete: document.isObsolete,
          qmsApprovalStatus: document.isQmsDocument
              ? qmsStatus
              : QmsApprovalStatus.approved,
          createdAt: document.createdAt,
          updatedAt: document.updatedAt,
        ),
      );
      _showSnack('Document metadata updated.');
    } catch (e) {
      _showSnack('Failed to update metadata: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  Future<void> _archiveDocument(ComplianceDocumentModel document) async {
    if (document.isQmsDocument && !_canApproveQms) {
      _showSnack('Only QA or admin can archive QMS revisions.');
      return;
    }

    if (!document.isQmsDocument && document.isObsolete) {
      _showSnack('Document is already archived.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.archiveDocument(document);
      _showSnack(
        document.isQmsDocument
            ? 'QMS revision marked obsolete.'
            : 'Compliance document archived.',
      );
    } catch (e) {
      _showSnack('Failed to archive document: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNormalDocument(ComplianceDocumentModel document) async {
    if (!_canDeleteNormalCompliance || document.isQmsDocument) {
      _showSnack('This document cannot be deleted.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete compliance document?'),
          content: Text(
            'This removes ${document.title.isEmpty ? document.documentNo : document.title} and its uploaded file. QMS revision history cannot be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: zDanger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await _service.deleteNormalComplianceDocument(document);
      _showSnack('Compliance document deleted.');
    } catch (e) {
      _showSnack('Failed to delete document: $e');
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

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: zMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            displayValue,
            style: const TextStyle(
              color: zText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    required this.selectedBucket,
    required this.canApprove,
    required this.compact,
    required this.onBucketChanged,
    required this.onShowHistoryChanged,
    required this.onView,
    required this.onOpen,
    required this.onEdit,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final List<ComplianceDocumentModel> documents;
  final bool showHistory;
  final _QmsDocumentBucket selectedBucket;
  final bool canApprove;
  final bool compact;
  final ValueChanged<_QmsDocumentBucket> onBucketChanged;
  final ValueChanged<bool> onShowHistoryChanged;
  final ValueChanged<ComplianceDocumentModel> onView;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onEdit;
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
              SegmentedButton<_QmsDocumentBucket>(
                segments: const [
                  ButtonSegment(
                    value: _QmsDocumentBucket.all,
                    label: Text('All'),
                    icon: Icon(Icons.folder_copy_outlined),
                  ),
                  ButtonSegment(
                    value: _QmsDocumentBucket.iso,
                    label: Text('QMS / ISO'),
                    icon: Icon(Icons.rule_folder_outlined),
                  ),
                  ButtonSegment(
                    value: _QmsDocumentBucket.inspection,
                    label: Text('Inspections'),
                    icon: Icon(Icons.fact_check_outlined),
                  ),
                ],
                selected: {selectedBucket},
                onSelectionChanged: (selection) {
                  onBucketChanged(selection.first);
                },
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
                      onView: onView,
                      onOpen: onOpen,
                      onEdit: onEdit,
                      onNewRevision: onNewRevision,
                      onApprove: onApprove,
                      onArchive: onArchive,
                    );
                  },
                )
              : _QmsRevisionTable(
                  documents: documents,
                  canApprove: canApprove,
                  onView: onView,
                  onOpen: onOpen,
                  onEdit: onEdit,
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
    required this.onView,
    required this.onOpen,
    required this.onEdit,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final List<ComplianceDocumentModel> documents;
  final bool canApprove;
  final ValueChanged<ComplianceDocumentModel> onView;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onEdit;
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
                      onView: onView,
                      onOpen: onOpen,
                      onEdit: onEdit,
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
    required this.onView,
    required this.onOpen,
    required this.onEdit,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final ComplianceDocumentModel document;
  final bool canApprove;
  final ValueChanged<ComplianceDocumentModel> onView;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onEdit;
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
            onView: onView,
            onOpen: onOpen,
            onEdit: onEdit,
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
    required this.onView,
    required this.onOpen,
    required this.onEdit,
    required this.onNewRevision,
    required this.onApprove,
    required this.onArchive,
  });

  final ComplianceDocumentModel document;
  final bool canApprove;
  final ValueChanged<ComplianceDocumentModel> onView;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onEdit;
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
          tooltip: 'View details',
          onPressed: () => onView(document),
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'Edit metadata',
          onPressed: () => onEdit(document),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'New revision',
          onPressed: () => onNewRevision(document),
          icon: const Icon(Icons.add_circle_outline, size: 18),
        ),
        IconButton(
          tooltip: 'Open file',
          onPressed: () => onOpen(document),
          icon: const Icon(Icons.open_in_new, size: 18),
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
    required this.canDelete,
    required this.onView,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final List<ComplianceDocumentModel> documents;
  final bool compact;
  final bool canDelete;
  final ValueChanged<ComplianceDocumentModel> onView;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onEdit;
  final ValueChanged<ComplianceDocumentModel> onArchive;
  final ValueChanged<ComplianceDocumentModel> onDelete;

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
          return _DocumentCard(
            document: documents[index],
            canDelete: canDelete,
            onView: onView,
            onOpen: onOpen,
            onEdit: onEdit,
            onArchive: onArchive,
            onDelete: onDelete,
          );
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
              DataColumn(label: Text('Actions')),
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
                    _ComplianceActions(
                      document: document,
                      canDelete: canDelete,
                      onView: onView,
                      onOpen: onOpen,
                      onEdit: onEdit,
                      onArchive: onArchive,
                      onDelete: onDelete,
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
  const _DocumentCard({
    required this.document,
    required this.canDelete,
    required this.onView,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final ComplianceDocumentModel document;
  final bool canDelete;
  final ValueChanged<ComplianceDocumentModel> onView;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onEdit;
  final ValueChanged<ComplianceDocumentModel> onArchive;
  final ValueChanged<ComplianceDocumentModel> onDelete;

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
          _ComplianceActions(
            document: document,
            canDelete: canDelete,
            onView: onView,
            onOpen: onOpen,
            onEdit: onEdit,
            onArchive: onArchive,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ComplianceActions extends StatelessWidget {
  const _ComplianceActions({
    required this.document,
    required this.canDelete,
    required this.onView,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final ComplianceDocumentModel document;
  final bool canDelete;
  final ValueChanged<ComplianceDocumentModel> onView;
  final ValueChanged<ComplianceDocumentModel> onOpen;
  final ValueChanged<ComplianceDocumentModel> onEdit;
  final ValueChanged<ComplianceDocumentModel> onArchive;
  final ValueChanged<ComplianceDocumentModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        IconButton(
          tooltip: 'View details',
          onPressed: () => onView(document),
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'Edit metadata',
          onPressed: () => onEdit(document),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'Open file',
          onPressed: () => onOpen(document),
          icon: const Icon(Icons.open_in_new, size: 18),
        ),
        IconButton(
          tooltip: 'Archive / obsolete',
          onPressed: () => onArchive(document),
          icon: const Icon(Icons.archive_outlined, size: 18),
        ),
        if (canDelete)
          IconButton(
            tooltip: 'Delete document',
            onPressed: () => onDelete(document),
            icon: const Icon(Icons.delete_outline, size: 18, color: zDanger),
          ),
      ],
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
