import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/inspections/models/inspection_model.dart';
import 'package:QUIK/modules/production/inspections/repositories/inspection_repository.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';

class InspectionEntryScreen extends StatefulWidget {
  final String tenantId;

  const InspectionEntryScreen({super.key, required this.tenantId});

  @override
  State<InspectionEntryScreen> createState() => _InspectionEntryScreenState();
}

class _InspectionEntryScreenState extends State<InspectionEntryScreen> {
  static const _clientStatuses = ['pending', 'approved', 'rejected'];
  static const _dispatchStatuses = ['pending', 'approved', 'rejected'];

  final _formKey = GlobalKey<FormState>();
  late final String _inspectionId;

  final _inspectedQty = TextEditingController();
  final _approvedQty = TextEditingController();
  final _rejectedQty = TextEditingController();
  final _rejectionReason = TextEditingController();
  final _inspectorName = TextEditingController();
  final _delayReason = TextEditingController();
  final _remarks = TextEditingController();

  JobCardModel? _selectedJobCard;
  DateTime _inspectionDate = DateTime.now();
  bool _clientInspectionRequired = false;
  String _clientInspectionStatus = 'pending';
  String _dispatchClearanceStatus = 'pending';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _inspectionId = _activeTenantId.isEmpty ? '' : _repository.newInspectionId();
  }

  String get _activeTenantId => context.tenant.selectedTenantId.trim();

  InspectionRepository get _repository =>
      InspectionRepository(tenantId: _activeTenantId);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_activeTenantId.isEmpty) {
      _showSnack('Missing company workspace. Inspection was not saved.');
      return;
    }
    final jobCard = _selectedJobCard;
    if (jobCard == null) {
      _showSnack('Job Card is required.');
      return;
    }

    setState(() => _saving = true);
    try {
      final createdBy = FirebaseAuth.instance.currentUser?.uid ?? '';
      final inspection = InspectionModel(
        inspectionId: _inspectionId,
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        jobCardId: jobCard.jobCardId,
        jobCardNo: jobCard.jobCardNo,
        projectCode: jobCard.projectCode,
        productName: jobCard.productName.isEmpty
            ? jobCard.productCode
            : jobCard.productName,
        inspectionDate: _inspectionDate,
        dispatchCommitmentDate: jobCard.dispatchCommitmentDate,
        inspectedQty: _num(_inspectedQty),
        approvedQty: _num(_approvedQty),
        rejectedQty: _num(_rejectedQty),
        rejectionReason: _rejectionReason.text.trim(),
        inspectorName: _inspectorName.text.trim(),
        clientInspectionRequired: _clientInspectionRequired,
        clientInspectionStatus: _clientInspectionStatus,
        dispatchClearanceStatus: _dispatchClearanceStatus,
        delayReason: _delayReason.text.trim(),
        remarks: _remarks.text.trim(),
        createdBy: createdBy,
      );

      await _repository.saveInspection(inspection);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save inspection: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickInspectionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inspectionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _inspectionDate = picked);
  }

  @override
  void dispose() {
    _inspectedQty.dispose();
    _approvedQty.dispose();
    _rejectedQty.dispose();
    _rejectionReason.dispose();
    _inspectorName.dispose();
    _delayReason.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTenantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Select a company workspace first.')),
      );
    }

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: const Text('Create Inspection Entry'),
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
                child: StreamBuilder<List<JobCardModel>>(
                  stream: _repository.watchJobCards(),
                  builder: (context, snapshot) {
                    final cards = snapshot.data ?? const <JobCardModel>[];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedJobCard?.jobCardId,
                          decoration: const InputDecoration(
                            labelText: 'Select Job Card',
                          ),
                          items: cards
                              .map(
                                (card) => DropdownMenuItem(
                                  value: card.jobCardId,
                                  child: Text(
                                    '${card.jobCardNo} • ${card.productName.isEmpty ? card.productCode : card.productName}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            setState(() {
                              _selectedJobCard = _findJobCard(cards, value);
                            });
                          },
                          validator: (_) => _selectedJobCard == null
                              ? 'Job Card is required'
                              : null,
                        ),
                        if (_isDispatchNear(_selectedJobCard)) ...[
                          const SizedBox(height: 12),
                          _AlertCard(
                            message:
                                'Dispatch commitment is near and clearance is still pending.',
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Inspection Quantities',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dateButton(
                      label: 'Inspection Date',
                      value: _inspectionDate,
                      onTap: _pickInspectionDate,
                    ),
                    _field(
                      _inspectedQty,
                      'Inspected Qty',
                      required: true,
                      number: true,
                      validator: _validateInspectedQty,
                    ),
                    _field(
                      _approvedQty,
                      'Approved Qty',
                      required: true,
                      number: true,
                      validator: _validateQtyPart,
                    ),
                    _field(
                      _rejectedQty,
                      'Rejected Qty',
                      required: true,
                      number: true,
                      validator: _validateQtyPart,
                    ),
                    _field(_rejectionReason, 'Rejection Reason', width: 520),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Clearance',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _field(_inspectorName, 'Inspector Name', width: 240),
                    SizedBox(
                      width: 260,
                      child: SwitchListTile(
                        value: _clientInspectionRequired,
                        onChanged: (value) {
                          setState(() => _clientInspectionRequired = value);
                        },
                        title: const Text('Client Inspection Required'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    _dropdown(
                      label: 'Client Inspection Status',
                      value: _clientInspectionStatus,
                      values: _clientStatuses,
                      onChanged: (value) {
                        setState(() => _clientInspectionStatus = value);
                      },
                    ),
                    _dropdown(
                      label: 'Dispatch Clearance',
                      value: _dispatchClearanceStatus,
                      values: _dispatchStatuses,
                      onChanged: (value) {
                        setState(() => _dispatchClearanceStatus = value);
                      },
                    ),
                    _field(_delayReason, 'Delay Reason', width: 520),
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

  String? _validateInspectedQty(String? value) {
    final qty = double.tryParse((value ?? '').trim()) ?? 0;
    if (qty <= 0) return 'Inspected qty must be > 0';
    return _validateQtyTotal();
  }

  String? _validateQtyPart(String? value) {
    final qty = double.tryParse((value ?? '').trim()) ?? -1;
    if (qty < 0) return 'Qty is invalid';
    return _validateQtyTotal();
  }

  String? _validateQtyTotal() {
    final inspected = _num(_inspectedQty);
    final approved = _num(_approvedQty);
    final rejected = _num(_rejectedQty);
    if (inspected <= 0) return null;
    if ((approved + rejected - inspected).abs() > 0.001) {
      return 'Approved + rejected must match inspected qty';
    }
    return null;
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
      width: 240,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 240,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text('$label: ${_dateLabel(value)}'),
        ),
      ),
    );
  }

  bool _isDispatchNear(JobCardModel? card) {
    final date = card?.dispatchCommitmentDate;
    if (date == null || _dispatchClearanceStatus != 'pending') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = target.difference(today).inDays;
    return days >= 0 && days <= 3;
  }

  JobCardModel? _findJobCard(List<JobCardModel> cards, String? jobCardId) {
    if (jobCardId == null) return null;
    for (final card in cards) {
      if (card.jobCardId == jobCardId) return card;
    }
    return null;
  }

  double _num(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
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

class _AlertCard extends StatelessWidget {
  final String message;

  const _AlertCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
