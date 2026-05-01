import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/galvanizing/models/galvanizing_job_model.dart';
import 'package:QUIK/modules/production/galvanizing/repositories/galvanizing_job_repository.dart';

class GalvanizingReceiveScreen extends StatefulWidget {
  final String tenantId;
  final GalvanizingJobModel galvanizingJob;

  const GalvanizingReceiveScreen({
    super.key,
    required this.tenantId,
    required this.galvanizingJob,
  });

  @override
  State<GalvanizingReceiveScreen> createState() =>
      _GalvanizingReceiveScreenState();
}

class _GalvanizingReceiveScreenState extends State<GalvanizingReceiveScreen> {
  static const _statuses = ['sent', 'partial', 'received', 'closed'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _receivedWeightKg;
  late final TextEditingController _ratePerKg;
  late final TextEditingController _remarks;
  late DateTime _receivedDate;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _receivedWeightKg = TextEditingController(
      text: _numText(widget.galvanizingJob.receivedWeightKg),
    );
    _ratePerKg = TextEditingController(
      text: _numText(widget.galvanizingJob.ratePerKg),
    );
    _remarks = TextEditingController(text: widget.galvanizingJob.remarks);
    _receivedDate = widget.galvanizingJob.receivedDate ?? DateTime.now();
    _status = _statuses.contains(widget.galvanizingJob.status)
        ? widget.galvanizingJob.status
        : 'partial';
  }

  String get _activeTenantId => context.tenant.selectedTenantId.trim();

  GalvanizingJobRepository get _repository =>
      GalvanizingJobRepository(tenantId: _activeTenantId);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_activeTenantId.isEmpty) {
      _showSnack('Missing company workspace. Galvanizing job was not saved.');
      return;
    }

    setState(() => _saving = true);
    try {
      final receivedWeightKg =
          double.tryParse(_receivedWeightKg.text.trim()) ?? 0;
      final ratePerKg = double.tryParse(_ratePerKg.text.trim()) ?? 0;
      final shortageKg = GalvanizingJobModel.shortageFor(
        widget.galvanizingJob.sentWeightKg,
        receivedWeightKg,
      );
      final excessKg = GalvanizingJobModel.excessFor(
        widget.galvanizingJob.sentWeightKg,
        receivedWeightKg,
      );
      final amount = receivedWeightKg * ratePerKg;

      final updated = GalvanizingJobModel(
        galvanizingJobId: widget.galvanizingJob.galvanizingJobId,
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        vendorId: widget.galvanizingJob.vendorId,
        vendorName: widget.galvanizingJob.vendorName,
        jobCardId: widget.galvanizingJob.jobCardId,
        jobCardNo: widget.galvanizingJob.jobCardNo,
        sendDate: widget.galvanizingJob.sendDate,
        sentWeightKg: widget.galvanizingJob.sentWeightKg,
        receivedDate: _receivedDate,
        receivedWeightKg: receivedWeightKg,
        shortageKg: shortageKg,
        excessKg: excessKg,
        ratePerKg: ratePerKg,
        amount: amount,
        status: _status,
        remarks: _remarks.text.trim(),
        createdBy: widget.galvanizingJob.createdBy,
        createdAt: widget.galvanizingJob.createdAt,
      );

      await _repository.saveGalvanizingJob(updated);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to receive galvanizing job: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickReceivedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _receivedDate = picked);
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
        title: const Text('Receive from Galvanizing Vendor'),
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
              _SummaryCard(job: widget.galvanizingJob),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Receive Details',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dateButton(
                      label: 'Received Date',
                      value: _receivedDate,
                      onTap: _pickReceivedDate,
                    ),
                    _field(
                      _receivedWeightKg,
                      'Received Weight Kg',
                      required: true,
                      number: true,
                      validator: (value) {
                        final received =
                            double.tryParse((value ?? '').trim()) ?? -1;
                        if (received < 0) return 'Received weight is invalid';
                        final logicalMax =
                            widget.galvanizingJob.sentWeightKg * 1.10;
                        if (received > logicalMax) {
                          return 'Received exceeds logical limit';
                        }
                        return null;
                      },
                    ),
                    _field(
                      _ratePerKg,
                      'Rate Per Kg',
                      number: true,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        final rate = double.tryParse(text) ?? -1;
                        return rate >= 0 ? null : 'Rate is invalid';
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

  Widget _dateButton({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 220,
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

class _SummaryCard extends StatelessWidget {
  final GalvanizingJobModel job;

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
          _metric('Vendor', job.vendorName),
          _metric('Job Card', job.jobCardNo),
          _metric('Sent', '${job.sentWeightKg.toStringAsFixed(2)} kg'),
          _metric('Received', '${job.receivedWeightKg.toStringAsFixed(2)} kg'),
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
