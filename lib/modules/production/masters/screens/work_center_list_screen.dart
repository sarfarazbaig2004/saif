import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/production/core/production_list_scaffold.dart';
import 'package:QUIK/modules/production/masters/models/work_center_model.dart';
import 'package:QUIK/modules/production/masters/repositories/work_center_repository.dart';
import 'package:QUIK/modules/production/masters/screens/work_center_form_screen.dart';

class WorkCenterListScreen extends StatelessWidget {
  final String tenantId;

  const WorkCenterListScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final activeTenantId = context.watchTenant.selectedTenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = WorkCenterRepository(tenantId: activeTenantId);

    return ProductionListScaffold<WorkCenterModel>(
      title: 'Work Centers',
      subtitle: 'Tenant-specific machines, bays, and shop-floor stations',
      icon: Icons.precision_manufacturing_outlined,
      stream: repository.watchWorkCenters(),
      emptyTitle: 'No work centers configured',
      emptyMessage:
          'Add cutting machines, punching stations, welding bays, or galvanizing vendors.',
      headerAction: FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkCenterFormScreen(tenantId: activeTenantId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Work Center'),
      ),
      itemBuilder: (context, workCenter) {
        return ProductionListTile(
          icon: Icons.precision_manufacturing_outlined,
          title: '${workCenter.workCenterCode}  ${workCenter.workCenterName}',
          subtitle: workCenter.location,
          trailing: '${workCenter.processIds.length} processes',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkCenterFormScreen(
                tenantId: activeTenantId,
                workCenter: workCenter,
              ),
            ),
          ),
        );
      },
    );
  }
}
