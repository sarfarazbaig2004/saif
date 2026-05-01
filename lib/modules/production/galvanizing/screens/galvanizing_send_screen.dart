import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/galvanizing/models/galvanizing_job_model.dart';
import 'package:QUIK/modules/production/galvanizing/repositories/galvanizing_job_repository.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';

class GalvanizingSendScreen extends StatefulWidget {
  final String tenantId;

  const GalvanizingSendScreen({super.key, required this.tenantId});

  @override
  State<GalvanizingSendScreen> createState() => _GalvanizingSendScreenState();
}

class _GalvanizingSendScreenState extends State<GalvanizingSendScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _galvanizingJobId;

  final _vendorId = TextEditingController();
  final _vendorName = TextEditingController();
  final _sentWeightKg = TextEditingController();
  final _ratePerKg = TextEditingController();
  final _remarks = TextEditingController();

  JobCardModel? _selectedJobCard;
  DateTime _sendDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _galvanizingJobId = _activeTenantId.isEmpty
        ? ''
        : _repository.newGalvanizingJobId();
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
    final jobCard = _selectedJobCard;
    if (jobCard == null) {
      _showSnack('Job Card is required.');
      return;
    }

    setState(() => _saving = true);
    try {
      final sentWeightKg = double.tryParse(_sentWeightKg.text.trim()) ?? 0;
      final ratePerKg = double.tryParse(_ratePerKg.text.trim()) ?? 0;
      final createdBy = FirebaseAuth.instance.currentUser?.uid ?? '';

      final job = GalvanizingJobModel(
        galvanizingJobId: _galvanizingJobId,
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        vendorId: _vendorId.text.trim(),
        vendorName: _vendorName.text.trim(),
        jobCardId: jobCard.jobCardId,
        jobCardNo: jobCard.jobCardNo,
        sendDate: _sendDate,
        sentWeightKg: sentWeightKg,
        receivedDate: null,
        receivedWeightKg: 0,
        shortageKg: sentWeightKg,
        excessKg: 0,
        ratePerKg: ratePerKg,
        amount: 0,
        status: 'sent',
        remarks: _remarks.text.trim(),
        createdBy: createdBy,
      );

      await _repository.saveGalvanizingJob(job);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save galvanizing job: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickSendDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sendDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _sendDate = picked);
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
    _vendorId.dispose();
    _vendorName.dispose();
    _sentWeightKg.dispose();
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
        title: const Text('Send to Galvanizing Vendor'),
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
                title: 'Vendor',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _field(_vendorId, 'Vendor ID'),
                    _field(_vendorName, 'Vendor Name', required: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Job Card',
                child: StreamBuilder<List<JobCardModel>>(
                  stream: _repository.watchJobCards(),
                  builder: (context, snapshot) {
                    final cards = snapshot.data ?? const <JobCardModel>[];
                    return DropdownButtonFormField<String>(
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Send Details',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dateButton(
                      label: 'Send Date',
                      value: _sendDate,
                      onTap: _pickSendDate,
                    ),
                    _field(
                      _sentWeightKg,
                      'Sent Weight Kg',
                      required: true,
                      number: true,
                      validator: (value) {
                        final weight =
                            double.tryParse((value ?? '').trim()) ?? 0;
                        return weight > 0 ? null : 'Sent weight must be > 0';
                      },
                    ),
                    _field(
                      _ratePerKg,
                      'Rate Per Kg',
                      number: true,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        final rate = double.tryParse(text) ?? 0;
                        return rate >= 0 ? null : 'Rate is invalid';
                      },
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

  JobCardModel? _findJobCard(List<JobCardModel> cards, String? jobCardId) {
    if (jobCardId == null) return null;
    for (final card in cards) {
      if (card.jobCardId == jobCardId) return card;
    }
    return null;
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
