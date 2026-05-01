import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/dispatch/models/dispatch_model.dart';
import 'package:QUIK/modules/dispatch/repositories/dispatch_repository.dart';
import 'package:QUIK/modules/production/inspections/models/inspection_model.dart';

class DispatchCreateScreen extends StatefulWidget {
  final String tenantId;

  const DispatchCreateScreen({super.key, required this.tenantId});

  @override
  State<DispatchCreateScreen> createState() => _DispatchCreateScreenState();
}

class _DispatchCreateScreenState extends State<DispatchCreateScreen> {
  static const _statuses = ['planned', 'dispatched', 'delivered'];

  final _formKey = GlobalKey<FormState>();
  late final String _dispatchId;

  final _dispatchQty = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _driverName = TextEditingController();
  final _transportName = TextEditingController();
  final _lrNumber = TextEditingController();
  final _invoiceNumber = TextEditingController();
  final _delayReason = TextEditingController();
  final _remarks = TextEditingController();

  InspectionModel? _selectedInspection;
  DateTime _dispatchDate = DateTime.now();
  String _dispatchStatus = 'planned';
  double _alreadyDispatchedQty = 0;
  bool _loadingPending = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dispatchId = _activeTenantId.isEmpty ? '' : _repository.newDispatchId();
  }

  String get _activeTenantId => context.tenant.selectedTenantId.trim();

  DispatchRepository get _repository =>
      DispatchRepository(tenantId: _activeTenantId);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_activeTenantId.isEmpty) {
      _showSnack('Missing company workspace. Dispatch was not saved.');
      return;
    }
    final inspection = _selectedInspection;
    if (inspection == null) {
      _showSnack('Approved inspection is required.');
      return;
    }
    if (!inspection.isDispatchAllowed) {
      _showSnack('Dispatch blocked. Inspection clearance is not approved.');
      return;
    }

    setState(() => _saving = true);
    try {
      final createdBy = FirebaseAuth.instance.currentUser?.uid ?? '';
      final dispatch = DispatchModel(
        dispatchId: _dispatchId,
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        inspectionId: inspection.inspectionId,
        jobCardId: inspection.jobCardId,
        jobCardNo: inspection.jobCardNo,
        projectCode: inspection.projectCode,
        productName: inspection.productName,
        dispatchDate: _dispatchDate,
        dispatchCommitmentDate: inspection.dispatchCommitmentDate,
        dispatchQty: _num(_dispatchQty),
        approvedQty: inspection.approvedQty,
        vehicleNumber: _vehicleNumber.text.trim(),
        driverName: _driverName.text.trim(),
        transportName: _transportName.text.trim(),
        lrNumber: _lrNumber.text.trim(),
        invoiceNumber: _invoiceNumber.text.trim(),
        dispatchStatus: _dispatchStatus,
        delayReason: _delayReason.text.trim(),
        remarks: _remarks.text.trim(),
        createdBy: createdBy,
      );

      await _repository.saveDispatch(dispatch);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save dispatch: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadPending(InspectionModel? inspection) async {
    setState(() {
      _selectedInspection = inspection;
      _alreadyDispatchedQty = 0;
      _loadingPending = inspection != null;
    });
    if (inspection == null) return;
    final dispatched = await _repository.dispatchedQtyForJobCard(
      inspection.jobCardId,
    );
    if (!mounted) return;
    setState(() {
      _alreadyDispatchedQty = dispatched;
      _loadingPending = false;
    });
  }

  Future<void> _pickDispatchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dispatchDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dispatchDate = picked);
  }

  @override
  void dispose() {
    _dispatchQty.dispose();
    _vehicleNumber.dispose();
    _driverName.dispose();
    _transportName.dispose();
    _lrNumber.dispose();
    _invoiceNumber.dispose();
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
        title: const Text('Create Dispatch'),
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
                title: 'Approved Inspection',
                child: StreamBuilder<List<InspectionModel>>(
                  stream: _repository.watchApprovedInspections(),
                  builder: (context, snapshot) {
                    final inspections =
                        snapshot.data ?? const <InspectionModel>[];
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedInspection?.inspectionId,
                      decoration: const InputDecoration(
                        labelText: 'Select cleared Job Card',
                      ),
                      items: inspections
                          .map(
                            (inspection) => DropdownMenuItem(
                              value: inspection.inspectionId,
                              child: Text(
                                '${inspection.jobCardNo} • ${inspection.productName}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        _loadPending(_findInspection(inspections, value));
                      },
                      validator: (_) => _selectedInspection == null
                          ? 'Approved inspection is required'
                          : null,
                    );
                  },
                ),
              ),
              if (_selectedInspection != null) ...[
                const SizedBox(height: 12),
                _PendingCard(
                  inspection: _selectedInspection!,
                  alreadyDispatchedQty: _alreadyDispatchedQty,
                  loading: _loadingPending,
                ),
              ],
              if (_isDelayed) ...[
                const SizedBox(height: 12),
                const _DelayAlert(),
              ],
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Dispatch Details',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dateButton(
                      label: 'Dispatch Date',
                      value: _dispatchDate,
                      onTap: _pickDispatchDate,
                    ),
                    _field(
                      _dispatchQty,
                      'Dispatch Qty',
                      required: true,
                      number: true,
                      validator: _validateDispatchQty,
                    ),
                    _dropdown(
                      label: 'Dispatch Status',
                      value: _dispatchStatus,
                      values: _statuses,
                      onChanged: (value) {
                        setState(() => _dispatchStatus = value);
                      },
                    ),
                    _field(_vehicleNumber, 'Vehicle Number'),
                    _field(_driverName, 'Driver Name'),
                    _field(_transportName, 'Transport Name'),
                    _field(_lrNumber, 'LR Number'),
                    _field(_invoiceNumber, 'Invoice Number'),
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

  String? _validateDispatchQty(String? value) {
    final qty = double.tryParse((value ?? '').trim()) ?? 0;
    if (qty <= 0) return 'Dispatch qty must be > 0';
    final inspection = _selectedInspection;
    if (inspection == null) return null;
    final pending = inspection.approvedQty - _alreadyDispatchedQty;
    if (qty > pending) return 'Dispatch qty exceeds pending approved qty';
    return null;
  }

  bool get _isDelayed {
    final inspection = _selectedInspection;
    final commitment = inspection?.dispatchCommitmentDate;
    if (commitment == null) return false;
    final dispatchDay = DateTime(
      _dispatchDate.year,
      _dispatchDate.month,
      _dispatchDate.day,
    );
    final commitmentDay = DateTime(
      commitment.year,
      commitment.month,
      commitment.day,
    );
    return dispatchDay.isAfter(commitmentDay);
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

  InspectionModel? _findInspection(
    List<InspectionModel> inspections,
    String? inspectionId,
  ) {
    if (inspectionId == null) return null;
    for (final inspection in inspections) {
      if (inspection.inspectionId == inspectionId) return inspection;
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

class _PendingCard extends StatelessWidget {
  final InspectionModel inspection;
  final double alreadyDispatchedQty;
  final bool loading;

  const _PendingCard({
    required this.inspection,
    required this.alreadyDispatchedQty,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final pending = inspection.approvedQty - alreadyDispatchedQty;
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
          _metric('Approved', inspection.approvedQty.toStringAsFixed(2)),
          _metric(
            'Already Dispatched',
            loading ? 'Loading' : alreadyDispatchedQty.toStringAsFixed(2),
          ),
          _metric(
            'Pending Dispatch',
            loading ? 'Loading' : pending.toStringAsFixed(2),
          ),
          _metric('Commitment', _date(inspection.dispatchCommitmentDate)),
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
            value,
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

  String _date(DateTime? value) {
    if (value == null) return '-';
    return '${value.day}/${value.month}/${value.year}';
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

class _DelayAlert extends StatelessWidget {
  const _DelayAlert();

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
              'Dispatch date is after the commitment date.',
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
