import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_model.dart';
import 'package:QUIK/modules/engineering/bom/repositories/engineering_bom_repository.dart';
import 'package:QUIK/modules/engineering/bom/services/bom_weight_engine.dart';
import 'package:QUIK/modules/sales/quotations/quotation_screen_local.dart';

class EngineeringBomEntryScreen extends StatefulWidget {
  final String tenantId;
  final String? initialInquiryId;
  final String? initialCustomer;
  final String? initialProject;
  final String? initialItemDescription;
  final double? initialQty;

  const EngineeringBomEntryScreen({
    super.key,
    required this.tenantId,
    this.initialInquiryId,
    this.initialCustomer,
    this.initialProject,
    this.initialItemDescription,
    this.initialQty,
  });

  @override
  State<EngineeringBomEntryScreen> createState() =>
      _EngineeringBomEntryScreenState();
}

class _EngineeringBomEntryScreenState extends State<EngineeringBomEntryScreen> {
  static const double _gridWidth = 1180;

  final _formKey = GlobalKey<FormState>();
  final _bomNo = TextEditingController();
  final _inquiryId = TextEditingController();
  final _customer = TextEditingController();
  final _project = TextEditingController();
  final _revision = TextEditingController(text: 'R0');
  final _lines = <_BomLineDraft>[];
  final _gridScrollController = ScrollController();

  late final String _bomId;
  bool _saving = false;

  EngineeringBomRepository get _repository =>
      EngineeringBomRepository(tenantId: widget.tenantId.trim());

  @override
  void initState() {
    super.initState();
    _bomId = widget.tenantId.trim().isEmpty ? '' : _repository.newBomId();
    _bomNo.text = widget.tenantId.trim().isEmpty ? '' : _repository.nextBomNo();
    _inquiryId.text = (widget.initialInquiryId ?? '').trim();
    _customer.text = (widget.initialCustomer ?? '').trim();
    _project.text = (widget.initialProject ?? '').trim();
    _lines.add(
      _BomLineDraft(
        itemDescription: widget.initialItemDescription,
        qty: widget.initialQty,
      ),
    );
  }

  double get _totalWeight {
    return _lines.fold(0, (total, line) => total + line.calculatedWeight);
  }

