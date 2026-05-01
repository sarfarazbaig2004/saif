import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';
import 'package:QUIK/modules/production/job_cards/repositories/job_card_repository.dart';

class JobCardFormScreen extends StatefulWidget {
  final String tenantId;
  final JobCardModel? jobCard;

  const JobCardFormScreen({super.key, required this.tenantId, this.jobCard});

  @override
  State<JobCardFormScreen> createState() => _JobCardFormScreenState();
}

class _JobCardFormScreenState extends State<JobCardFormScreen> {
  static const _priorities = ['low', 'normal', 'high', 'urgent'];
  static const _statuses = [
    'draft',
    'planned',
    'in_progress',
    'on_hold',
    'completed',
    'cancelled',
  ];

  final _formKey = GlobalKey<FormState>();
  late final String _jobCardId;

  final _jobCardNo = TextEditingController();
  final _projectCode = TextEditingController();
  final _customerName = TextEditingController();
  final _poNumber = TextEditingController();
  final _productCode = TextEditingController();
  final _productName = TextEditingController();
  final _drawingNo = TextEditingController();
  final _drawingRevision = TextEditingController();
  final _bomId = TextEditingController();
  final _boqId = TextEditingController();
  final _plannedQty = TextEditingController();
  final _completedQty = TextEditingController(text: '0');
  final _unit = TextEditingController(text: 'nos');
  final _delayReason = TextEditingController();
  final _remarks = TextEditingController();

  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;
  DateTime? _dispatchCommitmentDate;
  String _priority = 'normal';
  String _status = 'draft';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _jobCardId =
        widget.jobCard?.jobCardId ??
        (_activeTenantId.isEmpty ? '' : _repository.newJobCardId());
    _hydrate();
  }

  String get _activeTenantId {
    return context.tenant.selectedTenantId.trim();
  }

  JobCardRepository get _repository =>
      JobCardRepository(tenantId: _activeTenantId);

  void _hydrate() {
    final jobCard = widget.jobCard;
    if (jobCard == null) {
      _jobCardNo.text = 'JC-${DateTime.now().millisecondsSinceEpoch}';
      return;
    }

    _jobCardNo.text = jobCard.jobCardNo;
    _projectCode.text = jobCard.projectCode;
    _customerName.text = jobCard.customerName;
    _poNumber.text = jobCard.poNumber;
    _productCode.text = jobCard.productCode;
    _productName.text = jobCard.productName;
    _drawingNo.text = jobCard.drawingNo;
    _drawingRevision.text = jobCard.drawingRevision;
    _bomId.text = jobCard.bomId;
    _boqId.text = jobCard.boqId;
    _plannedQty.text = _numText(jobCard.plannedQty);
    _completedQty.text = _numText(jobCard.completedQty);
    _unit.text = jobCard.unit.isEmpty ? 'nos' : jobCard.unit;
    _plannedStartDate = jobCard.plannedStartDate;
    _plannedEndDate = jobCard.plannedEndDate;
    _dispatchCommitmentDate = jobCard.dispatchCommitmentDate;
    _priority = _priorities.contains(jobCard.priority)
        ? jobCard.priority
        : 'normal';
    _status = _statuses.contains(jobCard.status) ? jobCard.status : 'draft';
    _delayReason.text = jobCard.delayReason;
    _remarks.text = jobCard.remarks;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_activeTenantId.isEmpty) {
      _showSnack('Missing company workspace. Job card was not saved.');
      return;
    }
    if (_dispatchCommitmentDate == null) {
      _showSnack('Dispatch commitment date is required.');
      return;
    }

    setState(() => _saving = true);
    try {
      final plannedQty = double.tryParse(_plannedQty.text.trim()) ?? 0;
      final completedQty = double.tryParse(_completedQty.text.trim()) ?? 0;
      final balanceQty = plannedQty - completedQty;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final jobCard = JobCardModel(
        jobCardId: _jobCardId,
        jobCardNo: _jobCardNo.text.trim(),
        projectCode: _projectCode.text.trim(),
        customerName: _customerName.text.trim(),
        poNumber: _poNumber.text.trim(),
        productCode: _productCode.text.trim(),
        productName: _productName.text.trim(),
        drawingNo: _drawingNo.text.trim(),
        drawingRevision: _drawingRevision.text.trim(),
        bomId: _bomId.text.trim(),
        boqId: _boqId.text.trim(),
        plannedQty: plannedQty,
        completedQty: completedQty,
        balanceQty: balanceQty < 0 ? 0 : balanceQty,
        unit: _unit.text.trim().isEmpty ? 'nos' : _unit.text.trim(),
        plannedStartDate: _plannedStartDate,
        plannedEndDate: _plannedEndDate,
        dispatchCommitmentDate: _dispatchCommitmentDate,
        priority: _priority,
        status: _status,
        delayReason: _delayReason.text.trim(),
        remarks: _remarks.text.trim(),
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        createdBy: widget.jobCard?.createdBy ?? uid,
        createdAt: widget.jobCard?.createdAt,
      );

      await _repository.saveJobCard(jobCard);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save job card: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _pickDate({
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onChanged(picked));
  }

  @override
  void dispose() {
    _jobCardNo.dispose();
    _projectCode.dispose();
    _customerName.dispose();
    _poNumber.dispose();
    _productCode.dispose();
    _productName.dispose();
    _drawingNo.dispose();
    _drawingRevision.dispose();
    _bomId.dispose();
    _boqId.dispose();
    _plannedQty.dispose();
    _completedQty.dispose();
    _unit.dispose();
    _delayReason.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: Text(
          widget.jobCard == null ? 'Create Job Card' : 'Edit Job Card',
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Job Card',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _field(_jobCardNo, 'Job Card No', required: true),
                    _field(_projectCode, 'Project Code'),
                    _field(_customerName, 'Customer Name'),
                    _field(_poNumber, 'PO Number'),
                    _dropdown(
                      label: 'Priority',
                      value: _priority,
                      values: _priorities,
                      onChanged: (value) => setState(() => _priority = value),
                    ),
                    _dropdown(
                      label: 'Status',
                      value: _status,
                      values: _statuses,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Product and Drawing',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _field(_productCode, 'Product Code', required: true),
                    _field(_productName, 'Product Name'),
                    _field(_drawingNo, 'Drawing No'),
                    _field(_drawingRevision, 'Drawing Revision', width: 170),
                    _field(_bomId, 'BOM ID'),
                    _field(_boqId, 'BOQ ID'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Quantity and Dates',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _field(
                      _plannedQty,
                      'Planned Qty',
                      required: true,
                      number: true,
                      validator: (value) {
                        final qty = double.tryParse((value ?? '').trim()) ?? 0;
                        return qty > 0 ? null : 'Planned Qty must be > 0';
                      },
                    ),
                    _field(_completedQty, 'Completed Qty', number: true),
                    _field(_unit, 'Unit', width: 120),
                    _dateButton(
                      label: 'Planned Start',
                      value: _plannedStartDate,
                      onTap: () => _pickDate(
                        value: _plannedStartDate,
                        onChanged: (value) => _plannedStartDate = value,
                      ),
                    ),
                    _dateButton(
                      label: 'Planned End',
                      value: _plannedEndDate,
                      onTap: () => _pickDate(
                        value: _plannedEndDate,
                        onChanged: (value) => _plannedEndDate = value,
                      ),
                    ),
                    _dateButton(
                      label: 'Dispatch Commitment',
                      value: _dispatchCommitmentDate,
                      required: true,
                      onTap: () => _pickDate(
                        value: _dispatchCommitmentDate,
                        onChanged: (value) => _dispatchCommitmentDate = value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Notes',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _field(_delayReason, 'Delay Reason', width: 360),
                    _field(_remarks, 'Remarks', width: 520, maxLines: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    double width = 240,
    bool required = false,
    bool number = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator:
            validator ??
            (required
                ? (value) =>
                      (value ?? '').trim().isEmpty ? '$label is required' : null
                : null),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        validator: (value) =>
            (value ?? '').trim().isEmpty ? '$label is required' : null,
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool required = false,
  }) {
    final missingRequired = required && value == null;
    return SizedBox(
      width: 220,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value == null
                ? '$label${required ? ' *' : ''}'
                : '$label: ${_dateLabel(value)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: missingRequired ? Colors.red.shade700 : null,
          side: BorderSide(
            color: missingRequired ? Colors.red.shade300 : zBorder,
          ),
        ),
      ),
    );
  }

  String _numText(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _dateLabel(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: zText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
