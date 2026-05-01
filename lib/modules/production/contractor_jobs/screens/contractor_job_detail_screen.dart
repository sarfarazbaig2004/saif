import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/contractor_jobs/models/contractor_job_model.dart';
import 'package:QUIK/modules/production/contractor_jobs/screens/contractor_job_receive_screen.dart';

class ContractorJobDetailScreen extends StatelessWidget {
  final String tenantId;
  final ContractorJobModel contractorJob;

  const ContractorJobDetailScreen({
    super.key,
    required this.tenantId,
    required this.contractorJob,
  });

  Future<void> _receive(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContractorJobReceiveScreen(
          tenantId: activeTenantId,
          contractorJob: contractorJob,
        ),
      ),
    );
    if (saved == true && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = context.watchTenant.selectedTenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Select a company workspace first.')),
      );
    }

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: Text(contractorJob.contractorName),
        actions: [
          TextButton.icon(
            onPressed: () => _receive(context, activeTenantId),
            icon: const Icon(Icons.call_received_outlined),
            label: const Text('Receive'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(job: contractorJob),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Job Link',
              children: [
                _DetailRow(
                  label: 'Job Card No',
                  value: contractorJob.jobCardNo,
                ),
                _DetailRow(
                  label: 'Project Code',
                  value: contractorJob.projectCode,
                ),
                _DetailRow(
                  label: 'Product Name',
                  value: contractorJob.productName,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Contractor Work',
              children: [
                _DetailRow(
                  label: 'Contractor ID',
                  value: contractorJob.contractorId,
                ),
                _DetailRow(
                  label: 'Contractor Name',
                  value: contractorJob.contractorName,
                ),
                _DetailRow(
                  label: 'Issue Date',
                  value: _date(contractorJob.issueDate),
                ),
                _DetailRow(
                  label: 'Issued Weight',
                  value: '${contractorJob.issueWeightKg.toStringAsFixed(2)} kg',
                ),
                _DetailRow(
                  label: 'Received Weight',
                  value:
                      '${contractorJob.receivedWeightKg.toStringAsFixed(2)} kg',
                ),
                _DetailRow(
                  label: 'Pending Weight',
                  value:
                      '${contractorJob.pendingWeightKg.toStringAsFixed(2)} kg',
                ),
                _DetailRow(
                  label: 'Rate',
                  value: '${contractorJob.ratePerKg.toStringAsFixed(2)} / kg',
                ),
                _DetailRow(
                  label: 'Amount',
                  value: contractorJob.amount.toStringAsFixed(2),
                ),
                _DetailRow(label: 'Status', value: contractorJob.status),
                _DetailRow(label: 'Remarks', value: contractorJob.remarks),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '-';
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

class _Header extends StatelessWidget {
  final ContractorJobModel job;

  const _Header({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: zBlueSoft,
            child: Icon(Icons.engineering_outlined, color: zBlue),
          ),
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.contractorName,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.jobCardNo} • ${job.productName}',
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _Pill(label: 'Status', value: job.status),
          _Pill(
            label: 'Pending',
            value: '${job.pendingWeightKg.toStringAsFixed(2)} kg',
          ),
          _Pill(label: 'Amount', value: job.amount.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: zSurfaceSoft,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: ${value.trim().isEmpty ? '-' : value}',
        style: const TextStyle(
          color: zText,
          fontSize: 12.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: zMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(
                color: zText,
                fontSize: 13.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
