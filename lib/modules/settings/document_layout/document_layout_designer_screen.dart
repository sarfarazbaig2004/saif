import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'document_layout_model.dart';
import 'document_layout_repository.dart';

class DocumentLayoutDesignerScreen extends StatefulWidget {
  final String companyId;
  final bool canEdit;
  const DocumentLayoutDesignerScreen({super.key, required this.companyId, required this.canEdit});

  @override
  State<DocumentLayoutDesignerScreen> createState() => _DocumentLayoutDesignerScreenState();
}

class _DocumentLayoutDesignerScreenState extends State<DocumentLayoutDesignerScreen> {
  late final DocumentLayoutRepository _repository;
  DocumentLayoutModel _layout = const DocumentLayoutModel();
  Uint8List? _pendingBytes;
  String _pendingName = '';
  String _pendingExtension = '';
  bool _removeBackground = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); _repository = DocumentLayoutRepository(widget.companyId); _load(); }

  Future<void> _load() async {
    try { _layout = await _repository.load(); }
    catch (_) { _message('Document layout could not be loaded.', error: true); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _pickBackground() async {
    if (!widget.canEdit || _saving) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['png', 'jpg', 'jpeg'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final extension = (file.extension ?? '').toLowerCase();
    if (file.bytes == null) { _message('The selected file could not be read.', error: true); return; }
    if (!const ['png', 'jpg', 'jpeg'].contains(extension)) { _message('Choose a PNG or JPG image.', error: true); return; }
    if (file.size > 5 * 1024 * 1024) { _message('Background image must be 5 MB or smaller.', error: true); return; }
    setState(() { _pendingBytes = file.bytes; _pendingName = file.name; _pendingExtension = extension; _removeBackground = false; });
  }

  bool get _validLayout {
    final horizontal = _layout.leftMarginPt + _layout.rightMarginPt;
    final vertical = _layout.headerHeightPt + _layout.footerHeightPt + _layout.topMarginPt + _layout.bottomMarginPt;
    return horizontal <= DocumentLayoutModel.pageWidthPt - 72 && vertical <= DocumentLayoutModel.pageHeightPt - 144;
  }

  Future<void> _save() async {
    if (_saving || !widget.canEdit) return;
    if (!_validLayout) { _message('Printable area is too small. Reduce header, footer, or margins.', error: true); return; }
    setState(() => _saving = true);
    final oldPath = _layout.backgroundStoragePath;
    var next = _layout;
    String newUploadedPath = '';
    try {
      if (_pendingBytes != null) {
        final upload = await _repository.upload(bytes: _pendingBytes!, fileName: _pendingName, extension: _pendingExtension);
        newUploadedPath = upload.storagePath;
        next = next.copyWith(backgroundUrl: upload.url, backgroundStoragePath: upload.storagePath, backgroundFileName: _pendingName, backgroundFileType: _pendingExtension, backgroundSizeBytes: _pendingBytes!.length);
      } else if (_removeBackground) {
        next = next.copyWith(backgroundUrl: '', backgroundStoragePath: '', backgroundFileName: '', backgroundFileType: '', backgroundSizeBytes: 0);
      }
      await _repository.save(next, FirebaseAuth.instance.currentUser?.uid);
      if (oldPath.isNotEmpty && oldPath != next.backgroundStoragePath) {
        try { await _repository.deleteStorageFile(oldPath); } catch (_) { /* Saved layout remains valid even if cleanup is denied. */ }
      }
      if (!mounted) return;
      setState(() { _layout = next; _pendingBytes = null; _pendingName = ''; _pendingExtension = ''; _removeBackground = false; });
      _message('Document layout saved.');
    } catch (_) {
      if (newUploadedPath.isNotEmpty) { try { await _repository.deleteStorageFile(newUploadedPath); } catch (_) {} }
      _message('Document layout could not be saved. The previous background is unchanged.', error: true);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red.shade700 : null));
  }

  void _setValue(String key, double value) {
    final safe = value.clamp(0, key.contains('Margin') ? 144 : 180).toDouble();
    setState(() { switch (key) {
      case 'header': _layout = _layout.copyWith(headerHeightPt: safe); break;
      case 'footer': _layout = _layout.copyWith(footerHeightPt: safe); break;
      case 'leftMargin': _layout = _layout.copyWith(leftMarginPt: safe); break;
      case 'rightMargin': _layout = _layout.copyWith(rightMarginPt: safe); break;
      case 'topMargin': _layout = _layout.copyWith(topMarginPt: safe); break;
      case 'bottomMargin': _layout = _layout.copyWith(bottomMarginPt: safe); break;
    }});
  }

  Widget _control(String key, String label, double value, {double max = 144}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${value.toStringAsFixed(0)} pt  •  ${DocumentLayoutModel.pointsToMillimetres(value).toStringAsFixed(1)} mm', style: const TextStyle(color: zMuted, fontSize: 12))]),
    Slider(value: value.clamp(0, max).toDouble(), min: 0, max: max, divisions: max.toInt(), onChanged: widget.canEdit ? (next) => _setValue(key, next) : null),
  ]);

  Widget _configuration() {
    final visibleName = _pendingName.isNotEmpty ? _pendingName : _removeBackground ? '' : _layout.backgroundFileName;
    final visibleSize = _pendingBytes?.length ?? _layout.backgroundSizeBytes;
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: zBorder), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Document Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 6),
      Text(visibleName.isEmpty ? 'No background uploaded' : '$visibleName  •  ${(visibleSize / 1024).toStringAsFixed(1)} KB', style: const TextStyle(color: zMuted)), const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [OutlinedButton.icon(onPressed: widget.canEdit ? _pickBackground : null, icon: const Icon(Icons.upload_file_outlined), label: Text(visibleName.isEmpty ? 'Upload Background' : 'Replace Background')), if (visibleName.isNotEmpty) TextButton.icon(onPressed: widget.canEdit ? () => setState(() { _pendingBytes = null; _pendingName = ''; _pendingExtension = ''; _removeBackground = true; }) : null, icon: const Icon(Icons.delete_outline), label: const Text('Remove'))]),
      const Divider(height: 32), const Text('Printable Area', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
      _control('header', 'Header Height', _layout.headerHeightPt, max: 180), _control('footer', 'Footer Height', _layout.footerHeightPt, max: 180),
      _control('leftMargin', 'Left Margin', _layout.leftMarginPt), _control('rightMargin', 'Right Margin', _layout.rightMarginPt),
      _control('topMargin', 'Top Margin', _layout.topMarginPt), _control('bottomMargin', 'Bottom Margin', _layout.bottomMarginPt),
      if (!_validLayout) const Text('Printable area is too small.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _preview() => LayoutBuilder(builder: (_, constraints) {
    final width = constraints.maxWidth.clamp(260.0, 560.0).toDouble();
    final height = width * DocumentLayoutModel.pageHeightPt / DocumentLayoutModel.pageWidthPt;
    final sx = width / DocumentLayoutModel.pageWidthPt; final sy = height / DocumentLayoutModel.pageHeightPt;
    final background = _pendingBytes != null ? Image.memory(_pendingBytes!, fit: BoxFit.fill) : (!_removeBackground && _layout.backgroundUrl.isNotEmpty ? Image.network(_layout.backgroundUrl, fit: BoxFit.fill, errorBuilder: (_, __, ___) => const SizedBox()) : null);
    return Center(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white, boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18)]), child: Stack(fit: StackFit.expand, children: [
      if (background != null) background,
      Positioned(left: _layout.leftMarginPt * sx, right: _layout.rightMarginPt * sx, top: (_layout.headerHeightPt + _layout.topMarginPt) * sy, bottom: (_layout.footerHeightPt + _layout.bottomMarginPt) * sy, child: Container(decoration: BoxDecoration(color: const Color(0x0DFF7A00), border: Border.all(color: zOrange, width: 1.4)), child: const Center(child: Text('Printable document content', style: TextStyle(color: zMuted, fontWeight: FontWeight.w700))))),
      Positioned(left: 0, right: 0, top: _layout.headerHeightPt * sy, child: const Divider(color: Colors.blue, height: 1)),
      Positioned(left: 0, right: 0, bottom: _layout.footerHeightPt * sy, child: const Divider(color: Colors.blue, height: 1)),
    ]))));
  });

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: zAppBg, appBar: AppBar(title: const Text('Document Layout Designer'), actions: [if (widget.canEdit) Padding(padding: const EdgeInsets.only(right: 12), child: FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save Layout')))]), body: _loading ? const Center(child: CircularProgressIndicator()) : LayoutBuilder(builder: (_, constraints) {
    final narrow = constraints.maxWidth < 900;
    final config = _configuration(); final preview = _preview();
    return SingleChildScrollView(padding: const EdgeInsets.all(18), child: narrow ? Column(children: [config, const SizedBox(height: 18), preview]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 390, child: config), const SizedBox(width: 24), Expanded(child: preview)]));
  }));
}
