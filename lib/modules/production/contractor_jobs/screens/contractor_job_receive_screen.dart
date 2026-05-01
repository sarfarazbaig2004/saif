import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/contractor_jobs/models/contractor_job_model.dart';
import 'package:QUIK/modules/production/contractor_jobs/repositories/contractor_job_repository.dart';

class ContractorJobReceiveScreen extends StatefulWidget {
  final String tenantId;
  final ContractorJobModel contractorJob;

  const ContractorJobReceiveScreen({
    super.key,
    required this.tenantId,
    required this.contractorJob,
  });

  @override
  State<ContractorJobReceiveScreen> createState() =>
      _ContractorJobReceiveScreenState();
}

class _ContractorJobReceiveScreenState
    extends State<ContractorJobReceiveScreen> {
  static const _statuses = [
    'issued',
    'in_progress',
    'partial',
    'completed',
    'closed',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _receivedWeightKg;
  late final TextEditingController _ratePerKg;
  late final TextEditingController _remarks;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _receivedWeightKg = TextEditingController(
      text: _numText(widget.contractorJob.receivedWeightKg),
    );
    _ratePerKg = TextEditingController(
      text: _numText(widget.contractorJob.ratePerKg),
    );
    _remarks = TextEditingController(text: widget.contractorJob.remarks);
    _status = _statuses.contains(widget.contractorJob.status)
        ? widget.contractorJob.status
        : 'in_progress';
  }

  String get _activeTenantId => context.tenant.selectedTenantId.trim();

  ContractorJobRepository get _repository =>
      ContractorJobRepository(tenantId: _activeTenantId);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_activeTenantId.isEmpty) {
      _showSnack('Missing company workspace. Contractor job was not saved.');
      return;
    }

    setState(() => _saving = true);
    try {
      final receivedWeightKg =
          double.tryParse(_receivedWeightKg.text.trim()) ?? 0;
      final ratePerKg = double.tryParse(_ratePerKg.text.trim()) ?? 0;
      final pendingWeightKg =
          widget.contractorJob.issueWeightKg - receivedWeightKg;
      final amount = receivedWeightKg * ratePerKg;

      final updated = ContractorJobModel(
        jobId: widget.contractorJob.jobId,
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        contractorId: widget.contractorJob.contractorId,
        contractorName: widget.contractorJob.contractorName,
        jobCardId: widget.contractorJob.jobCardId,
        jobCardNo: widget.contractorJob.jobCardNo,
        projectCode: widget.contractorJob.projectCode,
        productName: widget.contractorJob.productName,
        issueDate: widget.contractorJob.issueDate,
        issueWeightKg: widget.contractorJob.issueWeightKg,
        receivedWeightKg: receivedWeightKg,
        pendingWeightKg: pendingWeightKg < 0 ? 0 : pendingWeightKg,
        ratePerKg: ratePerKg,
        amount: amount,
        status: _status,
        remarks: _remarks.text.trim(),
        createdBy: widget.contractorJob.createdBy,
        createdAt: widget.contractorJob.createdAt,
      );

      await _repository.saveContractorJob(updated);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to receive contractor job: $e');
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

  @override
  void dispose() {
    _receivedWeightKg.dispose();
    _ratePerKg.dispose();
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
        title: const Text('Receive from Contractor'),
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
              _SummaryCard(job: widget.contractorJob),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Receive Details',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _field(
                      _receivedWeightKg,
                      'Received Weight Kg',
                      required: true,
                      number: true,
                      validator: (value) {
                        final received =
                            double.tryParse((value ?? '').trim()) ?? 0;
                        if (received < 0) return 'Received weight is invalid';
                        if (received > widget.contractorJob.issueWeightKg) {
                          return 'Received cannot exceed issued weight';
                        }
                        return null;
                      },
                    ),
                    _field(
                      _ratePerKg,
                      'Rate Per Kg',
                      required: true,
                      number: true,
                      validator: (value) {
                        final rate = double.tryParse((value ?? '').trim()) ?? 0;
                        return rate > 0 ? null : 'Rate is required';
                      },
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _statuses
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                    ),
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

  String _numText(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _SummaryCard extends StatelessWidget {
  final ContractorJobModel job;

  const _SummaryCard({required this.job});

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
          _metric('Contractor', job.contractorName),
          _metric('Job Card', job.jobCardNo),
          _metric('Issued', '${job.issueWeightKg.toStringAsFixed(2)} kg'),
          _metric('Pending', '${job.pendingWeightKg.toStringAsFixed(2)} kg'),
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
