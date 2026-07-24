import 'dart:math' as math;
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

  const DocumentLayoutDesignerScreen({
    super.key,
    required this.companyId,
    required this.canEdit,
  });

  @override
  State<DocumentLayoutDesignerScreen> createState() =>
      _DocumentLayoutDesignerScreenState();
}

class _DocumentLayoutDesignerScreenState
    extends State<DocumentLayoutDesignerScreen> {
  static const _defaults = DocumentLayoutModel(
    headerHeightPt: 106,
    footerHeightPt: 80,
    leftMarginPt: 40,
    rightMarginPt: 40,
    topMarginPt: 0,
    bottomMarginPt: 0,
    showGrid: true,
    snapToGrid: true,
  );

  late final DocumentLayoutRepository _repository;
  DocumentLayoutModel _layout = _defaults;
  Uint8List? _pendingBytes;
  String _pendingName = '';
  String _pendingExtension = '';
  bool _removeBackground = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository = DocumentLayoutRepository(widget.companyId);
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _repository.load();
      setState(() {
        _layout = saved.backgroundUrl.isEmpty &&
                saved.headerHeightPt == 72 &&
                saved.footerHeightPt == 54 &&
                saved.leftMarginPt == 36 &&
                saved.rightMarginPt == 36
            ? _defaults
            : saved;
      });
    } catch (_) {
      _message('Document layout could not be loaded.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickBackground() async {
    if (!widget.canEdit || _saving) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final extension = (file.extension ?? '').toLowerCase();
    if (file.bytes == null || file.bytes!.isEmpty) {
      _message('The selected file could not be read.', error: true);
      return;
    }
    if (!const ['png', 'jpg', 'jpeg'].contains(extension)) {
      _message('Choose a PNG or JPG image.', error: true);
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      _message('Letterhead image must be 5 MB or smaller.', error: true);
      return;
    }
    setState(() {
      _pendingBytes = file.bytes;
      _pendingName = file.name;
      _pendingExtension = extension;
      _removeBackground = false;
    });
  }

  bool get _validLayout {
    final horizontal = _layout.leftMarginPt + _layout.rightMarginPt;
    final vertical =
        _layout.headerHeightPt +
        _layout.footerHeightPt +
        _layout.topMarginPt +
        _layout.bottomMarginPt;
    return horizontal <= DocumentLayoutModel.pageWidthPt - 72 &&
        vertical <= DocumentLayoutModel.pageHeightPt - 144;
  }

  Future<void> _save() async {
    if (_saving || !widget.canEdit) return;
    if (!_validLayout) {
      _message(
        'Printable area is too small. Reduce header, footer, or margins.',
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    final oldPath = _layout.backgroundStoragePath;
    var next = _layout;
    String newUploadedPath = '';
    try {
      if (_pendingBytes != null) {
        final upload = await _repository.upload(
          bytes: _pendingBytes!,
          fileName: _pendingName,
          extension: _pendingExtension,
        );
        newUploadedPath = upload.storagePath;
        next = next.copyWith(
          backgroundUrl: upload.url,
          backgroundStoragePath: upload.storagePath,
          backgroundFileName: _pendingName,
          backgroundFileType: _pendingExtension,
          backgroundSizeBytes: _pendingBytes!.length,
        );
      } else if (_removeBackground) {
        next = next.copyWith(
          backgroundUrl: '',
          backgroundStoragePath: '',
          backgroundFileName: '',
          backgroundFileType: '',
          backgroundSizeBytes: 0,
        );
      }
      await _repository.save(
        next,
        FirebaseAuth.instance.currentUser?.uid,
      );
      if (oldPath.isNotEmpty && oldPath != next.backgroundStoragePath) {
        try {
          await _repository.deleteStorageFile(oldPath);
        } catch (_) {
          // The saved layout remains valid if old-file cleanup is denied.
        }
      }
      if (!mounted) return;
      setState(() {
        _layout = next;
        _pendingBytes = null;
        _pendingName = '';
        _pendingExtension = '';
        _removeBackground = false;
      });
      _message('Document layout saved.');
    } catch (_) {
      if (newUploadedPath.isNotEmpty) {
        try {
          await _repository.deleteStorageFile(newUploadedPath);
        } catch (_) {}
      }
      _message(
        'Document layout could not be saved. The previous layout is unchanged.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  double _snap(double value) {
    final clamped = value.clamp(0, 180).toDouble();
    if (!_layout.snapToGrid) return clamped;
    return (clamped / 10).round() * 10;
  }

  void _setDimension(_Dimension dimension, double value) {
    if (!widget.canEdit) return;
    final safe = _snap(value);
    setState(() {
      switch (dimension) {
        case _Dimension.header:
          _layout = _layout.copyWith(headerHeightPt: safe);
        case _Dimension.footer:
          _layout = _layout.copyWith(footerHeightPt: safe);
        case _Dimension.left:
          _layout = _layout.copyWith(leftMarginPt: safe);
        case _Dimension.right:
          _layout = _layout.copyWith(rightMarginPt: safe);
      }
    });
  }

  void _restoreDefaults() {
    if (!widget.canEdit) return;
    setState(() {
      _layout = _layout.copyWith(
        headerHeightPt: _defaults.headerHeightPt,
        footerHeightPt: _defaults.footerHeightPt,
        leftMarginPt: _defaults.leftMarginPt,
        rightMarginPt: _defaults.rightMarginPt,
      );
    });
  }

  String get _visibleFileName {
    if (_pendingName.isNotEmpty) return _pendingName;
    if (_removeBackground) return '';
    return _layout.backgroundFileName;
  }

  Widget _panel({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: zBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 25),
            color: const Color(0xFFFAFBFC),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF334155), size: 25),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8ECF1)),
          Padding(padding: const EdgeInsets.all(28), child: child),
        ],
      ),
    );
  }

  Widget _backgroundPanel() {
    return _panel(
      icon: Icons.image_outlined,
      title: 'Document Background',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: widget.canEdit ? _pickBackground : null,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              _visibleFileName.isEmpty
                  ? 'Upload Letterhead (PNG/JPG)'
                  : 'Replace Letterhead',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF18181B),
              padding: const EdgeInsets.symmetric(vertical: 17),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              side: const BorderSide(color: Color(0xFFD9DEE5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          if (_visibleFileName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _visibleFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: zMuted),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.canEdit
                      ? () => setState(() {
                          _pendingBytes = null;
                          _pendingName = '';
                          _pendingExtension = '';
                          _removeBackground = true;
                        })
                      : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _printableAreaPanel() {
    return _panel(
      icon: Icons.fullscreen_outlined,
      title: 'Printable Area',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DimensionInput(
                  label: 'Header Height',
                  icon: Icons.vertical_align_top,
                  value: _layout.headerHeightPt,
                  enabled: widget.canEdit,
                  onChanged: (value) =>
                      _setDimension(_Dimension.header, value),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _DimensionInput(
                  label: 'Footer Height',
                  icon: Icons.vertical_align_bottom,
                  value: _layout.footerHeightPt,
                  enabled: widget.canEdit,
                  onChanged: (value) =>
                      _setDimension(_Dimension.footer, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DimensionInput(
                  label: 'Left Margin',
                  icon: Icons.format_align_left,
                  value: _layout.leftMarginPt,
                  enabled: widget.canEdit,
                  onChanged: (value) =>
                      _setDimension(_Dimension.left, value),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _DimensionInput(
                  label: 'Right Margin',
                  icon: Icons.format_align_right,
                  value: _layout.rightMarginPt,
                  enabled: widget.canEdit,
                  onChanged: (value) =>
                      _setDimension(_Dimension.right, value),
                ),
              ),
            ],
          ),
          if (!_validLayout) ...[
            const SizedBox(height: 16),
            const Text(
              'Printable area is too small.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _layoutToolsPanel() {
    return _panel(
      icon: Icons.grid_on_outlined,
      title: 'Layout Tools',
      child: Column(
        children: [
          _toggleRow(
            title: 'Show Grid & Rulers',
            subtitle: 'Display layout guides in preview',
            value: _layout.showGrid,
            onChanged: (value) =>
                setState(() => _layout = _layout.copyWith(showGrid: value)),
          ),
          const SizedBox(height: 25),
          _toggleRow(
            title: 'Snap to Grid',
            subtitle: 'Step dimensions by 10 points',
            value: _layout.snapToGrid,
            onChanged: (value) =>
                setState(() => _layout = _layout.copyWith(snapToGrid: value)),
          ),
          const Divider(height: 42),
          TextButton.icon(
            onPressed: widget.canEdit ? _restoreDefaults : null,
            icon: const Icon(Icons.history_rounded),
            label: const Text('Restore Default Dimensions'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF26A00),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF18181B),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF52525B)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: widget.canEdit ? onChanged : null,
          activeTrackColor: const Color(0xFFFF7114),
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }

  Widget _configuration() {
    return Column(
      children: [
        _backgroundPanel(),
        const SizedBox(height: 28),
        _printableAreaPanel(),
        const SizedBox(height: 28),
        _layoutToolsPanel(),
      ],
    );
  }

  Widget _preview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: const BoxConstraints(minHeight: 720),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            border: Border.all(color: const Color(0xFFB8B8B8)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: _PagePreview(
                layout: _layout,
                pendingBytes: _pendingBytes,
                removeBackground: _removeBackground,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18181B),
        elevation: 0,
        title: const Text(
          'Document Layout Designer',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (widget.canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 24, 10),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save Layout'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7114),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 980;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(36),
                  child: narrow
                      ? Column(
                          children: [
                            _configuration(),
                            const SizedBox(height: 24),
                            _preview(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 570, child: _configuration()),
                            const SizedBox(width: 36),
                            Expanded(child: _preview()),
                          ],
                        ),
                );
              },
            ),
    );
  }
}

enum _Dimension { header, footer, left, right }

class _DimensionInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _DimensionInput({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final millimetres = DocumentLayoutModel.pointsToMillimetres(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF27272A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 64,
                child: TextFormField(
                  key: ValueKey('$label-${value.toStringAsFixed(0)}'),
                  initialValue: value.toStringAsFixed(0),
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onFieldSubmitted: (text) {
                    final parsed = double.tryParse(text.trim());
                    if (parsed != null) onChanged(parsed);
                  },
                  style: const TextStyle(
                    color: Color(0xFF27272A),
                    fontSize: 20,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        enabled ? Colors.white : const Color(0xFFF4F4F5),
                    prefixIcon: Icon(
                      icon,
                      color: const Color(0xFF71717A),
                      size: 22,
                    ),
                    suffixText: 'pt',
                    suffixStyle: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontWeight: FontWeight.w700,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFFD8DDE5),
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFFFF7114),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFFD8DDE5),
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                _stepButton(
                  icon: Icons.arrow_drop_up,
                  onPressed: enabled ? () => onChanged(value + 1) : null,
                ),
                const SizedBox(height: 2),
                _stepButton(
                  icon: Icons.arrow_drop_down,
                  onPressed: enabled ? () => onChanged(value - 1) : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '≈ ${millimetres.toStringAsFixed(1)} mm',
          style: const TextStyle(
            color: Color(0xFF0877D1),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _stepButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 38,
      height: 31,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFF18181B),
          side: const BorderSide(color: Color(0xFFD8DDE5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _PagePreview extends StatelessWidget {
  final DocumentLayoutModel layout;
  final Uint8List? pendingBytes;
  final bool removeBackground;

  const _PagePreview({
    required this.layout,
    required this.pendingBytes,
    required this.removeBackground,
  });

  @override
  Widget build(BuildContext context) {
    const ruler = 20.0;
    const pageWidth = 515.0;
    final pageHeight =
        pageWidth *
        DocumentLayoutModel.pageHeightPt /
        DocumentLayoutModel.pageWidthPt;
    final scaleX = pageWidth / DocumentLayoutModel.pageWidthPt;
    final scaleY = pageHeight / DocumentLayoutModel.pageHeightPt;
    final header = layout.headerHeightPt * scaleY;
    final footer = layout.footerHeightPt * scaleY;
    final left = layout.leftMarginPt * scaleX;
    final right = layout.rightMarginPt * scaleX;

    Widget? background;
    if (pendingBytes != null) {
      background = Image.memory(pendingBytes!, fit: BoxFit.fill);
    } else if (!removeBackground && layout.backgroundUrl.isNotEmpty) {
      background = Image.network(
        layout.backgroundUrl,
        fit: BoxFit.fill,
        errorBuilder: (_, __, ___) => const SizedBox(),
      );
    }

    return SizedBox(
      width: pageWidth + ruler,
      height: pageHeight + ruler,
      child: Stack(
        children: [
          Positioned(
            left: ruler,
            top: ruler,
            width: pageWidth,
            height: pageHeight,
            child: Container(
              color: Colors.white,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (background != null) background,
                  if (layout.showGrid)
                    CustomPaint(painter: const _GridPainter()),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: header,
                    child: _zone(
                      color: const Color(0xFFDCEEFF),
                      label: 'HEADER\n${layout.headerHeightPt.toStringAsFixed(0)} pt',
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: footer,
                    child: _zone(
                      color: const Color(0xFFDCEEFF),
                      label: 'FOOTER\n${layout.footerHeightPt.toStringAsFixed(0)} pt',
                    ),
                  ),
                  Positioned(
                    left: left,
                    right: right,
                    top: header,
                    bottom: footer,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        border: Border.all(
                          color: const Color(0xFF3A9C4B),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const _DocumentSkeleton(),
                    ),
                  ),
                  Positioned(
                    left: 2,
                    top: header,
                    bottom: footer,
                    width: math.max(8.0, left - 2),
                    child: _sideMargin(
                      'L-MARGIN ${layout.leftMarginPt.toStringAsFixed(0)} pt',
                      clockwise: false,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: header,
                    bottom: footer,
                    width: math.max(8.0, right - 2),
                    child: _sideMargin(
                      'R-MARGIN ${layout.rightMarginPt.toStringAsFixed(0)} pt',
                      clockwise: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (layout.showGrid) ...[
            Positioned(
              left: ruler,
              top: 0,
              width: pageWidth,
              height: ruler,
              child: CustomPaint(painter: const _HorizontalRulerPainter()),
            ),
            Positioned(
              left: 0,
              top: ruler,
              width: ruler,
              height: pageHeight,
              child: CustomPaint(painter: const _VerticalRulerPainter()),
            ),
            const Positioned(
              left: 0,
              top: 0,
              width: ruler,
              height: ruler,
              child: ColoredBox(
                color: Color(0xFFF7F7F7),
                child: Center(
                  child: Text(
                    'pt',
                    style: TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _zone({required Color color, required String label}) {
    return Container(
      color: color.withValues(alpha: 0.88),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF064DAD),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.5,
        ),
      ),
    );
  }

  static Widget _sideMargin(String label, {required bool clockwise}) {
    return Container(
      color: const Color(0xFFFFF1DC).withValues(alpha: 0.9),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: clockwise ? 1 : 3,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFFF26000),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DocumentSkeleton extends StatelessWidget {
  const _DocumentSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, {double height = 7}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(3),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(120, height: 24),
                  const SizedBox(height: 18),
                  bar(136),
                  const SizedBox(height: 7),
                  bar(120),
                  const SizedBox(height: 7),
                  bar(98),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  bar(86, height: 14),
                  const SizedBox(height: 25),
                  bar(116),
                  const SizedBox(height: 7),
                  bar(102),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          bar(double.infinity, height: 18),
          const SizedBox(height: 10),
          bar(double.infinity),
          const SizedBox(height: 7),
          bar(double.infinity),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(100),
                  const SizedBox(height: 7),
                  bar(145),
                  const SizedBox(height: 7),
                  bar(125),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  bar(105),
                  const SizedBox(height: 12),
                  bar(145, height: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = const Color(0xFFE8EDF2).withValues(alpha: 0.65)
      ..strokeWidth = 0.6;
    final major = Paint()
      ..color = const Color(0xFFD5DDE5).withValues(alpha: 0.75)
      ..strokeWidth = 0.8;
    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), major);
    }
    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), major);
    }
    for (double x = 20; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    for (double y = 20; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HorizontalRulerPainter extends CustomPainter {
  const _HorizontalRulerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F7F7),
    );
    final line = Paint()
      ..color = const Color(0xFFB7BDC5)
      ..strokeWidth = 0.7;
    for (double x = 0; x <= size.width; x += 10) {
      final major = x % 50 == 0;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, major ? 7 : 13),
        line,
      );
      if (major && x > 0) {
        final painter = TextPainter(
          text: TextSpan(
            text: x.toInt().toString(),
            style: const TextStyle(fontSize: 6, color: Colors.grey),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x + 2, 1));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerticalRulerPainter extends CustomPainter {
  const _VerticalRulerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F7F7),
    );
    final line = Paint()
      ..color = const Color(0xFFB7BDC5)
      ..strokeWidth = 0.7;
    for (double y = 0; y <= size.height; y += 10) {
      final major = y % 50 == 0;
      canvas.drawLine(
        Offset(size.width, y),
        Offset(major ? 7 : 13, y),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
