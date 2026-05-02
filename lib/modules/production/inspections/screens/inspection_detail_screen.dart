import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/inspections/models/inspection_model.dart';
import 'package:QUIK/modules/production/inspections/screens/inspection_status_screen.dart';

class InspectionDetailScreen extends StatelessWidget {
  final String tenantId;
  final InspectionModel inspection;

  const InspectionDetailScreen({
    super.key,
    required this.tenantId,
    required this.inspection,
  });

  Future<void> _update(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionStatusScreen(
          tenantId: activeTenantId,
          inspection: inspection,
        ),
      ),
    );
    if (saved == true && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Select a company workspace first.')),
      );
    }

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: Text(inspection.jobCardNo),
        actions: [
          TextButton.icon(
            onPressed: () => _update(context, activeTenantId),
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Update Status'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(inspection: inspection),
            if (inspection.isPendingNearDispatch) ...[
              const SizedBox(height: 12),
              const _AlertCard(
                message:
                    'Dispatch commitment is near and clearance is still pending.',
              ),
            ],
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Job Card Link',
              children: [
                _DetailRow(label: 'Job Card No', value: inspection.jobCardNo),
                _DetailRow(label: 'Job Card ID', value: inspection.jobCardId),
                _DetailRow(label: 'Project Code', value: inspection.projectCode),
                _DetailRow(label: 'Product', value: inspection.productName),
                _DetailRow(
                  label: 'Dispatch Commitment',
                  value: _date(inspection.dispatchCommitmentDate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Inspection',
              children: [
                _DetailRow(
                  label: 'Inspection Date',
                  value: _date(inspection.inspectionDate),
                ),
                _DetailRow(
                  label: 'Inspected Qty',
                  value: inspection.inspectedQty.toStringAsFixed(2),
                ),
                _DetailRow(
                  label: 'Approved Qty',
                  value: inspection.approvedQty.toStringAsFixed(2),
                ),
                _DetailRow(
                  label: 'Rejected Qty',
                  value: inspection.rejectedQty.toStringAsFixed(2),
                ),
                _DetailRow(
                  label: 'Rejection Reason',
                  value: inspection.rejectionReason,
                ),
                _DetailRow(
                  label: 'Inspector',
                  value: inspection.inspectorName,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Clearance',
              children: [
                _DetailRow(
                  label: 'Client Inspection Required',
                  value: inspection.clientInspectionRequired ? 'yes' : 'no',
                ),
                _DetailRow(
                  label: 'Client Inspection Status',
                  value: inspection.clientInspectionStatus,
                ),
                _DetailRow(
                  label: 'Dispatch Clearance',
                  value: inspection.dispatchClearanceStatus,
                ),
                _DetailRow(
                  label: 'Dispatch Allowed',
                  value: inspection.isDispatchAllowed ? 'yes' : 'no',
                ),
                _DetailRow(label: 'Delay Reason', value: inspection.delayReason),
                _DetailRow(label: 'Remarks', value: inspection.remarks),
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
  final InspectionModel inspection;

  const _Header({required this.inspection});

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
            child: Icon(Icons.fact_check_outlined, color: zBlue),
          ),
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inspection.jobCardNo,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inspection.productName,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _Pill(label: 'Client', value: inspection.clientInspectionStatus),
          _Pill(label: 'Dispatch', value: inspection.dispatchClearanceStatus),
          _Pill(
            label: 'Allowed',
            value: inspection.isDispatchAllowed ? 'yes' : 'no',
          ),
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
        '$label: ${value.isEmpty ? '-' : value}',
        style: const TextStyle(
          color: zText,
          fontSize: 12.5,
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
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String message;

  const _AlertCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
              message,
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
