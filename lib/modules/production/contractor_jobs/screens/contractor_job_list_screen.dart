import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/production/contractor_jobs/models/contractor_job_model.dart';
import 'package:QUIK/modules/production/contractor_jobs/repositories/contractor_job_repository.dart';
import 'package:QUIK/modules/production/contractor_jobs/screens/contractor_job_detail_screen.dart';
import 'package:QUIK/modules/production/contractor_jobs/screens/contractor_job_issue_screen.dart';
import 'package:QUIK/modules/production/core/production_list_scaffold.dart';

class ContractorJobListScreen extends StatelessWidget {
  final String tenantId;

  const ContractorJobListScreen({super.key, required this.tenantId});

  Future<void> _openIssue(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContractorJobIssueScreen(tenantId: activeTenantId),
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Contractor job issued successfully')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = context.watchTenant.selectedTenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = ContractorJobRepository(tenantId: activeTenantId);

    return ProductionListScaffold<ContractorJobModel>(
      title: 'Contractor Job Work',
      subtitle:
          'Issue fabrication work to contractors and track pending, received, and completed weight',
      icon: Icons.engineering_outlined,
      stream: repository.watchContractorJobs(),
      intro: _ContractorJobReportStrip(
        stream: repository.watchContractorJobs(),
      ),
      emptyTitle: 'No contractor jobs yet',
      emptyMessage:
          'Issue a job card to a contractor to start tracking outside job work weight, pending quantity, and payable amount.',
      headerAction: FilledButton.icon(
        onPressed: () => _openIssue(context, activeTenantId),
        icon: const Icon(Icons.add),
        label: const Text('Issue to Contractor'),
      ),
      itemBuilder: (context, job) {
        final subtitle = [
          job.contractorName,
          if (job.jobCardNo.isNotEmpty) 'JC ${job.jobCardNo}',
          if (job.projectCode.isNotEmpty) job.projectCode,
          '${job.pendingWeightKg.toStringAsFixed(2)} kg pending',
        ].where((item) => item.trim().isNotEmpty).join(' • ');

        return ProductionListTile(
          icon: Icons.engineering_outlined,
          title: job.productName.isEmpty ? job.jobCardNo : job.productName,
          subtitle: subtitle,
          trailing: job.status,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContractorJobDetailScreen(
                tenantId: activeTenantId,
                contractorJob: job,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContractorJobReportStrip extends StatelessWidget {
  final Stream<List<ContractorJobModel>> stream;

  const _ContractorJobReportStrip({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContractorJobModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <ContractorJobModel>[];
        final pendingKg = jobs.fold<double>(
          0,
          (total, job) => total + job.pendingWeightKg,
        );
        final completedKg = jobs.fold<double>(
          0,
          (total, job) => total + job.receivedWeightKg,
        );
        final openJobs = jobs
            .where((job) => job.status != 'completed' && job.status != 'closed')
            .length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReportTile(
                label: 'Contractor Pending',
                value: '${pendingKg.toStringAsFixed(2)} kg',
                icon: Icons.pending_actions_outlined,
              ),
              _ReportTile(
                label: 'Contractor Completed',
                value: '${completedKg.toStringAsFixed(2)} kg',
                icon: Icons.task_alt_outlined,
              ),
              _ReportTile(
                label: 'Job-wise Status',
                value: '$openJobs open / ${jobs.length} total',
                icon: Icons.assignment_turned_in_outlined,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReportTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 210),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
