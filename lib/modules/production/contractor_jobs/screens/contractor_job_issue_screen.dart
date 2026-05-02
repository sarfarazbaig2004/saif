import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/contractor_jobs/models/contractor_job_model.dart';
import 'package:QUIK/modules/production/contractor_jobs/repositories/contractor_job_repository.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';

class ContractorJobIssueScreen extends StatefulWidget {
  final String tenantId;

  const ContractorJobIssueScreen({super.key, required this.tenantId});

  @override
  State<ContractorJobIssueScreen> createState() =>
      _ContractorJobIssueScreenState();
}

class _ContractorJobIssueScreenState extends State<ContractorJobIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _jobId;

  final _contractorId = TextEditingController();
  final _contractorName = TextEditingController();
  final _issueWeightKg = TextEditingController();
  final _ratePerKg = TextEditingController();
  final _remarks = TextEditingController();

  JobCardModel? _selectedJobCard;
  DateTime _issueDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _jobId = _activeTenantId.isEmpty ? '' : _repository.newJobId();
  }

  String get _activeTenantId => widget.tenantId.trim();

  ContractorJobRepository get _repository =>
      ContractorJobRepository(tenantId: _activeTenantId);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_activeTenantId.isEmpty) {
      _showSnack('Missing company workspace. Contractor job was not saved.');
      return;
    }
    final jobCard = _selectedJobCard;
    if (jobCard == null) {
      _showSnack('Job Card is required.');
      return;
    }

    setState(() => _saving = true);
    try {
      final issueWeightKg = double.tryParse(_issueWeightKg.text.trim()) ?? 0;
      final ratePerKg = double.tryParse(_ratePerKg.text.trim()) ?? 0;
      final createdBy = FirebaseAuth.instance.currentUser?.uid ?? '';

      final job = ContractorJobModel(
        jobId: _jobId,
        tenantId: _activeTenantId,
        companyId: _activeTenantId,
        contractorId: _contractorId.text.trim(),
        contractorName: _contractorName.text.trim(),
        jobCardId: jobCard.jobCardId,
        jobCardNo: jobCard.jobCardNo,
        projectCode: jobCard.projectCode,
        productName: jobCard.productName,
        issueDate: _issueDate,
        issueWeightKg: issueWeightKg,
        receivedWeightKg: 0,
        pendingWeightKg: issueWeightKg,
        ratePerKg: ratePerKg,
        amount: 0,
        status: 'issued',
        remarks: _remarks.text.trim(),
        createdBy: createdBy,
      );

      await _repository.saveContractorJob(job);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to issue contractor job: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _issueDate = picked);
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
    _contractorId.dispose();
    _contractorName.dispose();
    _issueWeightKg.dispose();
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
        title: const Text('Issue to Contractor'),
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
                title: 'Contractor',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _field(_contractorId, 'Contractor ID'),
                    _field(_contractorName, 'Contractor Name', required: true),
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
                title: 'Issue Details',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dateButton(
                      label: 'Issue Date',
                      value: _issueDate,
                      onTap: _pickIssueDate,
                    ),
                    _field(
                      _issueWeightKg,
                      'Issue Weight Kg',
                      required: true,
                      number: true,
                      validator: (value) {
                        final weight =
                            double.tryParse((value ?? '').trim()) ?? 0;
                        return weight > 0 ? null : 'Issue weight must be > 0';
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

  JobCardModel? _findJobCard(List<JobCardModel> cards, String? jobCardId) {
    if (jobCardId == null) return null;
    for (final card in cards) {
      if (card.jobCardId == jobCardId) return card;
    }
    return null;
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
