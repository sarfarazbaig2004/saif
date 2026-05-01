// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MirajVendorPurchaseOrderScreen extends StatelessWidget {
  final String tenantId;

  const MirajVendorPurchaseOrderScreen({super.key, required this.tenantId});

  CollectionReference<Map<String, dynamic>> get _purchaseOrdersRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(tenantId)
          .collection('purchase_orders');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _purchaseOrdersRef
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PoHeader(),
              const SizedBox(height: 14),
              Expanded(
                child:
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : docs.isEmpty
                    ? const _PoEmptyState()
                    : ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return _PurchaseOrderCard(
                            purchaseOrderId: doc.id,
                            data: doc.data(),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final String purchaseOrderId;
  final Map<String, dynamic> data;

  const _PurchaseOrderCard({required this.purchaseOrderId, required this.data});

  Future<void> _openAttachment(Map<String, dynamic> attachment) async {
    final uri = Uri.tryParse((attachment['url'] ?? '').toString());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final attachments = _normalizedAttachments(data);
    final lines = (data['lines'] as List? ?? []);
    final status = (data['status'] ?? 'draft').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_cart_checkout_outlined,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (data['poNo'] ?? purchaseOrderId).toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (data['vendorName'] ?? '').toString(),
            style: const TextStyle(
              color: Color(0xFF475467),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MiniMetric(
                label: 'Source Subject',
                value: _sourceSubjectText(data),
              ),
              _MiniMetric(label: 'Source Offer', value: _sourceOfferText(data)),
              _MiniMetric(label: 'Items', value: '${lines.length}'),
              _MiniMetric(
                label: 'Total',
                value:
                    'Rs ${(((data['totalAmount'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)}',
              ),
            ],
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...attachments.map(
              (attachment) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (attachment['name'] ?? 'Vendor offer attachment')
                            .toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAttachment(attachment),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...lines.take(4).map((line) {
              final map = line is Map ? Map<String, dynamic>.from(line) : {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (map['productName'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${map['qty'] ?? 0} x Rs ${map['rate'] ?? 0}',
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _sourceOfferText(Map<String, dynamic> data) {
    final offerNo = (data['sourceOfferNo'] ?? '').toString().trim();
    return offerNo.isEmpty ? 'Linked' : offerNo;
  }

  String _sourceSubjectText(Map<String, dynamic> data) {
    final subject = (data['sourceOfferSubject'] ?? '').toString().trim();
    return subject.isEmpty ? 'Not set' : subject;
  }

  List<Map<String, dynamic>> _normalizedAttachments(Map<String, dynamic> data) {
    final attachments = data['sourceOfferAttachments'];
    if (attachments is List) {
      return attachments
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final attachment = data['sourceOfferAttachment'];
    if (attachment is Map) {
      return [Map<String, dynamic>.from(attachment)];
    }

    return [];
  }
}

class _PoHeader extends StatelessWidget {
  const _PoHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          _HeaderIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase Orders',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Accepted vendor offers become PO drafts here with the original offer attachment linked.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          Icons.shopping_cart_checkout_outlined,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _PoEmptyState extends StatelessWidget {
  const _PoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4E7EC)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 42,
              color: Color(0xFF667085),
            ),
            SizedBox(height: 12),
            Text(
              'No purchase orders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Convert an accepted vendor offer to create a purchase order draft.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667085), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
