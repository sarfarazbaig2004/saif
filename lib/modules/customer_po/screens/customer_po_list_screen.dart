import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
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
      data['internalPoNo'],
      data['poNumber'],
      data['customerPoNumber'],
      data['customerName'],
      data['projectName'],
      data['siteLocation'],
      data['subject'],
      data['status'],
    ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

    return values.contains(search);
  }

  DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final activeCompanyId = context.watchTenant.selectedTenantId.trim().isEmpty
        ? widget.companyId
        : context.watchTenant.selectedTenantId.trim();
    final collectionPath =
        'companies/$activeCompanyId/${SalesCollections.customerPos}';
    debugPrint(
      'CUSTOMER_PO_LIST_QUERY widgetCompanyId=${widget.companyId} '
      'activeCompanyId=$activeCompanyId path=$collectionPath',
    );

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
                      CustomerPoFormScreen(companyId: activeCompanyId),
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
            .doc(activeCompanyId)
            .collection(SalesCollections.customerPos)
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

          debugPrint(
            'CUSTOMER_PO_LIST_RESULT path=$collectionPath count=${snapshot.data!.docs.length}',
          );
          for (final doc in snapshot.data!.docs) {
            final data = doc.data();
            debugPrint(
              'CUSTOMER_PO_LIST_DOC path=$collectionPath/${doc.id} '
              'docId=${doc.id} '
              'internalPoNo=${data['internalPoNo'] ?? data['poNumber'] ?? ''} '
              'customerName=${data['customerName'] ?? ''} '
              'status=${data['status'] ?? ''} '
              'linkedQuotationId=${data['linkedQuotationId'] ?? data['quotationId'] ?? ''}',
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            return doc.data()['isDeleted'] != true;
          }).toList();

          final filteredDocs = docs.where((doc) {
            final data = doc.data();
            return _matchesSearch(data);
          }).toList();
          filteredDocs.sort((a, b) {
            final aDate = _dateValue(a.data()['createdAt']);
            final bDate = _dateValue(b.data()['createdAt']);
            return bDate.compareTo(aDate);
          });

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

              final internalPoNo =
                  (data['internalPoNo'] ?? data['poNumber'] ?? '').toString();
              final customerPoNumber = (data['customerPoNumber'] ?? '')
                  .toString()
                  .trim();
              final customerName = (data['customerName'] ?? '').toString();
              final projectName = (data['projectName'] ?? '').toString();
              final status = (data['status'] ?? 'draft').toString();
              final totalValue = (data['totalValue'] is num)
                  ? (data['totalValue'] as num).toDouble()
                  : 0.0;

              return Card(
                child: ListTile(
                  isThreeLine: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerPoDetailScreen(
                        companyId: activeCompanyId,
                        docId: poDoc.id,
                      ),
                    ),
                  ),
                  title: Text(
                    internalPoNo.isEmpty
                        ? 'Internal PO No Missing'
                        : 'Internal PO No : $internalPoNo',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      if (customerPoNumber.isNotEmpty)
                        'Customer PO No : $customerPoNumber',
                      'Customer : $customerName',
                      if (projectName.isNotEmpty) projectName,
                    ].join('\n'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: SizedBox(
                    width: 150,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.format(totalValue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              CustomerPoStatusChip(status: status),
                            ],
                          ),
                          const SizedBox(width: 6),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value != 'duplicate') return;

                              await CustomerPoRecordStatusService.markAsDuplicate(
                                companyId: activeCompanyId,
                                docId: poDoc.id,
                                reason: 'Created twice by mistake',
                              );

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Duplicate Customer PO deleted from active list',
                                  ),
                                ),
                              );
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Delete Duplicate Entry'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
