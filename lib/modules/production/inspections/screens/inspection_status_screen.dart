import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/inspections/models/inspection_model.dart';
import 'package:QUIK/modules/production/inspections/repositories/inspection_repository.dart';

class InspectionStatusScreen extends StatefulWidget {
  final String tenantId;
  final InspectionModel inspection;

  const InspectionStatusScreen({
    super.key,
    required this.tenantId,
    required this.inspection,
  });

  @override
  State<InspectionStatusScreen> createState() => _InspectionStatusScreenState();
}

class _InspectionStatusScreenState extends State<InspectionStatusScreen> {
  static const _clientStatuses = ['pending', 'approved', 'rejected'];
  static const _dispatchStatuses = ['pending', 'approved', 'rejected'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _approvedQty;
  late final TextEditingController _rejectedQty;
  late final TextEditingController _rejectionReason;
  late final TextEditingController _inspectorName;
  late final TextEditingController _delayReason;
  late final TextEditingController _remarks;
  late bool _clientInspectionRequired;
  late String _clientInspectionStatus;
  late String _dispatchClearanceStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final inspection = widget.inspection;
    _approvedQty = TextEditingController(text: _numText(inspection.approvedQty));
    _rejectedQty = TextEditingController(text: _numText(inspection.rejectedQty));
    _rejectionReason = TextEditingController(text: inspection.rejectionReason);
    _inspectorName = TextEditingController(text: inspection.inspectorName);
    _delayReason = TextEditingController(text: inspection.delayReason);
    _remarks = TextEditingController(text: inspection.remarks);
    _clientInspectionRequired = inspection.clientInspectionRequired;
    _clientInspectionStatus = _clientStatuses.contains(
      inspection.clientInspectionStatus,
    )
        ? inspection.clientInspectionStatus
        : 'pending';
    _dispatchClearanceStatus = _dispatchStatuses.contains(
      inspection.dispatchClearanceStatus,
    )
        ? inspection.dispatchClearanceStatus
        : 'pending';
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

    setState(() => _saving = true);
    try {
      final base = widget.inspection;
      final updated = InspectionModel(
        inspectionId: base.inspectionId,
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        jobCardId: base.jobCardId,
        jobCardNo: base.jobCardNo,
        projectCode: base.projectCode,
        productName: base.productName,
        inspectionDate: base.inspectionDate,
        dispatchCommitmentDate: base.dispatchCommitmentDate,
        inspectedQty: base.inspectedQty,
        approvedQty: _num(_approvedQty),
        rejectedQty: _num(_rejectedQty),
        rejectionReason: _rejectionReason.text.trim(),
        inspectorName: _inspectorName.text.trim(),
        clientInspectionRequired: _clientInspectionRequired,
        clientInspectionStatus: _clientInspectionStatus,
        dispatchClearanceStatus: _dispatchClearanceStatus,
        delayReason: _delayReason.text.trim(),
        remarks: _remarks.text.trim(),
        createdBy: base.createdBy,
        createdAt: base.createdAt,
      );

      await _repository.saveInspection(updated);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to update inspection: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
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
        title: const Text('Update Inspection Status'),
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
              _SummaryCard(inspection: widget.inspection),
              if (_isPendingNearDispatch) ...[
                const SizedBox(height: 12),
                const _AlertCard(
                  message:
                      'Dispatch commitment is near and clearance is still pending.',
                ),
              ],
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Quantity Status',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
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

  String? _validateQtyPart(String? value) {
    final qty = double.tryParse((value ?? '').trim()) ?? -1;
    if (qty < 0) return 'Qty is invalid';
    final approved = _num(_approvedQty);
    final rejected = _num(_rejectedQty);
    if ((approved + rejected - widget.inspection.inspectedQty).abs() > 0.001) {
      return 'Approved + rejected must match inspected qty';
    }
    return null;
  }

  bool get _isPendingNearDispatch {
    final dispatchDate = widget.inspection.dispatchCommitmentDate;
    if (_dispatchClearanceStatus != 'pending' || dispatchDate == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      dispatchDate.year,
      dispatchDate.month,
      dispatchDate.day,
    );
    final days = target.difference(today).inDays;
    return days >= 0 && days <= 3;
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

  double _num(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  String _numText(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
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

class _SummaryCard extends StatelessWidget {
  final InspectionModel inspection;

  const _SummaryCard({required this.inspection});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metric('Job Card', inspection.jobCardNo),
          _metric('Product', inspection.productName),
          _metric('Inspected', inspection.inspectedQty.toStringAsFixed(2)),
          _metric('Dispatch Status', inspection.dispatchClearanceStatus),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: zMuted,
              fontSize: 12.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              color: zText,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