  void _addLine() {
    setState(() => _lines.add(_BomLineDraft()));
  }

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    setState(() => _lines.removeAt(index).dispose());
  }

  Future<void> _saveBom() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.tenantId.trim().isEmpty) {
      _showMessage('Missing company workspace. BOM was not saved.');
      return;
    }

    final lineModels = <EngineeringBomLineModel>[];
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.isBlank) continue;
      lineModels.add(line.toModel(i + 1));
    }

    if (lineModels.isEmpty) {
      _showMessage('Add at least one BOM line before saving.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.saveBom(
        EngineeringBomModel(
          id: _bomId,
          bomNo: _bomNo.text.trim(),
          inquiryId: _inquiryId.text.trim(),
          customer: _customer.text.trim(),
          project: _project.text.trim(),
          revision: _revision.text.trim().isEmpty
              ? 'R0'
              : _revision.text.trim(),
          lines: lineModels,
          totalCalculatedWeight: _totalWeight,
        ),
      );
      if (!mounted) return;
      _showMessage('Engineering BOM saved.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to save BOM: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _bomNo.dispose();
    _inquiryId.dispose();
    _customer.dispose();
    _project.dispose();
    _revision.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: const Text('Engineering BOM'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Generate Quotation',
            onSelected: _openQuotation,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'commercial',
                child: Text('Commercial Quotation'),
              ),
              PopupMenuItem(
                value: 'bomDetailed',
                child: Text('BOM Detailed Quotation'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.request_quote_outlined),
                  SizedBox(width: 6),
                  Text('Generate Quotation'),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _saving ? null : _saveBom,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving' : 'Save BOM'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(
                  bomNo: _bomNo,
                  inquiryId: _inquiryId,
                  customer: _customer,
                  project: _project,
                  revision: _revision,
                ),
                const SizedBox(height: 14),
                _WeightSummary(totalWeight: _totalWeight, onAddLine: _addLine),
                const SizedBox(height: 14),
                _buildLinesGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinesGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Scrollbar(
        controller: _gridScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _gridScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _gridWidth,
            child: Column(
              children: [
                _BomGridHeader(),
                const Divider(height: 1, color: zBorder),
                for (var i = 0; i < _lines.length; i++)
                  _BomLineRow(
                    line: _lines[i],
                    lineNo: i + 1,
                    canDelete: _lines.length > 1,
                    onChanged: () => setState(() {}),
                    onDelete: () => _removeLine(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuotation(String format) {
    final lineModels = <EngineeringBomLineModel>[];
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.isBlank) continue;
      lineModels.add(line.toModel(i + 1));
    }
    if (lineModels.isEmpty) {
      _showMessage('Add at least one BOM line before generating quotation.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationScreenLocal(
          companyId: widget.tenantId,
          inquirySeed: _buildQuotationSeed(format, lineModels),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildQuotationSeed(
    String format,
    List<EngineeringBomLineModel> lines,
  ) {
    return {
      'source': 'Engineering BOM',
      'quotationFormat': format,
      'engineeringBomId': _bomId,
      'engineeringBomNo': _bomNo.text.trim(),
      'inquiryId': _inquiryId.text.trim(),
      'inquiryNumber': _inquiryId.text.trim(),
      'customerName': _customer.text.trim(),
      'subject': _project.text.trim().isEmpty
          ? 'Engineering BOM ${_bomNo.text.trim()}'
          : _project.text.trim(),
      'notes': 'Generated from Engineering BOM ${_bomNo.text.trim()}',
      'products': format == 'bomDetailed'
          ? _buildDetailedQuotationItems(lines)
          : [_buildCommercialQuotationItem(lines)],
    };
  }

  Map<String, dynamic> _buildCommercialQuotationItem(
    List<EngineeringBomLineModel> lines,
  ) {
    final firstDescription = lines
        .map((line) => line.itemDescription)
        .where((value) => value.trim().isNotEmpty)
        .join(', ');
    return {
      'id': 'bom-commercial-$_bomId',
      'productId': '',
      'name': _project.text.trim().isEmpty
          ? 'Engineering BOM ${_bomNo.text.trim()}'
          : _project.text.trim(),
      'description': firstDescription,
      'quantity': _totalWeight,
      'uom': 'KG',
      'unit': 'KG',
      'rate': 0.0,
      'unitPrice': 0.0,
      'gstPercentage': 18.0,
      'quotationLineType': 'commercial',
    };
  }

  List<Map<String, dynamic>> _buildDetailedQuotationItems(
    List<EngineeringBomLineModel> lines,
  ) {
    return lines
        .map((line) {
          return {
            'id': 'bom-$_bomId-${line.lineNo}',
            'productId': '',
            'name': line.section.isEmpty ? line.itemDescription : line.section,
            'description': line.material.isEmpty
                ? line.itemDescription
                : '${line.itemDescription}\nMaterial: ${line.material}',
            'quantity': line.qty,
            'uom': 'KG',
            'unit': 'KG',
            'rate': 0.0,
            'unitPrice': 0.0,
            'gstPercentage': 18.0,
            'quotationLineType': 'bomDetailed',
            'bomSection': line.section,
            'bomMaterial': line.material,
            'bomLengthMm': line.lengthMm,
            'bomWeight': line.calculatedWeight,
          };
        })
        .toList(growable: false);
  }
}

class _HeaderCard extends StatelessWidget {
  final TextEditingController bomNo;
  final TextEditingController inquiryId;
  final TextEditingController customer;
  final TextEditingController project;
  final TextEditingController revision;

  const _HeaderCard({
    required this.bomNo,
    required this.inquiryId,
    required this.customer,
    required this.project,
    required this.revision,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 820;
          final fields = [
            _field(bomNo, 'BOM No', required: true),
            _field(inquiryId, 'Inquiry ID'),
            _field(customer, 'Customer', required: true),
            _field(project, 'Project'),
            _field(revision, 'Revision'),
          ];
          if (narrow) {
            return Column(children: fields.map(_withBottomGap).toList());
          }
          return Wrap(spacing: 12, runSpacing: 12, children: fields);
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return SizedBox(
      width: 220,
      child: TextFormField(
        controller: controller,
        decoration: _dec(label),
        validator: required
            ? (value) => (value ?? '').trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _withBottomGap(Widget child) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
  }
}

class _WeightSummary extends StatelessWidget {
  final double totalWeight;
  final VoidCallback onAddLine;

  const _WeightSummary({required this.totalWeight, required this.onAddLine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zBlueSoft,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.scale_outlined, color: zBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total calculated weight: ${totalWeight.toStringAsFixed(3)} kg',
              style: const TextStyle(fontWeight: FontWeight.w800, color: zText),
            ),
          ),
          FilledButton.icon(
            onPressed: onAddLine,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Line'),
          ),
        ],
      ),
    );
  }
}

class _BomGridHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w800, color: zMuted);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 42, child: Text('#', style: style)),
          SizedBox(width: 210, child: Text('Item Description', style: style)),
          SizedBox(width: 120, child: Text('Section', style: style)),
          SizedBox(width: 140, child: Text('Material', style: style)),
          SizedBox(width: 80, child: Text('Qty', style: style)),
          SizedBox(width: 110, child: Text('Length mm', style: style)),
          SizedBox(width: 140, child: Text('Weight / meter', style: style)),
          SizedBox(width: 150, child: Text('Calculated weight', style: style)),
          SizedBox(width: 150, child: Text('Galvanizing micron', style: style)),
          SizedBox(width: 110, child: Text('Grade', style: style)),
          SizedBox(width: 70),
        ],
      ),
    );
  }
}

