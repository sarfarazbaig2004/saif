import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/production/core/production_list_scaffold.dart';
import 'package:QUIK/modules/production/masters/models/process_model.dart';
import 'package:QUIK/modules/production/masters/repositories/process_repository.dart';
import 'package:QUIK/modules/production/masters/screens/process_form_screen.dart';

class ProcessListScreen extends StatelessWidget {
  final String tenantId;

  const ProcessListScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final activeTenantId = context.watchTenant.selectedTenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = ProcessRepository(tenantId: activeTenantId);

    return ProductionListScaffold<ProcessModel>(
      title: 'Processes',
      subtitle:
          'Cutting, punching, bending, welding, galvanizing, and routing steps',
      icon: Icons.account_tree_outlined,
      stream: repository.watchProcesses(),
      emptyTitle: 'No processes configured',
      emptyMessage:
          'Seed tenant-specific shop-floor processes before building BOM routing.',
      headerAction: FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProcessFormScreen(tenantId: activeTenantId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Process'),
      ),
      itemBuilder: (context, process) {
        return ProductionListTile(
          icon: Icons.account_tree_outlined,
          title: '${process.processCode}  ${process.processName}',
          subtitle: process.operationType,
          trailing: 'Seq ${process.defaultSeq}',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProcessFormScreen(tenantId: activeTenantId, process: process),
            ),
          ),
        );
      },
    );
  }
}
