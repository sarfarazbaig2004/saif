import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_customer_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_project_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_financial_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_terms_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_document_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_items_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_header_card.dart';

class CustomerPoDetailScreen extends StatelessWidget {
  final String companyId;
  final String docId;

  const CustomerPoDetailScreen({
    super.key,
    required this.companyId,
    required this.docId,
  });

  static const _maxWidth = 960.0;

  String _fmt(dynamic v) => (v ?? '').toString().trim();

  double _num(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    if (v is Timestamp) return DateFormat('dd MMM yyyy').format(v.toDate());
    final parsed = DateTime.tryParse(v.toString());
    if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    return '—';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue.shade700;
      case 'approved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      case 'in production':
        return Colors.orange.shade800;
      case 'partially dispatched':
        return Colors.deepPurple.shade600;
      case 'completed':
        return Colors.teal.shade700;
      case 'closed':
        return Colors.blueGrey.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue.shade50;
      case 'approved':
        return Colors.green.shade50;
      case 'rejected':
        return Colors.red.shade50;
      case 'in production':
        return Colors.orange.shade50;
      case 'partially dispatched':
        return Colors.deepPurple.shade50;
      case 'completed':
        return Colors.teal.shade50;
      case 'closed':
        return Colors.blueGrey.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('customer_pos')
          .doc(docId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the document')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
        title: const Text(
          'Customer PO',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit PO',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerPoFormScreen(
                  companyId: companyId,
                  existingDocId: docId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('customer_pos')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final d = snapshot.data!.data()!;
          final status = _fmt(d['status']).isEmpty
              ? 'draft'
              : _fmt(d['status']);
          final items = (d['items'] as List<dynamic>?) ?? [];
          final currency = NumberFormat('#,##0.00', 'en_IN');

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  PoHeaderCard(
                    pageContext: context,
                    data: d,
                    status: status,
                    currency: currency,
                    formatValue: _fmt,
                    formatDate: _formatDate,
                    numberValue: _num,
                    statusColor: _statusColor,
                    statusBg: _statusBg,
                    updateStatus: _updateStatus,
                  ),
                  const SizedBox(height: 16),
                  PoCustomerCard(
                    data: d,
                    formatValue: _fmt,
                    row2: _row2,
                    labelValue: _labelValue,
                  ),
                  const SizedBox(height: 16),
                  PoProjectCard(
                    data: d,
                    formatValue: _fmt,
                    row2: _row2,
                    labelValue: _labelValue,
                  ),
                  const SizedBox(height: 16),
                  PoItemsCard(
                    items: items,
                    currency: currency,
                    formatValue: _fmt,
                    numberValue: _num,
                  ),
                  const SizedBox(height: 16),
                  PoFinancialCard(
                    data: d,
                    currency: currency,
                    numberValue: _num,
                  ),
                  if (_hasTerms(d)) ...[
                    const SizedBox(height: 16),
                    PoTermsCard(
                      data: d,
                      formatValue: _fmt,
                      labelValue: _labelValue,
                    ),
                  ],
                  if (_fmt(d['poDocumentUrl']).isNotEmpty ||
                      _fmt(d['poFileName']).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PoDocumentCard(
                      data: d,
                      formatValue: _fmt,
                      formatDate: _formatDate,
                      openUrl: _openUrl,
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasTerms(Map<String, dynamic> d) {
    for (final key in [
      'paymentTerms',
      'deliveryTerms',
      'inspectionRequirement',
      'warranty',
      'ldClause',
    ]) {
      if (_fmt(d[key]).isNotEmpty) return true;
    }
    return false;
  }

  Widget _row2(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
