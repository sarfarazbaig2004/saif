import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_section_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_customer_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_project_card.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/po_financial_card.dart';

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
                  _headerCard(context, d, status, currency),
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
                  _itemsCard(items, currency),
                  const SizedBox(height: 16),
                  PoFinancialCard(
                    data: d,
                    currency: currency,
                    numberValue: _num,
                  ),
                  if (_hasTerms(d)) ...[
                    const SizedBox(height: 16),
                    _termsCard(d),
                  ],
                  if (_fmt(d['poDocumentUrl']).isNotEmpty ||
                      _fmt(d['poFileName']).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _documentCard(context, d),
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

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _headerCard(
    BuildContext context,
    Map<String, dynamic> d,
    String status,
    NumberFormat currency,
  ) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmt(d['poNumber']).isEmpty
                      ? 'PO Number Missing'
                      : _fmt(d['poNumber']),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Date: ${_formatDate(d['poDate'])}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_formatDate(d['createdAt'])}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Change Status',
                onSelected: (newStatus) => _updateStatus(context, newStatus),
                itemBuilder: (_) => CustomerPoModel.statuses.map((s) {
                  return PopupMenuItem<String>(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _statusColor(s),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(s),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
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
                          color: _statusColor(status),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: _statusColor(status),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₹ ${currency.format(_num(d['totalValue']))}',
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
          ),
        ],
      ),
    );
  }

  // ── Customer ─────────────────────────────────────────────────────────────────

  // ── Project ───────────────────────────────────────────────────────────────────

  // ── Items ─────────────────────────────────────────────────────────────────────

  Widget _itemsCard(List<dynamic> items, NumberFormat currency) {
    return _card(
      title: 'PO Items',
      child: items.isEmpty
          ? const Text(
              'No items recorded.',
              style: TextStyle(color: Colors.grey),
            )
          : Column(
              children: [
                _itemsHeader(),
                const SizedBox(height: 8),
                ...items.asMap().entries.map(
                  (entry) => _itemRow(entry.key, entry.value, currency),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '₹ ${currency.format(items.fold<double>(0, (acc, item) {
                        final m = item as Map<String, dynamic>;
                        return acc + _num(m['amount']);
                      }))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _itemsHeader() {
    const style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: Color(0xFF64748B),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Description', style: style)),
          Expanded(
            flex: 1,
            child: Text('Qty', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 1,
            child: Text('Unit', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Rate', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text('Amount', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(int index, dynamic item, NumberFormat currency) {
    final m = item as Map<String, dynamic>;
    final isEven = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _fmt(m['description']).isEmpty ? '—' : _fmt(m['description']),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _num(
                m['quantity'],
              ).toStringAsFixed(_num(m['quantity']) % 1 == 0 ? 0 : 2),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _fmt(m['unit']),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹ ${currency.format(_num(m['rate']))}',
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹ ${currency.format(_num(m['amount']))}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Financial Summary ─────────────────────────────────────────────────────────

  // ── Terms ─────────────────────────────────────────────────────────────────────

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

  Widget _termsCard(Map<String, dynamic> d) {
    return _card(
      title: 'Terms & Conditions',
      child: Column(
        children: [
          if (_fmt(d['paymentTerms']).isNotEmpty)
            _labelValue('Payment Terms', _fmt(d['paymentTerms'])),
          if (_fmt(d['deliveryTerms']).isNotEmpty) ...[
            const SizedBox(height: 10),
            _labelValue('Delivery Terms', _fmt(d['deliveryTerms'])),
          ],
          if (_fmt(d['inspectionRequirement']).isNotEmpty) ...[
            const SizedBox(height: 10),
            _labelValue('Inspection', _fmt(d['inspectionRequirement'])),
          ],
          if (_fmt(d['warranty']).isNotEmpty) ...[
            const SizedBox(height: 10),
            _labelValue('Warranty', _fmt(d['warranty'])),
          ],
          if (_fmt(d['ldClause']).isNotEmpty) ...[
            const SizedBox(height: 10),
            _labelValue('LD Clause', _fmt(d['ldClause'])),
          ],
        ],
      ),
    );
  }

  // ── Document ──────────────────────────────────────────────────────────────────

  Widget _documentCard(BuildContext context, Map<String, dynamic> d) {
    final url = _fmt(d['poDocumentUrl']);
    final fileName = _fmt(d['poFileName']);
    final uploadedAt = _formatDate(d['uploadedAt']);

    return _card(
      title: 'PO Document',
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName.isEmpty ? 'Attached Document' : fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (uploadedAt != '—')
                  Text(
                    'Uploaded: $uploadedAt',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (url.isNotEmpty)
            FilledButton.icon(
              onPressed: () => _openUrl(context, url),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open'),
            )
          else
            Text(
              'No URL',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _card({required Widget child, String? title}) {
    return PoSectionCard(title: title, child: child);
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
