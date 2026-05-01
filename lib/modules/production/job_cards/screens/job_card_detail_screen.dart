import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';
import 'package:QUIK/modules/production/job_cards/screens/job_card_form_screen.dart';

class JobCardDetailScreen extends StatelessWidget {
  final String tenantId;
  final JobCardModel jobCard;

  const JobCardDetailScreen({
    super.key,
    required this.tenantId,
    required this.jobCard,
  });

  Future<void> _edit(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            JobCardFormScreen(tenantId: activeTenantId, jobCard: jobCard),
      ),
    );

    if (saved == true && context.mounted) {
      Navigator.pop(context);
    }
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
        title: Text(jobCard.jobCardNo),
        actions: [
          TextButton.icon(
            onPressed: () => _edit(context, activeTenantId),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(jobCard: jobCard),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Order Details',
              children: [
                _detail('Project Code', jobCard.projectCode),
                _detail('Customer', jobCard.customerName),
                _detail('PO Number', jobCard.poNumber),
                _detail('Product Code', jobCard.productCode),
                _detail('Product Name', jobCard.productName),
                _detail('Drawing No', jobCard.drawingNo),
                _detail('Drawing Revision', jobCard.drawingRevision),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Planning',
              children: [
                _detail('BOM ID', jobCard.bomId),
                _detail('BOQ ID', jobCard.boqId),
                _detail('Planned Qty', _qty(jobCard.plannedQty, jobCard.unit)),
                _detail(
                  'Completed Qty',
                  _qty(jobCard.completedQty, jobCard.unit),
                ),
                _detail('Balance Qty', _qty(jobCard.balanceQty, jobCard.unit)),
                _detail('Planned Start', _date(jobCard.plannedStartDate)),
                _detail('Planned End', _date(jobCard.plannedEndDate)),
                _detail(
                  'Dispatch Commitment',
                  _date(jobCard.dispatchCommitmentDate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Status',
              children: [
                _detail('Priority', jobCard.priority),
                _detail('Status', jobCard.status),
                _detail('Delay Reason', jobCard.delayReason),
                _detail('Remarks', jobCard.remarks),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return _DetailRow(label: label, value: value.trim().isEmpty ? '-' : value);
  }

  String _qty(double value, String unit) {
    return '${value.toStringAsFixed(2)} ${unit.trim().isEmpty ? 'nos' : unit}';
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

class _SummaryCard extends StatelessWidget {
  final JobCardModel jobCard;

  const _SummaryCard({required this.jobCard});

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
            child: Icon(Icons.assignment_outlined, color: zBlue),
          ),
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobCard.jobCardNo,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jobCard.productName.isEmpty
                      ? jobCard.productCode
                      : jobCard.productName,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _Pill(label: 'Status', value: jobCard.status),
          _Pill(label: 'Priority', value: jobCard.priority),
          _Pill(
            label: 'Balance',
            value: '${jobCard.balanceQty.toStringAsFixed(2)} ${jobCard.unit}',
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
              value,
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
