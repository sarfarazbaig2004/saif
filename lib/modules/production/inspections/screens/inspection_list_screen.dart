import 'package:flutter/material.dart';

import 'package:QUIK/modules/production/core/production_list_scaffold.dart';
import 'package:QUIK/modules/production/inspections/models/inspection_model.dart';
import 'package:QUIK/modules/production/inspections/repositories/inspection_repository.dart';
import 'package:QUIK/modules/production/inspections/screens/inspection_detail_screen.dart';
import 'package:QUIK/modules/production/inspections/screens/inspection_entry_screen.dart';

class InspectionListScreen extends StatelessWidget {
  final String tenantId;

  const InspectionListScreen({super.key, required this.tenantId});

  Future<void> _openCreate(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionEntryScreen(tenantId: activeTenantId),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Inspection saved successfully')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = InspectionRepository(tenantId: activeTenantId);

    return ProductionListScaffold<InspectionModel>(
      title: 'Inspection & Dispatch Clearance',
      subtitle:
          'Control quality approvals and dispatch clearance before material leaves the factory',
      icon: Icons.fact_check_outlined,
      stream: repository.watchInspections(),
      emptyTitle: 'No inspections yet',
      emptyMessage:
          'Create an inspection entry from a Job Card to track approved quantity, rejection, client inspection, and dispatch clearance.',
      headerAction: FilledButton.icon(
        onPressed: () => _openCreate(context, activeTenantId),
        icon: const Icon(Icons.add),
        label: const Text('Create Inspection'),
      ),
      itemBuilder: (context, inspection) {
        final subtitle = [
          inspection.productName,
          if (inspection.projectCode.isNotEmpty) inspection.projectCode,
          'Inspected ${inspection.inspectedQty.toStringAsFixed(2)}',
          'Approved ${inspection.approvedQty.toStringAsFixed(2)}',
        ].where((item) => item.trim().isNotEmpty).join(' • ');

        return Column(
          children: [
            if (inspection.isPendingNearDispatch)
              const _NearDispatchAlert()
            else
              const SizedBox.shrink(),
            ProductionListTile(
              icon: Icons.fact_check_outlined,
              title: inspection.jobCardNo.isEmpty
                  ? inspection.productName
                  : inspection.jobCardNo,
              subtitle: subtitle,
              trailing: inspection.dispatchClearanceStatus,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InspectionDetailScreen(
                    tenantId: activeTenantId,
                    inspection: inspection,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NearDispatchAlert extends StatelessWidget {
  const _NearDispatchAlert();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dispatch date is near and clearance is still pending.',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
