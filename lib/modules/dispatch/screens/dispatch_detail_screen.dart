import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/dispatch/models/dispatch_model.dart';

class DispatchDetailScreen extends StatelessWidget {
  final String tenantId;
  final DispatchModel dispatch;

  const DispatchDetailScreen({
    super.key,
    required this.tenantId,
    required this.dispatch,
  });

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
      appBar: AppBar(title: Text(dispatch.jobCardNo)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(dispatch: dispatch),
            if (dispatch.isDelayed) ...[
              const SizedBox(height: 12),
              const _DelayAlert(),
            ],
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Job Card',
              children: [
                _DetailRow(label: 'Job Card No', value: dispatch.jobCardNo),
                _DetailRow(label: 'Job Card ID', value: dispatch.jobCardId),
                _DetailRow(
                  label: 'Inspection ID',
                  value: dispatch.inspectionId,
                ),
                _DetailRow(label: 'Project Code', value: dispatch.projectCode),
                _DetailRow(label: 'Product', value: dispatch.productName),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Dispatch',
              children: [
                _DetailRow(
                  label: 'Dispatch Date',
                  value: _date(dispatch.dispatchDate),
                ),
                _DetailRow(
                  label: 'Commitment Date',
                  value: _date(dispatch.dispatchCommitmentDate),
                ),
                _DetailRow(
                  label: 'Dispatch Qty',
                  value: dispatch.dispatchQty.toStringAsFixed(2),
                ),
                _DetailRow(
                  label: 'Approved Qty',
                  value: dispatch.approvedQty.toStringAsFixed(2),
                ),
                _DetailRow(label: 'Status', value: dispatch.dispatchStatus),
                _DetailRow(label: 'Delay Reason', value: dispatch.delayReason),
                _DetailRow(label: 'Remarks', value: dispatch.remarks),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Transport',
              children: [
                _DetailRow(
                  label: 'Vehicle Number',
                  value: dispatch.vehicleNumber,
                ),
                _DetailRow(label: 'Driver Name', value: dispatch.driverName),
                _DetailRow(
                  label: 'Transport Name',
                  value: dispatch.transportName,
                ),
                _DetailRow(label: 'LR Number', value: dispatch.lrNumber),
                _DetailRow(
                  label: 'Invoice Number',
                  value: dispatch.invoiceNumber,
                ),
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
  final DispatchModel dispatch;

  const _Header({required this.dispatch});

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
            child: Icon(Icons.local_shipping_outlined, color: zBlue),
          ),
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dispatch.jobCardNo,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dispatch.productName,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _Pill(label: 'Status', value: dispatch.dispatchStatus),
          _Pill(label: 'Qty', value: dispatch.dispatchQty.toStringAsFixed(2)),
          _Pill(label: 'Vehicle', value: dispatch.vehicleNumber),
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

class _DelayAlert extends StatelessWidget {
  const _DelayAlert();

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
              'Dispatch date is after the commitment date.',
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
