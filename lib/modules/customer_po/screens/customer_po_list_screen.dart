import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/modules/customer_po/screens/customer_po_detail_screen.dart';
import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/customer_po_search_bar.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/customer_po_status_chip.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_record_status_service.dart';

class CustomerPoListScreen extends StatefulWidget {
  final String companyId;

  const CustomerPoListScreen({super.key, required this.companyId});

  @override
  State<CustomerPoListScreen> createState() => _CustomerPoListScreenState();
}

class _CustomerPoListScreenState extends State<CustomerPoListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final search = _searchText.trim().toLowerCase();
    if (search.isEmpty) return true;

    final values = [
      data['poNumber'],
      data['customerName'],
      data['projectName'],
      data['siteLocation'],
      data['subject'],
      data['status'],
    ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

    return values.contains(search);
  }

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
                  builder: (_) =>
                      CustomerPoFormScreen(companyId: widget.companyId),
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
            .doc(widget.companyId)
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
          final seenKeys = <String>{};
          final filteredDocs = docs.where((doc) {
            final data = doc.data();
            if (data['isDeleted'] == true) return false;
            if (!_matchesSearch(data)) return false;

            final key = [
              data['customerId'] ?? '',
              data['poNumber'] ?? '',
            ].join('|');

            if (seenKeys.contains(key)) return false;
            seenKeys.add(key);
            return true;
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CustomerPoSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchText = value),
                );
              }

              final poDoc = filteredDocs[index - 1];
              final data = poDoc.data();

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
                        companyId: widget.companyId,
                        docId: poDoc.id,
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(totalValue),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          CustomerPoStatusChip(status: status),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value != 'duplicate') return;

                          await CustomerPoRecordStatusService.markAsDuplicate(
                            companyId: widget.companyId,
                            docId: poDoc.id,
                            reason: 'Created twice by mistake',
                          );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer PO marked as duplicate'),
                            ),
                          );
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Mark as Duplicate'),
                          ),
                        ],
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
