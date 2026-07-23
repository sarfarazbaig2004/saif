import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class LetterheadSettingsScreen extends StatefulWidget {
  final String companyId;
  final bool canEdit;
  final String currentUserName;

  const LetterheadSettingsScreen({
    super.key,
    required this.companyId,
    required this.canEdit,
    required this.currentUserName,
  });

  @override
  State<LetterheadSettingsScreen> createState() =>
      _LetterheadSettingsScreenState();
}

class _LetterheadSettingsScreenState extends State<LetterheadSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _domestic = _LetterheadForm.domestic();
  final _export = _LetterheadForm.export();

  bool _loading = true;
  bool _saving = false;
  String? _uploadingType;

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('settings')
          .doc('letterhead_settings');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _domestic.dispose();
    _export.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snapshot = await _settingsRef.get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      if (data['domestic'] is Map) {
        _domestic.load(Map<String, dynamic>.from(data['domestic'] as Map));
      }
      if (data['export'] is Map) {
        _export.load(Map<String, dynamic>.from(data['export'] as Map));
      }
    } catch (error) {
      _snack('Unable to load letterhead settings: $error', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadLetterhead(
    String type,
    _LetterheadForm form,
  ) async {
    if (!widget.canEdit || _saving || _uploadingType != null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    final extension = (file.extension ?? '').toLowerCase();
    if (bytes == null || bytes.isEmpty) {
      _snack('The selected file could not be read.', isError: true);
      return;
    }
    if (!const ['png', 'jpg', 'jpeg', 'pdf'].contains(extension)) {
      _snack('Only PNG, JPG, JPEG, or PDF files are allowed.', isError: true);
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      _snack('Letterhead file must be 5 MB or smaller.', isError: true);
      return;
    }

    setState(() => _uploadingType = type);
    try {
      final safeName = file.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final path =
          'companies/${widget.companyId}/letterhead_settings/$type/'
          '${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final reference = FirebaseStorage.instance.ref(path);
      await reference.putData(
        bytes,
        SettableMetadata(contentType: _contentType(extension)),
      );
      final url = await reference.getDownloadURL();

      if (!mounted) return;
      setState(() {
        form.letterheadUrl = url;
        form.letterheadFileName = file.name;
        form.letterheadFileType = extension;
      });
      _snack(
        extension == 'pdf'
            ? 'PDF uploaded. PNG or JPG is recommended for direct PDF backgrounds.'
            : 'Letterhead uploaded successfully.',
      );
    } catch (error) {
      _snack('Letterhead upload failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  String _contentType(String extension) {
    if (extension == 'pdf') return 'application/pdf';
    if (extension == 'png') return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _save() async {
    if (!widget.canEdit || _saving || _uploadingType != null) return;
    setState(() => _saving = true);
    try {
      await _settingsRef.set({
        'domestic': _domestic.toMap(),
        'export': _export.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updatedByName': widget.currentUserName,
      }, SetOptions(merge: true));
      _snack('Letterhead settings saved.');
    } catch (error) {
      _snack('Letterhead settings could not be saved: $error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        enabled: widget.canEdit,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _form(String type, _LetterheadForm form) {
    final uploading = _uploadingType == type;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'domestic'
                    ? 'Domestic Letterhead Settings'
                    : 'Export Letterhead Settings',
                style: const TextStyle(
                  color: zText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                type == 'domestic'
                    ? 'Applied to domestic quotation documents.'
                    : 'Applied to export quotation documents.',
                style: const TextStyle(color: zMuted),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: zBlueSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: zBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                form.letterheadFileName.isEmpty
                                    ? 'No letterhead uploaded'
                                    : form.letterheadFileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: zText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (form.letterheadFileType.isNotEmpty)
                                Text(
                                  form.letterheadFileType.toUpperCase(),
                                  style: const TextStyle(
                                    color: zMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: widget.canEdit &&
                                  !_saving &&
                                  _uploadingType == null
                              ? () => _uploadLetterhead(type, form)
                              : null,
                          icon: uploading
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(uploading ? 'Uploading...' : 'Upload'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: form.letterheadUrl.isEmpty
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: form.letterheadUrl.isEmpty
                              ? Colors.orange.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Text(
                        form.letterheadUrl.isEmpty
                            ? 'No letterhead uploaded yet.'
                            : 'Letterhead is uploaded and ready to use.',
                        style: TextStyle(
                          color: form.letterheadUrl.isEmpty
                              ? Colors.orange.shade900
                              : Colors.green.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Print Positions',
                      style: TextStyle(
                        color: zText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _numberField(form.dateX, 'Date X'),
                        _numberField(form.dateY, 'Date Y'),
                        _numberField(form.dateFontSize, 'Date Font'),
                        _numberField(form.quoteNoX, 'Quote No X'),
                        _numberField(form.quoteNoY, 'Quote No Y'),
                        _numberField(form.quoteNoFontSize, 'Quote Font'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Default Terms & Conditions',
                            style: TextStyle(
                              color: zText,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.canEdit
                              ? () => setState(
                                    () => form.terms.add(_Term.blank()),
                                  )
                              : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (var index = 0;
                        index < form.terms.length;
                        index++) ...[
                      _termRow(form, index),
                      if (index != form.terms.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _termRow(_LetterheadForm form, int index) {
    final term = form.terms[index];
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;
        final title = TextField(
          controller: term.title,
          enabled: widget.canEdit,
          decoration: const InputDecoration(
            labelText: 'Title',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        );
        final value = TextField(
          controller: term.value,
          enabled: widget.canEdit,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Value',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        );
        final remove = IconButton(
          tooltip: 'Remove term',
          onPressed: widget.canEdit
              ? () => setState(() {
                    final removed = form.terms.removeAt(index);
                    removed.dispose();
                  })
              : null,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        );
        if (narrow) {
          return Column(
            children: [
              title,
              const SizedBox(height: 10),
              Row(children: [Expanded(child: value), remove]),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 180, child: title),
            const SizedBox(width: 10),
            Expanded(child: value),
            remove,
          ],
        );
      },
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zAppBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: zText,
        elevation: 0,
        title: const Text(
          'Letterhead Settings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: zOrange,
          unselectedLabelColor: zMuted,
          indicatorColor: zOrange,
          tabs: const [
            Tab(text: 'Domestic'),
            Tab(text: 'Export'),
          ],
        ),
        actions: [
          if (!widget.canEdit)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'View only',
                  style: TextStyle(
                    color: zMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed:
                    _saving || _uploadingType != null ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _form('domestic', _domestic),
                _form('export', _export),
              ],
            ),
    );
  }
}

class _LetterheadForm {
  String letterheadUrl = '';
  String letterheadFileName = '';
  String letterheadFileType = '';

  final TextEditingController dateX;
  final TextEditingController dateY;
  final TextEditingController dateFontSize;
  final TextEditingController quoteNoX;
  final TextEditingController quoteNoY;
  final TextEditingController quoteNoFontSize;
  final List<_Term> terms;

  _LetterheadForm({
    required this.dateX,
    required this.dateY,
    required this.dateFontSize,
    required this.quoteNoX,
    required this.quoteNoY,
    required this.quoteNoFontSize,
    required this.terms,
  });

  factory _LetterheadForm.domestic() => _LetterheadForm(
        dateX: TextEditingController(text: '430'),
        dateY: TextEditingController(text: '98'),
        dateFontSize: TextEditingController(text: '10'),
        quoteNoX: TextEditingController(text: '80'),
        quoteNoY: TextEditingController(text: '98'),
        quoteNoFontSize: TextEditingController(text: '10'),
        terms: [
          _Term('Payment', '100% advance / as mutually agreed'),
          _Term('Delivery', 'As per stock availability'),
          _Term('Validity', '30 days'),
          _Term('Warranty', 'As per company policy'),
        ],
      );

  factory _LetterheadForm.export() => _LetterheadForm(
        dateX: TextEditingController(text: '430'),
        dateY: TextEditingController(text: '98'),
        dateFontSize: TextEditingController(text: '10'),
        quoteNoX: TextEditingController(text: '80'),
        quoteNoY: TextEditingController(text: '98'),
        quoteNoFontSize: TextEditingController(text: '10'),
        terms: [
          _Term('Payment', 'Advance / LC / CAD as mutually agreed'),
          _Term('Delivery', 'Ex-works / FOB / CIF as per offer'),
          _Term('Validity', '30 days'),
          _Term('Warranty', 'As per agreed export terms'),
          _Term('Packing', 'Export-worthy packing if applicable'),
        ],
      );

  void load(Map<String, dynamic> data) {
    letterheadUrl = (data['letterheadUrl'] ?? '').toString();
    letterheadFileName = (data['letterheadFileName'] ?? '').toString();
    letterheadFileType = (data['letterheadFileType'] ?? '').toString();
    dateX.text = (data['dateX'] ?? dateX.text).toString();
    dateY.text = (data['dateY'] ?? dateY.text).toString();
    dateFontSize.text = (data['dateFontSize'] ?? dateFontSize.text).toString();
    quoteNoX.text = (data['quoteNoX'] ?? quoteNoX.text).toString();
    quoteNoY.text = (data['quoteNoY'] ?? quoteNoY.text).toString();
    quoteNoFontSize.text =
        (data['quoteNoFontSize'] ?? quoteNoFontSize.text).toString();

    final rawTerms = data['terms'];
    if (rawTerms is! List) return;
    for (final term in terms) {
      term.dispose();
    }
    terms.clear();
    for (final item in rawTerms) {
      if (item is Map) {
        terms.add(
          _Term(
            (item['title'] ?? '').toString(),
            (item['value'] ?? '').toString(),
          ),
        );
      }
    }
  }

  Map<String, dynamic> toMap() => {
        'letterheadUrl': letterheadUrl,
        'letterheadFileName': letterheadFileName,
        'letterheadFileType': letterheadFileType,
        'dateX': double.tryParse(dateX.text.trim()) ?? 0,
        'dateY': double.tryParse(dateY.text.trim()) ?? 0,
        'dateFontSize': double.tryParse(dateFontSize.text.trim()) ?? 10,
        'quoteNoX': double.tryParse(quoteNoX.text.trim()) ?? 0,
        'quoteNoY': double.tryParse(quoteNoY.text.trim()) ?? 0,
        'quoteNoFontSize':
            double.tryParse(quoteNoFontSize.text.trim()) ?? 10,
        'terms': terms
            .map((term) => term.toMap())
            .where(
              (term) =>
                  term['title'].toString().isNotEmpty ||
                  term['value'].toString().isNotEmpty,
            )
            .toList(),
      };

  void dispose() {
    dateX.dispose();
    dateY.dispose();
    dateFontSize.dispose();
    quoteNoX.dispose();
    quoteNoY.dispose();
    quoteNoFontSize.dispose();
    for (final term in terms) {
      term.dispose();
    }
  }
}

class _Term {
  final TextEditingController title;
  final TextEditingController value;

  _Term(String titleText, String valueText)
      : title = TextEditingController(text: titleText),
        value = TextEditingController(text: valueText);

  factory _Term.blank() => _Term('', '');

  Map<String, dynamic> toMap() => {
        'title': title.text.trim(),
        'value': value.text.trim(),
      };

  void dispose() {
    title.dispose();
    value.dispose();
  }
}
