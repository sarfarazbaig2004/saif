import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/modules/customer_po/screens/customer_po_detail_screen.dart';
import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';

class CustomerPoListScreen extends StatelessWidget {
  final String companyId;

  const CustomerPoListScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer PO'),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerPoFormScreen(companyId: companyId),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create PO'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('customer_pos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load Customer POs: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No Customer PO found. Create your first PO.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final poNumber = (data['poNumber'] ?? '').toString();
              final customerName = (data['customerName'] ?? '').toString();
              final projectName = (data['projectName'] ?? '').toString();
              final status = (data['status'] ?? 'draft').toString();
              final totalValue = (data['totalValue'] is num)
                  ? (data['totalValue'] as num).toDouble()
                  : 0.0;

              return Card(
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerPoDetailScreen(
                        companyId: companyId,
                        docId: docs[index].id,
                      ),
                    ),
                  ),
                  title: Text(
                    poNumber.isEmpty ? 'PO Number Missing' : poNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '$customerName\n$projectName',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(totalValue),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(status),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
