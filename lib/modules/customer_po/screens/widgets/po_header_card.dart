import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_revision_badge.dart';

class PoHeaderCard extends StatelessWidget {
  final BuildContext pageContext;
  final Map<String, dynamic> data;
  final String status;
  final NumberFormat currency;
  final String Function(dynamic value) formatValue;
  final String Function(dynamic value) formatDate;
  final double Function(dynamic value) numberValue;
  final Color Function(String status) statusColor;
  final Color Function(String status) statusBg;
  final void Function(BuildContext context, String newStatus) updateStatus;

  const PoHeaderCard({
    super.key,
    required this.pageContext,
    required this.data,
    required this.status,
    required this.currency,
    required this.formatValue,
    required this.formatDate,
    required this.numberValue,
    required this.statusColor,
    required this.statusBg,
    required this.updateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return PoSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _leftInfo()),
          _rightStatus(),
        ],
      ),
    );
  }

  Widget _leftInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatValue(data['poNumber']).isEmpty
              ? 'PO Number Missing'
              : formatValue(data['poNumber']),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        PoRevisionBadge(
          revisionNo: numberValue(data['revisionNo']).toInt(),
          isAmended: data['isAmended'] == true,
        ),
        const SizedBox(height: 6),
        Text(
          'Date: ${formatDate(data['poDate'])}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          'Created: ${formatDate(data['createdAt'])}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _rightStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Change Status',
          onSelected: (newStatus) => updateStatus(pageContext, newStatus),
          itemBuilder: (_) => CustomerPoModel.statusOptions.map((s) {
            return PopupMenuItem<String>(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(s),
                ],
              ),
            );
          }).toList(),
          child: _statusBadge(),
        ),
        const SizedBox(height: 12),
        Text(
          '₹ ${currency.format(numberValue(data['totalValue']))}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2563EB),
          ),
        ),
        Text(
          'Total Value',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusBg(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: statusColor(status),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 16, color: statusColor(status)),
        ],
      ),
    );
  }
}
