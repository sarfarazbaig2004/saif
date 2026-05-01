import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/dispatch/models/dispatch_model.dart';
import 'package:QUIK/modules/dispatch/repositories/dispatch_repository.dart';
import 'package:QUIK/modules/dispatch/screens/dispatch_create_screen.dart';
import 'package:QUIK/modules/dispatch/screens/dispatch_detail_screen.dart';
import 'package:QUIK/modules/production/inspections/models/inspection_model.dart';

class DispatchListScreen extends StatelessWidget {
  final String tenantId;

  const DispatchListScreen({super.key, required this.tenantId});

  Future<void> _openCreate(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DispatchCreateScreen(tenantId: activeTenantId),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Dispatch saved successfully')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = context.watchTenant.selectedTenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = DispatchRepository(tenantId: activeTenantId);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onCreate: () => _openCreate(context, activeTenantId)),
                const SizedBox(height: 12),
                StreamBuilder<List<InspectionModel>>(
                  stream: repository.watchApprovedInspections(),
                  builder: (context, inspectionSnapshot) {
                    final inspections =
                        inspectionSnapshot.data ?? const <InspectionModel>[];
                    return StreamBuilder<List<DispatchModel>>(
                      stream: repository.watchDispatches(),
                      builder: (context, dispatchSnapshot) {
                        if ((inspectionSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                dispatchSnapshot.connectionState ==
                                    ConnectionState.waiting) &&
                            !inspectionSnapshot.hasData &&
                            !dispatchSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: CircularProgressIndicator(color: zBlue),
                            ),
                          );
                        }

                        if (inspectionSnapshot.hasError ||
                            dispatchSnapshot.hasError) {
                          return _EmptyState(
                            icon: Icons.error_outline,
                            title: 'Unable to load dispatches',
                            message:
                                '${inspectionSnapshot.error ?? dispatchSnapshot.error}',
                          );
                        }

                        final dispatches =
                            dispatchSnapshot.data ?? const <DispatchModel>[];
                        final pending = _pendingRows(inspections, dispatches);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PendingSummary(rows: pending),
                            const SizedBox(height: 12),
                            if (dispatches.isEmpty)
                              const _EmptyState(
                                icon: Icons.local_shipping_outlined,
                                title: 'No dispatches yet',
                                message:
                                    'Create a dispatch only after inspection clearance is approved.',
                              )
                            else
                              Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < dispatches.length;
                                    index++
                                  ) ...[
                                    _DispatchTile(
                                      dispatch: dispatches[index],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DispatchDetailScreen(
                                            tenantId: activeTenantId,
                                            dispatch: dispatches[index],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index != dispatches.length - 1)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_PendingDispatchRow> _pendingRows(
    List<InspectionModel> inspections,
    List<DispatchModel> dispatches,
  ) {
    return inspections
        .map((inspection) {
          final dispatched = dispatches
              .where((dispatch) => dispatch.jobCardId == inspection.jobCardId)
              .fold<double>(0, (sum, dispatch) => sum + dispatch.dispatchQty);
          return _PendingDispatchRow(
            jobCardNo: inspection.jobCardNo,
            productName: inspection.productName,
            approvedQty: inspection.approvedQty,
            dispatchedQty: dispatched,
          );
        })
        .where((row) => row.pendingQty > 0)
        .toList(growable: false);
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCreate;

  const _Header({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: zBlueSoft,
            child: Icon(Icons.local_shipping_outlined, color: zBlue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispatch',
                  style: TextStyle(
                    color: zText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track final material dispatch after approved inspection clearance',
                  style: TextStyle(
                    color: zMuted,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create Dispatch'),
          ),
        ],
      ),
    );
  }
}

class _PendingDispatchRow {
  final String jobCardNo;
  final String productName;
  final double approvedQty;
  final double dispatchedQty;

  const _PendingDispatchRow({
    required this.jobCardNo,
    required this.productName,
    required this.approvedQty,
    required this.dispatchedQty,
  });

  double get pendingQty => approvedQty - dispatchedQty;
}

class _PendingSummary extends StatelessWidget {
  final List<_PendingDispatchRow> rows;

  const _PendingSummary({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Dispatch Per Job Card',
            style: TextStyle(
              color: zText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'No approved quantity is pending dispatch.',
              style: TextStyle(
                color: zMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: rows
                  .map(
                    (row) => Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: zSurfaceSoft,
                        border: Border.all(color: zBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.jobCardNo,
                            style: const TextStyle(
                              color: zText,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: zMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pending ${row.pendingQty.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: zBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _DispatchTile extends StatelessWidget {
  final DispatchModel dispatch;
  final VoidCallback onTap;

  const _DispatchTile({required this.dispatch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      dispatch.productName,
      if (dispatch.projectCode.isNotEmpty) dispatch.projectCode,
      'Qty ${dispatch.dispatchQty.toStringAsFixed(2)}',
      if (dispatch.vehicleNumber.isNotEmpty) dispatch.vehicleNumber,
    ].where((item) => item.trim().isNotEmpty).join(' • ');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: dispatch.isDelayed ? Colors.red.shade200 : zBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: dispatch.isDelayed
                  ? Colors.red.shade50
                  : zBlueSoft,
              child: Icon(
                dispatch.isDelayed
                    ? Icons.warning_amber_outlined
                    : Icons.local_shipping_outlined,
                color: dispatch.isDelayed ? Colors.red.shade700 : zBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dispatch.jobCardNo.isEmpty
                        ? dispatch.productName
                        : dispatch.jobCardNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: zText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: zMuted,
                      fontSize: 12.6,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              dispatch.dispatchStatus,
              style: const TextStyle(
                color: zMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: zMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: zBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: zMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: zText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: zMuted,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