class _BomLineRow extends StatelessWidget {
  final _BomLineDraft line;
  final int lineNo;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _BomLineRow({
    required this.line,
    required this.lineNo,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('$lineNo', style: const TextStyle(color: zMuted)),
            ),
          ),
          _cell(line.itemDescription, 'Description', 210, required: true),
          _cell(line.section, 'Section', 120),
          _cell(line.material, 'Material', 140),
          _cell(line.qty, 'Qty', 80, number: true),
          _cell(line.lengthMm, 'Length', 110, number: true),
          _cell(line.weightPerMeter, 'Kg/m', 140, number: true),
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                line.calculatedWeight.toStringAsFixed(3),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _cell(line.galvanizingMicron, 'Micron', 150, number: true),
          _cell(line.grade, 'Grade', 110),
          SizedBox(
            width: 70,
            child: IconButton(
              tooltip: 'Delete line',
              onPressed: canDelete ? onDelete : null,
              icon: const Icon(Icons.delete_outline, color: zDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    TextEditingController controller,
    String label,
    double width, {
    bool number = false,
    bool required = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: TextFormField(
          controller: controller,
          decoration: _dec(label),
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          onChanged: (_) => onChanged(),
          validator: required
              ? (value) => (value ?? '').trim().isEmpty ? 'Required' : null
              : null,
        ),
      ),
    );
  }
}

class _BomLineDraft {
  final itemDescription = TextEditingController();
  final section = TextEditingController();
  final material = TextEditingController();
  final qty = TextEditingController(text: '1');
  final lengthMm = TextEditingController();
  final weightPerMeter = TextEditingController();
  final galvanizingMicron = TextEditingController();
  final grade = TextEditingController();

  _BomLineDraft({String? itemDescription, double? qty}) {
    this.itemDescription.text = (itemDescription ?? '').trim();
    if (qty != null && qty > 0) {
      this.qty.text = _formatNumber(qty);
    }
  }

  bool get isBlank {
    return itemDescription.text.trim().isEmpty &&
        section.text.trim().isEmpty &&
        material.text.trim().isEmpty &&
        lengthMm.text.trim().isEmpty &&
        weightPerMeter.text.trim().isEmpty;
  }

  double get calculatedWeight {
    return BomWeightEngine.calculatedWeight(
      qty: _toDouble(qty.text),
      lengthMm: _toDouble(lengthMm.text),
      weightPerMeter: _toDouble(weightPerMeter.text),
    );
  }

  EngineeringBomLineModel toModel(int lineNo) {
    return EngineeringBomLineModel(
      lineNo: lineNo,
      itemDescription: itemDescription.text.trim(),
      section: section.text.trim(),
      material: material.text.trim(),
      qty: _toDouble(qty.text),
      lengthMm: _toDouble(lengthMm.text),
      weightPerMeter: _toDouble(weightPerMeter.text),
      calculatedWeight: calculatedWeight,
      galvanizingMicron: _toDouble(galvanizingMicron.text),
      grade: grade.text.trim(),
    );
  }

  void dispose() {
    itemDescription.dispose();
    section.dispose();
    material.dispose();
    qty.dispose();
    lengthMm.dispose();
    weightPerMeter.dispose();
    galvanizingMicron.dispose();
    grade.dispose();
  }

  static double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

InputDecoration _dec(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: zSurfaceSoft,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: zBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: zBlue, width: 1.2),
    ),
  );
}
