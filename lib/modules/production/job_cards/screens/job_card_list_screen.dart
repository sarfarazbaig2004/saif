import 'package:flutter/material.dart';

import 'package:QUIK/modules/production/core/production_list_scaffold.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';
import 'package:QUIK/modules/production/job_cards/repositories/job_card_repository.dart';
import 'package:QUIK/modules/production/job_cards/screens/job_card_detail_screen.dart';
import 'package:QUIK/modules/production/job_cards/screens/job_card_form_screen.dart';

class JobCardListScreen extends StatelessWidget {
  final String tenantId;

  const JobCardListScreen({super.key, required this.tenantId});

  Future<void> _openForm(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JobCardFormScreen(tenantId: activeTenantId),
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Job card saved successfully')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = JobCardRepository(tenantId: activeTenantId);

    return ProductionListScaffold<JobCardModel>(
      title: 'Job Cards',
      subtitle:
          'Tenant-specific fabrication job cards for production planning and tracking',
      icon: Icons.assignment_outlined,
      stream: repository.watchJobCards(),
      emptyTitle: 'No job cards yet',
      emptyMessage:
          'Create a job card when a fabrication order is ready for planning. Job cards stay inside the selected company workspace.',
      headerAction: FilledButton.icon(
        onPressed: () => _openForm(context, activeTenantId),
        icon: const Icon(Icons.add),
        label: const Text('New Job Card'),
      ),
      itemBuilder: (context, jobCard) {
        final subtitle = [
          if (jobCard.projectCode.isNotEmpty) jobCard.projectCode,
          if (jobCard.customerName.isNotEmpty) jobCard.customerName,
          if (jobCard.productCode.isNotEmpty) jobCard.productCode,
          '${jobCard.balanceQty.toStringAsFixed(2)} ${jobCard.unit} balance',
        ].join(' • ');

        return ProductionListTile(
          icon: Icons.assignment_outlined,
          title: '${jobCard.jobCardNo}  ${jobCard.productName}',
          subtitle: subtitle,
          trailing: jobCard.status,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobCardDetailScreen(
                tenantId: activeTenantId,
                jobCard: jobCard,
              ),
            ),
          ),
        );
      },
    );
  }
}
