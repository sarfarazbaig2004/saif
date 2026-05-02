import 'package:flutter/material.dart';

import 'package:QUIK/modules/production/core/production_list_scaffold.dart';
import 'package:QUIK/modules/production/galvanizing/models/galvanizing_job_model.dart';
import 'package:QUIK/modules/production/galvanizing/repositories/galvanizing_job_repository.dart';
import 'package:QUIK/modules/production/galvanizing/screens/galvanizing_job_detail_screen.dart';
import 'package:QUIK/modules/production/galvanizing/screens/galvanizing_send_screen.dart';

class GalvanizingJobListScreen extends StatelessWidget {
  final String tenantId;

  const GalvanizingJobListScreen({super.key, required this.tenantId});

  Future<void> _openSend(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GalvanizingSendScreen(tenantId: activeTenantId),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Galvanizing job saved successfully')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = GalvanizingJobRepository(tenantId: activeTenantId);

    return ProductionListScaffold<GalvanizingJobModel>(
      title: 'Galvanizing Vendor Tracking',
      subtitle:
          'Track fabrication material sent to galvanizing vendors and received back',
      icon: Icons.hot_tub_outlined,
      stream: repository.watchGalvanizingJobs(),
      emptyTitle: 'No galvanizing jobs yet',
      emptyMessage:
          'Send material to a galvanizing vendor from a Job Card to start tracking sent, received, shortage, excess, and payable amount.',
      headerAction: FilledButton.icon(
        onPressed: () => _openSend(context, activeTenantId),
        icon: const Icon(Icons.add),
        label: const Text('Send to Vendor'),
      ),
      itemBuilder: (context, job) {
        final subtitle = [
          job.vendorName,
          if (job.jobCardNo.isNotEmpty) 'JC ${job.jobCardNo}',
          '${job.sentWeightKg.toStringAsFixed(2)} kg sent',
          '${job.receivedWeightKg.toStringAsFixed(2)} kg received',
        ].where((item) => item.trim().isNotEmpty).join(' • ');

        return ProductionListTile(
          icon: Icons.hot_tub_outlined,
          title: job.jobCardNo.isEmpty ? job.vendorName : job.jobCardNo,
          subtitle: subtitle,
          trailing: job.status,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GalvanizingJobDetailScreen(
                tenantId: activeTenantId,
                galvanizingJob: job,
              ),
            ),
          ),
        );
      },
    );
  }
}
