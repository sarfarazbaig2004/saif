import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MirajVendorLedgerScreen extends StatelessWidget {
  final String tenantId;

  const MirajVendorLedgerScreen({super.key, required this.tenantId});

  CollectionReference<Map<String, dynamic>> get _vendorsRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(tenantId)
      .collection('vendors');

  CollectionReference<Map<String, dynamic>> get _offersRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(tenantId)
      .collection('vendor_offers');

  CollectionReference<Map<String, dynamic>> get _purchaseOrdersRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(tenantId)
          .collection('purchase_orders');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: FutureBuilder<_VendorLedgerData>(
        future: _loadLedger(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load ledger: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? const _VendorLedgerData.empty();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LedgerHeader(data: data),
              const SizedBox(height: 14),
              Expanded(
                child: data.vendorRows.isEmpty
                    ? const _EmptyLedgerState()
                    : ListView.separated(
                        itemCount: data.vendorRows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _VendorLedgerCard(row: data.vendorRows[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_VendorLedgerData> _loadLedger() async {
    final vendorsSnap = await _vendorsRef.get();
    final offersSnap = await _offersRef.get();
    final purchaseOrdersSnap = await _purchaseOrdersRef.get();

    final rowsByVendor = <String, _VendorLedgerRowBuilder>{};

    for (final doc in vendorsSnap.docs) {
      final data = doc.data();
      if (data['isDeleted'] == true) continue;
      final vendorName = (data['name'] ?? '').toString().trim();
      if (vendorName.isEmpty) continue;
      rowsByVendor.putIfAbsent(
        _key(vendorName),
        () => _VendorLedgerRowBuilder(vendorName: vendorName),
      );
    }

    for (final doc in offersSnap.docs) {
      final data = doc.data();
      final vendorName = (data['vendorName'] ?? '').toString().trim();
      if (vendorName.isEmpty) continue;
      final row = rowsByVendor.putIfAbsent(
        _key(vendorName),
        () => _VendorLedgerRowBuilder(vendorName: vendorName),
      );
      row.offerCount += 1;
      row.offerTotal += _toDouble(data['totalAmount']);
      row.attachmentCount += _attachmentCount(data);
    }

    for (final doc in purchaseOrdersSnap.docs) {
      final data = doc.data();
      final vendorName = (data['vendorName'] ?? '').toString().trim();
      if (vendorName.isEmpty) continue;
      final row = rowsByVendor.putIfAbsent(
        _key(vendorName),
        () => _VendorLedgerRowBuilder(vendorName: vendorName),
      );
      row.purchaseOrderCount += 1;
      row.purchaseOrderTotal += _toDouble(data['totalAmount']);
    }

    final rows = rowsByVendor.values.map((row) => row.build()).toList()
      ..sort((a, b) => a.vendorName.compareTo(b.vendorName));

    return _VendorLedgerData(
      vendorRows: rows,
      vendorCount: rows.length,
      offerCount: rows.fold(
        0,
        (runningTotal, row) => runningTotal + row.offerCount,
      ),
      purchaseOrderCount: rows.fold(
        0,
        (runningTotal, row) => runningTotal + row.purchaseOrderCount,
      ),
      offerTotal: rows.fold(
        0,
        (runningTotal, row) => runningTotal + row.offerTotal,
      ),
      purchaseOrderTotal: rows.fold(
        0,
        (runningTotal, row) => runningTotal + row.purchaseOrderTotal,
      ),
    );
  }

  String _key(String vendorName) => vendorName.trim().toLowerCase();

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  int _attachmentCount(Map<String, dynamic> data) {
    final attachments = data['attachments'];
    if (attachments is List) return attachments.length;
    return data['attachment'] is Map ? 1 : 0;
  }
}

class _LedgerHeader extends StatelessWidget {
  final _VendorLedgerData data;

  const _LedgerHeader({required this.data});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vendor Ledger',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Vendor-wise view of offers, attachments, and converted purchase orders.',
            style: TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(label: 'Vendors', value: '${data.vendorCount}'),
              _Metric(label: 'Offers', value: '${data.offerCount}'),
              _Metric(label: 'POs', value: '${data.purchaseOrderCount}'),
              _Metric(label: 'Offer Total', value: _money(data.offerTotal)),
              _Metric(
                label: 'PO Total',
                value: _money(data.purchaseOrderTotal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorLedgerCard extends StatelessWidget {
  final _VendorLedgerRow row;

  const _VendorLedgerCard({required this.row});

  @override
  Widget build(BuildContext context) {
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
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF2FF),
                child: Icon(Icons.business_outlined, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.vendorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(label: 'Offers', value: '${row.offerCount}'),
              _Metric(label: 'Attachments', value: '${row.attachmentCount}'),
              _Metric(
                label: 'Purchase Orders',
                value: '${row.purchaseOrderCount}',
              ),
              _Metric(label: 'Offer Value', value: _money(row.offerTotal)),
              _Metric(label: 'PO Value', value: _money(row.purchaseOrderTotal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

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
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyLedgerState extends StatelessWidget {
  const _EmptyLedgerState();

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
            Icon(Icons.menu_book_outlined, size: 42, color: Color(0xFF667085)),
            SizedBox(height: 12),
            Text(
              'No ledger activity yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Create vendors and vendor offers first. Converted purchase orders will appear here vendor-wise.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667085), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorLedgerRowBuilder {
  final String vendorName;
  int offerCount = 0;
  int attachmentCount = 0;
  int purchaseOrderCount = 0;
  double offerTotal = 0;
  double purchaseOrderTotal = 0;

  _VendorLedgerRowBuilder({required this.vendorName});

  _VendorLedgerRow build() {
    return _VendorLedgerRow(
      vendorName: vendorName,
      offerCount: offerCount,
      attachmentCount: attachmentCount,
      purchaseOrderCount: purchaseOrderCount,
      offerTotal: offerTotal,
      purchaseOrderTotal: purchaseOrderTotal,
    );
  }
}

class _VendorLedgerData {
  final List<_VendorLedgerRow> vendorRows;
  final int vendorCount;
  final int offerCount;
  final int purchaseOrderCount;
  final double offerTotal;
  final double purchaseOrderTotal;

  const _VendorLedgerData({
    required this.vendorRows,
    required this.vendorCount,
    required this.offerCount,
    required this.purchaseOrderCount,
    required this.offerTotal,
    required this.purchaseOrderTotal,
  });

  const _VendorLedgerData.empty()
    : vendorRows = const [],
      vendorCount = 0,
      offerCount = 0,
      purchaseOrderCount = 0,
      offerTotal = 0,
      purchaseOrderTotal = 0;
}

class _VendorLedgerRow {
  final String vendorName;
  final int offerCount;
  final int attachmentCount;
  final int purchaseOrderCount;
  final double offerTotal;
  final double purchaseOrderTotal;

  const _VendorLedgerRow({
    required this.vendorName,
    required this.offerCount,
    required this.attachmentCount,
    required this.purchaseOrderCount,
    required this.offerTotal,
    required this.purchaseOrderTotal,
  });
}

String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';
