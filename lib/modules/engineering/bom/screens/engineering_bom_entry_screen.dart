import 'package:flutter/material.dart';
import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
import 'package:QUIK/modules/engineering/bom/repositories/engineering_bom_repository.dart';
import 'package:QUIK/modules/engineering/bom/services/bom_weight_calculator.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_draft_actions.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_draft_mapper.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_material_refresh_service.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_quotation_launcher.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_save_service.dart';
import 'package:QUIK/modules/engineering/bom/widgets/bom_column_selector_dialog.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_discard_dialog.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_entry_body.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_entry_scaffold.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_revision_reason_dialog.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_models.dart';
import 'package:QUIK/modules/inventory/material_master/repositories/material_master_repository.dart';

class EngineeringBomEntryScreen extends StatefulWidget {
  final String tenantId;
  final String? initialInquiryId;
  final String? initialCustomer;
  final String? initialProject;
  final String? initialItemDescription;
  final double? initialQty;
  final String? initialInquiryItemId;
  final String? initialBomId;
  final bool readOnly;

  const EngineeringBomEntryScreen({
    super.key,
    required this.tenantId,
    this.initialInquiryId,
    this.initialCustomer,
    this.initialProject,
    this.initialItemDescription,
    this.initialQty,
    this.initialInquiryItemId,
    this.initialBomId,
    this.readOnly = false,
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
  final _revision = TextEditingController(text: 'A');
  final _lines = <BomLineDraft>[];
  final _fasteners = <FastenerBomLineDraft>[];
  final _gridScrollController = ScrollController();
  List<String> _visibleColumns =
      BomColumnConfig.presets['Customer BOM Format']!;
  List<BomCustomField> _customFields = const [];

  late String _bomId;
  bool _saving = false;
  bool _dirty = false;
  bool _forcedReadOnly = false;
  String _status = 'Draft';
  String _revisionReason = '';
  String _inquiryItemId = '';

  EngineeringBomRepository get _repository =>
      EngineeringBomRepository(tenantId: widget.tenantId.trim());

  MaterialMasterRepository get _materialRepository =>
      MaterialMasterRepository(tenantId: widget.tenantId.trim());

  @override
  void initState() {
    super.initState();
    _forcedReadOnly = widget.readOnly;
    _inquiryItemId = (widget.initialInquiryItemId ?? '').trim();
    _bomId = (widget.initialBomId ?? '').trim().isEmpty
        ? widget.tenantId.trim().isEmpty
              ? ''
              : _repository.newBomId()
        : widget.initialBomId!.trim();
    if ((widget.initialBomId ?? '').trim().isNotEmpty) {
      _loadExistingBom();
    } else if (widget.tenantId.trim().isNotEmpty) {
      _loadBomNo();
    }
    _inquiryId.text = (widget.initialInquiryId ?? '').trim();
    _customer.text = (widget.initialCustomer ?? '').trim();
    _project.text = (widget.initialProject ?? '').trim();
    if ((widget.initialQty ?? 0) > 0) {
      _projectQuantity.text = widget.initialQty!.toStringAsFixed(0);
    }
    _lines.add(BomLineDraft());
    _fasteners.add(FastenerBomLineDraft());
  }

  Future<void> _loadBomNo() async {
    final no = await _repository.nextBomNo();
    if (mounted && _bomNo.text.trim().isEmpty) {
      setState(() => _bomNo.text = no);
    }
  }

  Future<void> _loadExistingBom() async {
    final bom = await _repository.getBom(_bomId);
    if (!mounted || bom == null) return;
    debugPrint('BOM_FOUND bomId=${bom.id}');
    setState(() {
      _bomNo.text = bom.bomNo;
      _inquiryId.text = bom.inquiryId;
      _inquiryItemId = bom.inquiryItemId;
      _customer.text = bom.customer;
      _project.text = bom.project;
      _projectQuantity.text = bom.projectQuantity.toStringAsFixed(0);
      _revision.text = bom.revision;
      _status = bom.status;
      _revisionReason = bom.revisionReason;
      _visibleColumns = BomColumnConfig.sanitize(bom.visibleColumns);
      _customFields = bom.customFields;
      disposeStructureBomLines(_lines);
      disposeFastenerBomLines(_fasteners);
      _lines
        ..clear()
        ..addAll(structureDraftsFromBom(bom));
      _fasteners
        ..clear()
        ..addAll(fastenerDraftsFromBom(bom));
    });
  }

  double get _projectQty => double.tryParse(_projectQuantity.text.trim()) ?? 1;

  double get _weightPerStructure =>
      _lines.fold(0, (total, line) => total + line.lineWeight);

  double get _totalProjectWeight => _lines.fold(
    0,
    (total, line) =>
        total +
        BomWeightCalculator.totalProjectWeight(line.lineWeight, _projectQty),
  );

  void _updateDrafts(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
  }

  List<EngineeringBomLineModel> get _lineModels => structureBomModels(
    lines: _lines,
    projectQuantity: _projectQty,
    customFields: _customFields,
  );

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
      _dirty = true;
    });
  }

  Future<void> _refreshMaterialValues() async {
    if (widget.tenantId.trim().isEmpty) {
      _showMessage('Missing company workspace. Materials were not refreshed.');
      return;
    }

    final result = await refreshEngineeringBomMaterials(
      repository: _materialRepository,
      lines: _lines,
    );
    if (!mounted) return;
    setState(() => _dirty = true);
    _showMessage(
      result.missing == 0
          ? 'Refreshed ${result.refreshed} BOM material lines.'
          : 'Refreshed ${result.refreshed} lines. '
                '${result.missing} material codes not found.',
    );
  }

  Future<void> _saveBom({String status = 'Saved'}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.tenantId.trim().isEmpty) {
      _showMessage('Missing company workspace. BOM was not saved.');
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await saveEngineeringBomDraft(
        repository: _repository,
        bomId: _bomId,
        bomNo: _bomNo.text.trim(),
        inquiryId: _inquiryId.text.trim(),
        inquiryItemId: _inquiryItemId,
        customer: _customer.text.trim(),
        project: _project.text.trim(),
        revision: _revision.text,
        status: status,
        revisionReason: _revisionReason,
        projectQuantity: _projectQty,
        visibleColumns: _visibleColumns,
        customFields: _customFields,
        structureLines: _lines,
        fastenerDrafts: _fasteners,
        totalCalculatedWeight: _totalProjectWeight,
      );
      if (!mounted) return;
      setState(() {
        _bomId = result.bomId;
        _bomNo.text = result.bomNo;
        _revision.text = result.revision;
        _status = result.status;
        _dirty = false;
      });
      debugPrint(
        'INQUIRY_BOM_LINK inquiryId=${result.inquiryId} bomId=${result.bomId}',
      );
      _showMessage(
        result.createdNewRevision
            ? 'Approved BOM kept unchanged. Created Rev ${result.revision}.'
            : status == 'Draft'
            ? 'BOM draft saved.'
            : 'Engineering BOM saved.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to save BOM: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createRevision() async {
    final reason = await askEngineeringBomRevisionReason(context);
    if (reason == null) return;
    setState(() {
      _revisionReason = reason;
      _dirty = true;
    });
    await _saveBom(status: 'Draft');
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

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
    disposeStructureBomLines(_lines);
    disposeFastenerBomLines(_fasteners);
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EngineeringBomEntryScaffold(
      dirty: _dirty,
      saving: _saving,
      readOnly: _forcedReadOnly || _status.toLowerCase() == 'approved',
      confirmDiscard: () async =>
          !_dirty || await confirmDiscardEngineeringBomChanges(context),
      onGenerateQuotation: _openQuotation,
      onRefreshMaterials: _refreshMaterialValues,
      onCreateRevision: _createRevision,
      onSaveDraft: () => _saveBom(status: 'Draft'),
      onSave: _saveBom,
      child: EngineeringBomEntryBody(
        formKey: _formKey,
        bomNo: _bomNo,
        inquiryId: _inquiryId,
        customer: _customer,
        project: _project,
        projectQuantity: _projectQuantity,
        revision: _revision,
        status: _status,
        revisionReason: _revisionReason,
        lines: _lines,
        fasteners: _fasteners,
        visibleColumns: _visibleColumns,
        customFields: _customFields,
        projectQty: _projectQty,
        weightPerStructure: _weightPerStructure,
        totalProjectWeight: _totalProjectWeight,
        tenantId: widget.tenantId,
        scrollController: _gridScrollController,
        onChanged: () => setState(() => _dirty = true),
        onAddLine: () => _updateDrafts(() => addStructureBomLine(_lines)),
        onDeleteLine: (index) =>
            _updateDrafts(() => removeStructureBomLine(_lines, index)),
        onCustomizeColumns: _customizeColumns,
        onAddFastener: () =>
            _updateDrafts(() => addFastenerBomLine(_fasteners)),
        onDeleteFastener: (index) =>
            _updateDrafts(() => removeFastenerBomLine(_fasteners, index)),
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
