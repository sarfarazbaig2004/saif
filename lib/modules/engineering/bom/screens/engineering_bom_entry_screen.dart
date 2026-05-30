import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_model.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_fastener_line_model.dart';
import 'package:QUIK/modules/engineering/bom/repositories/engineering_bom_repository.dart';
import 'package:QUIK/modules/engineering/bom/services/bom_weight_calculator.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_draft_mapper.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_quotation_launcher.dart';
import 'package:QUIK/modules/engineering/bom/widgets/bom_column_selector_dialog.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_app_bar_actions.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_grid_card.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_header.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_table.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _bomNo = TextEditingController();
  final _inquiryId = TextEditingController();
  final _customer = TextEditingController();
  final _project = TextEditingController();
  final _projectQuantity = TextEditingController(text: '1');
  final _revision = TextEditingController(text: 'R0');
  final _lines = <BomLineDraft>[];
  final _fasteners = <FastenerBomLineDraft>[];
  final _gridScrollController = ScrollController();
  List<String> _visibleColumns =
      BomColumnConfig.presets['Customer BOM Format']!;
  List<BomCustomField> _customFields = const [];

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
    if ((widget.initialQty ?? 0) > 0) {
      _projectQuantity.text = widget.initialQty!.toStringAsFixed(0);
    }
    _lines.add(BomLineDraft());
    _fasteners.add(FastenerBomLineDraft());
  }

  double get _projectQty => double.tryParse(_projectQuantity.text.trim()) ?? 1;

  double get _weightPerStructure {
    return _lines.fold(0, (total, line) => total + line.lineWeight);
  }

  double get _totalProjectWeight => _lines.fold(
    0,
    (total, line) =>
        total +
        BomWeightCalculator.totalProjectWeight(line.lineWeight, _projectQty),
  );

  void _addLine() {
    setState(() => _lines.add(BomLineDraft()));
  }

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    setState(() => _lines.removeAt(index).dispose());
  }

  void _addFastener() {
    setState(() => _fasteners.add(FastenerBomLineDraft()));
  }

  void _removeFastener(int index) {
    if (_fasteners.length == 1) return;
    setState(() => _fasteners.removeAt(index).dispose());
  }

  List<EngineeringBomLineModel> get _lineModels => structureBomModels(
    lines: _lines,
    projectQuantity: _projectQty,
    customFields: _customFields,
  );

  List<EngineeringFastenerLineModel> get _fastenerModels =>
      fastenerBomModels(lines: _fasteners, projectQuantity: _projectQty);

  Future<void> _customizeColumns() async {
    final result = await showDialog<BomFieldConfigResult>(
      context: context,
      builder: (_) => BomColumnSelectorDialog(
        visibleColumns: _visibleColumns,
        customFields: _customFields,
      ),
    );
    if (result == null) return;
    setState(() {
      _customFields = result.customFields;
      _visibleColumns = BomColumnConfig.sanitize(result.visibleColumns);
    });
  }

  Future<void> _saveBom() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.tenantId.trim().isEmpty) {
      _showMessage('Missing company workspace. BOM was not saved.');
      return;
    }

    final lineModels = _lineModels;
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
          projectQuantity: _projectQty,
          visibleColumns: _visibleColumns,
          customFields: _customFields,
          lines: lineModels,
          fastenerLines: _fastenerModels,
          totalCalculatedWeight: _totalProjectWeight,
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
    for (final controller in [
      _bomNo,
      _inquiryId,
      _customer,
      _project,
      _projectQuantity,
      _revision,
    ]) {
      controller.dispose();
    }
    for (final line in _lines) {
      line.dispose();
    }
    for (final fastener in _fasteners) {
      fastener.dispose();
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
          EngineeringBomAppBarActions(
            saving: _saving,
            onGenerateQuotation: _openQuotation,
            onSave: _saveBom,
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
                EngineeringBomHeader(
                  bomNo: _bomNo,
                  inquiryId: _inquiryId,
                  customer: _customer,
                  project: _project,
                  projectQuantity: _projectQuantity,
                  revision: _revision,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 14),
                EngineeringBomSummary(
                  weightPerStructure: _weightPerStructure,
                  totalProjectWeight: _totalProjectWeight,
                  onAddLine: _addLine,
                ),
                const SizedBox(height: 14),
                EngineeringBomGridCard(
                  lines: _lines,
                  visibleColumns: _visibleColumns,
                  customFields: _customFields,
                  projectQuantity: _projectQty,
                  tenantId: widget.tenantId,
                  scrollController: _gridScrollController,
                  onChanged: () => setState(() {}),
                  onCustomizeColumns: _customizeColumns,
                  onDelete: _removeLine,
                ),
                const SizedBox(height: 14),
                EngineeringFastenerBomTable(
                  lines: _fasteners,
                  projectQuantity: _projectQty,
                  onAddLine: _addFastener,
                  onDelete: _removeFastener,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuotation(String format) {
    final lineModels = _lineModels;
    if (lineModels.isEmpty) {
      _showMessage('Add at least one BOM line before generating quotation.');
      return;
    }

    openEngineeringBomQuotation(
      context: context,
      companyId: widget.tenantId,
      format: format,
      bomId: _bomId,
      bomNo: _bomNo.text.trim(),
      inquiryId: _inquiryId.text.trim(),
      customer: _customer.text.trim(),
      project: _project.text.trim(),
      totalProjectWeight: _totalProjectWeight,
      lines: lineModels,
    );
  }
}
